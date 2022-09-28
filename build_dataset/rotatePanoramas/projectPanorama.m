function panoramaProjections = projectPanorama(panoImg, viewSize, fov, nViews)
%PROJECTPANORAMA projecects the panorama under different views.
% The panoramas are by rotating along the Y axis in consistent number of
% steps
% panoImg: panorama image as MxNx3 array
% viewSize: scalar value. determines size of each panorama view
% fov:  horizontal field of view field of view of perspective views
% nViews: how dense to sample projections

panoImg = im2double(panoImg);

nAngles = nViews/2;
xh = -pi:(pi/nAngles):((nAngles-1)/nAngles*pi);
%shift = 1.02;
%xh = 0+shift:(pi/16):(15/16*pi+shift);
yh = zeros(1, length(xh));
x = [xh];
y = [yh]; % viewing direction of perspective views

[sepScene] = separatePano(panoImg, fov, x, y, viewSize);

%% visualization
%ID = randsample(length(sepScene), nViews);

% figure(1);
% uv = [x(ID)' y(ID)'];
% coords = uv2coords(uv, 1024, 512);
% imshow(imresize(panoImg, [512, 1024])); hold on
% for i = 1:nViews
%     scatter(coords(i,1),coords(i,2), 40, [1 0 0],'fill');
%     text(coords(i,1)+8, coords(i,2),sprintf('%d', i), ...
%         'BackgroundColor',[.7 .9 .7], ...
%         'Color', [1 0 0]); 
% end
% title('Project viewpoints to perspective views: Image');

for i = 1:nViews
    panoramaProjections(i).img = sepScene(i).img;
    panoramaProjections(i).vx = sepScene(i).vx;
end