function [ params ] = holoLens2Params(params)
    % TODO: some of these params are legacy. Adjustments needed.

    params.dataset.query.dirname = 'query-HoloLens2';
    params.dataset.query.dir = fullfile(params.dataset.dir, params.dataset.query.dirname); % NOTE: it cannot be extracted to setupParams.m, because we need it in here already
    params.holoLens.dir = '/Volumes/GoogleDrive/Můj disk/ARTwin/personal/lucivpav/HoloLens sequences';
    params.holoLens.measurement.path = fullfile(params.holoLens.dir, 'measurement2.txt');
    params.holoLens.recording.dir = fullfile(params.holoLens.dir, 'HoloLensRecording__2020_04_23__10_15_23');
    params.holoLens.query.dir = fullfile(params.holoLens.recording.dir, 'pv');
    params.holoLens.poses.path = fullfile(params.holoLens.recording.dir, 'pv_locationData.csv');
    params.HoloLensPoses.dir = fullfile(params.dataset.query.dir, 'HoloLensPoses');
    params.HoloLensProjectedPointCloud.dir = fullfile(params.dataset.query.dir, 'HoloLensProjectedPointCloud');
    params.HoloLensTranslationDelay = 5; % in frames, w.r.t. reference poses
    params.HoloLensOrientationDelay = 4; % in frames, w.r.t. reference poses
    params.sequence.length = 1; % data is sequential, but we do not want to leverage pose estimates provided by HoloLens. TODO

    % NOTE: some reference poses are wrong due to Vicon error, blacklist them
    params.blacklistedQueryInd = [1:86, 88, 91, 212:235, 239:240, 253:332, 335, 376:391, 403:436, 442:485, 561:564, 567:572];

    %params.camera.rotation.wrt.marker = [2.0 2.0 3.0]; % this is near optimal for query 1
    %params.camera.rotation.wrt.marker = [2.0 5.0 5.0]; % this is near optimal for query 2
    %params.camera.rotation.wrt.marker = [-1.0 3.0 4.0]; % this is near optimal for query 3
    %params.camera.rotation.wrt.marker = [2.0 5.0 5.0]; % this is optimal for query 1 & 2
    %params.camera.rotation.wrt.marker = [-1.0 3.0 4.0]; % this is optimal for query 3 & 4
    params.camera.rotation.wrt.marker = [2.0 5.0 5.0]; % this is optimal for query 1 & 2 & 4
    params.camera.originConstant = 0.023;
    %params.camera.origin.wrt.marker = params.camera.originConstant * [-3; 13; -5]; % this is near optimal for query 1
    %params.camera.origin.wrt.marker = params.camera.originConstant * [3; 16; -3]; % this is near optimal for query 2
    %params.camera.origin.wrt.marker = params.camera.originConstant * [3; 13; -7]; % this is near optimal for query 3
    %params.camera.origin.wrt.marker = params.camera.originConstant * [1; 15; -7]; % this is optimal for query 1 & 2
    %params.camera.origin.wrt.marker = params.camera.originConstant * [2; 11; -3]; % this is optimal for query 3 & 4
    params.camera.origin.wrt.marker = params.camera.originConstant * [1; 15; -7]; % this is optimal for query 1 & 2 & 4
    params.camera.sensor.size = [756, 1344]; % height, width
    params.camera.fl = 1015; % in pixels
    %params.HoloLensViconSyncConstant = 29.0 * 1000; % [ms]; expected: <28.8, 29.4> % this is near optimal for query 1
    %params.HoloLensViconSyncConstant = 29.0 * 1000; % [ms]; expected: <28.8, 29.4> % this is near optimal for query 2
    %params.HoloLensViconSyncConstant = 29.0 * 1000; % [ms]; expected: <28.8, 29.4> % this is near optimal for query 3
    %params.HoloLensViconSyncConstant = 29.1 * 1000; % [ms]; expected: <28.8, 29.4> % this is optimal for query 1 & 2
    %params.HoloLensViconSyncConstant = 29.2 * 1000; % [ms]; expected: <28.8, 29.4> % this is optimal for query 3 & 4
    params.HoloLensViconSyncConstant = 29.1 * 1000; % [ms]; expected: <28.8, 29.4> % this is optimal for query 1 & 2 & 4

    % NOTE: params for 1 & 2 & 4 are the same as for 1 & 2
    
    %% interesting queries and corresponding matches %%
    params.interestingQueries = ["00132321103461934087.jpg", ... % aka query 1
                                    "00132321103645112241.jpg", ... % aka query 2
                                    "00132321104757170200.jpg", ... % aka query 3
                                    "00132321104893721201.jpg"]; % aka query 4
    % interestingPointsQuery{i} are 2D projections of points in interestingPointsPC{i}.
    % i is the i-th query in params.interestingQueries
    params.interestingPointsPC{1} = [5.2058, 1.1974, 2.2684; ...
                                        4.0178, 0.7731, 2.5884; ...
                                        2.7156, 0.0101, 2.2784; ...
                                        5.1687, 0.9174, 2.2984]';
    params.interestingPointsQuery{1} = [87, 21; ...
                                        594, 79; ...
                                        1243, 601; ...
                                        187, 112]';

    params.interestingPointsPC{2} = [-2.2044, 3.544, -2.7116; ...
                                        -3.5044, 3.0874, -3.2630; ...
                                        0.2856, 3.5303, -2.1116; ...
                                        -2.4144, 3.5350, -0.8916]';
    params.interestingPointsQuery{2} = [523, 406; ...
                                        307, 582; ...
                                        1227, 210; ...
                                        157, 132]'; % first row: x, second row: y

    params.interestingPointsPC{3} = [4.3559, 0.7856, 5.3284; ...
                                        9.8700, 1.9774, 1.5384; ...
                                        16.8459, 2.0674, 6.6384; ...
                                        9.1756, 0.7735, 7.8538]';
    params.interestingPointsQuery{3} = [1032, 502; ...
                                        325, 12; ...
                                        946, 34;
                                        1297, 223]';

    params.interestingPointsPC{4} = [3.9556, 3.5440, 8.2384; ...
                                        7.0156, 3.4907, 8.2184; ...
                                        5.8256, 2.0874, 7.8641; ...
                                        1.8656, 2.5312, 8.9884]';
    params.interestingPointsQuery{4} = [655, 256; ...
                                        142, 404; ...
                                        207, 663; ...
                                        1317, 477]';
end