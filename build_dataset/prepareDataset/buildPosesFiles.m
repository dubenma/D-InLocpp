% input_path = "/home/ciirc/dubenma1/data/Inloc dataset/Maps/SPRING/Broca_dataset2/Broca Living Lab without Curtains/all/cutouts_matlab/poses.csv";
% output_path = "~/dubenma1/data/Inloc dataset/Maps/SPRING/Broca_dataset2";
% 
% input_path = "/local1/projects/artwin/datasets/B-315_dataset/matterport_data";
% output_path = "/local1/projects/artwin/datasets/B-315_dataset/matterport_data/localization_service/Maps/b315_dataset/queries/seq03/"

disp("Creating poses files")
cutouts_in_path = fullfile(input_path, "cutouts");
% poses_file_path = fullfile('/local1/projects/artwin/datasets/B-315_dataset/seq03/', "GT_poses.csv");
poses_file_path = fullfile(cutouts_in_path, "poses.csv");
poses_path = fullfile(output_path, "poses");

table = readtable(poses_file_path);

if not(isfolder(poses_path))
        mkdir(poses_path)
end
    
for i = 1 : size(table,1)
    cutout_name = string(table2cell(table(i,1)));
    
    tmp = split(cutout_name, "_");
    pano_id = str2double(tmp(3)); 
%     pano_id = 0; % for b315
    
    path = fullfile(poses_path, space_name, string(pano_id + 1));
    if not(isfolder(path))
        mkdir(path)
    end
    
    poses = table2array(table(i,2:end));
    position = poses(1:3);
    q = poses(4:end);
    R = q2r(q);
    
    
    save(fullfile(path, cutout_name + ".mat"),'position','R')
end

disp("Creating poses files done!")




