addpath('../functions/relja_matlab');
addpath('../functions/relja_matlab/matconvnet/');
addpath('../functions/netvlad/');
addpath('../functions/InLocCIIRC_utils/at_netvlad_function');
addpath('../functions/InLocCIIRC_utils/params');
run('../functions/matconvnet/matlab/vl_setupnn.m');

params = setupParams('hospital_1', true); % TODO: adjust the mode
queryDirWithSlash = [params.dataset.query.dir, '/'];

x = load(params.input.dblist.path);
cutoutImageFilenames = x.cutout_imgnames_all;
cutoutSize = size(imread(fullfile(params.dataset.db.cutouts.dir, cutoutImageFilenames{1})));
cutoutSize = [cutoutSize(2), cutoutSize(1)]; % width, height

if exist(params.input.feature.dir, 'dir') ~= 7
    mkdir(params.input.feature.dir);
end

load(params.netvlad.dataset.pretrained, 'net');
net = relja_simplenn_tidy(net);
net = relja_cropToLayer(net, 'postL2'); %original
% net = relja_cropToLayer(net, 'vlad:intranorm'); %experiment SS2021

%% query
x = load(params.input.qlist.path);
queryImageFilenames = x.query_imgnames_all;

featureLength = 32768;

%serialAllFeats(net, queryDirWithSlash, queryImageFilenames, params.input.feature.dir, 'useGPU', false, 'batchSize', 1);

nQueries = size(queryImageFilenames,2);
queryFeatures = struct('queryname', {}, 'features', {});
for i=1:nQueries
    fprintf('Finding features for query #%d/%d\n\n', i, nQueries)
    queryName = queryImageFilenames{i};
    queryImage = load_query_image_compatible_with_cutouts(fullfile(queryDirWithSlash, queryName), cutoutSize);
    cnn = at_serialAllFeats_convfeat(net, queryImage, 'useGPU', true);
    queryFeatures(i).queryname = queryName;
    queryFeatures(i).features = cnn{6}.x(:);
end

%% cutouts
nCutouts = size(cutoutImageFilenames,2);
cutoutFeatures = zeros(nCutouts, featureLength, 'single');
cutoutFeatures = struct('cutoutname', {}, 'features', {});
for i=1:nCutouts
    fprintf('Finding features for cutout #%d/%d\n\n', i, nCutouts)
    cutoutName = cutoutImageFilenames{i};
    cutoutImage = imread(fullfile(params.dataset.db.cutouts.dir, cutoutName));
    cnn = at_serialAllFeats_convfeat(net, cutoutImage, 'useGPU', true);
    cutoutFeatures(i).cutoutname = cutoutName;
    cutoutFeatures(i).features = cnn{6}.x(:);
end

%% save the features
p = fullfile(params.input.feature.dir, 'computed_features.mat');
save(p, 'queryFeatures', 'cutoutFeatures', '-v7.3');