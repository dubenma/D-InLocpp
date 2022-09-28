import os
os.environ["PYOPENGL_PLATFORM"] = "osmesa"
import numpy as np
import sys
import scipy.io as sio

import pyrender
import trimesh
from PIL import Image
import open3d as o3d
import matplotlib.pyplot as plt






def projectMesh(meshPath, f, R, t, sensorSize, ortho, mag):
    RGBcut, XYZcut, depth, XYZpts = projectMeshDebug(meshPath, f, R, t, sensorSize, ortho, mag, False)
    return RGBcut, XYZcut, depth

def projectMeshCached(scene, f, R, t, sensorSize, ortho, mag):
    RGBcut, XYZcut, depth, XYZpts = projectMeshCachedDebug(scene, f, R, t, sensorSize, ortho, mag, False)
    return RGBcut, XYZcut, depth

def getCentered3Dindices(mode, sensorWidth, sensorHeight):
    if mode == 'x':
        length = sensorWidth
    elif mode == 'y':
        length = sensorHeight
    else:
        raise ValueError('Unknown mode!')

    halfFloat = length/2
    halfInt = int(halfFloat)
    lower = -halfInt
    upper = halfInt
    if not np.allclose(halfFloat, halfInt):
        upper += 1
    ind = np.arange(lower, upper)
    if mode == 'x':
        ind = np.broadcast_to(ind, (sensorHeight, sensorWidth)).T
    elif mode == 'y':
        ind = np.broadcast_to(ind, (sensorWidth, sensorHeight))
    ind = np.reshape(ind, (sensorHeight*sensorWidth, 1))
    ind = np.tile(ind, (1,3))
    return ind

def buildXYZcut(sensorWidth, sensorHeight, t, cameraDirection, scaling, sensorXAxis, sensorYAxis, depth):
    # TODO: compute xs, ys only once (may not actually matter)
    ts = np.broadcast_to(t, (sensorHeight*sensorWidth, 3))
    camDirs = np.broadcast_to(cameraDirection, (sensorHeight*sensorWidth, 3))
    xs = getCentered3Dindices('x', sensorWidth, sensorHeight)
    ys = getCentered3Dindices('y', sensorWidth, sensorHeight)
    sensorXAxes = np.broadcast_to(sensorXAxis, (sensorHeight*sensorWidth, 3))
    sensorYAxes = np.broadcast_to(sensorYAxis, (sensorHeight*sensorWidth, 3))
    sensorPoints = ts + camDirs + scaling * np.multiply(xs, sensorXAxes) + scaling * np.multiply(ys, sensorYAxes)
    sensorDirs = sensorPoints - ts
    depths = np.reshape(depth.T, (sensorHeight*sensorWidth, 1))
    depths = np.tile(depths, (1,3))
    pts = ts + np.multiply(sensorDirs, depths)
    xyzCut_T = np.reshape(pts, (sensorWidth, sensorHeight, 3))
    xCut =xyzCut_T[:,:,0].T
    yCut =xyzCut_T[:,:,1].T
    zCut =xyzCut_T[:,:,2].T
    xyzCut = np.reshape(pts, (sensorHeight, sensorWidth, 3))
    xyzCut[:,:,0] = xCut
    xyzCut[:,:,1] = yCut
    xyzCut[:,:,2] = zCut
    #xyzCut = np.reshape(pts, (sensorWidth, sensorHeight, 3))
    return xyzCut, pts

def projectMeshCachedDebug(scene, f, R, t, sensorSize, ortho, mag, debug):
    a = os.environ['PATH'] 
    b =os.environ['LD_LIBRARY_PATH']  
    # In OpenGL, camera points toward -z by default, hence we don't need rFix like in the MATLAB code
    sensorWidth = sensorSize[0]
    sensorHeight = sensorSize[1]
    fovHorizontal = 2*np.arctan((sensorWidth/2)/f)
    fovVertical = 2*np.arctan((sensorHeight/2)/f)

    if ortho:
        camera = pyrender.OrthographicCamera(xmag=mag, ymag=mag)
    else:
        camera = pyrender.PerspectiveCamera(fovVertical)

    camera_pose = np.eye(4)
    camera_pose[0:3,0:3] = R
    camera_pose[0:3,3] = t
    cameraNode = scene.add(camera, pose=camera_pose)

    scene._ambient_light = np.ones((3,))

    r = pyrender.OffscreenRenderer(sensorWidth, sensorHeight)
    meshProjection, depth = r.render(scene) # TODO: this thing consumes ~14 GB RAM!!!
    r.delete() # this releases that; but it should not require so much RAM in the first place

    # XYZ cut
    scaling = 1.0/f

    spaceCoordinateSystem = np.eye(3)

    sensorCoordinateSystem = np.matmul(R, spaceCoordinateSystem)
    sensorXAxis = sensorCoordinateSystem[:,0]
    sensorYAxis = -sensorCoordinateSystem[:,1]
    # make camera point toward -z by default, as in OpenGL
    cameraDirection = -sensorCoordinateSystem[:,2] # unit vector

    xyzCut, pts = buildXYZcut(sensorWidth, sensorHeight, t, cameraDirection, scaling,
                                sensorXAxis, sensorYAxis, depth)

    XYZpc = -1
    if debug:
        XYZpc = o3d.geometry.PointCloud()
        XYZpc.points = o3d.utility.Vector3dVector(pts)
    
    scene.remove_node(cameraNode)

    return meshProjection, xyzCut, depth, XYZpc


def test(stri):
    print('hello'+str(stri))

def projectMeshDebug(meshPath, f, R, t, sensorSize, ortho, mag, debug):
    trimeshScene = trimesh.load(meshPath)
    scene = pyrender.Scene.from_trimesh_scene(trimeshScene)
    return projectMeshCachedDebug(scene, f, R, t, sensorSize, ortho, mag, debug)

if __name__ == '__main__':
    debug = False
    if not debug:
        if len(sys.argv) != 3:
            print('Usage: python3 projectMesh.py <input path> <output path>')
            print('Example: python3 projectMesh.py input.mat output.mat')
            exit(1)
        inputPath = sys.argv[1]
        outputPath = sys.argv[2]
    else:
        inputPath = '/private/var/folders/n0/m5ngvx3920n720yl5v9px94h0000gn/T/tp9d64aadb_8996_4290_a8fd_af152c40a41a.mat'
        outputPath = 'output.mat'
        spacePc = o3d.io.read_point_cloud('/Volumes/GoogleDrive/Můj disk/ARTwin/InLocCIIRC_dataset/models/B-670/cloud - rotated.ply')

    inputData = sio.loadmat(inputPath, squeeze_me=True)
    meshPath = str(inputData['meshPath'])
    f = float(inputData['f'])
    R = inputData['R']
    t = inputData['t']
    sensorSize = inputData['sensorSize'].astype(np.int64) # avoid overflow, because they are uint16 by default
    ortho = inputData['ortho']
    mag = inputData['mag']

    RGBcut, XYZcut, depth, XYZpc = projectMeshDebug(meshPath, f, R, t, sensorSize, ortho, mag, debug)

    if debug:
        o3d.visualization.draw_geometries([spacePc, XYZpc])

    sio.savemat(outputPath, {'RGBcut': RGBcut, 'XYZcut': XYZcut, 'depth': depth})

    print('done!')