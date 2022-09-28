addpath('..')
% startup;

setenv("INLOC_EXPERIMENT_NAME","SPRING_Demo")
setenv("INLOC_HW","GPU")
[ params ] = setupParams('SPRING_Demo', true); % NOTE: adjust


QNs = load('/local/localization_service/Cache/inputs-SPRING_Demo/query_imgnames_all.mat');
query_imgnames_all = QNs.query_imgnames_all;
imList = load('/local/localization_service/Cache/outputs-SPRING_Demo/densePV_top10_shortlist.mat');
imList = imList.ImgList;
query_gt = cell(1,numel(query_imgnames_all));
for i = 1:numel(query_imgnames_all)
    
        query_gt{i} = {};
    [query_gt{i}.pose, query_gt{i}.space, query_gt{i}.full_name]= getReferencePose(i,imList,params); 
%     query_gt{i}.pose = query_gt{i}.pose(:);
      query_gt{i}.id = i;
end
save('/local/localization_service/Maps/SPRING/Broca_dataset/queries/q_gts.mat','query_gt', '-v7');