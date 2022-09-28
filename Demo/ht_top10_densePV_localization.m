%Note: It first synthesize query views according to top10 pose candedates
%and compute similarity between original query and synthesized views. Pose
%candidates are then re-scored by the similarity.

PV_topN = params.PV.topN; % assuming this is not larger than mCombinations
densePV_matname = fullfile(params.output.dir, 'densePV_top10_shortlist.mat');
if exist(densePV_matname, 'file') ~= 2

    sequentialPV = isfield(params, 'sequence') && strcmp(params.sequence.processing.mode, 'sequentialPV');
    if sequentialPV
        % build queryInd (i-th query in ImgList does not mean i-th query in the whole sequence)
        queryInd = zeros(length(ImgList_densePE),1);
        for i=1:length(ImgList_densePE)
            queryIdx = queryNameToQueryId(ImgList_densePE(i).queryname);
            queryInd(i) = queryIdx;
        end

        secondaryIdx = size(ImgList_densePE,2)+1;
        for i=1:size(ImgList_densePE,2)
            parentQueryId = queryNameToQueryId(ImgList_densePE(i).queryname);

            desiredSequenceLength = params.sequence.length;
            if parentQueryId-desiredSequenceLength+1 < 1
                actualSequenceLength = parentQueryId;
            else
                actualSequenceLength = desiredSequenceLength;
            end

            for queryId=parentQueryId-actualSequenceLength+1:parentQueryId-1
                idx = find(queryInd,queryId);
                if ~isempty(idx)
                    continue;
                end 
                queryInd(secondaryIdx) = queryId;
                secondaryIdx = secondaryIdx + 1;
            end
        end

        posesFromHoloLens = getPosesFromHoloLens(params.HoloLensOrientationDelay, params.HoloLensTranslationDelay, ...
                                                    queryInd, params);
        nQueries = length(queryInd);
        assert(size(posesFromHoloLens,1) == nQueries);
    end
    
    %synthesis list
    qlist = cell(1, PV_topN*length(ImgList_densePE));
    dblist = cell(1, PV_topN*length(ImgList_densePE));
    PsList = cell(1, PV_topN*length(ImgList_densePE));
    dbind = cell(1, PV_topN*length(ImgList_densePE));
    for ii = 1:1:length(ImgList_densePE)
        for jj = 1:1:PV_topN
            idx = PV_topN*(ii-1)+jj;
            qlist{idx} = ImgList_densePE(ii).queryname;
            dblist{idx} = ImgList_densePE(ii).topNname(:,jj);
            if sequentialPV

                desiredSequenceLength = params.sequence.length;
                parentQueryId = queryInd(ii);
                if parentQueryId-desiredSequenceLength+1 < 1
                    actualSequenceLength = parentQueryId;
                else
                    actualSequenceLength = desiredSequenceLength;
                end

                % convert Ps such that Ps{end} == ImgList_densePE(ii).Ps{jj}{1}
                P_P3P = ImgList_densePE(ii).Ps{jj}{1};

                if any(isnan(P_P3P(:))) % avoid NaN warnings
                    PsList{idx} = ImgList_densePE(ii).Ps{jj};
                    dbind{idx} = jj;
                    continue;
                end

                R_P3P = P_P3P(1:3,1:3)'; % epsilonBasesToModelBases
                T_P3P = -inv(P_P3P(1:3,1:3))*P_P3P(1:3,4); % wrt model

                P_HL = squeeze(posesFromHoloLens(queryInd == parentQueryId,:,:));

                if any(isnan(P_HL(:))) % avoid NaN warnings
                    PsList{idx} = ImgList_densePE(ii).Ps{jj};
                    dbind{idx} = jj;
                    continue;
                end

                R_HL = P_HL(1:3,1:3); % epsilonBasesTo HL CS Bases
                T_HL = P_HL(1:3,4); % wrt HL CS

                R_diff = R_P3P * R_HL';
                T_diff = T_P3P - T_HL;
                P_diff = [R_diff, R_diff*T_diff]; % HL format
                P_diff = [P_diff;0,0,0,1];

                Ps = cell(1,actualSequenceLength);
                for kk=1:actualSequenceLength
                    thisQueryId = parentQueryId - actualSequenceLength + kk;
                    tmp = P_diff * squeeze(posesFromHoloLens(queryInd == thisQueryId,:,:));
                    tmp(1:3,4) = inv(R_diff)*tmp(1:3,4);
                    tmp = tmp(1:3,1:4); % this is a HL format, we need to use the P3P aka InLoc format:
                    R_P3P = tmp(1:3,1:3)'; % modelBasesToEpsilonBases
                    T_P3P = R_P3P * -tmp(1:3,4);
                    Ps{kk} = [R_P3P,T_P3P];
                end
                assert(sum( ImgList_densePE(ii).Ps{jj}{1} - Ps{end}, 'all') < 1e-6);
                PsList{idx} = Ps;
            else
                PsList{idx} = ImgList_densePE(ii).Ps{jj};
            end
            dbind{idx} = jj;
        end
    end
    %find unique scans
    dbscanlist = cell(size(dblist));
    for ii = 1:1:length(dblist)
        for j=1:size(dblist{ii},1)
            dbpath = dblist{ii}{j};
            this_floorid = strsplit(dbpath, '/');this_floorid = this_floorid{1};
            info = parse_WUSTL_cutoutname(dbpath);
            dbscanlist{ii} = strcat(this_floorid, params.dataset.db.scan.matformat);
        end
    end
    [dbscanlist_uniq, sort_idx, uniq_idx] = unique(dbscanlist);
    qlist_uniq = cell(size(dbscanlist_uniq));
    dblist_uniq = cell(size(dbscanlist_uniq));
    PsList_uniq = cell(size(dbscanlist_uniq));
    dbind_uniq = cell(size(dbscanlist_uniq));
    for ii = 1:1:length(dbscanlist_uniq)
        idx = uniq_idx == ii;
        qlist_uniq{ii} = qlist(idx);
        dblist_uniq{ii} = dblist(idx);
        PsList_uniq{ii} = PsList(idx);
        dbind_uniq{ii} = dbind(idx);
    end
    
    %compute synthesized views and similarity

    % Because projectMesh in densePV requires up to 20 GB of RAM per one instance,
    % we need to limit the number of workers
    % TODO: optimize and leverage more workers
    poolobj = gcp('nocreate');
    delete(poolobj); % terminate any previous pool
    if strcmp(environment(), 'laptop')
        nWorkers = 1;
    else
        nWorkers = 8;
    end
    c = parcluster;
    c.NumWorkers = nWorkers;
    saveProfile(c);
    p = parpool('local', nWorkers);

    for ii = 1:1:length(dbscanlist_uniq)
        this_dbscan = dbscanlist_uniq{ii};
        this_qlist = qlist_uniq{ii};
        this_dblist = dblist_uniq{ii};
        this_PsList = PsList_uniq{ii};
        this_dbind = dbind_uniq{ii};
        
        %compute synthesized images and similarity scores
