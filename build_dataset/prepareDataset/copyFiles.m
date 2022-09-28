% output_path = "~/dubenma1/data/Inloc dataset/Maps/SPRING/Broca_dataset2";
% input_path = "~/dubenma1/data/Inloc dataset/Maps/SPRING/Broca_dataset2/Broca Living Lab without Curtains/all";
% space_name = "livinglab_2";


%%
disp("Copying files")
disp("From: " + input_path)
disp("To: " + output_path)
static_str = "static";
d_str = "dynamic";
%% cutouts
disp("Copying cutouts")

cutouts_in_path = fullfile(input_path, "cutouts");
cutouts_out_path = fullfile(output_path, "cutouts");

if not(isfolder(cutouts_out_path))
    mkdir(cutouts_out_path)
end

for i = 0 : n_cutouts
    path = fullfile(cutouts_out_path, space_name, string(i+1));
    if not(isfolder(path))
        mkdir(path)
    end
    
    copyfile(fullfile(cutouts_in_path, "cutout_pano_" + string(i) + "_*.jpg"), path)
end
    
disp("Copying cutouts done!")
%% matfiles
disp("Copying matfiles")
matfiles_out_path = fullfile(output_path, "matfiles");
matfiles_in_path = fullfile(input_path, habitat_dir_name, static_str, "pointcloud");

if not(isfolder(matfiles_out_path))
    mkdir(matfiles_out_path)
end

for i = 0 : n_cutouts
    path = fullfile(matfiles_out_path, space_name, string(i+1));
    if not(isfolder(path))
        mkdir(path)
    end
    
    copyfile(fullfile(matfiles_in_path, "cutout_pano_" + string(i) + "_*.jpg.mat"), path)
end

disp("Copying matfiles done!")
%% meshes
disp("Copying meshes")
meshes_out_path = fullfile(output_path, "meshes");
meshes_in_path = fullfile(input_path, habitat_dir_name, static_str, "rgbs");

if not(isfolder(meshes_out_path))
    mkdir(meshes_out_path)
end

for i = 0 : n_cutouts
    path = fullfile(meshes_out_path, space_name, string(i+1));
    if not(isfolder(path))
        mkdir(path)
    end
    
    copyfile(fullfile(meshes_in_path, "cutout_pano_" + string(i) + "_*.jpg"), path)
end

disp("Copying meshes done!")

%% semantic
% disp("Copying semantic")
% semantic_out_path = fullfile(output_path, "semantic");
% semantic_in_path = fullfile(input_path, habitat_dir_name, dynam_str, "semantic");
% 
% if not(isfolder(semantic_out_path))
%     mkdir(semantic_out_path)
% end
% 
% for i = 0 : n_cutouts
%     path = fullfile(semantic_out_path, space_name, string(i+1));
%     if not(isfolder(path))
%         mkdir(path)
%     end
%     
%     copyfile(fullfile(semantic_in_path, "cutout_pano_" + string(i) + "_*.png"), path)
% end
% 
% copyfile(fullfile(semantic_in_path, "semantic.csv"), fullfile(semantic_out_path, space_name))
% 
% disp("Copying semantic done!")
%% dynamic 
if dynamic
% cutouts
    disp("Copying dynamic cutouts")

    cutouts_in_path = fullfile(input_path, habitat_dir_name, dynam_str, "cutouts");
    cutouts_out_path = fullfile(output_path, "cutouts_" + d_str);

    if not(isfolder(cutouts_out_path))
        mkdir(cutouts_out_path)
    end

    for i = 0 : n_cutouts
        path = fullfile(cutouts_out_path, space_name, string(i+1));
        if not(isfolder(path))
            mkdir(path)
        end

        copyfile(fullfile(cutouts_in_path, "cutout_pano_" + string(i) + "_*.jpg"), path)
    end

    disp("Copying dynamic cutouts done!")
% matfiles
    disp("Copying dynamic matfiles")
    matfiles_out_path = fullfile(output_path, "matfiles_" + d_str);
    matfiles_in_path = fullfile(input_path, habitat_dir_name, dynam_str, "pointcloud");

    if not(isfolder(matfiles_out_path))
        mkdir(matfiles_out_path)
    end

    for i = 0 : n_cutouts
        path = fullfile(matfiles_out_path, space_name, string(i+1));
        if not(isfolder(path))
            mkdir(path)
        end

        copyfile(fullfile(matfiles_in_path, "cutout_pano_" + string(i) + "_*.jpg.mat"), path)
    end

    disp("Copying dynamic matfiles done!")
    
% meshes
    disp("Copying dynamic meshes")
    meshes_out_path = fullfile(output_path, "meshes_" + d_str);
    meshes_in_path = fullfile(input_path, habitat_dir_name, dynam_str, "rgbs");

    if not(isfolder(meshes_out_path))
        mkdir(meshes_out_path)
    end

    for i = 0 : n_cutouts
        path = fullfile(meshes_out_path, space_name, string(i+1));
        if not(isfolder(path))
            mkdir(path)
        end

        copyfile(fullfile(meshes_in_path, "cutout_pano_" + string(i) + "_*.jpg"), path)
    end

    disp("Copying dynamic meshes done!")
 % masks
    disp("Copying dynamic masks")
    masks_out_path = fullfile(output_path, "masks_" + d_str);
    masks_in_path = fullfile(input_path, habitat_dir_name, dynam_str, "masks");

    if not(isfolder(masks_out_path))
        mkdir(masks_out_path)
    end

    for i = 0 : n_cutouts
        path = fullfile(masks_out_path, space_name, string(i+1));
        if not(isfolder(path))
            mkdir(path)
        end

        copyfile(fullfile(masks_in_path, "cutout_pano_" + string(i) + "_*.png"), path)
    end

    disp("Copying dynamic masks done!")
end