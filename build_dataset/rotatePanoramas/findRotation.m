function [xMid, panoramaProjection, idx, diffs] = findRotation(projectedPointCloud, ...
    panoramaProjections, panoImg, goodness)
% goodness: which sorted loss to prefer. Default should be 1, which means
% the panorama projection with lowest loss is chosen

pointCloudPerspective = rgb2gray(projectedPointCloud);

nCandidates = size(panoramaProjections, 2);
losses = zeros([nCandidates,1]);
se = offsetstrel('ball', 3, 3);
edge1 = uint8(255 * edge(pointCloudPerspective));
dilated1 = imdilate(edge1, se);

for i=1:nCandidates
    panoramaPerspective = rgb2gray(panoramaProjections(i).img); 
    edge2 = uint8(255 * edge(panoramaPerspective));
    dilated2 = imdilate(edge2, se);
    diffs(i).img = bitxor(dilated1, dilated2);
end

for i=1:nCandidates
    losses(i,1) = sum(diffs(i).img(:)==255);
end

[sorted, indices] = sort(losses);

idx = indices(goodness);
panoramaProjection = panoramaProjections(idx).img;

xMid = ((panoramaProjections(idx).vx + pi) / (2*pi)) * size(panoImg, 2);
xMid = round(xMid);