function depth_img = depth_maps(uvs, img_size, fpts, C)
    f = uvs(1,:) > 0 & uvs(2,:) > 0 & uvs(1,:) <= img_size(1) & uvs(2,:) <= img_size(2); 
    uvs = uvs(:,f);
    fpts = fpts(:,f);
    depth_img = zeros(img_size(2),img_size(1));
    for i = 1:length(uvs)
        depth_img(uvs(2,i),uvs(1,i)) = norm(fpts(:,i)-C);
    end
end