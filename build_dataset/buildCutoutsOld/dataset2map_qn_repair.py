import numpy as np


import matplotlib.pyplot as plt
from scipy.spatial.transform import Rotation as R
import scipy.io as sio
import sys
import os
import open3d as o3d
import py360convert
import multiprocessing  
from itertools import repeat
from sklearn.model_selection import train_test_split
import trimesh
import json
os.environ["PYOPENGL_PLATFORM"] = "egl"
import pyrender
from distutils.dir_util import copy_tree

sys.path.insert(1, os.path.join(sys.path[0], '../../functions'))
from InLocCIIRC_utils.projectMesh.projectMesh import projectMeshCached


class NpEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer):
            return int(obj)
        elif isinstance(obj, np.floating):
            return float(obj)
        elif isinstance(obj, np.ndarray):
            return obj.tolist()
        else:
            return super(NpEncoder, self).default(obj)



def getSweepRecord(sweepData, panoId):
    for i in range(len(sweepData)):
        sweepRecord = sweepData[i]
        if sweepRecord['panoId'] == panoId:
            return sweepRecord

# FoV: degrees
def computeFocalLength(sensorSize, FoV):
    FoV = np.deg2rad(FoV)
    return sensorSize / (2*np.tan(FoV/2))

# FoV: degrees
def computeFoV(sensorSize, f):
    FoV = 2*np.arctan((sensorSize/2)/f)
    return np.rad2deg(FoV)

def processPanoramas(panoIds,thisSpaceCutoutsDir,panoramasDir,pano_prefix,fovHorizontal,fovVertical,sensorHeight,sensorWidth):
    env = {}
    env['thisSpaceCutoutsDir']= thisSpaceCutoutsDir
    env['panoramasDir']= panoramasDir
    env['pano_prefix']= pano_prefix
    env['fovHorizontal']= fovHorizontal
    env['fovVertical']= fovVertical
    env['sensorHeight']= sensorHeight
    env['sensorWidth']= sensorWidth
    Ids_db ,Ids_test = train_test_split(list(range(1,N_Panoramas+1)),test_size=0.1,random_state=16) 
    env['Ids_db']= Ids_db
    env['Ids_test']= Ids_test
    
    fn = os.path.join(thisSpaceCutoutsDir,'env_params.json')
    # with open(fn, 'w') as fp:  
    #     json.dump(env, fp, cls=NpEncoder)
    for panoId in panoIds:
       cutoutsFromPanorama(panoId, env)
       
    # pool = multiprocessing.Pool(processes=1)
    # pool.starmap(cutoutsFromPanorama, zip(panoIds, repeat(env)))
    # pool.close()
    # pool.join()  

    fn = os.path.join('/local/localization_service/Workspace','query_mapping.json')
    with open(fn, 'w') as fp:  
        json.dump(query_mapping, fp, cls=NpEncoder) 
    print('done')


def cutoutsFromPanorama(panoId,env):

    thisSpaceCutoutsDir= env['thisSpaceCutoutsDir']
    panoramasDir=env['panoramasDir'] 
    pano_prefix=env['pano_prefix']
    fovHorizontal=env['fovHorizontal']
    fovVertical=env['fovVertical']
    sensorHeight= env['sensorHeight']
    sensorWidth = env['sensorWidth']
    print('processing img #'+str(panoId) + ' db image:' + str(panoId in env['Ids_db']))
    if panoId in env['Ids_db']:
        dataset='hospital_1-database'
    else:
        dataset='hospital_1-query'

    thisPanoCutoutsDir = os.path.join(thisSpaceCutoutsDir,dataset)
    # if not os.path.isdir(thisPanoCutoutsDir):
    #     os.mkdir(thisPanoCutoutsDir)

    

    thisSpaceCutoutsDepth = os.path.join(thisPanoCutoutsDir,'depthmaps', str(panoId))
    thisSpaceCutoutsMesh = os.path.join(thisPanoCutoutsDir,'meshes', str(panoId))
    thisSpaceCutoutsCutout = os.path.join(thisPanoCutoutsDir,'cutouts', str(panoId))
    thisSpaceCutoutsMats = os.path.join(thisPanoCutoutsDir,'matfiles', str(panoId))
    thisSpaceCutoutsPoses = os.path.join(thisPanoCutoutsDir,'poses', str(panoId))
    # if panoId not in env['Ids_db']:
    #     thisSpaceQueries = os.path.join(thisPanoCutoutsDir,'query_all')
    #     if not os.path.isdir(thisSpaceQueries):
    #         os.makedirs(thisSpaceQueries)


    # if not os.path.isdir(thisSpaceCutoutsDepth):
    #     os.makedirs(thisSpaceCutoutsDepth)
    # if not os.path.isdir(thisSpaceCutoutsMesh):
    #     os.makedirs(thisSpaceCutoutsMesh)
    # if not os.path.isdir(thisSpaceCutoutsCutout):
    #     os.makedirs(thisSpaceCutoutsCutout)    
    # if not os.path.isdir(thisSpaceCutoutsMats):
    #     os.makedirs(thisSpaceCutoutsMats)   
    # if not os.path.isdir(thisSpaceCutoutsPoses):
    #     os.makedirs(thisSpaceCutoutsPoses)   
    

    panoramaPath = os.path.join(panoramasDir, pano_prefix+str(panoId) + '.jpg')
    # panoramaImage = plt.imread(panoramaPath)
    # sweepRecord = getSweepRecord(sweepData, panoId)
    #xh = np.arange(-180, 180, 30)
    step_angle = 30 #30,45,60,90
    xh = np.arange(-180, 180, step_angle)
    yh0 = np.zeros((len(xh)))

    if panoId in env['Ids_db']:
        yhTop = yh0 + 30
        yhBottom = yh0 - 30

        x = np.concatenate((xh, xh, xh))
        y = np.concatenate((yh0, yhTop, yhBottom))
    else:       
        x = xh
        y = yh0

    for i in range(len(x)):

        yaw = x[i]
        pitch = y[i]

        filename = 'mesh_%d_%d_%d.jpg' % (panoId, yaw, pitch)
        path = os.path.join(thisSpaceCutoutsMesh, filename)
        if os.path.exists(path):
            print('part: %d : %d : %d already satisfied' % (panoId, yaw, pitch))
            # continue
        print('part: %d : %d : %d' % (panoId, yaw, pitch))
        # panoramaProjection = py360convert.e2p(panoramaImage, (fovHorizontal, fovVertical),
        #                                         yaw, pitch, (sensorHeight, sensorWidth),
        #                                         in_rot_deg=0, mode='bilinear')
        filename = 'cutout_%d_%d_%d.jpg' % (panoId, yaw, pitch)
        path = os.path.join(thisSpaceCutoutsCutout, filename)
        # plt.imsave(path, panoramaProjection)
        if panoId not in env['Ids_db']:
            filename_query = '%d.jpg' % (len(query_mapping)+1)
            # path = os.path.join(thisSpaceQueries, filename_query)
            # plt.imsave(path, panoramaProjection)
            query_mapping.append(filename)
            # return query_mapping


        # # set up the mat file
        # cameraRotation = sweepRecord['rotation'] + np.array([pitch, -yaw, 0.0])
        # rotationMatrix = R.from_euler('xyz', cameraRotation, degrees=True).as_matrix()
        # RGBcut, XYZcut, depth = projectMeshCached(scene, f, rotationMatrix, sweepRecord['position'], sensorSize, False, -1)
        # filename = filename + '.mat'
        # path = os.path.join(thisSpaceCutoutsMats, filename)
        # sio.savemat(path, {'RGBcut': panoramaProjection, 'XYZcut': XYZcut})


        # path = os.path.join(thisSpaceCutoutsPoses, filename)
        # sio.savemat(path, {'R': rotationMatrix, 'position': sweepRecord['position']})
        # if debug:
        #     filename = 'depth_%d_%d_%d.jpg' % (panoId, yaw, pitch)
        #     path = os.path.join(thisSpaceCutoutsDepth, filename)
        #     plt.imsave(path, depth, cmap=plt.cm.gray_r)

        #     filename = 'mesh_%d_%d_%d.jpg' % (panoId, yaw, pitch)
        #     path = os.path.join(thisSpaceCutoutsMesh, filename)
        #     plt.imsave(path, RGBcut)


