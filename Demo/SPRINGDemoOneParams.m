function [ params ] = SPRINGDemoOneParams(params)
    
    params.spaceName = sprintf('');
    params.dataset.query.space_names = {'hospital_1'};
    params.dataset.query.dirname = sprintf('queries');
    params.dataset.query.mainDir =  fullfile(params.dataset.dir,params.dataset.query.dirname);
    params.dataset.query.dir = fullfile(params.dataset.query.mainDir,params.dataset.query.space_names,'query_one'); % NOTE: it cannot be extracted to setupParams.m, because we need it in here already
    params.dataset.query.dslevel = 8^-1;
    params.camera.sensor.size = [1200 1600 3];
    params.camera.fl = 600.0; 
    params.blacklistedQueryInd = [];
    
end