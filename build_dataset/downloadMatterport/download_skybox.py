import json
import os.path
import requests
from requests.auth import HTTPBasicAuth

pano_path = 'C:\\Users\\zsd\\CIIRC\\data\\skybox\\Broca Hospital without Curtains'
space_id = '6ak4XqnRK9c'

matterport_id = '' 
secret_token = ''
    
if not os.path.exists(pano_path):
    os.makedirs(pano_path)
    
step = 50
s = 0
while True:
    # Making a get request
    url = 'https://api.matterport.com/api/models/graph?query=query{model(id:"'+space_id+'"){locations{panos{id%20position{x%20y%20z}%20rotation{x%20y%20z%20w}%20skybox(resolution:"2k"){children}}}}}'
    response = requests.get(url,
                auth = HTTPBasicAuth(matterport_id, secret_token))
    
    data = json.loads(response.text)
    l = len(data['data']['model']['locations'])
    
    stop = l if l < s+step else s+step       
    for i in range(s,stop):
        pano = data['data']['model']['locations'][i]['panos'][0]
        id = pano['id']
        
        pos_x = pano['position']['x']
        pos_y = pano['position']['y']
        pos_z = pano['position']['z']
        
        rot_x = pano['rotation']['x']
        rot_y = pano['rotation']['y']
        rot_z = pano['rotation']['z']
        rot_w = pano['rotation']['w']
        
        skybox = pano['skybox']['children']
        
        print('skybox'+str(i)+' downloading')
        s = s + 1
        
        for j in range(len(skybox)):
            url_skybox = skybox[j]
            r = requests.get(url_skybox)
            name = os.path.join(pano_path,'pano'+str(i)+'_skybox'+str(j)+'.jpg')
            open(name, 'wb').write(r.content)

    if i == l-1:
        break

    