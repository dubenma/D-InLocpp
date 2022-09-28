%ImgList_densePV;
addpath('./tools')
[C_pred.K,C_pred.R,C_pred.C] = P2KRC(ImgList_densePV.Ps{1}{1});
camplot(C_pred,10,[-1 1 1 -1;-1 -1 1 1]);

query_id = 8;
sweepdata = load('/local/localization_service/Maps/SPRING/hospital_1/cutouts_36/sweepData/hospital_1.mat','sweepData');
cutout_gt = load('/local/localization_service/Maps/SPRING/hospital_1/cutouts_36/hospital_1-query/poses/8/cutout_8_60_-30.jpg.mat');
db_gt = sweepdata.sweepData;
C_gt.R = db_gt(5).rotation;
t = db_gt(5).position;
C_gt.R = db_gt(5).rotation;


meshPath ='/local/localization_service/Maps/SPRING/hospital_1/cutouts_36/model/model_rotated.obj';
% meshPath ='/local/localization_service/Maps/SPRING/hospital_1/cutouts_32/model/hospital_1_orig.obj';

fl = params.camera.fl;
fl=600;
R = cutout_gt.R;
t = cutout_gt.position';
sensorSize = [params.camera.sensor.size(2), params.camera.sensor.size(1)];
ortho = false;
mag = -1;
projectMeshPyPath = params.input.projectMesh_py_path;
headless = true;
[RGBcut, XYZcut, depth] = projectMesh(meshPath, fl, R, t, sensorSize, ortho, mag, projectMeshPyPath, headless);
figure;
imshow(RGBcut);
figure;
imshow(XYZcut);

%ImgList_densePV
%ImgList_densePV.topNname{1};
P = ImgList_densePV.Ps{1}{1};
R = P(1:3,1:3);
t = P(1:3,4);

[RGBcut, XYZcut, depth] = projectMesh(meshPath, fl, R, t, sensorSize, ortho, mag, projectMeshPyPath, headless);
figure;
imshow(RGBcut);
figure;
imshow(XYZcut);

print('done')
% %load downsampled images
% thisQueryName = qname;%sprintf('%d.jpg', firstQueryId + i - 1);
% Iq = imresize(imread(fullfile(params.dataset.query.dir, thisQueryName)), params.dataset.query.dslevel);
% fl = params.camera.fl * params.dataset.query.dslevel;
% R = P(1:3,1:3);
% t = P(1:3,4);
% 
% spaceName = strsplit(dbname, '/');
% spaceName = spaceName{1};
% %             meshPath = fullfile(params.dataset.models.dir, spaceName, 'mesh_rotated.obj');
% meshPath = fullfile(params.dataset.models.dir, 'model_rotated.obj');
% t = -inv(R)*t;
% rFix = [180.0, 0.0, 0.0];
% Rfix = rotationMatrix(deg2rad(rFix), 'XYZ');
% sensorSize = [params.camera.sensor.size(2), params.camera.sensor.size(1)];
% headless = ~strcmp(environment(), 'laptop');
% [RGBpersp, XYZpersp, depth] = projectMesh(meshPath, fl, inv(R)*Rfix, t, sensorSize, false, -1, params.input.projectMesh_py_path, headless);