function [ params ] = hospital_1Params(params)
    
    params.spaceName = sprintf('%s-database',params.mode);
    params.dataset.query.dirname = sprintf('%s-query',params.mode);
    params.dataset.query.dir = fullfile(params.dataset.dir, params.dataset.query.dirname,'query_all'); % NOTE: it cannot be extracted to setupParams.m, because we need it in here already
    params.dataset.query.dslevel = 8^-1;
    params.camera.sensor.size = [1200 1600 3];
    params.camera.fl = 600.0; 
    params.blacklistedQueryInd = [1];
    
end