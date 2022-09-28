function image = at_imageresize(image, desiredWidth, desiredHeight, mode)

w = size(image, 2);
h = size(image, 1);
desiredAspectRatio = desiredWidth/desiredHeight;

% NOTE: this mode padds the image by adding rows, in order to maintain hFoV.
if strcmp(mode, 'pad')
  padding = (w/desiredAspectRatio-h)/2;
  paddingRows = zeros(padding, w, 3);
  image = [paddingRows; image; paddingRows];
end

if strcmp(mode, 'crop')
  error('Crop mode not implemented.\n');
end

scale = desiredWidth / w;
image = imresize(image, scale);

end