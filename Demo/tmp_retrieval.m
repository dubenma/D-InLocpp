
% ... RUN IMAGE DENSEGV BEFORE THIS SCRIPT


% INPUT GT DATA
cutout_poses_B315 = "/nfs/projects/artwin/VisLoc/Data/InLocCIIRC_dataset/sweepData/B-315.mat";
cutout_poses_B640 = "/nfs/projects/artwin/VisLoc/Data/InLocCIIRC_dataset/sweepData/B-670.mat";
s10e_poses = "/nfs/projects/artwin/InLoc/InLocCIIRC_dataset/query-s10e/poses";

% LOAD CUTOUT POSES 
cutout_poses = struct();
load(cutout_poses_B315);
cutout_poses = simplify_cutout_poses(sweepData, "B315", cutout_poses);
load(cutout_poses_B640);
cutout_poses = simplify_cutout_poses(sweepData, "B670", cutout_poses);
cutout_names = fieldnames(cutout_poses);

% WE ARE CALLCULATING
recall_thresholds = [1 2 3 4 5 10 15 20 25];
N = length(ImgList_original);
M = size(recall_thresholds);
best_img_netvlad = zeros(N,1);
best_img_densegv = zeros(N,1);
best_img_densepv = zeros(N,1);

d_netvlad = zeros(40, 58); 
ImgList = struct('queryname', {}, 'topNname', {}, 'topNscore', {}, 'primary', {}, 'Ps', {});
for ii = 1:N
    ImgList(ii).queryname = ImgList_original(ii).queryname;
    ImgList(ii).topNname = ImgList_original(ii).topNname(1:shortlist_topN);
    ImgList(ii).primary = ImgList_original(ii).primary;
    queryname = ImgList_original(ii).queryname;
    queryscores = ImgList_original(ii).topNscore;
    topNname = ImgList_original(ii).topNname;
    query_id = str2num(queryname(1:end-4));
    

%%  TEST THE RECALL BEFORE denseGV
    fileID = fopen(sprintf("%s/%d.txt",s10e_poses, query_id),'r');  v = fscanf(fileID, '%f');  fclose(fileID); 
    query_pose = reshape(v,4,4)';
    query_C = - query_pose(1:3,1:3)' * query_pose(1:3,4); 
    
%     FIND THE CLOSEST VIEW
    cutouts_C = cell2mat(cellfun(@(fname) cutout_poses.(fname),fieldnames(cutout_poses),'UniformOutput', false)');
    [min_dist, closest_cutout_id] = min(sum((cutouts_C - query_C).^2));
    closest_cutout_name = cutout_names{closest_cutout_id};
    d_netvlad(ii,:) = sum((cutouts_C - query_C).^2);
%     figure(); plot(d_netvlad);
    
%     CALCULATE HOW FAR IS THE BEST IMG
    for j = 1:100
        c = split(ImgList(ii).topNname{j},'/');
        cutout_name = sprintf("%s_%02d",strrep(c{1},'-',''), str2num(c{2}));
        if strcmp(cutout_name, closest_cutout_name)
            best_img_netvlad(ii) = j;
            break;
        end
    end

    
    
%%  CALCULATE GV AND SORT SCORE
%     for j = 1:100
%         fprintf('dense matching: %s vs %s\n', queryname, topNname{j});
%         parfor_denseGV( cnnq, queryname, topNname{j}, params );
%     end
    for jj = 1:100
        cutoutPath = ImgList(ii).topNname{jj};
        this_gvresults = load(fullfile(params.output.gv_dense.dir, ImgList(ii).queryname, buildCutoutName(cutoutPath, params.output.gv_dense.matformat)));
        ImgList(ii).topNscore(jj) = ImgList_original(ii).topNscore(jj) + size(this_gvresults.inls12, 2);
        
%         this_densegv_matname = fullfile(params.output.gv_dense.dir, queryname, buildCutoutName(topNname{j}, params.output.gv_dense.matformat));
%         load(this_densegv_matname,'inls12');
%         if ~isempty(inls12)
%             queryscores(j) = queryscores(j) + size(inls12,2);
%         end
    end
    [sorted_score, idx] = sort(ImgList(ii).topNscore, 'descend');
    ImgList(ii).topNname = ImgList(ii).topNname(idx);
    ImgList(ii).topNscore = ImgList(ii).topNscore(idx);
    
    
    %     CALCULATE HOW FAR IS THE BEST IMG
    for j = 1:100
        c = split(ImgList(ii).topNname{j},'/');
        cutout_name = sprintf("%s_%02d",strrep(c{1},'-',''), str2num(c{2}));
        if strcmp(cutout_name, closest_cutout_name)
            best_img_densegv(ii) = j;
            break;
        end
    end
    

% %%     CALCUALTE PV AND SORT SCORE
%     for j = 1:100
%         c = split(topNname{j},'/');
%         this_densepe_matname = fullfile(params.output.pnp_dense_inlier.dir, queryname, ...
%             sprintf('%d%s', str2num(c{2}), params.output.pnp_dense.matformat));
%         load(this_densepe_matname);
%     
%     end
end

[best_img_netvlad best_img_densegv]
best_img_netvlad(best_img_netvlad == 0) = 100;
best_img_densegv(best_img_densegv == 0) = 100;

recall_netvlad_q = zeros(size(recall_thresholds,2),1);
recall_densegv_q = zeros(size(recall_thresholds,2),1);
for j = 1:size(recall_thresholds,2)
    recall_netvlad_q(j) = sum(best_img_netvlad <= recall_thresholds(j));
    recall_densegv_q(j) = sum(best_img_densegv <= recall_thresholds(j));
end
recall_netvlad_q = recall_netvlad_q / size(best_img_netvlad,1);
recall_densegv_q = recall_densegv_q / size(best_img_densegv,1);

figure();
plot(recall_thresholds, 100*recall_netvlad_q, 'r.-', 'MarkerSize', 25, 'LineWidth', 2); hold on;
plot(recall_thresholds, 100*recall_densegv_q, 'b.-', 'MarkerSize', 25, 'LineWidth', 2); 
xlabel('number of candidate images'); grid on;
ylabel('recall@1');
legend('NetVLAD', 'DenseGV');


%% inner functions
function s = simplify_cutout_poses(sweepData, room_name, s)
    for i = 1:size(sweepData,2)
        s.(sprintf("%s_%02d",room_name,sweepData(i).panoId)) = sweepData(i).position;
    end
end