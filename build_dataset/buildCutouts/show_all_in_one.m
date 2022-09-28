function show_all_in_one(pts,pano_C,pano_q,pano_poses,pano_images,pano_id,pano_img,K,R,img_size)
    
    R2 = q2r(pano_q(:,pano_id));
    C2 = pano_C(:,pano_id); 

    % show the pointcloud
    step = 10;
	pano_pts_visual = pts(1:3,1:step:end)';
    pano_pts_visual_col = (1/255) * pts(4:6,1:step:end)';
    filter = pano_pts_visual(:,1) > -10 & pano_pts_visual(:,1) < 10 & ...
             pano_pts_visual(:,2) > -10 & pano_pts_visual(:,2) < 10 & ...
             pano_pts_visual(:,3) < 2.5;
    pano_pts_visual = pano_pts_visual(filter,:);
    pano_pts_visual_col = pano_pts_visual_col(filter,:);
    figure(); pcshow(pano_pts_visual, pano_pts_visual_col); hold on; 
    subfig(3,3,1,gcf); hold on;
    
    % show the coordinate system of panorama
    show_pano_in_world( pano_C(:,pano_id), pano_q(:,pano_id), pano_poses(pano_id,:), pano_images(pano_id) );


    % show the sfere
    [cBeta,cAlpha] = meshgrid(  linspace(-pi/2,pi/2,size(pano_img,1)),...
                                linspace(pi,-pi,size(pano_img,2)));
    beta = cBeta(:); alpha = cAlpha(:);                        
    pts2 = R2 * [cos(alpha).*cos(beta) sin(alpha).*cos(beta) -sin(beta)]' + C2;
    Rcol = pano_img(:,:,1)';
    Gcol = pano_img(:,:,2)';
    Bcol = pano_img(:,:,3)';
    rgb2 = [Rcol(:), Gcol(:), Bcol(:)];
    hold on;
    pcshow(pts2(:,1:100:end)', rgb2(1:100:end,:));
    
    % show the image boundary
    hold on;
    show_boundary_of_render_on_sfere(R2 * R' * inv(K), C2, img_size);
    
    % show the world coodinate system in C
    rgb = 'rgb';
    end_pts = 2 * R2 * eye(3) + C2;
    for j = 1:3
        hold on;
        plot3([C2(1) end_pts(1,j)],[C2(2) end_pts(2,j)],[C2(3) end_pts(3,j)],[rgb(j) ':'],'LineWidth',3);
    end
    
    % select pointcloud
    [ fpts, frgb ] = filterFieldView( struct('R', R * R2', 'C', C2), pts(1:3,:), pts(4:6,:));
    hold on;
    pcshow(fpts', (1/255) * frgb');

end

