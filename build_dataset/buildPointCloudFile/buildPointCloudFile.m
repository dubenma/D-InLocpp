addpath('../functions/InLocCIIRC_utils/params');

params = setupParams('s10e'); % NOTE: dummy value, mode is not important here
spaceName = 'B-315'; % TODO: adjust

params.sweepDataMatPath = fullfile(params.dataset.dir, 'sweepData', sprintf('%s.mat', spaceName));
modelPath = fullfile(params.dataset.models.dir, spaceName, 'cloud - rotated.ply');
outputPath = fullfile(params.dataset.dir, 'scans', sprintf('%s.ptx.mat', spaceName));

%%
pc = pcread(modelPath);
x = pc.Location(:,1);
y = pc.Location(:,2);
z = pc.Location(:,3);
intensity = ones(size(x,1), 1);
r = pc.Color(:,1);
g = pc.Color(:,2);
b = pc.Color(:,3);

A = {x, y, z, intensity, r, g, b};

% TODO: nCol, nRow, S, T
save(params.output.path, 'A');