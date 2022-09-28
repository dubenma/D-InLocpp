addpath('visual_inspection/')
addpath('tools/')


%% ids for all montages
% id_q = randperm(numel(ImgList_densePV),n_q);
id_q =[158   137   275   284    67   174   360   229   250   265];
foldername = 'montages_id_q_';
for id = id_q
foldername = sprintf('%s_%d',foldername,id);
end
mkdirIfNonExistent(fullfile(params.evaluation.dir,foldername));
% seems nice
% id_q =[158   137   275   284    67   174   360   229   250   265];
%% montage image retrieval
ImgList_original;
n_q = min(numel(ImgList_original),10);
% id_q = randperm(numel(ImgList_original),n_q);
n_top = 5;
img_fns = cell(n_top+1,n_q);
for i_ = 1:n_q
    i = id_q(i_);
    img_fns{1,i_} = fullfile(params.dataset.query.mainDir, ImgList_original(i).queryname);
    for j_ = 1:n_top
       j = j_+1;
       img_fns{j,i_} = fullfile(params.dataset.db.cutout.dir, ImgList_original(i).topNname{j_});
    end
   
end
figure();
% title('Image Retrieval');
hold on;
montage(img_fns,'Size',[n_q n_top+1]);
 saveas(gcf,fullfile(params.evaluation.dir,foldername,'image_retrieval.jpg'))
%% montage post Pose estimation
ImgList_densePE;
n_q = min(numel(ImgList_densePE),10);
% id_q = randperm(numel(ImgList),n_q);
n_top = 5;
img_fns = cell(n_top+1,n_q);
for i_ = 1:n_q
    i = id_q(i_);
    img_fns{1,i_} = fullfile(params.dataset.query.mainDir, ImgList_densePE(i).queryname);
    for j_ = 1:n_top
       j = j_+1;
       img_fns{j,i_} = fullfile(params.dataset.db.cutout.dir, ImgList_densePE(i).topNname{j_});
    end
%     figure();
%     montage(img_fns(:,i));
end
figure();
% title('Ranking by Pose Estimation');
hold on;
montage(img_fns,'Size',[n_q n_top+1]);
 saveas(gcf,fullfile(params.evaluation.dir,foldername,'pose_estimation.jpg'))

%% montage final reranking
ImgList_densePV;
n_q = min(numel(ImgList_densePV),10);

n_top = 5;
img_fns = cell(n_top+1,n_q);
for i_ = 1:n_q
    i = id_q(i_);
    img_fns{1,i_} = fullfile(params.dataset.query.mainDir, ImgList_densePV(i).queryname);
    for j_ = 1:n_top
       j = j_+1;
       img_fns{j,i_} = fullfile(params.dataset.db.cutout.dir, ImgList_densePV(i).topNname{j_});
    end
%     figure();
%     montage(img_fns(:,i));
end
figure();
% title('Final Reranking');
hold on;
montage(img_fns,'Size',[n_q n_top+1]);
saveas(gcf,fullfile(params.evaluation.dir,foldername,'final_reranking.jpg'))

%% montage synth 
ImgList_densePV;
n_q = min(numel(ImgList_densePV),10);
% id_q = randperm(numel(ImgList_densePV),n_q);
n_top = 5;
img_fns = cell(n_top+1,n_q);
for i_ = 1:n_q
    i = id_q(i_);
    img_fns{1,i_} = imread(fullfile(params.dataset.query.mainDir, ImgList_densePV(i).queryname));
    for j_ = 1:n_top
       j = j_+1;
       img_fns{j,i_} =  getSynthView(params,ImgList_densePV,i,j_,false);
    end
%     figure();
%     montage(img_fns(:,i));
end
figure();
% title('Synthetic Views');
hold on;
montage(img_fns,'Size',[n_q n_top+1]);
saveas(gcf,fullfile(params.evaluation.dir,foldername,'synthetic_preranking.jpg'))