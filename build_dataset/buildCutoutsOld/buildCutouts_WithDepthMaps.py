import numpy as np
import trimesh
import pyrender
import matplotlib.pyplot as plt
from scipy.spatial.transform import Rotation as R
import scipy.io as sio
import sys
import os
import open3d as o3d
import py360convert
import multiprocessing  
from itertools import repeat

sys.path.insert(1, os.path.join(sys.path[0], '../functions'))
from InLocCIIRC_utils.projectMesh.projectMesh import projectMeshCached

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

    pool = multiprocessing.Pool(processes=1)
    pool.starmap(cutoutsFromPanorama, zip(panoIds, repeat(env)))
    #pool.map(cutoutsFromPanorama, panoIds)
    pool.close()
    pool.join()   
    print('done')


def cutoutsFromPanorama(panoId,env):

    thisSpaceCutoutsDir= env['thisSpaceCutoutsDir']
    panoramasDir=env['panoramasDir'] 
    pano_prefix=env['pano_prefix']
    fovHorizontal=env['fovHorizontal']
    fovVertical=env['fovVertical']
    sensorHeight= env['sensorHeight']
    sensorWidth = env['sensorWidth']
    print('processing img #'+str(panoId))
    thisPanoCutoutsDir = os.path.join(thisSpaceCutoutsDir)
    if not os.path.isdir(thisPanoCutoutsDir):
        os.mkdir(thisPanoCutoutsDir)

    thisSpaceCutoutsDepth = os.path.join(thisPanoCutoutsDir,'depthmaps', str(panoId//5))
    thisSpaceCutoutsMesh = os.path.join(thisPanoCutoutsDir,'meshes', str(panoId//5))
    thisSpaceCutoutsCutout = os.path.join(thisPanoCutoutsDir,'cutouts', str(panoId//5))
    thisSpaceCutoutsMats = os.path.join(thisPanoCutoutsDir,'matfiles', str(panoId//5))

    if not os.path.isdir(thisSpaceCutoutsDepth):
        os.makedirs(thisSpaceCutoutsDepth)
    if not os.path.isdir(thisSpaceCutoutsMesh):
        os.makedirs(thisSpaceCutoutsMesh)
    if not os.path.isdir(thisSpaceCutoutsCutout):
        os.makedirs(thisSpaceCutoutsCutout)    
    if not os.path.isdir(thisSpaceCutoutsMats):
        os.makedirs(thisSpaceCutoutsMats)    
    

    panoramaPath = os.path.join(panoramasDir, pano_prefix+str(panoId) + '.jpg')
    panoramaImage = plt.imread(panoramaPath)
    sweepRecord = getSweepRecord(sweepData, panoId)
    #xh = np.arange(-180, 180, 30)
    step_angle = 30 #30,45,60,90
    xh = np.arange(-180, 180, step_angle)
    yh0 = np.zeros((len(xh)))
    yhTop = yh0 + 30
    yhBottom = yh0 - 30

    x = np.concatenate((xh, xh, xh))
    y = np.concatenate((yh0, yhTop, yhBottom))
    #x = xh
    #y = yh0

    for i in range(len(x)):

        yaw = x[i]
        pitch = y[i]
        print('part: %d : %d : %d' % (panoId, yaw, pitch))
        panoramaProjection = py360convert.e2p(panoramaImage, (fovHorizontal, fovVertical),
                                                yaw, pitch, (sensorHeight, sensorWidth),
                                                in_rot_deg=0, mode='bilinear')
        filename = 'cutout_%d_%d_%d.jpg' % (panoId, yaw, pitch)
        path = os.path.join(thisSpaceCutoutsCutout, filename)
        plt.imsave(path, panoramaProjection)
        # set up the mat file
        cameraRotation = sweepRecord['rotation'] + np.array([pitch, -yaw, 0.0])
        rotationMatrix = R.from_euler('xyz', cameraRotation, degrees=True).as_matrix()
        RGBcut, XYZcut, depth = projectMeshCached(scene, f, rotationMatrix, sweepRecord['position'], sensorSize, False, -1)
        filename = filename + '.mat'
        path = os.path.join(thisSpaceCutoutsMats, filename)
        sio.savemat(path, {'RGBcut': panoramaProjection, 'XYZcut': XYZcut})
        if debug:
            filename = 'depth_%d_%d_%d.jpg' % (panoId, yaw, pitch)
            path = os.path.join(thisSpaceCutoutsDepth, filename)
            plt.imsave(path, depth, cmap=plt.cm.gray_r)

            filename = 'mesh_%d_%d_%d.jpg' % (panoId, yaw, pitch)
            path = os.path.join(thisSpaceCutoutsMesh, filename)
            plt.imsave(path, RGBcut)


if __name__ == '__main__':
    datasetDir ='/media/steidsta/Seagate Basic/SPRING/data'
    #datasetDir = '/home/steidsta/projects/Broca_to_map/data'
    spaceName = 'hospital_1'
    cutoutName = 'cutouts_32'
    #cutoutName = 'cutouts'
    pano_prefix = 'Broca-Hospital-with-Curtains-scan'
    #spaceName = 'B-670'
    spaceDir = os.path.join(datasetDir, spaceName)
    thisSpaceCutoutsDir = os.path.join(spaceDir,cutoutName)
    thisSpaceCutoutsDepth = os.path.join(thisSpaceCutoutsDir,'depthmaps')
    thisSpaceCutoutsMesh = os.path.join(thisSpaceCutoutsDir,'meshes')
    thisSpaceCutoutsCutout = os.path.join(thisSpaceCutoutsDir,'cutouts')
    thisSpaceCutoutsMats = os.path.join(thisSpaceCutoutsDir,'matfiles')
    panoramasDir = os.path.join(spaceDir, 'panoramas')
    meshPath = os.path.join(spaceDir, 'model', '%s.obj' % spaceName)
    meshPath = os.path.join(spaceDir, 'model', 'model_rotated.obj' )
    sweepDataPath = os.path.join(spaceDir, 'sweepData', '%s.mat' % spaceName)
    debug = True
    panoIds = range(1,117)
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

    sweepData = sio.loadmat(sweepDataPath, squeeze_me=True)['sweepData']


    if not os.path.isdir(thisSpaceCutoutsDir):
        os.mkdir(thisSpaceCutoutsDir)
    
    trimeshScene = trimesh.load(meshPath)
    scene = pyrender.Scene.from_trimesh_scene(trimeshScene) # TODO: this thing consumes ~5-6 GB RAM!

    processPanoramas(panoIds,thisSpaceCutoutsDir,panoramasDir,pano_prefix,fovHorizontal,fovVertical,sensorHeight,sensorWidth)
    
    