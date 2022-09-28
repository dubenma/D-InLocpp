function [ params ] = setupParamsSingleQuery(mode, metaparams,requireExperimentName)
    % mode is one of {'s10e', 'holoLens1', 'holoLens2'}
    % NOTE: the number after 'holoLens' is a sequence number, not a version of HoloLens glasses!
arguments
    mode char
    metaparams 
    requireExperimentName logical = false
end




thisScriptPath = [fileparts(mfilename('fullpath')), '/'];
addpath([thisScriptPath, '../environment']);
addpath([thisScriptPath, '../buildK']);

params = struct();
env = environment();

if strcmp(env, 'laptop')
    params.dataset.dir = '/Volumes/GoogleDrive/Můj disk/ARTwin/InLocCIIRC_dataset';
    params.netvlad.dataset.dir = '/Volumes/GoogleDrive/Můj disk/ARTwin/InLocCIIRC_dataset/NetVLAD';
    params.multiCameraPoseExe.path = '/Users/lucivpav/repos/MultiCameraPose/build/src/multi_camera_pose';
elseif strcmp(env, 'cmp')
    params.dataset.dir = '/mnt/datagrid/personal/lucivpav/InLocCIIRC_dataset';
    params.netvlad.dataset.dir = '/mnt/datagrid/personal/lucivpav/NetVLAD';
    params.multiCameraPoseExe.path = '/mnt/datagrid/personal/lucivpav/MultiCameraPose/build/src/multi_camera_pose';
elseif strcmp(env, 'ciirc')
    params.dataset.dir = '/nfs/projects/artwin/VisLoc/Data/InLocCIIRC_dataset';
    params.netvlad.dataset.dir = '/nfs/projects/artwin/VisLoc/Models/NetVLAD';
    params.multiCameraPoseExe.path = 'TODO';
elseif strcmp(env, 'localization_service')
    params.dataset.dir = '/local/localization_service/Maps/SPRING/hospital_1/cutouts_32';
    params.netvlad.dataset.dir = '/local/localization_service/Models/NetVLAD';
    params.multiCameraPoseExe.path = 'TODO'; 
    
else
    error('Unrecognized environment');
end

params.netvlad.dataset.pretrained = fullfile(params.netvlad.dataset.dir, 'vd16_pitts30k_conv5_3_vlad_preL2_intra_white.mat');

if strcmp(mode, 's10e')
    params = s10eParams(params);
elseif strcmp(mode, 'holoLens1')
    params = holoLens1Params(params);
elseif strcmp(mode, 'holoLens2')
    params = holoLens2Params(params);
elseif strcmp(mode, 'hospital_1')
    params = singleQueryParams(params,metaparams);
else
    error('Unrecognized mode');
end

experimentName = getenv("INLOC_EXPERIMENT_NAME");
if requireExperimentName && isempty(experimentName)
    error('Please specify environment variable INLOC_EXPERIMENT_NAME.');
end

if isempty(experimentName)
    experimentSuffix = '';
    warning('InLocCIIRC is running without an experiment name.');
else
    experimentSuffix = sprintf('-%s', experimentName);
    fprintf('InLocCIIRC is running experiment "%s".\n', experimentName);
end

params.mode = mode;
params.spaceName = 'hospital_1-database'; % TODO: this should be a  propery of the queries - where they were taken
params.dataset.models.dir = fullfile(params.dataset.dir, params.spaceName, 'model');
params.pointCloud.path = fullfile(params.dataset.models.dir, 'cloud - rotated.ply');
params.mesh.path = fullfile(params.dataset.models.dir,  'model_rotated.obj');
params.projectPointCloudPy.path = [thisScriptPath, '../projectPointCloud/projectPointCloud.py'];
params.reconstructPosePy.path = [thisScriptPath, '../reconstructPose/reconstructPose.py'];
params.poses.dir = fullfile(params.dataset.query.dir, 'poses');
params.projectedPoses.dir = fullfile(params.dataset.query.dir, 'projectedPoses');
params.queryDescriptions.path = fullfile(params.dataset.query.dir, 'descriptions.csv');
params.rawPoses.path = fullfile(params.dataset.query.dir, 'rawPoses.csv');
params.inMap.tDiffMax = 1.3;
params.inMap.rotDistMax = 10; % in degrees
params.renderClosestCutouts = false;
params.closest.cutout.dir = fullfile(params.dataset.query.dir, 'closestCutout');
params.vicon.origin.wrt.model = [-0.13; 0.04; 2.80];
params.vicon.rotation.wrt.model = deg2rad([90.0 180.0 0.0]);

params.camera.K = buildK(params.camera.fl, params.camera.sensor.size(2), params.camera.sensor.size(1));

