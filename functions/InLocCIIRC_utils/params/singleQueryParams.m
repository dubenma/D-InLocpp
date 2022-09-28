function [ params ] = singleQueryParams(params,metaparams)
    params.dataset.query.dir = metaparams.query_folder; % NOTE: it cannot be extracted to setupParams.m, because we need it in here already
    params.dataset.query.dslevel = 8^-1;
    pathparts = strsplit(params.dataset.query.dir,filesep);
    params.dataset.query.dirname = pathparts{end};
    params.camera.sensor.size = [1200 1600 3];
    params.camera.fl = 600.0; 
    params.blacklistedQueryInd = [1];
end