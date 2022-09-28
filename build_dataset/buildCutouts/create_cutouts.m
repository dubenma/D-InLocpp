% clear; close all; 
addpath(fullfile(pwd,'codes'));

%% settings
debug = 0;

dataset_dir = fullfile('C:\Users\zsd\CIIRC\data\matterport\Broca Living Lab without Curtains');
pts_file = fullfile(dataset_dir,'matterpak','cloud.xyz');
poses_file = fullfile(dataset_dir,'poses.csv');
pano_dir = fullfile(dataset_dir,'panos_rotated');
save_directory = fullfile(dataset_dir,'tmp');

% params of the generated image (one exapmpe)q
pano_id = 1;                    % example for image id
f = (1038.135254 + 1036.468140) / 2;                    % focal length
u0 = 664.387146;                    % principal point u0
v0 = 396.142090;                    % principal point v0
img_size = [1344 756];         % image size
K = [f 0 u0; 0 f v0; 0 0 1];    % the calibration matrix 
fi_x = 0;
Rx = [1  0           0; ...
    0   cos(fi_x)     -sin(fi_x); ...
    0   sin(fi_x)     cos(fi_x)];	% some 

Rz = eye(3);
fi_z = 0;
Rz = [cos(fi_z) -sin(fi_z) 0; ...
    sin(fi_z)   cos(fi_z)   0; ...
    0   0   1];
R = Rz*Rx;
% R = eye(3);
%% process
% load points in 3D & panorama poses
pts = load_pts( pts_file );
[ pano_images, pano_poses, pano_C, pano_q ] = load_pano_poses( poses_file );

% show pointcloud
% show panorama coordinate systems
if debug
    show_pointcloud( pts ); 
    subfig(3,3,1,gcf); hold on;
    show_pano_in_world( pano_C, pano_q, pano_poses, pano_images );
end 

% load panorama
pano_img = imread(fullfile(pano_dir,pano_images{pano_id}));
% figure; imshow(pano_img); subfig(3,3,2,gcf); title(sprintf('Panorama "%s"',pano_images{pano_id}));

% projection of sfere to plane  
% -> we assume projection matrix P = K R q2r(pano_q(:,pano_id))' [I pano_C(:,pano_id)];
R2 = q2r(pano_q(:,pano_id));

% pano_q = [1 0 0 0; 1 0 0 0]';
% R2 = eye(3);

C2 = pano_C(:,pano_id); 
iQ = R2 * R * inv(K); 
[X,Y] = meshgrid(0:img_size(1)-1, 0:img_size(2)-1);
X = X(:); Y = Y(:);
proj = iQ * [X, Y, ones(length(X),1)]';
proj = R2' * proj .* (ones(3,1) * 1./sqrt(sum(proj.^2)));     
beta_proj = -asin(proj(3,:));
cos_beta_proj = real(cos(beta_proj));
alpha_proj = atan2(proj(2,:)./cos_beta_proj, proj(1,:)./cos_beta_proj);
uv = real([	(beta_proj / (pi)) * size(pano_img,1) + size(pano_img,1)/2 + 1; ...
            (alpha_proj / (2*pi)) * size(pano_img,2) + size(pano_img,2)/2 + 1]); 

       
% show all in one 
if debug
    show_all_in_one(pts,pano_C,pano_q,pano_poses,pano_images,pano_id,pano_img,K,R,img_size);
end 

% bilinear interpolation from original image
img = flip(bilinear_interpolation( img_size, uv, pano_img ));
figure(); imshow(img); %set(gca, 'XDir','reverse'); 
subfig(3,3,4,gcf); title('Rendered image');
imwrite(img,sprintf('cutouts/cutout%d.jpg', pano_id));

% project the factory pointcloud by related projection matrix P
P = K * R * R2' * [eye(3) -C2];
[ fpts, frgb ] = filterFieldView( ...
    struct('R', R * R2', 'C', C2), ...
    pts(1:3,:), pts(4:6,:));
uvs = round(h2a(P * a2h(fpts))); % projected points into image plane

if debug
    % show selected pointcloud
    show_selected_pointcloud( fpts, frgb, pano_q, pano_C, pano_id  );
    subfig(3,3,5,gcf); title('Selected subset of 3D points for projection');
    
    %show projected points in 2D image
    img_pts = show_projected_pts( uvs, img_size, frgb ); 
    subfig(3,3,6,gcf); title('Projected 3D points into the image using P');
    
    %show projected points in 2D image & renderd image
    imshow(0.5*img + 0.5*img_pts);
    subfig(3,3,7,gcf); title('Projected 3D points into the image using P');
end

q = r2q(R * R2');
writematrix([C2;q]', sprintf('cutouts/pose%d.csv', pano_id));

fprintf('pano %d\n',pano_id)
fprintf('fi %f\n',fi_x)
fprintf('point = [%f, %f, %f]\n',C2) 
fprintf('quat = [%f, %f, %f, %f]\n',q)
fprintf('%f, %f, %f, %f, %f, %f, %f\n',[C2;q])