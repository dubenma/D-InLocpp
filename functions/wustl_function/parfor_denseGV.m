function parfor_denseGV( cnnq, qname, dbname, id, params )
%debug
debug = 0;

coarselayerlevel = 5;
finelayerlevel = 3;

this_densegv_matname = fullfile(params.output.gv_dense.dir, qname, buildCutoutName(dbname, params.output.gv_dense.matformat));

if exist(this_densegv_matname, 'file') ~= 2
    
    %load input feature
    dbfname = fullfile(params.input.feature.dir, params.dataset.db.cutout.dirname, [dbname, params.input.feature.db_matformat]);
    cnndb = load(dbfname, 'cnn');cnndb = cnndb.cnn;
    
    %coarse-to-fine matching
    cnnfeat1size = size(cnnq{finelayerlevel}.x);
    cnnfeat2size = size(cnndb{finelayerlevel}.x);
    [match12,f1,f2,cnnfeat1,cnnfeat2] = at_coarse2fine_matching(cnnq,cnndb,coarselayerlevel,finelayerlevel);
        
    if contains(params.dynamicMode, "dynamic")
        mask_name = fullfile(params.input.dir, "queries_masks", string(id) + ".png"); % TODO: pridat space_name
        mask = imresize(imread(mask_name), cnnfeat2size(1:2), 'nearest');
        if debug == 1
            im1 = imresize(imread(fullfile(params.dataset.query.mainDir, qname)), cnnfeat1size(1:2));
            im2 = imresize(imread(fullfile(params.dataset.db.cutout.dir, dbname)), cnnfeat2size(1:2));
            im3 = (mask == 0);
    %         f = figure();
    %         imshow([rgb2gray([im1 im2]) im3*255]);hold on;
    %         plot(f1(1,match12(1,:)),f1(2,match12(1,:)),'b.');
    %         plot(f2(1,match12(2,:)) + size(im1,2),f2(2,match12(2,:)),'b.');
            f = figure('visible','off');
    %         figure();
            tent_xq2d = f1(:, match12(1, :));
            tent_xdb2d = f2(:, match12(2, :));
            imshow([rgb2gray([im1]) im3*255]);hold on;
            plot3d(tent_xq2d,'b.');
        end

        match12_filtered = [];
        for i = 1 : size(match12, 2)
            
            c = f1(2,match12(1,i));
            r = f1(1,match12(1,i));
    %         plot(r,c,'r.')
        
            if mask(c,r) == 0
                match12_filtered = [match12_filtered, match12(:, i)];
            else
                if debug == 1
                    plot(r,c,'r*')
                    plot(r + 168,c,'r*')
                end
            end
           
        end
        
        match12 = match12_filtered;
        if debug == 1
            [~, q_id, ~] = fileparts(qname);
            [~, dbname, ~]=fileparts(dbname);
            path = fullfile(params.output.dir, 'matches', q_id);
            if exist(path, 'dir')~=7; mkdir(path); end
            set(f,'position',[0,0,1500,500])
            saveas(f,fullfile(path, ['mask_', dbname , '.png']));
        end
    end
    
     % original matching algorithm - n x homography
    if isempty(match12)
        inls12 = [];
    else
        [inls12] = at_denseransac(f1,f2,match12,2);
    end
    
%     % new matching algorithm - F10e
%     K = [0.8*cnnfeat1size(2) 0 cnnfeat1size(2)/2; 0 0.8*cnnfeat1size(2) cnnfeat1size(1)/2; 0 0 1];
%     corresp1 = f1(:,match12(1,:));
%     corresp2 = f2(:,match12(2,:));
%     [inls12, ~] = verify_matches( corresp1, corresp2, ([1;1] * [1:size(corresp1,2)]), 1, K, K );
%     inls12 = [match12(1,inls12(1,:)); match12(2,inls12(2,:))];
    
    
    % TODO: possible race condition?
    % this function is executed in parfor in ht_top100_densePE_localization and all the workers are working on the same query
    % if that happens, though, mkdir is noop but it shows an error.
    if exist(fullfile(params.output.gv_dense.dir, qname), 'dir') ~= 7
        mkdir(fullfile(params.output.gv_dense.dir, qname));
    end
    save('-v6', this_densegv_matname, 'cnnfeat1size', 'cnnfeat2size', 'f1', 'f2', 'inls12', 'match12');
    
    
    
    if debug == 1
        f = figure('visible','off');
%         f = figure()
        imshow(rgb2gray([im1 im2]));hold on;
        if ~isempty(match12)
            plot(f1(1,match12(1,:)),f1(2,match12(1,:)),'b.');
            plot(f1(1,inls12(1,:)),f1(2,inls12(1,:)),'g.');
            plot(f2(1,match12(2,:)) + size(im1,2),f2(2,match12(2,:)),'b.');
            plot(f2(1,inls12(2,:)) + size(im1,2),f2(2,inls12(2,:)),'g.');
            hold on;
            for i = 1:25:size(match12,2)
                plot([f1(1,match12(1,i)) f2(1,match12(2,i)) + size(im1,2)],[f1(2,match12(1,i)) f2(2,match12(2,i))],'r-');
            end
            for i = 1:size(inls12,2)
                h = plot([f1(1,inls12(1,i)) f2(1,inls12(2,i)) + size(im1,2)],[f1(2,inls12(1,i)) f2(2,inls12(2,i))],'-','Color',[0 0 1 0.5]);
        %         alpha(h,.5)
            end
        end

        [~, q_id, ~] = fileparts(qname);
        [~, dbname, ~]=fileparts(dbname);
        path = fullfile(params.output.dir, 'matches', q_id);
        if exist(path, 'dir')~=7; mkdir(path); end
        set(f,'position',[0,0,1500,500])
        saveas(f,fullfile(path, [dbname , '.png']));
    end
end
end

