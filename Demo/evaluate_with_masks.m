% user configuration
addpath('utils/')
addpath('tools/')
addpath('visual_inspection/')
%% initialization

occupance_thr = 0.3;

load(params.input.qlist.path); % loads query_imgnames_all.mat
densePV_matname = fullfile(params.output.dir, 'densePV_top10_shortlist.mat');
load(densePV_matname, 'ImgList');

mkdirIfNonExistent(params.evaluation.dir);
mkdirIfNonExistent(params.evaluation.retrieved.poses.dir);
mkdirIfNonExistent(params.evaluation.query_vs_synth.dir);
mkdirIfNonExistent(params.evaluation.query_segments_vs_synth_segments.dir);

%% quantitative results

% do not compute a numerical error for those queries I dont have reference pose! (they are on params.blacklistedQueryInd)
% this would screw up the resulting statistics
nQueries = size(query_imgnames_all,2);
% whitelistedQueries = ones(1,nQueries);
% blacklistedQueries = false(1,nQueries);
% nBlacklistedQueries = 0;
% if isfield(params, 'blacklistedQueryInd')
%     blacklistedQueryNames = arrayfun(@(idx) sprintf('%d.jpg', idx), params.blacklistedQueryInd, 'UniformOutput', false);
%     blacklistedQueries = false(1,nQueries);
%     nSuggestedBlacklistedQueries = length(params.blacklistedQueryInd);
%     for i=1:nSuggestedBlacklistedQueries
%         queryName = blacklistedQueryNames{i};
%         idx = find(strcmp(queryName,query_imgnames_all));
%         if ~isempty(idx)
%             blacklistedQueries(idx) = true;
%         end
%     end
%     nBlacklistedQueries = sum(blacklistedQueries);
%     fprintf('Skipping %0.0f%% queries without reference poses. %d queries remain.\n', ...
%                 nBlacklistedQueries*100/nQueries, nQueries-nBlacklistedQueries);
%     whitelistedQueries = logical(ones(1,nQueries) - blacklistedQueries); % w.r.t. reference frame
% end
query_eval = cell(1,numel(query_imgnames_all));
errors = struct();
retrievedQueries = struct();
inLocCIIRCLostCount = 0;
lostIds = [];
for i=1:numel(ImgList) %continue where we stopped
    %     [~,name,~] =fileparts(ImgList(i).queryname);
    %     queryId = str2num(name);
    mask_name = fullfile(params.input.dir, "queries_masks", string(i) + ".png");
    mask = imread(mask_name);
    mask = mask(:,:,1)/255;
    [w,h] = size(mask);
    occupance = sum(sum(mask))/ (w*h);
    
    if occupance < occupance_thr
        errors(i).queryId =  ImgList(i).queryname;
        errors(i).translation = Inf;
        errors(i).orientation = Inf;
        errors(i).inMap = false;
        retrievedQueries(i).id = i;
        retrievedQueries(i).space = 'hospital';
        continue
    end
   
    
    queryPoseFilename = sprintf('%s.txt', ImgList(i).queryname);
    mkdirIfNonExistent(params.evaluation.dir);
    
    
    
    
    [P,ref_spaceName,fullName] = getReferencePose(i,ImgList,params);
    P_ref = {};
    P_ref.R = P(:,1:3);
    P_ref.t = P(:,4);
    P_ref.P = P;
    P_ref.C = -P_ref.R'*P_ref.t;
    
    P_est = {};
    P_est.P = ImgList(i).Ps{1}{1};
    [P_est.K,P_est.R,P_est.C] = P2KRC(P_est.P);
    P_est.t = -P_est.R*P_est.C;
    est_spaceName = strsplit(ImgList(i).topNname{1},'/'); est_spaceName = est_spaceName{1};
    est_mapName = strsplit(est_spaceName,'_'); est_mapName = est_mapName{1};
    ref_mapName = strsplit(ref_spaceName,'_'); ref_mapName = ref_mapName{1};
    if strcmp(params.mode, 'B315')
        ref_spaceName = 'b315';
        ref_mapName = 'b315';
    end
    
    C_ref = [];
    R_ref = [];
