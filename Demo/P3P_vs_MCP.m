% the goal of this script is to determine whether the quality of 2D-3D matches given to MCP when processing a segment is good enough
% if P3P can handle the individual queries without a problem, it means the matches should be good enough
% data used from previously run inloc_demo.m
% this script is processing individual queries in the segment using P3P

%% script inputs - adjust accordingly
queryMode = 'holoLens1';
experimentName = 'HL1-v4.2-k2';
segmentName = '197.jpg'; % the best choice from PV shortlist will be chosen

%% initialize
setenv("INLOC_EXPERIMENT_NAME", experimentName);
startup;

%% setup original and new params; clean previously generated data
[ params ] = setupParams(queryMode, true);

newExperimentName = sprintf('%s-P3P_vs_MCP', experimentName);
setenv("INLOC_EXPERIMENT_NAME", newExperimentName);
% this will trigger warning, if newParams.input.dblist.path does not exist
[ newParams ] = setupParams(queryMode, true);
setenv("INLOC_EXPERIMENT_NAME", experimentName);

[~,~,~] = rmdir(newParams.input.dir, 's');
[~,~,~] = rmdir(newParams.output.dir, 's');
[~,~,~] = rmdir(newParams.evaluation.dir, 's');

mkdirIfNonExistent(newParams.input.dir);
copyfile(params.input.dblist.path, newParams.input.dblist.path);

% now there must not be any warning
setenv("INLOC_EXPERIMENT_NAME", newExperimentName);
[ newParams ] = setupParams(queryMode, true);
setenv("INLOC_EXPERIMENT_NAME", experimentName);

%% parfor_densePE
mkdirIfNonExistent(newParams.output.dir);
mkdirIfNonExistent(newParams.output.gv_dense.dir);
load(fullfile(params.output.dir, 'densePV_top10_shortlist.mat'), 'ImgList');
ImgListRecord = ImgList(strcmp({ImgList.queryname}, segmentName));
qname = segmentName;
parentQueryId = queryNameToQueryId(segmentName);
dbnames = ImgListRecord.topNname(:,1);
dbnamesId = ImgListRecord.dbnamesId(1); % dbnamesId can be basically arbitrary in this script
segmentLength = length(dbnames);
queryInd = zeros(segmentLength, 1);
for i=1:segmentLength
    queryInd(i) = parentQueryId - segmentLength + i;
end
posesFromHoloLens = getPosesFromHoloLens(params.HoloLensOrientationDelay, params.HoloLensTranslationDelay, queryInd, params);
    % not actually used
firstQueryId = parentQueryId - segmentLength + 1;
lastQueryId = parentQueryId;
% we need to copy precomputed denseGV results
for i=1:length(queryInd)
    thisQueryId = queryInd(i);
    thisQueryName = sprintf('%d.jpg', thisQueryId);
    dbname = dbnames{i};
    mkdirIfNonExistent(fullfile(newParams.output.gv_dense.dir, thisQueryName));
    source_this_densegv_matname = fullfile(params.output.gv_dense.dir, thisQueryName, ...
                                            buildCutoutName(dbname, params.output.gv_dense.matformat));
    target_this_densegv_matname = fullfile(newParams.output.gv_dense.dir, thisQueryName, ...
                                            buildCutoutName(dbname, newParams.output.gv_dense.matformat));
    copyfile(source_this_densegv_matname, target_this_densegv_matname);
    parfor_densePE(thisQueryName, {dbname}, dbnamesId, posesFromHoloLens, thisQueryId, thisQueryId, newParams);
end

%% create shortlist PE, such that it contains segmentLength lines, representing single queries
ImgList = struct('queryname', {}, 'topNname', {}, 'topNscore', {}, 'Ps', {});
for i=1:segmentLength
    thisQueryId = queryInd(i);
    thisQueryName = sprintf('%d.jpg', thisQueryId);
    this_densepe_matname = fullfile(newParams.output.pnp_dense_inlier.dir, thisQueryName, ...
                                        sprintf('%d%s', dbnamesId, newParams.output.pnp_dense.matformat));
    load(this_densepe_matname, 'Ps');
    ImgList(i).queryname = thisQueryName;
    ImgList(i).topNname = dbnames(i);
    ImgList(i).topNscore = ones(1,1);
    ImgList(i).Ps = {{Ps{1}}}; % this must be 1x1 cell array containing a 1x1 cell array containing 3x4 double (the P)
end
save('-v6', fullfile(newParams.output.dir, 'densePE_top100_shortlist.mat'), 'ImgList');

%% parfor_densePV that chooses only top 1 from dense PE shortlist
newParams.PV.topN = 1;
paramsBak = params;
params = newParams;
ImgList_densePE = ImgList;
ht_top10_densePV_localization;
params = paramsBak;

%% evaluate
query_imgnames_all = cell(1,segmentLength);
for i=1:segmentLength
    thisQueryId = queryInd(i);
    thisQueryName = sprintf('%d.jpg', thisQueryId);
    query_imgnames_all{i} = thisQueryName;
end
save(fullfile(newParams.input.qlist.path), 'query_imgnames_all');
paramsBak = params;
params = newParams;
evaluate;
params = paramsBak;