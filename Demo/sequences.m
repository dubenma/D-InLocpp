%% DEPRECATED. Do NOT use without reworking the code first. %%
assert(false);

addpath('functions/InLocCIIRC_utils/params');
addpath('functions/InLocCIIRC_utils/load_CIIRC_transformation');
addpath('functions/InLocCIIRC_utils/mkdirIfNonExistent');
addpath('functions/InLocCIIRC_utils/multiCameraPose');
addpath('functions/InLocCIIRC_utils/projectPointCloud');
addpath('functions/InLocCIIRC_utils/projectPointsUsingP');
addpath('functions/InLocCIIRC_utils/rotationDistance');
addpath('functions/InLocCIIRC_utils/R_to_numpy_array');
addpath('functions/InLocCIIRC_utils/T_to_numpy_array');
addpath('functions/InLocCIIRC_utils/printErrors');
addpath('functions/InLocCIIRC_utils/loadPoseFromInLocCIIRC_demo');
[ params ] = setupParams('holoLens1'); % NOTE: adjust

useLongestSequence = false;

% the following can be ignored if useLongestSequence = true
startIdx = 127; % the index of the first query to be considered in the sequence
k = 5; % the length of the sequence

matchesFromReferencePoses = false; % NOTE: must be false in production

%% extract HoloLens poses wrt initial unknown HoloLens CS
descriptionsTable = readtable(params.queryDescriptions.path); % decribes the reference poses

prevWarningState = warning();
warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames');
rawHoloLensPosesTable = readtable(params.holoLens.poses.path);
warning(prevWarningState);

assert(size(descriptionsTable,1) == size(rawHoloLensPosesTable,1));
nQueries = size(descriptionsTable,1);

if useLongestSequence
    startIdx = 1;
    k = nQueries - max([params.HoloLensTranslationDelay, params.HoloLensOrientationDelay]);
end

cameraPosesWrtHoloLensCS = zeros(nQueries,4,4);
queryInd = zeros(nQueries,1);
for i=1:nQueries
    queryId = descriptionsTable{i, 'id'};
    queryInd(i,:) = queryId;
    %space = descriptionsTable{i, 'space'}{1,1};
    %inMap = descriptionsTable{i, 'inMap'};
    t = [rawHoloLensPosesTable{i, 'Position_X'}; ...
                rawHoloLensPosesTable{i, 'Position_Y'}; ...
                rawHoloLensPosesTable{i, 'Position_Z'}];
    orientation = [rawHoloLensPosesTable{i, 'Orientation_W'}, ...
                    rawHoloLensPosesTable{i, 'Orientation_X'}, ...
                    rawHoloLensPosesTable{i, 'Orientation_Y'}, ...
                    rawHoloLensPosesTable{i, 'Orientation_Z'}];
    R = rotmat(quaternion(orientation), 'frame'); % what are the columns of R? 
        % Bases of WHAT wrt WHAT? (one of them is initial unknown HL CS, the other is HL camera CS)
        % -> it is most likely a rotation matrix from initial unknown HL CS to HL camera CS. i.e. the columns
        % are bases of initial unknown HL CS in HL camera CS coordinates

    % camera points to -z in HoloLens
    % see https://docs.microsoft.com/en-us/windows/mixed-reality/coordinate-systems-in-directx
    rFix = rotationMatrix([pi, 0.0, 0.0], 'ZYX'); % correct
    %rFix = eye(3); % incorrect

    %R = R';

    R1 = (rFix * R)';
    R2 = R' * rFix;
    Rd = R1-R2;
    eps = 1e-8;
    assert(all(Rd(:) < eps));

    cameraPositionWrtHoloLensCS = t';
    cameraOrientationWrtHoloLensCS = R2;

    pose = eye(4);
    pose(1:3,1:3) = cameraOrientationWrtHoloLensCS;
    pose(1:3,4) = cameraPositionWrtHoloLensCS;
    cameraPosesWrtHoloLensCS(i,:,:) = pose;
