function [ params ] = setupParams2

addpath('../functions/InLocCIIRC_utils/params');
params = setupParams('hospital_1'); % NOTE: dummy value, it does not matter which mode is set

% add some extra stuff
params.spaceName = 'dining_room';
params.sweepData.json.path = fullfile(params.dataset.dir, 'sweepData', sprintf('%s.json', params.spaceName));
params.sweepData.mat.path = fullfile(params.dataset.dir, 'sweepData', sprintf('%s.mat', params.spaceName));
params.pointCloud.path = fullfile(params.dataset.models.dir,  'cloud_rotated.ply');
params.panoramas.dir = fullfile(params.dataset.dir, 'panoramas', params.spaceName);
params.panorama2pointClouds.dir = fullfile(params.dataset.dir, 'panoramas2pointClouds', params.spaceName);
params.rotatedPanoramas.dir = fullfile(params.dataset.dir, 'rotatedPanoramas', params.spaceName);
params.temporary.dir = fullfile(params.dataset.dir, 'temp');

end

