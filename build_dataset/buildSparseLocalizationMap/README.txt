For building the sparse map, the HoloLens mapper GUI is used. The definition of the inputs / outputs and algorithm parameters is in JSON file called "build_sparse_localization_map.mg".

Please, follow the instructions of: https://github.com/michalpolic/hololens_mapper
to install the HoloLens mapper. 

Run the GUI, load the "build_sparse_localization_map.mg", and adjust the inputs. There are required two inputs:
- the COLMAP reconstruction files (cameras.txt, images.txt, points3D.txt, and images)
- the dense point cloud from Matterport in "*.obj" format

The output is HLOC map that contains the sparse correspondences between images.