end

%% extract poses used for 2D-3D matches construction
posesForMatches = zeros(nQueries,4,4);
if ~matchesFromReferencePoses
    load(fullfile(params.output.dir, 'densePV_top10_shortlist.mat'), 'ImgList');
end
for i=1:nQueries
    queryId = queryInd(i);
    if matchesFromReferencePoses
        retrievedPosePath = fullfile(params.poses.dir, sprintf('%d.txt', queryId));
        retrievedPose = load_CIIRC_transformation(retrievedPosePath);
    else
        retrievedPosePath = fullfile(params.evaluation.retrieved.poses.dir, sprintf('%d.txt', queryId));
        [retrievedPose,~,~,~] = loadPoseFromInLocCIIRC_demo(queryId, ImgList, params);
    end
    posesForMatches(i,:,:) = retrievedPose;
end

% blacklist queries for which we dont have reference pose
whitelistedQueries = ones(1,nQueries);
if isfield(params, 'blacklistedQueryInd')
    blacklistedQueries = false(1,nQueries);
    blacklistedQueries(params.blacklistedQueryInd) = true;
    nBlacklistedQueries = sum(blacklistedQueries);
    whitelistedQueries = logical(ones(1,nQueries) - blacklistedQueries); % w.r.t. reference frames
end

if ~matchesFromReferencePoses
    % additionally blacklist queries at which InLocCIIRC_demo returned NaN (thus got lost)
    for i=1:nQueries
        poseForMatches = squeeze(posesForMatches(i,:,:));
        if any(isnan(poseForMatches(:)))
            blacklistedQueries(i) = true;
            whitelistedQueries(i) = false;
        end
    end
    nBlacklistedQueries = sum(blacklistedQueries);
end

% update k and queryInd to exclude blacklisted queries
nWhitelistedQueries = sum(whitelistedQueries);
kWhitelisted = 0;
for i=startIdx:startIdx+k-1
    queryId = queryInd(i);
    if whitelistedQueries(queryId)
        kWhitelisted = kWhitelisted + 1;
    end
end

queryInd2 = zeros(kWhitelisted,1);
j = 1;
for i=startIdx:startIdx+k-1
    queryId = queryInd(i);
    if whitelistedQueries(queryId)
        queryInd2(j,:) = queryId;
        j = j + 1;
    end
end
kPrev = size(queryInd,1);
k = kWhitelisted;
queryInd = queryInd2;

if k==0
    fprintf('Unable to proceed, because k, after removing blacklisted queries, is zero.\n');
    fprintf('Note that if this was production, and k=0 because of missing reference poses,\n');
    fprintf('you could still proceed.\n');
    assert(false);
end

nBlacklistedQueriesInSequence = kPrev-kWhitelisted;
fprintf('You have blacklisted %0.0f%% queries in the sequence. %d queries remain.\n', ...
        nBlacklistedQueriesInSequence*100/kPrev, kPrev-nBlacklistedQueriesInSequence);

%% include only those in the sequence
cameraPosesWrtHoloLensCS2 = zeros(k,4,4); % accounted for (possible) delay
% TODO: assert all query IDs are sorted and increasing by 1
for i=1:k
    queryId = queryInd(i);
    orientationDataIdx = queryId+params.HoloLensOrientationDelay;
    translationDataIdx = queryId+params.HoloLensTranslationDelay;
    %orientationDataIdx = queryId+4;
    %translationDataIdx = queryId+6;
    %orientationDataIdx = queryId;
    %translationDataIdx = queryId;
    if (orientationDataIdx > nQueries || translationDataIdx > nQueries)
        error('No HoloLens pose data for query %d', queryId);
    end
    pose = eye(4);
    pose(1:3,1:3) = cameraPosesWrtHoloLensCS(orientationDataIdx,1:3,1:3);
    pose(1:3,4) = cameraPosesWrtHoloLensCS(translationDataIdx,1:3,4);
    cameraPosesWrtHoloLensCS2(i,:,:) = pose;
