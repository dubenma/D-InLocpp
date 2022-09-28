%% NOTE: this script is unnecessary, because the sweeps are already registered wrt World by Matterport


addpath('../functions/InLocCIIRC_utils/rotationMatrix');
addpath('../functions/InLocCIIRC_utils/P_to_str')
addpath('../functions/InLocCIIRC_utils/params');

params = setupParams('s10e'); % NOTE: mode can be anything, its specific params are not used here

params = struct();
spaceName = 'B-315'; % TODO: adjust
sweepDataMatPath = fullfile(params.dataset.dir, 'sweepData', sprintf('%s.mat', spaceName));
alignmentsDir = fullfile(params.dataset.db.trans.dir, params.spaceName);
allTransformationsPath = fullfile(params.alignments.dir, 'all_transformations.txt');
knownIncorrectPath = fullfile(alignmentsDir, 'know_incorrect.txt');
transformationsDir = fullfile(alignmentsDir, 'transformations');
fl = 1385.6406460551023;
sensorSize = [1600 1200];

if exist(alignmentsDir, 'dir') ~= 7
    mkdir(alignmentsDir);
end

if exist(transformationsDir, 'dir') ~= 7
    mkdir(transformationsDir);
end

load(sweepDataMatPath);
all_transformationsFile = fopen(allTransformationsPath, 'w');

% create an empty file
knownIncorrectFile = fopen(knownIncorrectPath, 'w');
fclose(knownIncorrectFile);

for i=1:size(sweepData, 2)
    sweepRecord = sweepData(i);
    thisPanoTransformationPath = fullfile(transformationsDir, sprintf('trans_%d.txt', sweepRecord.panoId));
    thisTransformationFile = fopen(thisPanoTransformationPath, 'w');
    angles = sweepRecord.rotation*pi/180;
    R = rotationMatrix(angles, 'XYZ'); % ZYX?
    P = eye(4);
    P(1:3,1:4) = K * [R sweepRecord.position];
    P_str = P_to_str(P);
    fprintf(all_transformationsFile, '%d\n\n%s\n', sweepRecord.panoId, P_str);
    fprintf(thisTransformationFile, '%s\n', P_str);
    fclose(thisTransformationFile);
end

fclose(all_transformationsFile);