function [P,spaceName,fullName] = getReferencePose(qid,imgList,params)
%GETQUERYPOSE Summary of this function goes here
%   Detailed explanation goes here
    qname = imgList(qid).queryname;
    spaceName = strsplit(qname,'/'); spaceName = spaceName{1};
    [~,space_id,~] = fileparts(qname); space_id = str2num(space_id); % space_id is the query id
    params.dataset.db.space_names;
    trueName = '';

    run(fullfile(params.dataset.query.mainDir, spaceName, 'query_all', 'metadata', 'query_mapping.m'));

    trueName = q2name(space_id);

    
    if strcmp(params.mode,'B315')
        panoDirId = 1;
    else
        panoId = strsplit(trueName,'_'); 
        panoDirId = str2double(panoId{3})+1;
    end
    P_gt = load(fullfile(params.dataset.query.mainDir,spaceName,'poses',string(panoDirId),sprintf('%s.%s',trueName,'mat')));
    P_gt.C = P_gt.position';
    rFix = [0., 180., 180.];
    Rfix = rotationMatrix(deg2rad(rFix), 'XYZ');
    Rfix = eye(3);
    % Rfix = [1 0 0; 0 -1 0; 0 0 -1]
    P_gt.R =Rfix*P_gt.R';
    P = [P_gt.R, -P_gt.R*P_gt.C];
    fullName = sprintf('%s/%s',string(panoDirId),trueName);
end