end
cameraPosesWrtHoloLensCS = cameraPosesWrtHoloLensCS2;

%% debug - we need to print: origin of each camera wrt Omega, bases of each camera wrt Omega,
%for i=1:k
%    queryId = queryInd(i);
%    fprintf('query: %d\n', queryId);
%    fprintf('camera bases wrt Omega: %s\n', R_to_numpy_array(squeeze(cameraPosesWrtHoloLensCS(i,1:3,1:3))));
%    fprintf('camera origin wrt Omega: %s\n', T_to_numpy_array(cameraPosesWrtHoloLensCS(i,1:3,4)));
%end

%% set up 2D-3D correspondences for the k queries
sensorSize = params.camera.sensor.size; % height, width
imageWidth = sensorSize(2);
imageHeight = sensorSize(1);
correspondences2D = [imageWidth/4, imageHeight/4; ...
                        imageWidth/4, imageHeight-imageHeight/4; ...
                        imageWidth-imageWidth/4, imageHeight/4; ...
                        imageWidth-imageWidth/4, imageHeight-imageHeight/4; ...
                        imageWidth/3, imageHeight/3; ...
                        imageWidth/3, imageHeight-imageHeight/3; ...
                        imageWidth-imageWidth/3, imageHeight/3; ...
                        imageWidth-imageWidth/3, imageHeight-imageHeight/3]';
nMatchesPerQuery = size(correspondences2D,2);
correspondences3D = zeros(k,3,nMatchesPerQuery);

toDeproject = ones(4,nMatchesPerQuery);
toDeproject(1:2,:) = correspondences2D;
toDeproject(3,:) = 1.0 + rand(1,nMatchesPerQuery) * 2.0; % NOTE: optional

normalized = toDeproject ./ toDeproject(3,:);
for i=1:nMatchesPerQuery
    correspondences2D(:,i) = normalized(1:2,i);
end

for i=1:k
    queryId = queryInd(i);
    retrievedPose = squeeze(posesForMatches(queryId,:,:));
    retrievedT = -inv(retrievedPose(1:3,1:3))*retrievedPose(1:3,4); % wrt model
    retrievedR = retrievedPose(1:3,1:3); % modelBasesToEpsilonBases
    P = [params.camera.K*retrievedR, -params.camera.K*retrievedR*retrievedT]; 
    imageToModel = inv([P; 0,0,0,1]);
    correspondences4D = imageToModel * toDeproject;
    correspondences3D(i,:,:) = correspondences4D(1:3,:);
end

%% verification of correspondences - it works
%close all;
%figure;
%pointSize = 8.0;
%outputSize = params.camera.sensor.size;
%projectedPointCloud = projectPointCloud(params.pointCloud.path, params.camera.fl, retrievedR, ...
%                                    retrievedT, params.camera.sensor.size, outputSize, pointSize, ...
%                                    params.projectPointCloudPy.path); % TODO: use projectMesh instead, which can work in headless mode
%image(projectedPointCloud);
%axis image;
%
%hold on;
%scatter(correspondences2D(1,:), correspondences2D(2,:), 40, 'r', 'filled');
%reprojectedPts = projectPointsUsingP(squeeze(correspondences3D(end,:,:)), P);
%scatter(reprojectedPts(1,:), reprojectedPts(2,:), 20, 'g', 'filled');
%hold off;
%set(gcf, 'Position', get(0, 'Screensize'));

%% execute and collect results
workingDir = tempname;
%workingDir = '/Volumes/GoogleDrive/Můj disk/ARTwin/InLocCIIRC_dataset/evaluation/sequences'; % only for debugging; TODO: remove
    % this does NOT support multiple experiments!
    