if __name__ == '__main__':
    spaceName = 'livinglab_2'
    cutoutName = 'cutouts_36'
    datasetDir ='/local/localization_service/Maps/SPRING'
    sourceDataDir = '/local/localization_service/Data/spring/broca/livinglab_2'
    #datasetDir = '/home/steidsta/projects/Broca_to_map/localization_service/Maps/SPRING'
    #datasetDir= '/home/steidsta/projects/Broca_to_map/localization_service/Maps/SPRING/'
    #datasetDir= '/media/steidsta/Seagate Basic/SPRING/'
    
    pano_prefix = 'Broca-Hospital-with-Curtains-scan'
    
    spaceDir = os.path.join(datasetDir, spaceName)
    thisSpaceCutoutsDir = os.path.join(spaceDir,cutoutName)

    panoramasDir = os.path.join(sourceDataDir, 'rotatedPanoramas')
    #meshPath = os.path.join(spaceDir, 'model', '%s.obj' % spaceName)
    meshPath = os.path.join(sourceDataDir, 'model', 'model_rotated.obj' )
    sweepDataPath = os.path.join(sourceDataDir, 'sweepData', '%s.mat' % spaceName)
    debug = True
    

    _, _, files = next(os.walk(panoramasDir))
    N_Panoramas = len(files)
    panoIds = range(1,N_Panoramas+1)
    #panoIds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ,13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27] # B-315
    #panoIds = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ,13 ,15, 16, 20, 21, 22, 23 ,24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 35, 36, 37] # B-670
    sensorSize = np.array([1600, 1200]) # width, height
    sensorWidth = sensorSize[0]
    sensorHeight = sensorSize[1]
    #fovHorizontal = 60.0 # [deg]; to match InLoc paper; NOTE: do not use! it is not actually working with this
    fovHorizontal = 106.2602047 # [deg]; solid results with this. TODO: what other more optimal FoVs should I try?
    f = computeFocalLength(sensorWidth, fovHorizontal)
    #assert(np.allclose(f, 1385.6406460551023)) # to match InLoc paper
    fovVertical = computeFoV(sensorHeight, f)

    #sweepData = sio.loadmat(sweepDataPath, squeeze_me=True)['sweepData']
    query_mapping = []

    #if not os.path.isdir(thisSpaceCutoutsDir):
    #    os.mkdir(thisSpaceCutoutsDir)
    #copy_tree(panoramasDir, os.path.join(thisSpaceCutoutsDir, 'rotatedPanoramas'))
    #copy_tree(os.path.join(sourceDataDir, 'model'), os.path.join(thisSpaceCutoutsDir, 'model'))
    #copy_tree(os.path.join(sourceDataDir, 'sweepData'), os.path.join(thisSpaceCutoutsDir, 'sweepData'))
    
    #trimeshScene = trimesh.load(meshPath)
    #scene = pyrender.Scene.from_trimesh_scene(trimeshScene) # TODO: this thing consumes ~5-6 GB RAM!

    processPanoramas(panoIds,thisSpaceCutoutsDir,panoramasDir,pano_prefix,fovHorizontal,fovVertical,sensorHeight,sensorWidth)
    
    