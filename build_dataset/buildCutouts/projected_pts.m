function img_pts = projected_pts( uvs, img_size, frgb )
%SHOW_PROJECTED_PTS 
    f = uvs(1,:) > 0 & uvs(2,:) > 0 & uvs(1,:) <= img_size(1) & uvs(2,:) <= img_size(2); 
    uvs = uvs(:,f);
    frgb = frgb(:,f);
    img_pts = uint8(zeros(img_size(2),img_size(1),3));
    for i = 1:length(uvs)
        img_pts(uvs(2,i),uvs(1,i),:) = frgb(:,i);
    end
end

