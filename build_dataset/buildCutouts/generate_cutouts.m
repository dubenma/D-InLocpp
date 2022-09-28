% clear; 
close all; 
addpath(fullfile(pwd,'codes'));

%% settings
debug = 1;
debug_cutouts = 1;
save_pointcloud_cutout = 0;

dataset_dir = fullfile('/home/ciirc/dubenma1/data/Broca Living Lab without Curtains');
% dataset_dir = fullfile('/home/ciirc/dubenma1/data/Broca Hospital with Curtains');
pts_file = fullfile(dataset_dir,'matterpak','cloud.xyz');
poses_file = fullfile(dataset_dir,'pano_poses.csv');
pano_dir = fullfile(dataset_dir,'panos_rotated');
save_directory = fullfile(dataset_dir,'cutouts');

rot_x = [-120:30:-60];
rot_z = [0:30:359];

% params of the generated image (one exapmpe)q   
HFOV = 66;
f = 1344/2/tan((HFOV/180*pi)/2);                    % focal length
img_size = [1344 756];         % image size
u0 = img_size(1)/2;                    % principal point u0
v0 = img_size(2)/2;                    % principal point v0

K = [f 0 u0; 0 f v0; 0 0 1];    % the calibration matrix 

%% process
% load points in 3D & panorama poses
    pts = load_pts( pts_file );
    [ pano_images, pano_poses, pano_C, pano_q ] = load_pano_poses( poses_file );

% show pointcloud
% show panorama coordinate systems
if debug
    pts(:,pts(3,:) > 2) = [];
    show_pointcloud( pts ); 
    %subfig(3,3,1,gcf); 
    hold on;
    show_pano_in_world( pano_C, pano_q, pano_poses, pano_images );
end 

%%
csv_rows = [];

for pano_id = 1:size(pano_images,1)
    % load panorama
    pano_img = imread(fullfile(pano_dir,pano_images{pano_id}));
    % figure; imshow(pano_img); subfig(3,3,2,gcf); title(sprintf('Panorama "%s"',pano_images{pano_id}));

  

    for i = 1:length(rot_x)
        for j = 1:length(rot_z)
            fi_x = rot_x(i);
            Rx = [1  0           0; ...
                0   cosd(fi_x)     -sind(fi_x); ...
                0   sind(fi_x)     cosd(fi_x)];	% some 

            fi_z = rot_z(j);
            Rz = [cosd(fi_z) -sind(fi_z) 0; ...
                sind(fi_z)   cosd(fi_z)  0; ...
                0   0   1];
            R = Rz*Rx;

            % projection of sfere to plane  
            % -> we assume projection matrix P = K R q2r(pano_q(:,pano_id))' [I -pano_C(:,pano_id)];
            R2 = q2r(pano_q(:,pano_id));
            C2 = pano_C(:,pano_id); 
            iQ = R2 * R * inv(K); 
            [X,Y] = meshgrid(0:img_size(1)-1, 0:img_size(2)-1);
            X = X(:); Y = Y(:);
            proj = iQ * [X, Y, ones(length(X),1)]';
            proj = R2' * proj .* (ones(3,1) * 1./sqrt(sum(proj.^2)));     
            beta_proj = -asin(proj(3,:));
            alpha_proj = -atan2(proj(2,:), proj(1,:));
            uv = real([	(beta_proj / (pi)) * size(pano_img,1) + size(pano_img,1)/2 + 1; ...
                        (alpha_proj / (2*pi)) * size(pano_img,2) + size(pano_img,2)/2 + 1]); 
                    
            % show all in one 
            if debug
                show_all_in_one(pts,pano_C,pano_q,pano_poses,pano_images,pano_id,pano_img,K,R,img_size);
            end 

            % bilinear interpolation from original image
            img = bilinear_interpolation( img_size, uv, pano_img );
            if debug
                figure(); imshow(img); %set(gca, 'XDir','reverse'); 
                subfig(3,3,4,gcf); title('Rendered image');
            end
            cutout_name = sprintf('cutout_pano_%d_%d_%d.jpg', pano_id-1,fi_x,fi_z);
            imwrite(img,fullfile(save_directory, cutout_name));
            q = r2q(R2 * R);
            str_C = [string(sprintf('%.15f', C2(1))), string(sprintf('%.15f', C2(2))),string(sprintf('%.15f', C2(3)))];
            str_q = [string(sprintf('%.15f', q(1))), string(sprintf('%.15f', q(2))),string(sprintf('%.15f', q(3))),string(sprintf('%.15f', q(4)))];
            row = [string(cutout_name), str_C, str_q ];
            csv_rows = [csv_rows; row];


            % project the factory pointcloud by related projection matrix P
            P = K * R' * R2' * [eye(3) -C2];
            [ fpts, frgb ] = filterFieldView( ...
                struct('R', R' * R2', 'C', C2), ...
                pts(1:3,:), pts(4:6,:));
            uvs = round(h2a(P * a2h(fpts))); % projected points into image plane

            if debug
                % show selected pointcloud
                show_selected_pointcloud( fpts, frgb, pano_q, pano_C, pano_id  );
                subfig(3,3,5,gcf); title('Selected subset of 3D points for projection');
                
                depth_img = depth_maps(uvs, img_size, fpts, C2);
                figure;
                imshow(depth_img/10);
            end
            
            

            %show projected points in 2D image
            img_pts = projected_pts( uvs, img_size, frgb ); 
            if debug || debug_cutouts
                figure(); 
                imshow(img_pts);
                subfig(3,3,6,gcf); title('Projected 3D points into the image using P');
            end
%             if save_pointcloud_cutout
%                 imwrite(img_pts,fullfile(save_directory,sprintf('cutout_pano_pts_%d_%d_%d.jpg', pano_id-1,fi_x,fi_z)));
%             end

            %show projected points in 2D image & renderd image
            if debug || debug_cutouts
                figure()
                imshow(0.5*img + 0.5*img_pts); 
                subfig(3,3,7,gcf); title('Projected 3D points into the image using P with cutout');
            end
            if save_pointcloud_cutout
                imwrite(0.5*img + 0.5*img_pts,fullfile(save_directory, sprintf('cutout_pts_cut_pano_%d_%d_%d.jpg', pano_id-1,fi_x,fi_z)));
            end
        end
    end
    fprintf('Cutouts for pano %d out of %d done\n', pano_id-1,size(pano_images,1)-1)
end

writematrix(csv_rows, fullfile(save_directory,'poses.csv'));
