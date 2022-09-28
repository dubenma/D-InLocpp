addpath('../functions/InLocCIIRC_utils/params');

params = setupParams('hospital_1', true); % NOTE: mode can be anything, its specific params are not used here

featuresPath = fullfile(params.input.feature.dir, 'computed_features.mat');

files = dir(fullfile(params.dataset.db.cutouts.dir, '**/cutout*.jpg'));
nCutouts = size(files,1); % TODO: use the actual number from featuresPath

%x = matfile(featuresPath);
load(featuresPath, 'queryFeatures', 'cutoutFeatures');
nQueries = size(queryFeatures,2);
score = struct('queryname', {}, 'scores', {});

allCutoutFeatures = zeros(nCutouts, size(cutoutFeatures(1).features,1));
for i=1:nCutouts
    allCutoutFeatures(i,:) = cutoutFeatures(i).features';
end
allCutoutFeatures = allCutoutFeatures';

tol = 1e-6;
if ~all(abs(vecnorm(allCutoutFeatures)-1.0)<tol)
    fprintf('norm: %f\n', vecnorm(allCutoutFeatures));
    error('Features are not normalized!');
end
for i=1:nQueries
    fprintf('processing query %d/%d\n', i, nQueries);
    thisQueryFeatures = queryFeatures(i).features';
    if ~all(abs(norm(thisQueryFeatures)-1.0)<tol)
        fprintf('norm: %f\n', norm(thisQueryFeatures));
        error('Features are not normalized!');
    end
    thisQueryFeatures = repmat(thisQueryFeatures, nCutouts, 1)';
    similarityScores = dot(thisQueryFeatures, allCutoutFeatures);
    score(i).queryname = queryFeatures(i).queryname;
    score(i).scores = single(similarityScores); % NOTE: this is not a probability distribution (and it does not have to be)
end

save(params.input.scores.path, 'score');