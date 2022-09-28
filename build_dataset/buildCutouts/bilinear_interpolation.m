function [ img ] = bilinear_interpolation( img_size, uv, pano_img )
%BILINEAR_INTERPOLATION - bilinear interpolation from original image
    
    % define output image 
    img = uint8(zeros(img_size(2),img_size(1),3));
    [X,Y] = meshgrid(1:img_size(1), 1:img_size(2));
    X = X(:); Y = Y(:);

    % floor / ceil the coodinates
    uv11 = repfun([floor(uv(1,:)); floor(uv(2,:))], pano_img);  
    uv22 = repfun([ceil(uv(1,:)); ceil(uv(2,:))], pano_img);
    
    % compute biliner estimate for each pixel
    for i = 1:length(uv)
        Argb = [pano_img(uv11(1,i),uv11(2,i),:), pano_img(uv11(1,i),uv22(2,i),:);...
                pano_img(uv22(1,i),uv11(2,i),:), pano_img(uv22(1,i),uv22(2,i),:)];
        if uv22(2,i) == uv(2,i)
            lx1 = Argb(1,1,:);
            lx2 = Argb(2,1,:);
        else
            lx1 = (uv22(2,i) - uv(2,i)) / (uv22(2,i) - uv11(2,i)) * Argb(1,1,:) + ...
                  (uv(2,i) - uv11(2,i)) / (uv22(2,i) - uv11(2,i)) * Argb(1,2,:);
            lx2 = (uv22(2,i) - uv(2,i)) / (uv22(2,i) - uv11(2,i)) * Argb(2,1,:) + ...
                  (uv(2,i) - uv11(2,i)) / (uv22(2,i) - uv11(2,i)) * Argb(2,2,:);
        end
        if uv22(1,i) == uv(1,i)
            img(Y(i), X(i), :) = lx1;
        else
            img(Y(i), X(i), :) = (uv22(1,i) - uv(1,i)) / (uv22(1,i) - uv11(1,i)) * lx1 + ...
                                 (uv(1,i) - uv11(1,i)) / (uv22(1,i) - uv11(1,i)) * lx2;
        end
    end
end

