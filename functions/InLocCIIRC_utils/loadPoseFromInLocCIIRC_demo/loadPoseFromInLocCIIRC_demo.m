function [P,T,R,spaceName,descriptions] = loadPoseFromInLocCIIRC_demo(queryId, ImgList, params)
    % queryId: e.g. 134
    % P: it is NOT a projection matrix, but a format used by InLocCIIRC to store poses
    % T: wrt model
    % R: modelBasesToEpsilonBases
    % it can handle the case when the returned relative pose is NaN, because InLocCIIRC got lost
    queryName = sprintf('%d.jpg', queryId);
    ImgListRecord = ImgList(find(strcmp({ImgList.queryname}, queryName)));
    cutoutPath = ImgListRecord.topNname{end,1};
    cutoutPath = strsplit(cutoutPath, '/');
    spaceName = cutoutPath{1};
    sweepId = cutoutPath{2};
    transPath = fullfile(params.dataset.db.trans.dir, spaceName, 'transformations', sprintf('trans_%s.txt', sweepId));
    P1 = load_CIIRC_transformation(transPath);
    R1 = P1(1:3,1:3);
    P2 = ImgListRecord.Ps{1}{end};
    if any(isnan(P2(:)))
        P = nan(4,4);
        T = nan(3,1);
        R = nan(3,3);
    else
        P = P2*P1;
        P = [P; 0 0 0 1];
        T = -inv(P(1:3,1:3))*P(1:3,4);
        R = P(1:3,1:3);
    end
end