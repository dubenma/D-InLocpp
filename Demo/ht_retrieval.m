%Note: It loads localization score and output top100 database list for each query. 

%% Load query and database list
load(params.input.qlist.path);
load(params.input.dblist.path);

%% top100 retrieval
shortlist_topN = 100;
top100_matname = fullfile(params.output.dir, 'original_top100_shortlist.mat');
if exist(top100_matname, 'file') ~= 2
    ImgList = struct('queryname', {}, 'topNname', {}, 'topNscore', {}, 'primary', {});
        % primary means the user requested to evaluate InLoc on these poses
        % if a query in ImgList is not primary, it is there because it is part of a k-sequence
    
    %Load score
    load(params.input.scores.path, 'score');
    
    %shortlist format
    for i=1:size(query_imgnames_all,2)
        queryName = query_imgnames_all{i};
        ImgList(i).queryname = queryName;
        ii = find(strcmp({score.queryname}, queryName));
        [~, score_idx] = sort(score(ii).scores, 'descend');
        ImgList(i).topNname = cutout_imgnames_all(score_idx(1:shortlist_topN));
        ImgList(i).topNscore = score(ii).scores(score_idx(1:shortlist_topN));
        ImgList(i).primary = true;
    end

    % add secondary queries
    areQueriesFromHoloLensSequence = isfield(params, 'sequence') && isfield(params.sequence, 'length');
    if ~areQueriesFromHoloLensSequence || strcmp(params.sequence.processing.mode, 'sequentialPV')
        desiredSequenceLength = 1;
    else
        desiredSequenceLength = params.sequence.length;
    end

    secondaryQueryImgListIdx = size(ImgList,2)+1;
    for i=1:size(query_imgnames_all,2)
        parentQueryName = query_imgnames_all{i};
        parentQueryId = queryNameToQueryId(parentQueryName);

        if parentQueryId-desiredSequenceLength+1 < 1
            actualSequenceLength = parentQueryId;
        else
            actualSequenceLength = desiredSequenceLength;
        end

        for queryId=parentQueryId-actualSequenceLength+1:parentQueryId-1
            queryName = sprintf('%d.jpg', queryId);
            idx = find(strcmp(queryName,{ImgList.queryname}));
            if ~isempty(idx)
                continue;
            end

            ImgList(secondaryQueryImgListIdx).queryname = queryName;
            ii = find(strcmp({score.queryname}, queryName));
            [~, score_idx] = sort(score(ii).scores, 'descend');
            ImgList(secondaryQueryImgListIdx).topNname = cutout_imgnames_all(score_idx(1:shortlist_topN));
            ImgList(secondaryQueryImgListIdx).topNscore = score(ii).scores(score_idx(1:shortlist_topN)); 
            ImgList(secondaryQueryImgListIdx).primary = false;
            secondaryQueryImgListIdx = secondaryQueryImgListIdx + 1;
        end
    end
    
    if exist(params.output.dir, 'dir') ~= 7
        mkdir(params.output.dir);
    end
    save('-v6', top100_matname, 'ImgList');
else
    load(top100_matname, 'ImgList');
end
ImgList_original = ImgList;
