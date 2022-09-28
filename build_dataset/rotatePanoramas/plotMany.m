function [] = plotMany(images)

nImages = size(images,2);
squareSize = ceil(sqrt(nImages));
figure;
for i = 1:nImages
    subplot(squareSize, squareSize, i);
    imshow(images(i).img);
    title(sprintf('%d', i));
end