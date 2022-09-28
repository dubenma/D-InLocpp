function [inliers] = adjust_inliers_to_match_original_query(inliers, queryWidth, queryHeight, cutoutWidth, cutoutHeight)
    % resize so that width=query width and height=query height+padding
    cutoutAspectRatio = cutoutWidth/cutoutHeight;
    topAndBottomPaddingHeight = queryWidth/cutoutAspectRatio-queryHeight; % TODO: how does this work?
    targetWidth = queryWidth;
    targetHeight = queryHeight + topAndBottomPaddingHeight;
    inliers(1,:) = (inliers(1,:) / cutoutWidth) * targetWidth;
    inliers(2,:) = (inliers(2,:) / cutoutHeight) * targetHeight;
    % remove padding
    inliers(2,:) = inliers(2,:) - topAndBottomPaddingHeight/2;
end
