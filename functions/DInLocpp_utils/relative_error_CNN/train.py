import argparse
import os
import torch
from torch.utils.data import DataLoader

from sklearn.model_selection import train_test_split

from models import RelPNet
from dataset import PosesDataset, load_data_from_files
import datetime

IMG_SIZE = (448,252) # Resize images to this resolution to save GPU memory

def evaluate(model, dataloader, device):
    print("Evaluating..")
    model.eval()
    total_err, total_count = 0, 0

    with torch.no_grad():
        for idx, (inputs , target) in enumerate(dataloader):
            output = model(inputs.to(device)).cpu()
            total_err += (output.squeeze().abs() - target).abs().sum()
            total_count += target.size(0)

    return total_err/total_count

def loss_f(output, target):
    loss = torch.mean((output.abs()- target)**2)
    return loss

def error_fn1(q_error, t_error):
    return min(1, (q_error + t_error*10)/50)

def error_fn2(q_error, t_error):
    return min(1, (q_error + t_error*5)/50)

def main(args):
    # load lists of query images, masked query images, list of query id - synth image pairs and pair corresponding errors
    queries, queries_m, pairs, errors =  load_data_from_files(args.raw_data_path, IMG_SIZE, args.preprocessed_data_path)

    pairs_train, pairs_test, errors_train, errors_test = train_test_split(pairs, errors, test_size=0.05, random_state=7)

    error_fn = error_fn1 if '10' in args.error_fc else error_fn2 # error function used in dataset to serve target loss from gt. angle and gt. translation errors
    qrs = queries if args.method_name.endswith('nm') else queries_m
    trn_dataset = PosesDataset(qrs, pairs_train, errors_train, error_fn)
    trn_loader = DataLoader(trn_dataset, batch_size=16, shuffle=True)

    tst_dataset = PosesDataset(qrs, pairs_test, errors_test, error_fn)
    tst_loader = DataLoader(tst_dataset, batch_size=16, shuffle=True)

    device = torch.device(args.device if torch.cuda.is_available() else 'cpu')
    model = RelPNet(encoder=args.method_name).to(device)
    if args.checkpoint_path:
        checkpoint = torch.load(args.checkpoint_path)
        model.load_state_dict(checkpoint)

    optimizer = torch.optim.Adam(model.parameters(), lr=0.0001)

    best_error = float('inf')
    print(f'Starting training for method {args.method_name}.')
    
    for epoch in range(40):
        running_loss = 0.0

        model.train()
        for i, (inputs , target) in enumerate(trn_loader):
            inputs = inputs.to(device)
            target = target.to(device)
            model.zero_grad()

            output = model(inputs)
            loss = loss_f(output.squeeze(), target)
            
            loss.backward()
            optimizer.step()
            
            running_loss += loss.item()
            print(f'  It no. {i} | current loss {loss.item():.8} | loss so far:{running_loss:.8}')

        tst_err_avg = evaluate(model, tst_loader, device)
        trn_err_avg = evaluate(model, trn_loader, device)
        print(f'Epoch no. {epoch} | cumm. loss {running_loss} | tst avg. err  {tst_err_avg} | trn  avg. err {trn_err_avg}')
        if abs(tst_err_avg) < best_error:
            print("Saving.")
            best_error = tst_err_avg
            out_wgh_path = os.path.join(args.out_wghs_path, args.method_name)
            if not os.path.exists(out_wgh_path):
                os.makedirs(out_wgh_path)
            now = datetime.datetime.now()
            out_name =  f'rpecnn_err:{best_error:.3f}_ep:{epoch}_{now:%m-%d_%H:%M}.pt'
            torch.save(model.state_dict(),  os.path.join(out_wgh_path,out_name))

if __name__ == "__main__":
    parser = argparse.ArgumentParser("IMC2021 sample submission script")
    parser.add_argument("--method_name", type=str,  choices={'RelPNet_b0', 'RelPNet_b3', 'RelPNet_b0_nm', 'RelPNet_b3_nm'}, default='RelPNet_b0')
    parser.add_argument("--error_fc", type=str,  choices={'abs_10_50', 'abs_5_50'}, default='abs_10_50')
    parser.add_argument("--device", type=str,  choices={'cuda:0', 'cuda:1', 'cpu'}, default='cuda:1')
    parser.add_argument("--out_wghs_path", type=str, default='/home/user01/projects/relative_pose/rpecnn/wghs/')
    parser.add_argument("--preprocessed_data_path", type=str, default='/home/user01/projects/relative_pose/rpecnn/data')
    parser.add_argument("--raw_data_path", type=str, default='/local1/projects/artwin/datasets/Broca_dataset/nn_dataset/Broca_dataset_dynamic_1/randomized_from_database/')
    parser.add_argument("--checkpoint_path", type=str, default='')
    parser.add_argument("--use_mask", type=str, choices={'qt_mask', 'yolact', 'none'}, default='qt_mask')
    args = parser.parse_args()

    main(args)