%database
params.dataset.db.space_names = {'B-670', 'B-315'};
%%scan
params.dataset.db.scan.dir = 'scans';
params.dataset.db.scan.matformat = '.ptx.mat';
%%cutouts
params.dataset.db.cutout.dirname = 'cutouts'; % TODO: rename to ...cutouts...?
params.dataset.db.cutout.MatDirname = 'matfiles'; % TODO: rename to ...cutouts...?
params.dataset.db.cutouts.dir = fullfile(params.dataset.dir, params.spaceName, params.dataset.db.cutout.dirname);
params.dataset.db.cutouts.MatDir = fullfile(params.dataset.dir, params.spaceName, params.dataset.db.cutout.MatDirname);
params.dataset.db.cutout.imgformat = '.jpg';
params.dataset.db.cutout.matformat = '.mat';

%%alignments
params.dataset.db.trans.dir = fullfile(params.dataset.dir, 'alignments.legacy');
%query
params.dataset.query.imgformat = '.jpg';

%input
params.input.dir = fullfile(metaparams.cache_folder, 'preprocessing');

params.input.dblist.path = fullfile(params.input.dir, 'cutout_imgnames_all.mat');%string cell containing cutout image names
params.input.qlist.path = fullfile(params.input.dir, 'query_imgnames_all.mat');%string cell containing query image names
params.input.scores.path = fullfile(params.input.dir, 'scores.mat');%retrieval score matrix

params.input.feature.dir = fullfile(params.input.dir, 'features');
params.input.feature.db_matformat = '.features.dense.mat';
params.input.feature.q_matformat = '.features.dense.mat';
params.input.feature.db_sps_matformat = '.features.sparse.mat';
params.input.feature.q_sps_matformat = '.features.sparse.mat';
params.input.projectMesh_py_path = fullfile([thisScriptPath, '../projectMesh/projectMesh.py']);

%output
params.output.dir = fullfile(metaparams.cache_folder, 'main_cache');
params.output.gv_dense.dir = fullfile(params.output.dir, 'gv_dense');%dense matching results (directory)
params.output.gv_dense.matformat = '.gv_dense.mat';%dense matching results (file extention)
params.output.gv_sparse.dir = fullfile(params.output.dir, 'gv_sparse');%sparse matching results (directory)
params.output.gv_sparse.matformat = '.gv_sparse.mat';%sparse matching results (file extention)

params.output.pnp_dense_inlier.dir = fullfile(params.output.dir, 'PnP_dense_inlier');%PnP results (directory)
params.output.pnp_dense.matformat = '.pnp_dense_inlier.mat';%PnP results (file extention)
params.output.pnp_sparse_inlier.dir = fullfile(params.output.dir, 'PnP_sparse_inlier');%PnP results (directory)
params.output.pnp_sparse_inlier.matformat = '.pnp_sparse_inlier.mat';%PnP results (file extention)

params.output.pnp_sparse_origin.dir = fullfile(params.output.dir, 'PnP_sparse_origin');%PnP results (directory)
params.output.pnp_sparse_origin.matformat = '.pnp_sparse_origin.mat';%PnP results (file extention)

params.output.synth.dir = fullfile(params.output.dir, 'synthesized');%View synthesis results (directory)
params.output.synth.matformat = '.synth.mat';%View synthesis results (file extention)

% evaluation
params.evaluation.dir = fullfile(metaparams.output_folder, 'evaluations');
params.evaluation.query_vs_synth.dir = fullfile(params.evaluation.dir, 'queryVsSynth');
params.evaluation.query_segments_vs_synth_segments.dir = fullfile(params.evaluation.dir, 'querySegmentsVsSynthSegments');
params.evaluation.errors.path = fullfile(params.evaluation.dir, 'errors.csv');
params.evaluation.summary.path = fullfile(params.evaluation.dir, 'summary.txt');
params.evaluation.retrieved.poses.dir = fullfile(params.evaluation.dir, 'retrievedPoses');
params.evaluation.retrieved.queries.path = fullfile(params.evaluation.dir, 'retrievedQueries.csv');

% NOTE: this snippet might be expensive
if ~exist(params.input.dblist.path, 'file')
    warning('params.input.dblist.path "%s" does not exists. Some params.dataset.db.cutout params will not be set.', params.input.dir);
else
    load(params.input.dblist.path);
    params.dataset.db.cutout.size = size(imread(fullfile(params.dataset.db.cutouts.dir, cutout_imgnames_all{1})));
    params.dataset.db.cutout.size = [params.dataset.db.cutout.size(2), params.dataset.db.cutout.size(1)]; % width, height
    params.dataset.db.cutout.fl = 600.0000; % TODO: this must match the params in buildCutouts (see _dataset repo)!
    params.dataset.db.cutout.K = buildK(params.dataset.db.cutout.fl, params.dataset.db.cutout.size(1), params.dataset.db.cutout.size(2));
end

%% topN constants; TODO: set it up for ht_retrieval, dense_PE and rename the script names
params.PV.topN = 10;

end