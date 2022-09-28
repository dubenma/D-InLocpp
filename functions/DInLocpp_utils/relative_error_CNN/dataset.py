import os

import torch
from torch.utils.data import DataLoader, Dataset

import scipy.io
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt
import numpy as np
import cv2

def load_data_from_files(root_dir, IMG_SIZE, out_path=''):
    ''' General function for retreiving trainig data specific for our cluster data structure and format.
        Desired output of this function is a tuple of
        (queries, queries_m, pairs, errors),
        where queries is a list of query images (already as tensonrs), queries_m are corresponding images with applied gt masks, pairs is a list of tuples, 
        where each tuple holds one query-synth image pair as (query_img_id_in_the_array, synth_image_tensor) 
        and errors are gt_error values. In our case computed as combination of rotation error and translation error - for details
        on errors see the paper. 
    '''
    queries = []
    queries_m = []
    pairs = [] 
    errors = []

    loaded = False
    if out_path:
        pairs_path = os.path.join(out_path, 'pairs.npy')
        queries_path = os.path.join(out_path, 'queries.npy')
        queriesm_path = os.path.join(out_path, 'queries_m.npy')
        errors_path = os.path.join(out_path, 'errors.npy')
        if os.path.exists(pairs_path) and os.path.exists(queries_path) and os.path.exists(errors_path):
            pairs = np.load(pairs_path, allow_pickle=True)
            queries = np.load(queries_path, allow_pickle=True)
            queries_m = np.load(queriesm_path, allow_pickle=True)
            errors = np.load(errors_path, allow_pickle=True)
            loaded = True
            print('Preprocessed data found, loading .npy files.')

    if not loaded:
        print('No preprocessed data found.')
        query_id = -1
        print(f'Starting data loading from {root_dir}.')
        query_fns = os.listdir(root_dir)
        for query_fn in query_fns:
            print(f'--Processing query no. {query_fn}.')
            query_dir = os.path.join(root_dir, query_fn)
            query_image_path = os.path.join(query_dir, 'query.mat')
            try:
                query = scipy.io.loadmat(query_image_path)
            except:
                print('----Exception encoutered!')
                continue
            query_img = cv2.resize(query['query']['query_img'][0][0], dsize=IMG_SIZE)
            masked_img = cv2.resize(query['query']['query_img'][0][0], dsize=IMG_SIZE)
            mask = cv2.resize(query['query']['qt_mask'][0][0], dsize=IMG_SIZE, interpolation=cv2.INTER_NEAREST)
            masked_img[mask>0] = [255,0,0]

            queries.append(torch.tensor(query_img).permute(2,0,1).to(torch.float)[None]) 
            queries_m.append(torch.tensor(masked_img).permute(2,0,1).to(torch.float)[None]) 
            query_id += 1

            synth_fns = os.listdir(query_dir)
            for synth_fn in synth_fns:
                if synth_fn == 'query.mat':
                    continue
                synth_image_path = os.path.join(query_dir, synth_fn)
                synth = scipy.io.loadmat(synth_image_path)
                synth_img = cv2.resize(synth['synth']['synth_img'][0][0], dsize=IMG_SIZE)
                pairs.append((query_id, torch.tensor(synth_img).permute(2,0,1).to(torch.float)[None]))

                q_error = synth['synth']['error_rotation'][0][0][0][0]
                t_error = synth['synth']['error_translation'][0][0][0][0]
                errors.append( torch.tensor([q_error, t_error]).to(torch.float32))
                #error_num = min(1, (q_error + t_error*10)/50)
                #errors.append(torch.tensor(error_num).to(torch.float32))
        np.save(os.path.join(out_path, 'pairs.npy'), pairs)
        np.save(os.path.join(out_path, 'queries.npy'), queries)
        np.save(os.path.join(out_path, 'queries_m.npy'), queries_m)
        np.save(os.path.join(out_path, 'errors.npy'), errors) 
    return queries, queries_m, pairs, errors


class PosesDataset(Dataset):
    """
        Dataset for relative camera pose error estimation with dynamic objects.
    """
    def __init__(self, queries, pairs, errors, error_fc, transform=None):
        self.queries = queries
        self.pairs = pairs
        self.errors = errors
        self.error_fc = error_fc
        
    def __getitem__(self, i):
        query_id = self.pairs[i][0]
        query_tensor = self.queries[query_id]
        synth_tensor = self.pairs[i][1]
        q_error = self.errors[i][0]
        t_error = self.errors[i][1]
        error_num = torch.tensor(self.error_fc(q_error,t_error)).to(torch.float32)
        return torch.concat([query_tensor, synth_tensor]), error_num
    
    def __len__(self):
        return len(self.pairs)
