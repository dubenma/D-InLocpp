%% select space
space_name = "hospital_real_objects"; % hospital, livinglab, b315, hospital_with_textures

% if dynamic is 0 then it generates the same dataset as if no dynamic 
% objects were used
% if dynamic is 1 or more, combination of static and dynamic datasets is
% created, and data for dynamic part are taken from the directory "dynamic_" + string(dynamic)
dynamic = 1;
%% set paths
if dynamic
    dynam_str = "dynamic_" + string(dynamic);
else
    dynam_str = "static";
end

if space_name == "hospital"
    input_path = "/local1/homes/dubenma1/data/inloc_dataset/habitat + matlab dataset/hospital";
    output_path = "/local1/homes/dubenma1/data/inloc_dataset/before_splitting_queries";
    output_path = fullfile(output_path, dynam_str, space_name);
    n_cutouts = 115;
    habitat_dir_name = "semantic_h";
elseif space_name == "livinglab"
    input_path = "/local1/homes/dubenma1/data/inloc_dataset/habitat + matlab dataset/livinglab/-120:30:-60/";
    output_path = "/local1/homes/dubenma1/data/inloc_dataset/before_splitting_queries";
    output_path = fullfile(output_path, dynam_str, space_name);
    n_cutouts = 35;
    habitat_dir_name = "semantic_l";
elseif space_name == "b315"
    input_path = "/local1/projects/artwin/datasets/B-315_dataset/matterport_data";
    output_path = "/local1/projects/artwin/datasets/B-315_dataset/matterport_data/inloc_dataset/before_splitting_queries";
    output_path = fullfile(output_path, dynam_str, space_name);
    n_cutouts = 26;
    habitat_dir_name = "b315_habitat";
elseif space_name == "hospital_real_objects"
    input_path = "/local1/homes/dubenma1/data/inloc_dataset/habitat + matlab dataset/hospital_real_objects";
    output_path = "/local1/homes/dubenma1/data/inloc_dataset/before_splitting_queries";
    output_path = fullfile(output_path, dynam_str, space_name);
    n_cutouts = 115;
    habitat_dir_name = "semantic_h";
end
% output_path = fullfile(output_path, space_name);

if not(isfolder(output_path))
    mkdir(output_path)
end

%% create query images with inserted dynamic meshes
if dynamic
    createDynamicQuery
end
%% copy files, move them with correct structure
copyFiles

%% create mat file with poses
buildPosesFiles

%% manually copy 3D models
models_path = fullfile(output_path, 'models', space_name)

if not(isfolder(models_path))
    mkdir(models_path)
end

if dynamic
    disp('Copy contents of the directory "models" from static to:')
    disp(models_path)
    disp("Then add to this directory the directory:")
    disp("habitat_ros_semantic_2/spring_simulation/data/objects_categorized/<space_name>_dynamic/Dynamic_obj")
else
    disp('Do not forget to copy the contents of the directory "matterpak" to:')
    disp(models_path)
    disp("Rename the main .obj to model.obj")
end