%         parfor jj = 1:1:length(this_qlist)
        parfor jj = 1:1:length(this_qlist)
            parfor_densePV( this_qlist{jj}, this_dblist{jj}, this_dbind{jj}, this_PsList{jj}, params );
            fprintf('densePV: %d / %d done. \n', jj, length(this_qlist));
        end
        fprintf('densePV: scan %s (%d / %d) done. \n', this_dbscan, ii, length(dbscanlist_uniq));
    end
    
    %load similarity score and reranking
    ImgList = struct('queryname', {}, 'topNname', {}, 'topNscore', {}, 'Ps', {}, 'dbnamesId', {});
    for ii = 1:1:length(ImgList_densePE)
        ImgList(ii).queryname = ImgList_densePE(ii).queryname;
        ImgList(ii).topNname = ImgList_densePE(ii).topNname(:,1:PV_topN);
        ImgList(ii).topNscore = zeros(1, PV_topN);
        ImgList(ii).Ps = ImgList_densePE(ii).Ps(1:PV_topN);
        for jj = 1:1:PV_topN
            dbnamesId = jj;
            ImgList(ii).dbnamesId(jj) = dbnamesId;
            load(fullfile(params.output.synth.dir, ImgList(ii).queryname, sprintf('%d%s', dbnamesId, params.output.synth.matformat)), 'scores');
            cumulativeScore = sum(cell2mat(scores)); % TODO: try something else than a sum?
            ImgList(ii).topNscore(jj) = cumulativeScore;
        end
        
        %reranking
        [sorted_score, idx] = sort(ImgList(ii).topNscore, 'descend');
        ImgList(ii).topNname = ImgList(ii).topNname(:,idx);
        ImgList(ii).topNscore = ImgList(ii).topNscore(idx);
        ImgList(ii).Ps = ImgList(ii).Ps(idx);
        ImgList(ii).dbnamesId = ImgList(ii).dbnamesId(idx);
    end
    
    if exist(params.output.dir, 'dir') ~= 7
        mkdir(params.output.dir);
    end
    save('-v6', densePV_matname, 'ImgList');
    
else
    load(densePV_matname, 'ImgList');
end
ImgList_densePV = ImgList;
