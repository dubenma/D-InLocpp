function [ uv ] = repfun( uv, pano_img )
%REPFUN - we assume continous function on a sfere, i.e., force the values 
%to be in range certain range 
    f1 = uv(1,:) > size(pano_img,1);
    f2 = uv(2,:) > size(pano_img,2);
    uv(1,f1) = uv(1,f1) - size(pano_img,1);
    uv(2,f2) = uv(2,f2) - size(pano_img,2);
    f1 = uv(1,:) < 1;
    f2 = uv(2,:) < 1;
    uv(1,f1) = uv(1,f1) + size(pano_img,1);
    uv(2,f2) = uv(2,f2) + size(pano_img,2);
end