%     if ~strcmp(est_spaceName,ref_spaceName) &&  strcmp(est_mapName,ref_mapName)
%         interesting = true;
%         transform = [];
%         E_h_12 = [1.000000000000 0.000265824958 -0.000320481340 -0.965982019901;
%             -0.000265917915 0.999999940395 -0.000290183641 0.005340866279;
%             0.000320404157 0.000290269381 1.000000119209 0.241866841912;
%             0.000000000000 0.000000000000 0.000000000000 1.000000000000];
%         
%         E_l_21 = [ 0.999996125698 0.000008564073 0.002756817034 3.283028602600;
%             -0.000006930272 0.999999821186 -0.000592759345 0.000593465462;
%             -0.002756824018 0.000592722441 0.999996006489 1.970497488976;
%             0.000000000000 0.000000000000 0.000000000000 1.000000000000];
%         switch (est_spaceName)
%             case params.dataset.db.space_names{1}
%                 transform = E_h_12;
%             case params.dataset.db.space_names{2}
%                 transform = inv(E_h_12);
%             case params.dataset.db.space_names{3}
%                 transform = inv(E_l_21);
%             case params.dataset.db.space_names{4}
%                 transform = E_l_21;
%             otherwise
%                 interesting = true
%                 error('ups')
%                 % getSynthView(params,ImgList,i,1,true);
%         end
%         
%         
%         
%         
%         % norm(P_ref.C - P_est.C)
%         % norm((E)*[P_ref.C;1] - P_est.C)
%         
%         C_ref = transform*[P_ref.C;1];
%         C_ref = C_ref(1:3);
%         R_ref = P_ref.R*transform(1:3,1:3);
% %         errors(i).translation = norm(C_ref(1:3) - P_est.C);
%         
%     else
    transform = eye(4);
    C_ref = P_ref.C;
    R_ref = P_ref.R;
