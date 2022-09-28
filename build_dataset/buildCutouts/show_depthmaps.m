files = dir('/home/ciirc/dubenma1/repos/habitat_ros_semantic_2/spring_simulation/data/datasets/cutout_dataset/semantic_l/depth/cutout_pano_*.mat');

for i = 1:size(files,1)
    load(fullfile(files(i).folder, files(i).name))
    plot3(cam_pos(1),cam_pos(2),cam_pos(3),'yx','MarkerSize',30,'LineWidth',10);
%     pcshow(xyz_mat');
    hold on;
    
    X = xys(1:3,1:10:end) - cam_pos';
%     u = R X + t
%     R' u = X - C
    hold on; pcshow(xyz_mat');
end