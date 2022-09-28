clear all;
close;

% paths to images - contains folders with database images
paths_to_images = {'SPRING_Demo/DB_Broca_dynamic_1/cutouts_dynamic/hospital',...
    'SPRING_Demo/DB_Broca_dynamic_1/cutouts_dynamic/livinglab'};

% paths to camera poses - contains folders with *.mat files with camera
% poses generated as the input database of the InLoc
paths_to_poses = {'SPRING_Demo/DB_Broca_dynamic_1/poses/hospital',...
    'SPRING_Demo/DB_Broca_dynamic_1/poses/livinglab'};

% camera intrinsic in COLMAP format, i.e., MODEL, WIDTH, HEIGHT, PARAMS[]
camera_intrinsics= 'SIMPLE_PINHOLE 1344 756 1034.7892 672 378';

% run the conversion
for i = 1:length(paths_to_images)
    convertDB2COLMAP(paths_to_images{i}, paths_to_poses{i}, camera_intrinsics)
end