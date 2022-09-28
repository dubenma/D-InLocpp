function show_selected_pointcloud( fpts, frgb, pano_q, pano_C, pano_id  )
%SHOW_SELECTED_POINTCLOUD Summary of this function goes here
    figure(); pcshow(fpts', (1/255) * frgb'); hold on;
    pano_xyz = q2r(pano_q(:,pano_id)) + pano_C(:,pano_id);
    rgb = 'rgb';
    for j = 1:3
        plot3([pano_C(1,pano_id) pano_xyz(1,j)],[pano_C(2,pano_id) pano_xyz(2,j)],[pano_C(3,pano_id) pano_xyz(3,j)],[rgb(j) '-'],'LineWidth',3);
    end
end

