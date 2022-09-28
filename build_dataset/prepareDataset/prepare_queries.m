
spaces = dir(fullfile(params.dataset.query.mainDir));
spaces = spaces(3:end);

for i = 2 % 1 : length(spaces)
    space_name = spaces(i).name;
    query_dir = fullfile(params.dataset.query.mainDir, space_name, 'query_all');
    if not(isfolder(query_dir))
        mkdir(query_dir)
    end
    
    metadata_dir = fullfile(query_dir, 'metadata');
    if not(isfolder(metadata_dir))
        mkdir(metadata_dir)
    end
    
    if strcmp(params.dynamicMode, 'original')
        cutouts_dir = fullfile(params.dataset.query.mainDir, space_name, 'cutouts');
    else
        cutouts_dir = fullfile(params.dataset.query.mainDir, space_name, 'cutouts_dynamic');
    end
    pano_ids = dir(cutouts_dir);
    pano_ids = pano_ids(3:end);
    
    % q2name = ["cutout_pano_14_-120_0.jpg", "cutout_pano_30_-90_330.jpg"];
    q_names = {};
    query_count = 0;
    
    for j = 1 : length(pano_ids)
        cutouts = dir(fullfile(cutouts_dir, pano_ids(j).name, "cutout_pano_*_-90_*.jpg"));
%         cutouts = dir(fullfile(cutouts_dir, pano_ids(j).name));
        for k = 1 : length(cutouts)
            cutout_name = cutouts(k).name;
            if length(cutout_name) > 2
                query_count = query_count + 1;
                copyfile(fullfile(cutouts(k).folder, cutout_name), fullfile(query_dir, string(query_count) + ".jpg"));
                q_names{end+1} = cutout_name;  
            end
        end
    end
    
    metadata_str = "q2name = [";
    for q = 1 : length(q_names)
        metadata_str = metadata_str +  sprintf('"%s"', q_names{q});
        if q < length(q_names)
            metadata_str = metadata_str + ", ";
        end
        
    end
    metadata_str = metadata_str + "];";
    
    fileID = fopen(fullfile(metadata_dir, 'query_mapping.m'),'w');
    fprintf(fileID, metadata_str);
    fclose(fileID);
    
end