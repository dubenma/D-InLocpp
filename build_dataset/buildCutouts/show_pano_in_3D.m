function show_pano_in_3D( pano_img, R, C )
%SHOW_PANO_IN_3D - show panorama points on a sfere in 3D
    [cBeta,cAlpha] = meshgrid(  linspace(pi/2,-pi/2,size(pano_img,1)),...
                                linspace(-pi,pi,size(pano_img,2)));
    beta = cBeta(:); alpha = cAlpha(:);                        
    pts = R' * [sin(alpha).*cos(beta) cos(alpha).*cos(beta) sin(beta)]' + C;
    R = pano_img(:,:,1)';
    G = pano_img(:,:,2)';
    B = pano_img(:,:,3)';
    rgb = [R(:), G(:), B(:)];
    figure; axis equal;
    pcshow(pts(:,1:100:end)', rgb(1:100:end,:));
end