inlierThreshold = 12.0; % TODO
numLoSteps = 10; % TODO; why is this parameter seem to have no effect (I tried 0, 1, 10, 100).
                 % It is actualy correctly used in RansacLib: ransac.h:378...
invertYZ = false; % TODO
pointsCentered = false;
undistortionNeeded = false; % TODO
estimatedPoses = multiCameraPose(workingDir, queryInd, cameraPosesWrtHoloLensCS, ...
                                    correspondences2D, correspondences3D, ...
                                    inlierThreshold, numLoSteps, ...
                                    invertYZ, pointsCentered, undistortionNeeded,
                                    imageWidth, imageHeight, params.camera.K, params); % wrt model
rmdir(workingDir, 's');

%% compare poses estimated by MultiCameraPose with reference poses
%% quantitative results
if matchesFromReferencePoses
    originalErrors = struct();
    for i=1:k
        queryId = queryInd(i);
        originalErrors(i).queryId = queryId;
        originalErrors(i).translation = 0.0;
        originalErrors(i).orientation = 0.0;
    end
else
    originalErrorsTable = readtable(params.evaluation.errors.path);
    nQueries2 = size(originalErrorsTable,1);
    assert(nQueries == nQueries2);
    originalErrors = struct();
    for i=1:k
        queryId = queryInd(i);
        queryId2 = originalErrorsTable{queryId, 'id'};
        assert(queryId == queryId2);
        originalErrors(i).queryId = queryId;
        originalErrors(i).translation = originalErrorsTable{queryId, 'translation'};
        originalErrors(i).orientation = originalErrorsTable{queryId, 'orientation'};
    end
end
fprintf('Original errors (InLocCIIRC poses wrt reference poses):\n');
printErrors(originalErrors);
fprintf('\n');

errors = struct();
for i=1:k
    queryId = queryInd(i);
    queryPoseFilename = sprintf('%d.txt', queryId);
    posePath = fullfile(params.dataset.query.dir, 'poses', queryPoseFilename);
    referenceP = load_CIIRC_transformation(posePath);
    referenceT = -inv(referenceP(1:3,1:3))*referenceP(1:3,4);
    referenceR = referenceP(1:3,1:3);

    estimatedPose = estimatedPoses{i};
    estimatedT = estimatedPose(1:3,4)';
    estimatedR = squeeze(estimatedPose(1:3,1:3));

    errors(i).queryId = queryId;
    errors(i).translation = norm(estimatedT - referenceT);
    errors(i).orientation = rotationDistance(referenceR, estimatedR);
end
fprintf('Errors (MultiCameraPoses poses wrt reference poses):\n');
printErrors(errors);
fprintf('\n');

errorDiffs = struct();
for i=1:k
    queryId = queryInd(i);
    errorDiffs(i).queryId = queryId;
    errorDiffs(i).translation = errors(i).translation - originalErrors(i).translation;
    errorDiffs(i).orientation = errors(i).orientation - originalErrors(i).orientation;
end
fprintf('Change from original errors (InLocCIIRC):\n');
printErrors(errorDiffs);
fprintf('\n');

meanTranslationDiff = mean([errorDiffs.translation]);
meanOrientationDiff = mean([errorDiffs.orientation]);
if ~matchesFromReferencePoses && (meanTranslationDiff > 0.0 || meanOrientationDiff > 0.0)
    warning('The new poses are not better!');
end
return;

%% qualitative results
close all;
for i=1:k
    figure;
    pointSize = 8.0;
    outputSize = params.camera.sensor.size;
    estimatedPose = estimatedPoses{i};
    estimatedT = estimatedPose(1:3,4)';
    estimatedR = squeeze(estimatedPose(1:3,1:3));
    projectedPointCloud = projectPointCloud(params.pointCloud.path, params.camera.fl, estimatedR, ...
                                        estimatedT, params.camera.sensor.size, outputSize, pointSize, ...
                                        params.projectPointCloudPy.path);
    image(projectedPointCloud);
    axis image;
end