function [queryImage] = load_query_image_compatible_with_cutouts(queryImagePath, cutoutSize)
    % NOTE: use this only when necessary. for instance, you don't need to use it in parfor_densePV
    queryImage = imread(queryImagePath);
    desiredWidth = cutoutSize(1);
    desiredHeight = cutoutSize(2);
    queryImage = at_imageresize(queryImage, desiredWidth, desiredHeight, 'pad');
end
