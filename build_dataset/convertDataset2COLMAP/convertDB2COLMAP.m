function convertDB2COLMAP(images_path, poses_path, camera_intrinsics)

    % create folders
    colmap_folder = [images_path '_COLMAP'];
    if ~exist(colmap_folder,'dir')
       mkdir(colmap_folder); 
    end
    colmap_images = fullfile(colmap_folder,'images');
    if ~exist(colmap_images,'dir')
       mkdir(colmap_images); 
    end
    
    % CAMERA_ID, MODEL, WIDTH, HEIGHT, PARAMS[]
    fileID2 = fopen(fullfile(colmap_folder,'cameras.txt'),'w');
    fprintf(fileID2,['1 ' camera_intrinsics]);
    fclose(fileID2);

    % points3D.txt
    fileID3 = fopen(fullfile(colmap_folder,'points3D.txt'),'w');
    fclose(fileID3);

    img_id = 1;
    fileID = fopen(fullfile(colmap_folder,'images.txt'),'w');
    db_imgs_folders = dir(images_path);
    for j = 3:size(db_imgs_folders,1)
        db_imgs_path = dir(fullfile(images_path,db_imgs_folders(j).name,'*.jpg'));
        for k = 1:size(db_imgs_path,1)
            % copy image 
            img_name = db_imgs_path(k).name;
            img_path = fullfile(db_imgs_path(k).folder,db_imgs_path(k).name);
            new_img_path = fullfile(colmap_images,img_name);
            new_img_rel_path = ['images/' img_name];
            if ~exist(new_img_path,'file')
                copyfile(img_path,new_img_path);
            end
            pose_path = fullfile(poses_path,db_imgs_folders(j).name,...
                [db_imgs_path(k).name '.mat']);

            % save the image rotation and translation
            load(pose_path);
    %         f = figure(1); imshow(query.query_img); axis image; subfig(2,2,2,f); 
    %         query_masks = query.mask(:,:,1);
    %         figure(); imshow(query_masks);
            R = R';
            C = position';
            t = - R * C;
            q = r2q(R);

            % IMAGE_ID, QW, QX, QY, QZ, TX, TY, TZ, CAMERA_ID, NAME
            fprintf(fileID,'%d ',img_id);
            fprintf(fileID,'%.5f ',q);
            fprintf(fileID,'%.5f ',t);
            fprintf(fileID,'1 %s\n0 0 -1\n',new_img_rel_path);
            img_id = img_id + 1;
        end
    end
    fclose(fileID);

end