%     end
    query_eval{i}.pano_id = strsplit(fullName,'/'); query_eval{i}.pano_id = query_eval{i}.pano_id{1};
    query_eval{i}.id = i;
    query_eval{i}.query_name = ImgList(i).queryname;
    query_eval{i}.C_ref = C_ref;
    query_eval{i}.R_ref = R_ref;
    query_eval{i}.C_ref_orig = P_ref.C;
    query_eval{i}.R_ref_orig = P_ref.R;
    query_eval{i}.C_est= P_est.C;
    query_eval{i}.R_est = P_est.R;
    query_eval{i}.est_space = est_spaceName;
    query_eval{i}.ref_space = ref_spaceName;
    query_eval{i}.spaceTransform = transform;
    errors(i).translation = norm(C_ref - P_est.C); 
    if strcmp(params.mode, 'B315')
        errors(i).orientation = rotationDistance(R_ref, P_est.R');
    else
        errors(i).orientation = rotationDistance(R_ref, P_est.R);
    end
    errors(i).queryId =  ImgList(i).queryname;
    errors(i).inMap = strcmp(est_mapName,ref_mapName);
    inLocCIIRCLostCount = inLocCIIRCLostCount + isnan(errors(i).translation);
    if isnan(errors(i).translation)
        lostIds = [lostIds i];
    end
    
    visual_inspection = false;
    if errors(i).translation > 2 && visual_inspection
        %         getSynthView(params,ImgList,i,1,true,params.evaluation.dir,sprintf('err_%.2fm',errors(i).translation));
        
    end
    if visual_inspection  && ~isnan(errors(i).translation)
        if ~exist(fullfile(fullfile(params.evaluation.dir,'all_results'),sprintf('%s_results_q_id_%d_best_db_%d.jpg',sprintf('err_%.2fm_%.0fdeg',errors(i).translation,errors(i).orientation),i,1)))
            getSynthView(params,ImgList,i,1,true,fullfile(params.evaluation.dir,'all_results'),sprintf('err_%.2fm_%.0fdeg',errors(i).translation,errors(i).orientation));
        end
    end
    if visual_inspection && isnan(errors(i).translation)
        if ~exist(fullfile(fullfile(params.evaluation.dir,'all_results'),sprintf('%s_results_q_id_%d_best_db_%d.jpg',sprintf('err_NaN'),i,1)))
            getFailureView(params,ImgList,i,1,true,fullfile(params.evaluation.dir,'all_results'),sprintf('%s_results_q_id_%d_best_db_%d.jpg',sprintf('err_NaN'),i,1));
        end
    end
    if visual_inspection    
        if ~exist(fullfile(fullfile(params.evaluation.dir,'all_results', 'matches'),sprintf('%s_results_q_id_%d_best_db_%d.jpg',sprintf('err_NaN'),i,1)))
            getFailureView(params,ImgList,i,1,true,fullfile(params.evaluation.dir,'all_results', 'matches'),sprintf('%s_results_q_id_%d_best_db_%d.jpg',sprintf('err_NaN'),i,1));
        end
    end
  
    
    
    
    
    retrievedPosePath = fullfile(params.evaluation.retrieved.poses.dir, queryPoseFilename);
    mkdirIfNonExistent(fileparts(retrievedPosePath));
    retrievedPoseFile = fopen(retrievedPosePath, 'w');
    P_str = P_to_str(P_est.P);
    fprintf(retrievedPoseFile, '%s', P_str);
    fclose(retrievedPoseFile);
    
    retrievedQueries(i).id = i;
    retrievedQueries(i).space = ref_spaceName;
    
end
save(fullfile(params.evaluation.dir,'query_eval.mat'),'query_eval', 'errors', '-v7');
% errors
errorsBak = errors;
errorsTable = struct2table(errors);
errors = table2struct(sortrows(errorsTable, 'queryId'));
errorsFile = fopen(params.evaluation.errors.path, 'w');
fprintf(errorsFile, 'id,inMap,translation,orientation\n');
for i=1:nQueries
    inMapStr = 'No';
    if errors(i).inMap
        inMapStr = 'Yes';
    end
    fprintf(errorsFile, '%d,%s,%0.4f,%0.4f\n', errors(i).queryId, inMapStr, errors(i).translation, errors(i).orientation);
end
fclose(errorsFile);
errors = errorsBak; % we cannot use the sorted. it would break compatibility with blacklistedQueries array!

meaningfulTranslationErrors = [errors(~isnan([errors.translation])).translation];
meaningfulOrientationErrors = [errors(~isnan([errors.orientation])).orientation];

% statistics of the errors
meanTranslation = mean(meaningfulTranslationErrors);
meanOrientation = mean(meaningfulOrientationErrors);
medianTranslation = median(meaningfulTranslationErrors);
medianOrientation = median(meaningfulOrientationErrors);
stdTranslation = std(meaningfulTranslationErrors);
stdOrientation = std(meaningfulOrientationErrors);

% retrievedQueries
retrievedQueriesTable = struct2table(retrievedQueries);
retrievedQueries = table2struct(sortrows(retrievedQueriesTable, 'id'));
retrievedQueriesFile = fopen(params.evaluation.retrieved.queries.path, 'w');
fprintf(retrievedQueriesFile, 'id space\n');
for i=1:nQueries
    fprintf(retrievedQueriesFile, '%d %s\n', retrievedQueries(i).id, ...
        retrievedQueries(i).space);
end
fclose(retrievedQueriesFile);

%% summary
summaryFile = fopen(params.evaluation.summary.path, 'w');
% thresholds = [[0.05 10],[0.10 10],[0.15 10],[0.20 10],[0.25 10], [0.5 10], [0.75 10],[1 10],[2 10],[5 10]];
thresholds =  logspace(0,2,32)/50;
thresholds = [thresholds; 10*ones(1,size(thresholds,2))];
scores = zeros(1, size(thresholds,2));
inMapScores = scores;
offMapScores = scores;
fprintf(summaryFile, 'Conditions: ');
for i=1:size(thresholds,2)
    if i > 1
        fprintf(summaryFile, ' / ');
    end
    fprintf(summaryFile, '(%g [m], %g [deg])', thresholds(1,i), thresholds(2,i));
    
    count = 0;
    inMapCount = 0;
    offMapCount = 0;
    inMapSize = 0;
    offMapSize = 0;
    for j=1:length(errors)
        if errors(j).translation < thresholds(1,i) && errors(j).orientation < thresholds(2,i)
            count = count + 1;
            if errors(j).inMap
                inMapCount = inMapCount + 1;
            else
                offMapCount = offMapCount + 1;
            end
        end
        if errors(j).inMap
            inMapSize = inMapSize + 1;
        else
            offMapSize = offMapSize + 1;
        end
    end
    
    % we want to include cases InLoc got lost, but not blacklisted queries (=no reference poses)
    nMeaningfulErrors = length(errors);
    scores(i) = count / nMeaningfulErrors * 100;
    inMapScores(i) = inMapCount / inMapSize * 100;
    offMapScores(i) = offMapCount / offMapSize * 100;
end
fprintf(summaryFile, '\n');
for i=1:size(scores,2)
    if i > 1
        fprintf(summaryFile, ' / ');
    end
    fprintf(summaryFile, '%g [%%]', scores(i));
end
fprintf(summaryFile, '\n');

% inMap
for i=1:size(inMapScores,2)
    if i > 1
        fprintf(summaryFile, ' / ');
    end
    fprintf(summaryFile, '%0.2f [%%]', inMapScores(i));
end
fprintf(summaryFile, ' -- InMap\n');

% offMap
% for i=1:size(offMapScores,2)
%     if i > 1
%         fprintf(summaryFile, ' / ');
%     end
%     fprintf(summaryFile, '%0.2f [%%]', offMapScores(i));
% end
% fprintf(summaryFile, ' -- OffMap\n');
fprintf(summaryFile, '\nInLocCIIRC got completely lost %d out of %d times. Not included in the mean/median/std errors.\n', ...
    inLocCIIRCLostCount, nQueries);
fprintf(summaryFile, '\nInLocCIIRC selected a wrong map %d out of %d times.\n', ...
    offMapCount, nQueries);
fprintf(summaryFile, '\nErrors (InLocCIIRC poses wrt reference poses):\n');
fprintf(summaryFile, ' \ttranslation [m]\torientation [deg]\n');
fprintf(summaryFile, 'Mean\t%0.2f\t%0.2f\n', meanTranslation, meanOrientation);
fprintf(summaryFile, 'Median\t%0.2f\t%0.2f\n', medianTranslation, medianOrientation);
fprintf(summaryFile, 'Std\t%0.2f\t%0.2f\n', stdTranslation, stdOrientation);
fclose(summaryFile);
disp(fileread(params.evaluation.summary.path));

figure();
thr_t = thresholds(1,:);
thr_t;
% plot3d([(0:size(scores,2))/2; 0 scores],'-b');
% plot3d([thr_t;scores],'-b','Marker','.','MarkerSize',20); hold on;
plot3d([thr_t;inMapScores],'-b','Marker','.','MarkerSize',20); hold on;
grid on;
% ax = gca
xticks(gca,[0.1,0.15,0.2,(1:8)/4])
xtickangle(-75)
ylim([0 90])
% xticklabels(gca,strsplit(num2str(thr_t)))

hold on;
xlabel('Distance threshold [m]');
ylabel('Correctly localised queries [%]');
title('InLoc results')

 if contains(params.dynamicMode, "static")
    title_str = "without filtering";
elseif contains(params.dynamicMode, "dynamic")
    title_str = "with filtering";
 end

title(title_str)
eval_name = "correctly_localized_queries";
eval_name = eval_name + "_occupance_" + occupance_thr*100 + "%";
saveas(gcf,fullfile(params.evaluation.dir, eval_name + ".jpg"))
save(fullfile(params.evaluation.dir, eval_name + ".mat"),'thr_t', 'scores', 'inMapScores','title_str', '-v7');