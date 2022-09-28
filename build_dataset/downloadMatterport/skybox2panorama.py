import os

path_skybox = 'C:\\Users\\zsd\\CIIRC\\data\\skybox\\Broca Living Lab without Curtains'
path_panos = os.path.join(path_skybox,'panos')

if not os.path.exists(path_panos):
    os.makedirs(path_panos)

res = '8192 4096'
form = 'JPEG'
blender_path = 'C:\\Program Files\\Blender Foundation\\Blender 2.83\\blender.exe'
output = os.path.join(path_skybox,'out')

i = 0
while True: 
    front = os.path.join(path_skybox,'pano'+str(i)+'_skybox3.jpg')
    back = os.path.join(path_skybox,'pano'+str(i)+'_skybox1.jpg')
    left = os.path.join(path_skybox,'pano'+str(i)+'_skybox2.jpg')
    right = os.path.join(path_skybox,'pano'+str(i)+'_skybox4.jpg')
    top = os.path.join(path_skybox,'pano'+str(i)+'_skybox0.jpg')
    bottom = os.path.join(path_skybox,'pano'+str(i)+'_skybox5.jpg')
    
    if not os.path.exists(front):
        break
    cmd = 'cube2sphere "'+front+'" "'+back+'" "'+left+'" "'+right+'" "'+top+'" "'+bottom+'" -r '+res+' -f'+form+' -o "'+output+'" -b "'+blender_path+'"'
    # cmd = 'cube2sphere pano0_skybox3.jpg pano0_skybox1.jpg pano0_skybox2.jpg pano0_skybox4.jpg pano0_skybox0.jpg pano0_skybox5.jpg -r 8192 4096 -fJPEG -opano -b "C:\Program Files\Blender Foundation\Blender 2.83\blender.exe"'
    os.system(cmd)
    os.rename(output+'0001.jpg',os.path.join(path_panos,'pano'+str(i)+'.jpg'))
    print('pano'+str(i))
    i = i+1