from PIL import Image
from IPython.display import display
import os
from numpy import asarray
import numpy as np

path = r'C:\Users\zsd\CIIRC\data\matterport\Broca Hospital with Curtains'

path_skybox = os.path.join(path, 'skybox')
path_old = os.path.join(path, 'panos')
path_new = os.path.join(path, 'panos_rotated')

if not os.path.exists(path_new):
    os.makedirs(path_new)

i = 0
while True:
    name = 'pano'+str(i)+'.jpg'
    if not os.path.exists(os.path.join(path_old, name)):
        break
    old_pic = Image.open(os.path.join(path_old, name))
    # display(old_pic)
    
    old_np = asarray(old_pic)
    
    new_np = np.zeros(old_np.shape)
    y = new_np.shape[1]//2
    
    new_np[:,:y,:] = old_np[:,y:,:]
    new_np[:,y:,:] = old_np[:,:y,:]
    
    rotated_pic = Image.fromarray(new_np.astype(np.uint8))
    # display(rotated_pic)
    
    rotated_pic.save(os.path.join(path_new, name))
    
    print('Rotating '+ name)
    i = i + 1
