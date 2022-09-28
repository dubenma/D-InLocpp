%% set parameters for 'dynamic' and 'space_name' 
dynamic = 1;
space_name = "hospital_real_objects"; % hospital, livinglab

if not(exist('dynamic','var'))
    dynamic = 0;
end

if not(exist('space_name','var'))
    space_name = "livinglab"; % hospital, livinglab
end
%% set paths

if dynamic
    dynam_str = "dynamic_" + string(dynamic);
else
    dynam_str = "static";
end

new_dataset_dir = "/local1/homes/dubenma1/data/inloc_dataset/final_dataset/Broca_dataset_" + dynam_str;
input_dir = fullfile("/local1/homes/dubenma1/data/inloc_dataset/before_splitting_queries", dynam_str, space_name);

if space_name == "hospital" || space_name == "hospital_with_textures" || space_name == "hospital_real_objects"
    query_ids = [10,14,27,40,43,46,51,56,73,74,82,91,101,103,108]; %old = [8,10,14,27,40,43,46,51,56,91,101,103];
elseif space_name == "livinglab"
    query_ids = [12,23,24,31,34]; % old = [15,21,31,34];
end

%% copy all database and query data
copyfile(input_dir, new_dataset_dir);

%% separate query data
queries_path = fullfile(new_dataset_dir, "queries");

if not(isfolder(queries_path))
    mkdir(queries_path)
end

for i = 1 : length(query_ids)
    % cutouts
    dir_name = "cutouts";
    inpath = fullfile(new_dataset_dir, dir_name, space_name, string(query_ids(i)));
    outpath = fullfile(new_dataset_dir, "queries", space_name, dir_name);
    if not(isfolder(outpath))
        mkdir(outpath)
    end
    movefile(inpath, outpath);
    
    % matfiles
    dir_name = "matfiles";
    inpath = fullfile(new_dataset_dir, dir_name, space_name, string(query_ids(i)));
    outpath = fullfile(new_dataset_dir, "queries", space_name, dir_name);
    if not(isfolder(outpath))
        mkdir(outpath)
    end
    movefile(inpath, outpath);
    
    % meshes
    dir_name = "meshes";
    inpath = fullfile(new_dataset_dir, dir_name, space_name, string(query_ids(i)));
    outpath = fullfile(new_dataset_dir, "queries", space_name, dir_name);
    if not(isfolder(outpath))
        mkdir(outpath)
    end
    movefile(inpath, outpath);
    
    % poses
    dir_name = "poses";
    inpath = fullfile(new_dataset_dir, dir_name, space_name, string(query_ids(i)));
    outpath = fullfile(new_dataset_dir, "queries", space_name, dir_name);
    if not(isfolder(outpath))
        mkdir(outpath)
    end
    movefile(inpath, outpath);
    
    % dynamic
    if dynamic 
    % cutouts
        dir_name = "cutouts_dynamic";
        inpath = fullfile(new_dataset_dir, dir_name, space_name, string(query_ids(i)));
        outpath = fullfile(new_dataset_dir, "queries", space_name, dir_name);
        if not(isfolder(outpath))
            mkdir(outpath)
        end
        movefile(inpath, outpath);

        % matfiles
        dir_name = "matfiles_dynamic";
        inpath = fullfile(new_dataset_dir, dir_name, space_name, string(query_ids(i)));
        outpath = fullfile(new_dataset_dir, "queries", space_name, dir_name);
        if not(isfolder(outpath))
            mkdir(outpath)
        end
        movefile(inpath, outpath);

        % meshes
        dir_name = "meshes_dynamic";
        inpath = fullfile(new_dataset_dir, dir_name, space_name, string(query_ids(i)));
        outpath = fullfile(new_dataset_dir, "queries", space_name, dir_name);
        if not(isfolder(outpath))
            mkdir(outpath)
        end
        movefile(inpath, outpath);
        
        % masks
        dir_name = "masks_dynamic";
        inpath = fullfile(new_dataset_dir, dir_name, space_name, string(query_ids(i)));
        outpath = fullfile(new_dataset_dir, "queries", space_name, dir_name);
        if not(isfolder(outpath))
            mkdir(outpath)
        end
        movefile(inpath, outpath);
    end

        

end

%% delete excessive query data




%% generate query_all

% query_all_path = fullfile(new_dataset_dir, "queries", space_name, "query_all");
% if not(isfolder(query_all_path))
%         mkdir(query_all_path)
% end
%     
% query_name = 1;
% for i = 1 : length(query_ids)
%    files = dir(fullfile(new_dataset_dir, "queries", space_name, "cutouts", string(query_ids(i))));
%    for j = 3 : length(files)
%        copyfile( fullfile(files(j).folder, files(j).name), fullfile(query_all_path, string(query_name) + ".jpg"));
%        query_name = query_name + 1;
%    end
% end
