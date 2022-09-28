function im_synth = getFailureView(params,ImgList,q_id,db_rank,showMontage,savePth,prefix)
qname =  ImgList(q_id).queryname;
cutoutName = ImgList(q_id).topNname;  cutoutName= cutoutName{db_rank};
Iq = imread(fullfile(params.dataset.query.mainDir, qname));

im_synth = [];
%dense features

this_densegv_matname = fullfile(params.output.gv_dense.dir, qname, buildCutoutName(cutoutName, params.output.gv_dense.matformat));
gvresults = load(this_densegv_matname);

if ~isempty(gvresults.match12)
    tent_xq2d = gvresults.f1(:, gvresults.match12(1, :));
    tent_xdb2d = gvresults.f2(:, gvresults.match12(2, :)); %matches

    inls_xq2d = gvresults.f1(:, gvresults.inls12(1, :));
    inls_xdb2d = gvresults.f2(:, gvresults.inls12(2, :)); %matches

    %Feature upsampling
    Idbsize = size(imread(fullfile(params.dataset.db.cutout.dir, cutoutName)));
    Iqsize = Idbsize; % we padded the queries to match cutout aspect ratio (and rescaled to cutout dimensions
    tent_xq2d = at_featureupsample(tent_xq2d,gvresults.cnnfeat1size,Iqsize);
    % without this, the features in query image would not match the cutout aspect ratio
    tent_xdb2d = at_featureupsample(tent_xdb2d,gvresults.cnnfeat2size,Idbsize);
    inls_xq2d = at_featureupsample(inls_xq2d,gvresults.cnnfeat1size,Iqsize);
    % without this, the features in query image would not match the cutout aspect ratio
    inls_xdb2d = at_featureupsample(inls_xdb2d,gvresults.cnnfeat2size,Idbsize);


    queryWidth = params.camera.sensor.size(2);
    queryHeight = params.camera.sensor.size(1);
    cutoutWidth = Idbsize(2);
    cutoutHeight = Idbsize(1);

    inls_xq2d = adjust_inliers_to_match_original_query(inls_xq2d, queryWidth, queryHeight, cutoutWidth, cutoutHeight);
    tent_xq2d = adjust_inliers_to_match_original_query(tent_xq2d, queryWidth, queryHeight, cutoutWidth, cutoutHeight);
%     together_q = repmat(together, [1, 1, 3]);
%     for feat_i = 1: size(tent_xq2d,2)
%         color = [0 0 255];
%         block = zeros(3,3,3);
%         block(:,:,1:)
%         together_q(tent_xq2d(1,feat_i)-1:tent_xq2d(1,feat_i)+1,tent_xq2d(2,feat_i)-1:tent_xq2d(2,feat_i)+1,:) = ;
%     end
end

figure('visible','off');
im_q = imread(fullfile(params.dataset.query.mainDir, qname));
im_db = imread(fullfile(params.dataset.db.cutout.dir, cutoutName));
imshow(rgb2gray([im_q im_db]));hold on;

if ~isempty(gvresults.match12)
    for c = 1:20:size(tent_xq2d,2)
        plot3d([tent_xq2d(:,c), tent_xdb2d(:,c) + [size(im_q,2) 0 ]'],'r-');
    end
    for c = 1:20:size(inls_xq2d,2)
        plot3d([inls_xq2d(:,c), inls_xdb2d(:,c) + [size(im_q,2) 0 ]'],'-g');
    end
    plot3d(tent_xq2d,'b.');
    plot3d(inls_xq2d,'g.');
    plot3d(tent_xdb2d + [size(im_q,2) 0 ]','b.');
    plot3d(inls_xdb2d + [size(im_q,2) 0 ]','g.');
end
if showMontage
    %                 errmaps =load(fullfile(params.output.synth.dir, ImgList(q_id).queryname, sprintf('%d%s', db_rank, params.output.synth.matformat)),'errmaps');
    %                 errmaps= grs2rgb(errmaps.errmaps{1});
    if nargin >= 6
        if nargin >=7
            mkdirIfNonExistent(savePth);
            saveas(gcf,fullfile(savePth,sprintf('%s_results_q_id_%d_best_db_%d.jpg',prefix,q_id,db_rank)));
        else
            saveas(gcf,fullfile(savePth,sprintf('results_q_id_%d_best_db_%d.jpg',q_id,db_rank)));
            %                     close(f);
        end
    end    
end
end