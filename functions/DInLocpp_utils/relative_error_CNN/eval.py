import os
import matplotlib.pyplot as plt
import argparse
import datetime

import scipy.io
import numpy as np
import cv2

from models import RelPNet
import torch

IMG_SIZE =  (448, 252)
CNN_DSIFT_THRESHOLD = 0.18 # threshold for guidelining of DSIFT by CNN - omptimized empirically on the training data 

def pose_eval(poses_nn, poses_dsift): 
    '''
        Function creating evaluation for graph
    '''
    thrs = np.logspace(0,2,32)/50

    res_nn = []
    res_dsift = []
    poses_nn = np.array(poses_nn)
    poses_dsift = np.array(poses_dsift)
    for thr in thrs:
        angle_nn = poses_nn[:,0] <= 10 
        thr_nn = poses_nn[:,1] <= thr
        res_nn.append((angle_nn * thr_nn).sum()/len(poses_nn))

        angle_dsift = poses_dsift[:,0] <= 10 
        thr_dsift = poses_dsift[:,1] <= thr
        res_dsift.append((angle_dsift * thr_dsift).sum()/len(poses_dsift))

    return thrs, res_nn, res_dsift
    
        
def cnn_dsift_results(results, pose_errs, threshold):
    '''
        Function for assessing results of DSIFT+CNN method on data from the evaluation loop
    '''
    poses = []

    correct = 0
    for key in results.keys():
        res = results[key]
        best_gt = res.argmin(axis=1)[0]
        dsift_res = np.array(res[1,:])
        dsift_res[res[2,:] > threshold] = 0
        best_dsift_nn = dsift_res.argmax()
        correct += best_gt == best_dsift_nn
        poses.append(pose_errs[key][:, best_dsift_nn])
    
    return correct, poses
        

