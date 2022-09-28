import numpy as np

def load_CIIRC_transformation(path):
    P = np.zeros((4,4), dtype=np.float)
    file = open(path, 'r') 
    lines = file.readlines() 
    i = 0
    for line in lines:
        P[i,:] = np.fromstring(line.strip(), dtype=np.float, sep='\t')
        i += 1
    return P