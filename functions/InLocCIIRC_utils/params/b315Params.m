function [ params ] = b315Params(params)
    
    %params.spaceName = sprintf('');
    params.dynamicMode = "static"; % original, static, dynamic
    
    params.dataset.name = "b315_dataset"; %TODO
    
    % query
    params.dataset.query.space_names = {'seq03'}; % {'seq03', 'seq04'}
    % database
    params.dataset.db.space_names = {'b315'};
   
    params.dataset.dir = fullfile('/local1/projects/artwin/datasets/B-315_dataset/matterport_data/localization_service/Maps/', params.dataset.name); %TODO
    
    params.dataset.query.dirname = sprintf('queries');
    params.dataset.query.mainDir =  fullfile(params.dataset.dir,params.dataset.query.dirname);
    params.dataset.query.dir = fullfile(params.dataset.query.mainDir,params.dataset.query.space_names,'query_all');
    params.dataset.query.dslevel = 8^-1;
    params.camera.sensor.size = [756 1344 3]; %height, width, 3
    
    % hololens parameters
    params.camera.fl = 1037.301697;
    u0 = 664.387146;
    v0 = 396.142090;
    params.camera.K = [params.camera.fl 0 u0; 0 params.camera.fl v0; 0 0 1];
    
    params.blacklistedQueryInd = [];

    space_names_strs = string(params.dataset.query.space_names);
    str = params.dataset.name;
    for i = 1 : length(space_names_strs)   
        str = str + "_" + space_names_strs(i);
    end
    
    n_queries = 0;
    for i = 1 : length(params.dataset.query.space_names)
        n_queries = n_queries + length(dir(fullfile(params.dataset.query.dir{i}, "*.jpg"))); % number of queries   
    end
    
    main_dir = fullfile('/local1/projects/artwin/datasets/B-315_dataset/', 'inloc_results');
    params.cache.dir = fullfile(main_dir, 'Cache_' + params.dataset.name, params.dynamicMode, string(n_queries) + "_queries");
    params.results.dir = fullfile(main_dir, 'Results_' + params.dataset.name, params.dynamicMode, string(n_queries) + "_queries");
    
end