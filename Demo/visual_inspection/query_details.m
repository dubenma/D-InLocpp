id_q =[158   137   275   284    67   174   360   229   250   265];
% id_q = 40;
skip_synth = true;
for q_id= id_q
    close all
    output_folder = fullfile(params.evaluation.dir,num2str(q_id));
    if exist(fullfile(output_folder), 'dir') ~= 7
        mkdir(fullfile(output_folder));
    end
    % image_retrieval
    n_q = min(numel(ImgList_original),5);
    n_top = 5;
    query.ir = cell(1,n_q);
    i = q_id;
    query.ir{1} = imread(fullfile(params.dataset.query.mainDir, ImgList_original(i).queryname));
    for j_ = 1:n_top
        j = j_+1;
        query.ir{j} = imread(fullfile(params.dataset.db.cutout.dir, ImgList_original(i).topNname{j_}));
    end
    figure();
    montage( query.ir,'Size',[1 n_top+1]);
    saveas(gcf,fullfile(output_folder,'image_retrieval.png'));
    
    
    
    %dense features
    n_q = min(numel(ImgList_original),5);
    n_top = 5;
    query.gv = cell(1,6);
    i = q_id;
    for p = 1:n_top
        qname =  ImgList_original(i).queryname;
        cutoutName = ImgList_original(i).topNname{p};
        this_densegv_matname = fullfile(params.output.gv_dense.dir, qname, buildCutoutName(cutoutName, params.output.gv_dense.matformat));
        gvresults = load(this_densegv_matname);
        
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
        im_q = imread(fullfile(params.dataset.query.mainDir, qname));
        im_db = imread(fullfile(params.dataset.db.cutout.dir, cutoutName));
        together = rgb2gray([im_q im_db]);
        %     together_q = repmat(together, [1, 1, 3]);
        %     for feat_i = 1: size(tent_xq2d,2)
        %         color = [0 0 255];
        %         block = zeros(3,3,3);
        %         block(:,:,1:)
        %         together_q(tent_xq2d(1,feat_i)-1:tent_xq2d(1,feat_i)+1,tent_xq2d(2,feat_i)-1:tent_xq2d(2,feat_i)+1,:) = ;
        %     end
        figure();
        imshow(rgb2gray([im_q im_db]));hold on;
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
        
        %
        
        saveas(gcf,fullfile(output_folder,sprintf('dense_matches_GV_q_to_%s.png',num2str(p))));
        
    end
    %
    % geometrical_verification
    n_q = min(numel(ImgList_denseGV),5);
    n_top = 5;
    query.gv = cell(1,n_q);
    i = q_id;
    query.gv{1} = imread(fullfile(params.dataset.query.mainDir, ImgList_denseGV(i).queryname));
    for j_ = 1:n_top
        j = j_+1;
        query.gv{j} = imread(fullfile(params.dataset.db.cutout.dir, ImgList_denseGV(i).topNname{j_}));
    end
    figure();
    montage( query.gv,'Size',[1 n_top+1]);
    saveas(gcf,fullfile(output_folder,'geometrical_verification.png'));
    
    
    
    
    %reprojections
    n_q = min(numel(ImgList_denseGV),5);
    n_top = 5;
    i = q_id;
    for p = 1:n_top
        qname =  ImgList_denseGV(i).queryname;
        cutoutName = ImgList_denseGV(i).topNname{p};
        this_densegv_matname = fullfile(params.output.gv_dense.dir, qname, buildCutoutName(cutoutName, params.output.gv_dense.matformat));
        gvresults = load(this_densegv_matname);
        %depth information
        this_db_matname = fullfile(params.dataset.db.cutout.MatDir, [cutoutName, params.dataset.db.cutout.matformat]);
        load(this_db_matname, 'XYZcut');
        
        this_densepe_matname = fullfile(params.output.pnp_dense_inlier.dir, qname, sprintf('%d%s', p, params.output.pnp_dense.matformat));
        this_densepe = load(this_densepe_matname);
        inls_pe = this_densepe.allInls{1};
        
        inls_xq2d = gvresults.f1(:, gvresults.inls12(1, :));
        inls_xdb2d = gvresults.f2(:, gvresults.inls12(2, :)); %matches
        
        %Feature upsampling
        Idbsize = size(imread(fullfile(params.dataset.db.cutout.dir, cutoutName)));
        Iqsize = Idbsize; % we padded the queries to match cutout aspect ratio (and rescaled to cutout dimensions
        inls_xq2d = at_featureupsample(inls_xq2d,gvresults.cnnfeat1size,Iqsize);
        % without this, the features in query image would not match the cutout aspect ratio
        inls_xdb2d = at_featureupsample(inls_xdb2d,gvresults.cnnfeat2size,Idbsize);
        K = params.camera.K;
        %     tent_ray2d = K^-1 * [inls_xq2d; ones(1, size(inls_xq2d, 2))];
        %DB 3d points
        indx = sub2ind(size(XYZcut(:,:,1)),inls_xdb2d(2,:),inls_xdb2d(1,:));
        X = XYZcut(:,:,1);Y = XYZcut(:,:,2);Z = XYZcut(:,:,3);
        inls_xdb3d = [X(indx); Y(indx); Z(indx)];
        inls_xdb3d = inls_xdb3d(:,inls_pe);
        im_q = imread(fullfile(params.dataset.query.mainDir, qname));
        im_db = imread(fullfile(params.dataset.db.cutout.dir, cutoutName));
        
        %     P_est.C =this_densepe.Ps{1}(:,4);
        %     P_est.K = params.camera.K;
        % %     rFix = [0., 180., 180.];
        % rFix = [0., 0., 0.];
        % % rFix = [0., -60.0, -30.]; % ACCOUNT FOR THE CUTOUT ROTATION WITHIN PANORAMA
        %     Rfix = rotationMatrix(deg2rad(rFix), 'XYZ');
        % % rot = -inv(P_db.R)*Rfix;
        %     P_est.R = this_densepe.Ps{1}(:,1:3);
        %     P_est.R =Rfix*P_est.R';
        %     P_est.type = 'KRC';
        %  P_db.K = eye(3);
        
        [P_est.K,P_est.R,P_est.C] = P2KRC(this_densepe.Ps{1});
        P_est.K = params.camera.K;
        P_est.type = 'KRC';
        reproj_xdb3d =  X2u(inls_xdb3d,P_est);
        
        im_q = imread(fullfile(params.dataset.query.mainDir, qname));
        figure();
        imshow(rgb2gray(im_q));
        hold on;
        plot3d(inls_xq2d,'.r');
        inls_pe_q = inls_xq2d(:,inls_pe);
        for r = 1:size(reproj_xdb3d,2)
            v = reproj_xdb3d(:,r)-inls_pe_q(:,r);
            scale = 5;
            plot3d([inls_pe_q(:,r), inls_pe_q(:,r)+v*scale],'m-');
        end
        
        plot3d(inls_xq2d(:,inls_pe),'.y');
        plot3d(reproj_xdb3d,'.c');
        saveas(gcf,fullfile(output_folder,sprintf('reprojections_PE_%s.png',num2str(p))));
        
    end
    
    
    
    % pose_estimation_reranking
    n_q = min(numel(ImgList_densePE),5);
    n_top = 5;
    query.pe = cell(1,n_q);
    i = q_id;
    query.pe{1} = imread(fullfile(params.dataset.query.mainDir, ImgList_densePE(i).queryname));
    for j_ = 1:n_top
        j = j_+1;
        query.pe{j} = imread(fullfile(params.dataset.db.cutout.dir, ImgList_densePE(i).topNname{j_}));
    end
    figure();
    montage( query.pe,'Size',[1 n_top+1]);
    saveas(gcf,fullfile(output_folder,'pose_estimation.png'));
    
    
    % pose_estimation_reranking
    n_q = min(numel(ImgList_densePV),5);
    n_top = 5;
    query.pv = cell(1,n_q);
    i = q_id;
    query.pv{1} = imread(fullfile(params.dataset.query.mainDir, ImgList_densePV(i).queryname));
    for j_ = 1:n_top
        j = j_+1;
        query.pv{j} = imread(fullfile(params.dataset.db.cutout.dir, ImgList_densePV(i).topNname{j_}));
    end
    figure();
    montage( query.pv,'Size',[1 n_top+1]);
    saveas(gcf,fullfile(output_folder,'pose_verification.png'));
    
    
    if ~skip_synth
    % synthetic view
    n_q = min(numel(ImgList_densePV),5);
    n_top = 5;
    query.syn = cell(1,n_q);
    i = q_id;
    query.syn{1} = imread(fullfile(params.dataset.query.mainDir, ImgList_densePE(i).queryname));
    for j_ = 1:n_top
        j = j_+1;
        query.syn{j} = getSynthView(params,ImgList_densePE,i,j_,false);
    end
    figure();
    montage( query.syn,'Size',[1 n_top+1]);
    saveas(gcf,fullfile(output_folder,'synthetic_views.png'));
    
    
    
    % synthetic view_ final ordering
    n_q = min(numel(ImgList_densePV),5);
    n_top = 5;
    query.syn_fin = cell(1,n_q);
    i = q_id;
    query.syn_fin{1} = imread(fullfile(params.dataset.query.mainDir, ImgList_densePV(i).queryname));
    for j_ = 1:n_top
        j = j_+1;
        query.syn_fin{j} = getSynthView(params,ImgList_densePV,i,j_,false);
    end
    figure();
    montage( query.syn_fin,'Size',[1 n_top+1]);
    saveas(gcf,fullfile(output_folder,'synthetic_views_final.png'));
    
    
    % synthetic view_ final ordering _ with blend
    n_q = min(numel(ImgList_densePV),5);
    n_top = 5;
    query.syn_blend = cell(1,n_q);
    i = q_id;
    query.syn_blend{1} = imread(fullfile(params.dataset.query.mainDir, ImgList_densePV(i).queryname));
    for j_ = 1:n_top
        j = j_+1;
        query.syn_blend{j} = (getSynthView(params,ImgList_densePV,i,j_,false)/2 + query.syn_blend{1}/2);
    end
    figure();
    montage( query.syn_blend,'Size',[1 n_top+1]);
    saveas(gcf,fullfile(output_folder,'synthetic_views_blended.png'));
    end
    
    query.toMontage = cell(4,n_top+1);
    query.toMontage(1,:) = query.ir;
    query.toMontage(2,:) = query.gv;
    query.toMontage(3,:) = query.pe;
    query.toMontage(4,:) = query.pv;
    
    figure();
    montage( query.toMontage','Size',[4 n_top+1]);
    saveas(gcf,fullfile(output_folder,'reranking_together.png'));
    
    if ~skip_synth
    query.toMontageWithSyn = cell(7,n_top+1);
    query.toMontageWithSyn(1,:) = query.ir;
    query.toMontageWithSyn(2,:) = query.gv;
    query.toMontageWithSyn(3,:) = query.pe;
    query.toMontageWithSyn(4,:) = query.syn;
    query.toMontageWithSyn(5,:) = query.pv;
    query.toMontageWithSyn(6,:) = query.syn_fin;
    query.toMontageWithSyn(7,:) = query.syn_blend;
    
    figure();
    montage( query.toMontageWithSyn','Size',[7 n_top+1]);
    saveas(gcf,fullfile(output_folder,'reranking_together_with_synth.png'));
    end
end