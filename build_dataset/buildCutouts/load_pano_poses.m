function [ pano_images, pano_poses, pano_C, pano_q ] = load_pano_poses( pano_file )
%LOAD_PANO_POSES Summary of this function goes here
    pano_table = readtable(pano_file, 'HeaderLines',1);
    pano_images = table2cell(pano_table(:,2));
    pano_poses = table2array(pano_table(:,end-6:end));
    pano_C = pano_poses(:,1:3)';
    pano_q = pano_poses(:,4:end)';
   end

