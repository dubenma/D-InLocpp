function [ params ] = SPRINGDemoParams(params)
    experiment_name = "yolact_masks_final"; % "", "gt_masks", yolact_masks, yolact_masks_final
    params.experiment_name = experiment_name;
    %params.spaceName = sprintf('');
    params.dynamicMode = "dynamic_1"; % original, static_1, dynamic_1, dynamic_2...
    
    if params.dynamicMode == "original"
        params.dataset.name = "Broca_dataset_static";
    elseif contains(params.dynamicMode, "static")
        tmp = split(params.dynamicMode, "_");
        modeN = tmp(2);
        params.dataset.name = "Broca_dataset_dynamic_" + modeN;
    elseif contains(params.dynamicMode, "dynamic")
        params.dataset.name = "Broca_dataset_" + params.dynamicMode; 
    else
        error('Unrecognized mode');
    end
    % query
    params.dataset.query.space_names = {'hospital_real_objects'}; % {'livinglab', 'hospital'};
    % database
    params.dataset.db.space_names = params.dataset.query.space_names;
   
    params.dataset.dir = fullfile('/local1/homes/dubenma1/data/localization_service_dataset/Maps', params.dataset.name);
    
    params.dataset.query.dirname = sprintf('queries');
    params.dataset.query.mainDir =  fullfile(params.dataset.dir,params.dataset.query.dirname);
    params.dataset.query.dir = fullfile(params.dataset.query.mainDir,params.dataset.query.space_names,'query_all'); % NOTE: it cannot be extracted to setupParams.m, because we need it in here already
    params.dataset.query.dslevel = 8^-1;
    params.camera.sensor.size = [756 1344 3]; %height, width, 3
    params.camera.fl = 1034.0000; 
    params.camera.K = buildK(params.camera.fl, params.camera.sensor.size(2), params.camera.sensor.size(1));
    
    params.blacklistedQueryInd = [];

    space_names_strs = string(params.dataset.query.space_names);
    str = space_names_strs(1);
    for i = 2 : length(space_names_strs)   
        str = str + "_" + space_names_strs(i);
    end
    
    n_queries = 0;
    for i = 1 : length(params.dataset.query.space_names)
        n_queries = n_queries + length(dir(fullfile(params.dataset.query.dir{i}, "*.jpg"))); % number of queries   
    end
    
%     params.cache.dir = fullfile('/local1/homes/dubenma1/data/localization_service_dataset/Cache_' + params.dataset.name, params.dynamicMode, string(n_queries) + "_queries");
%     params.results.dir = fullfile('/local1/homes/dubenma1/data/localization_service_dataset/Results_' + params.dataset.name, params.dynamicMode, string(n_queries) + "_queries");     

    params.cache.dir = fullfile('/local1/homes/dubenma1/data/localization_service_dataset/Cache_' + params.dataset.name, params.dynamicMode, str + "_" + string(n_queries) + "_queries");
    params.results.dir = fullfile('/local1/homes/dubenma1/data/localization_service_dataset/Results_' + params.dataset.name, params.dynamicMode, str + "_" + string(n_queries) + "_queries");
    
    if experiment_name ~= ""
        params.cache.dir = fullfile(params.cache.dir, experiment_name);
        params.results.dir = fullfile(params.results.dir, experiment_name);
    end
    
end