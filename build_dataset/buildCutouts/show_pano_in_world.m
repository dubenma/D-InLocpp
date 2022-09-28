function show_pano_in_world( pano_C, pano_q, pano_poses, pano_images )
%SHOW_PANO_IN_WORLD - show panoramatic images coordinates in the world
    plot3(pano_C(1,:),pano_C(2,:),pano_C(3,:),'m.','MarkerSize',15);
    rgb = 'rgb';
    for i = 1:size(pano_poses,1)
       pano_xyz = q2r(pano_q(:,i)) * 1.5 * eye(3) + pano_C(:,i);
       for j = 1:3
            plot3([pano_C(1,i) pano_xyz(1,j)],[pano_C(2,i) pano_xyz(2,j)],[pano_C(3,i) pano_xyz(3,j)],[rgb(j) '-'],'LineWidth',3);
       end
       text(pano_C(1,i),pano_C(2,i),pano_C(3,i)+0.5,pano_images{i},'Color',[1 0 0],'FontWeight','bold');
    end
end