def main(args):
    
    root_dir = args.data_path 
    datsets = { # dataset name with optional specification of which images should not be used
        'hospital_real_objects' : {
            'nonusable_imgs' : []#'2.jpg', '3.jpg', '12.jpg', '17.jpg', '18.jpg', '19.jpg', '21.jpg', '72.jpg', '74.jpg', '75.jpg', '76.jpg', '77.jpg', '78.jpg', '89.jpg', '90.jpg', '91.jpg', '95.jpg', '98.jpg', '103.jpg', '105.jpg', '108.jpg', '112.jpg', '117.jpg', '150.jpg', '151.jpg', '153.jpg', '172.jpg', '173.jpg']
        }
    
    }

    print('Creating NN model.') # create model and load checkpoint
    model = RelPNet(args.method_name)
    checkpoint = torch.load(args.checkpoint_path)
    model.load_state_dict(checkpoint)
    model.eval()

    # result data variables
    total_queries = 0
    values = {'nn': [], 'dsift': []}
    poses = {'nn': [], 'dsift': []}
    correct = {'nn': 0, 'dsift': 0}
    all_estimates = {}
    all_pose_errs = {}

    print(f'Starting data loading from {root_dir}.')
    for dataset in datsets.keys(): 
        print(f'-Processing dataset {dataset}.')
        dtst_dir = os.path.join(root_dir, dataset, 'query_all')
        imgs = sorted(os.listdir(dtst_dir)) # listed images in dataset
        for img in imgs:
            print(f'--Processing query {img}.')
            if img in dataset[dataset]['nonusable_imgs']: # this image should be skipped as it is in nonusabel images
                continue

            img_dir = os.path.join(dtst_dir, img)
            synth_fns = os.listdir(img_dir)

            # variables for estimates
            query_saved = False # save query only once
            estimates = np.zeros([3,len(synth_fns)])
            pose_errs = np.zeros([2,len(synth_fns)])

            for i in range(len(synth_fns)):
                # load img
                synth_fn = synth_fns[i]
                synth_image_path = os.path.join(img_dir, synth_fn)
                synth = scipy.io.loadmat(synth_image_path) #get synthetic matfile

                if not query_saved: # this query image has not yet been processed
                    query_img = cv2.resize(synth['query_img'], dsize=IMG_SIZE)
                    masked_img = cv2.resize(synth['query_img'], dsize=IMG_SIZE)
                    mask =  cv2.resize(synth['mask'], dsize=IMG_SIZE, interpolation=cv2.INTER_NEAREST)

                    masked_img[mask>0] = [255,0,0] #mask img

                    query_tensor = torch.tensor(query_img).permute(2,0,1).to(torch.float)[None]
                    query_masked_tensor = torch.tensor(masked_img).permute(2,0,1).to(torch.float)[None]
                    query_saved = True
                
                synth_img = cv2.resize(synth['synth_img'], dsize=IMG_SIZE)
                synth_tensor = torch.tensor(synth_img).permute(2,0,1).to(torch.float)[None]
                if args.filter_mask:
                    pair_tensor =  torch.concat([query_masked_tensor, synth_tensor])[None]
                else:
                    pair_tensor =  torch.concat([query_tensor, synth_tensor])[None]
                output = model(pair_tensor)

                # get gt error
                err_q = synth['error']['orientation'][0][0][0][0]
                err_t = synth['error']['translation'][0][0][0][0]
                err_num = err_q + err_t*10

                dsift_res = synth['score'][0][0]
                nn_res = abs(output.data.numpy()[0][0])
            
                estimates[:,i] = np.array([err_num, dsift_res, nn_res]).T
                pose_errs[:,i] = np.array([err_q, err_t]).T


            # save data
            all_estimates[img] = estimates
            all_pose_errs[img] = pose_errs
            # get estimates
            best_gt = estimates.argmin(axis=1)[0]
            best_nn = estimates.argmin(axis=1)[2]
            best_dsift = estimates.argmax(axis=1)[1]
            # save results
            correct['dsift'] += best_gt == best_dsift        
            correct['nn'] += best_gt == best_nn
            values['dsift'].append(estimates[1, best_gt])
            values['nn'].append(estimates[2, best_gt])
            poses['dsift'].append(pose_errs[:, best_dsift])
            poses['nn'].append(pose_errs[:, best_nn])
            total_queries += 1

    correct_dcnn, poses_ths= cnn_dsift_results(all_estimates, all_pose_errs, CNN_DSIFT_THRESHOLD)
    cd = int(correct['dsift'])
    cn = int(correct['nn'])
    cdn = int(correct_dcnn)
     
    print('Loading and evaluating data finished.')
    print(f'Accuracy: dsift {cd/total_queries*100:.2f}% | cnn {cn/total_queries*100:.2f}% | dcnn {cdn/total_queries*100:.2f}% ') 

    print('Collect results.')
    thrs, cnnd_res, d_res = pose_eval(poses_ths, poses['dsift'])
    res_graph = {'cdnn':cnnd_res, 'dsift':d_res}
    benchmark_results = {'total_queries':total_queries, 'res_graph':res_graph, 'values':values, 'poses':poses, 'correct':correct, 'all_estimates':all_estimates, 'all_pose_errs':all_pose_errs}
    print('Cdnn and Dsfit results:')
    print(cnnd_res)
    print(d_res)

    #Save and visualize results 
    print("Saving.")
    out_res_path = os.path.join(args.results_path, args.method_name)
    if not os.path.exists(out_res_path):
        os.makedirs(out_res_path)

    now = datetime.datetime.now()
    checkpoint_name = args.checkpoint_path.split('/')[-1][6:-3]
    out_name =  f'results_ds{cd/total_queries*100}_nn{cn/total_queries*100}_checkpoint:--{checkpoint_name}_{now:%m-%d_%H:%M}.npy'
    fig_name = f'fig_ds{cd/total_queries*100}_nn{cn/total_queries*100}_{now:%m-%d_%H:%M}'
    np.save(os.path.join(out_res_path,out_name), benchmark_results)

    plt.figure()
    plt.plot(thrs, cnnd_res, label="d+nn")
    plt.plot(thrs, d_res, label="d")
    plt.savefig(os.path.join(out_res_path,fig_name + '_poses.png'))

    # plt.figure()
    # plt.plot(thrs, cnnd_res, label="d+nn")
    # plt.plot(thrs, d_res, label="d")
    # plt.savefig(os.path.join(out_res_path,fig_name + '_poses'))

    print(f'Saved to {out_res_path}.')

   

if __name__ == "__main__":
    parser = argparse.ArgumentParser("Script")
    parser.add_argument("--data_path", type=str,  default='/local1/homes/user02/data/localization_service_dataset/Cache_Broca_dataset_dynamic_1/dynamic_1/hospital_real_objects_180_queries/outputs-SPRING_Demo/nn_dataset/dynamic_1/')
    parser.add_argument("--method_name", type=str,  choices={'RelPNet_b0', 'RelPNet_b3', 'RelPNet_b0_nm', 'RelPNet_b3_nm', 'RelPNet_b0_old'}, default='RelPNet_b0_nm')
    parser.add_argument("--results_path", type=str, default='/home/user01/projects/relative_pose/rpecnn/results/')
    parser.add_argument("--checkpoint_path", type=str, default='/home/user01/projects/relative_pose/rpecnn/wghs/RelPNet_b0_nm/rpecnn_err:0.066_ep:10_07-30_15:50.pt')#'/home/kafkaon1/projects/relative_pose/rpecnn/wghs/old/rpecnn_b0_wghs_mask_0_0.07548220455646515_15.pt')#'/home/kafkaon1/projects/relative_pose/rpecnn/wghs/RelPNet_b3/rpecnn_err:0.053_ep:34_07-30_02:04.pt')#'/home/kafkaon1/projects/relative_pose/rpecnn/wghs/old/rpecnn_b0_wghs_mask_0_0.07548220455646515_15.pt')#
    parser.add_argument("--filter_mask", type=bool, default=False)
    args = parser.parse_args()

    main(args)
