% queries with true names + their masks

spaces = dir(fullfile(params.dataset.query.mainDir));
spaces = spaces(3:end);

output_dir = "/local1/projects/artwin/datasets/Broca_dataset/Broca_real_objects_queries/";

for i = 2 %1 : length(spaces)
    space_name = spaces(i).name;
    cutout_dir_out = fullfile(output_dir, 'cutouts');
    if not(isfolder(cutout_dir_out))
        mkdir(cutout_dir_out)
    end
    
    masks_dir_out = fullfile(output_dir, 'masks_gt');
    if not(isfolder(masks_dir_out))
        mkdir(masks_dir_out)
    end
    
    if strcmp(params.dynamicMode, 'original')
        cutouts_dir_in = fullfile(params.dataset.query.mainDir, space_name, 'cutouts');
    else
        cutouts_dir_in = fullfile(params.dataset.query.mainDir, space_name, 'cutouts_dynamic');
    end
    masks_dir_in = fullfile(params.dataset.query.mainDir, space_name, 'masks_dynamic');
    pano_ids = dir(cutouts_dir_in);
    pano_ids = pano_ids(3:end);
    
    % q2name = ["cutout_pano_14_-120_0.jpg", "cutout_pano_30_-90_330.jpg"];
    q_names = {};
    
    for j = 1 : length(pano_ids)
        cutouts_in = dir(fullfile(cutouts_dir_in, pano_ids(j).name, "cutout_pano_*_-90_*.jpg"));
        masks_in = dir(fullfile(masks_dir_in, pano_ids(j).name, "cutout_pano_*_-90_*.png"));
%         cutouts = dir(fullfile(cutouts_dir, pano_ids(j).name));
        for k = 1 : length(cutouts_in)
            cutout_name = cutouts_in(k).name;
            cutout_name = cutout_name(1:end-4);
            if length(cutout_name) > 2
                copyfile(fullfile(cutouts_in(k).folder, cutout_name + ".jpg"), fullfile(cutout_dir_out, cutout_name + ".jpg"));
                copyfile(fullfile(masks_in(k).folder, cutout_name + ".png"), fullfile(masks_dir_out, cutout_name + ".png"));  
            end
        end
    end
    
    
%     fileID = fopen(fullfile(metadata_dir, 'query_mapping.m'),'w');
%     fprintf(fileID, metadata_str);
%     fclose(fileID);
    
end