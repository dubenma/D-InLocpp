import numpy as np
import matplotlib.pyplot as plt
from scipy.spatial.transform import Rotation as R
import open3d as o3d
import scipy.io as sio
import os
import sys
from PIL import Image

if __name__ == '__main__':
    debug = False
    if not debug:
        if len(sys.argv) != 3:
            print('Usage: python3 projectPointCloud.py <input path> <output path>')
            print('Example: python3 projectPointCloud.py input.mat projection.png')
            exit(1)
        inputPath = sys.argv[1]
        projectionPath = sys.argv[2]
    else:
        inputPath = '/private/var/folders/n0/m5ngvx3920n720yl5v9px94h0000gn/T/tp36180ce9_018a_4ac3_94a3_654bf4d4b36f.mat'
        projectionPath = '/Users/lucivpav/repos/InLocCIIRC_dataset (repo)/projection.png'

    inputData = sio.loadmat(inputPath, squeeze_me=True)
    pcPath = str(inputData['pcPath'])
    f = float(inputData['f'])
    R = inputData['R']
    t = inputData['t']
    sensorSize = inputData['sensorSize']
    outputSize = inputData['outputSize']
    pointSize = inputData['pointSize']

    sensorWidth = sensorSize[1]
    sensorHeight = sensorSize[0]
    fovVertical = 2*np.arctan((sensorHeight/2)/f)

    if sensorWidth > 2560 or sensorHeight > 1600:
        # make the sensor size smaller in order to cast it onto screen, while keeping the FoV
        sensorWidth = sensorWidth / 2
        sensorHeight = sensorHeight / 2
        f = sensorHeight / (2 * np.tan(fovVertical/2))

    pcd = o3d.io.read_point_cloud(pcPath)

    camera_position_mat = np.eye(4)
    camera_position_mat[0:3,3] = -t
    pcd.transform(camera_position_mat)

    camera_pose = np.eye(4)
    camera_pose[0:3,0:3] = R

    vis = o3d.visualization.Visualizer()
    vis.create_window(width=int(sensorWidth), height=int(sensorHeight))
    ctr = vis.get_view_control()
    vis.add_geometry(pcd)
    ro = vis.get_render_option()
    ro.point_size = pointSize

    intrinsic = o3d.camera.PinholeCameraIntrinsic()
    pcp = ctr.convert_to_pinhole_camera_parameters()
    pcp.intrinsic.set_intrinsics(int(sensorWidth), int(sensorHeight), f, f, sensorWidth/2-0.5, sensorHeight/2-0.5)
    pcp.extrinsic = camera_pose
    ctr.convert_from_pinhole_camera_parameters(pcp)
    vis.poll_events()
    vis.update_renderer()
    vis.capture_screen_image(projectionPath)
    vis.destroy_window()

    # resize to match output size
    projection = Image.open(projectionPath)
    projection = projection.resize((outputSize[1], outputSize[0]), resample=Image.NEAREST)
    projection.save(projectionPath)