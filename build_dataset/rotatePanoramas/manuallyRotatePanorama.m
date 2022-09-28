% panoId = 1;
%% initialize 
startup;

%% run LOCALLY!! requires display
[ params ] = setupParams2;


for panoId = 38:73
panoId
panoProjectionIdx = -1; % -1 for the first step, valid idx for the second step

load(params.sweepData.mat.path);
% pc = pcread(params.pointCloud.path);

fun = @(x) sweepData(x).panoId == panoId;
tf = arrayfun(fun, 1:numel(sweepData));
sweepRecord = sweepData(find(tf));

if exist(params.temporary.dir, 'dir') ~= 7
    mkdir(params.temporary.dir);
end

if exist(fullfile(params.temporary.dir,num2str(panoId)), 'dir') ~= 7
    mkdir(fullfile(params.temporary.dir,num2str(panoId)));
end

%% Project the point cloud

f = 500;
sensorSize = [1000,1000];
rFix = [0, 180, 180.0];
r = rFix + sweepRecord.rotation;
r = deg2rad(r);
R = rotationMatrix(r, 'XYZ');
t = sweepRecord.position;
% t = -R*t;
outputSize = [300 300];
% 
% f = 500;
% sensorSize = [1000,1000];
% rFix = [0.0, -180.0, 180.0];
% r = rFix + sweepRecord.rotation;
% t = -sweepRecord.position;
% outputSize = [300 300];
projectedPointCloud = projectPointCloud(params.pointCloud.path, f, R, t, ...
                        sensorSize, outputSize, ...
                        8.0, params.projectPointCloudPy.path);
% 
% projectedPointCloud = projectPointCloud(params.pointCloud.path, f, r, t, sensorSize, outputSize, ...
%                         8.0, params.projectPointCloudPy.path);
%figure(1);
% imshow(projectedPointCloud);

%% Project the panorama
panoImg = imread(fullfile(params.panoramas.dir, strcat('Broca-Hospital-with-Curtains-scan',int2str(panoId), '.jpg')));
viewSize = outputSize(1);
fov = 2*atan((sensorSize(1)/2)/f);
nViews = 256;
panoramaProjections = projectPanorama(panoImg, viewSize, fov, nViews);
%plotMany(panoramaProjections);

if (panoProjectionIdx ~= -1)
    xMid = ((panoramaProjections(panoProjectionIdx).vx + pi) / (2*pi)) * size(panoImg, 2);
    xMid = round(xMid);
%     rmdir(params.temporary.dir);
    %% Perform panorama rotation and save the result
    panoMid = round(size(panoImg, 2)/2);
    rotatedPanorama = [panoImg(:,xMid:end,:) panoImg(:,1:xMid,:)];
    rotatedPanorama = [rotatedPanorama(:,panoMid:end,:) rotatedPanorama(:,1:panoMid,:)];
    %figure(4);
    %imshow(rotatedPanorama);
    imwrite(rotatedPanorama, fullfile(params.rotatedPanoramas.dir, strcat('Broca-Hospital-with-Curtains-scan',int2str(panoId), '.jpg')));
    exit();
end
fh = figure('visible','off');
for idx=1:size(panoramaProjections, 2)
    panoramaProjection = panoramaProjections(idx).img;
    merged = (double(projectedPointCloud)/255 + panoramaProjection )/2;    
    imshow(merged);
    saveas(fh,fullfile(params.temporary.dir,num2str(panoId), strcat(int2str(idx), '.jpg')))
    
end
close(fh);
end