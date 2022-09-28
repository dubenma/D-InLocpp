function show_pointcloud( pts )
%SHOW_POINTCLOUD - show poincloud for debuging
    pano_pts_visual = pts(1:3,1:30:end)';
    pano_pts_visual_col = (1/255) * pts(4:6,1:30:end)';
    filter_z = pano_pts_visual(:,3) < 4;
    pano_pts_visual = pano_pts_visual(filter_z,:);
    pano_pts_visual_col = pano_pts_visual_col(filter_z,:);
    pcshow(pano_pts_visual, pano_pts_visual_col); hold on;
end

