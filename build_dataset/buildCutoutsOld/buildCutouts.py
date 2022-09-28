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

if __name__ == '__main__':
    datasetDir = '/Volumes/GoogleDrive/Můj disk/ARTwin/InLocCIIRC_dataset'
    spaceName = 'B-315'
    #spaceName = 'B-670'
    cutoutsDir = os.path.join(datasetDir, 'cutouts')
    thisSpaceCutoutsDir = os.path.join(cutoutsDir, spaceName)
    panoramasDir = os.path.join(datasetDir, 'rotatedPanoramas', spaceName)
    meshPath = os.path.join(datasetDir, 'models', spaceName, 'mesh_rotated.obj')
    sweepDataPath = os.path.join(datasetDir, 'sweepData', '%s.mat' % spaceName)
    debug = True
    panoIds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ,13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27] # B-315
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

    if not os.path.isdir(cutoutsDir):
        os.mkdir(cutoutsDir)

    if not os.path.isdir(thisSpaceCutoutsDir):
        os.mkdir(thisSpaceCutoutsDir)
    
    trimeshScene = trimesh.load(meshPath)
    scene = pyrender.Scene.from_trimesh_scene(trimeshScene) # TODO: this thing consumes ~5-6 GB RAM!

    for panoId in panoIds:
        sweepRecord = getSweepRecord(sweepData, panoId)

        thisPanoCutoutsDir = os.path.join(thisSpaceCutoutsDir, str(panoId))
        if not os.path.isdir(thisPanoCutoutsDir):
            os.mkdir(thisPanoCutoutsDir)

        panoramaPath = os.path.join(panoramasDir, str(panoId) + '.jpg')
        panoramaImage = plt.imread(panoramaPath)

        xh = np.arange(-180, 180, 30)
        yh0 = np.zeros((len(xh)))
        yhTop = yh0 + 30
        yhBottom = yh0 - 30

        x = np.concatenate((xh, xh, xh))
        y = np.concatenate((yh0, yhTop, yhBottom))

        for i in range(len(x)):
            yaw = x[i]
            pitch = y[i]
            panoramaProjection = py360convert.e2p(panoramaImage, (fovHorizontal, fovVertical),
                                                    yaw, pitch, (sensorHeight, sensorWidth),
                                                    in_rot_deg=0, mode='bilinear')
            filename = 'cutout_%d_%d_%d.jpg' % (panoId, yaw, pitch)
            path = os.path.join(thisPanoCutoutsDir, filename)
            plt.imsave(path, panoramaProjection)
            # set up the mat file
            cameraRotation = sweepRecord['rotation'] + np.array([pitch, -yaw, 0.0])
            rotationMatrix = R.from_euler('xyz', cameraRotation, degrees=True).as_matrix()
            RGBcut, XYZcut, depth = projectMeshCached(scene, f, rotationMatrix, sweepRecord['position'], sensorSize, False, -1)
            filename = filename + '.mat'
            path = os.path.join(thisPanoCutoutsDir, filename)
            sio.savemat(path, {'RGBcut': panoramaProjection, 'XYZcut': XYZcut})

            if debug:
                filename = 'depth_%d_%d_%d.jpg' % (panoId, yaw, pitch)
                path = os.path.join(thisPanoCutoutsDir, filename)
                plt.imsave(path, depth, cmap=plt.cm.gray_r)

                filename = 'mesh_%d_%d_%d.jpg' % (panoId, yaw, pitch)
                path = os.path.join(thisPanoCutoutsDir, filename)
                plt.imsave(path, RGBcut)