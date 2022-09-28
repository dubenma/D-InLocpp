%% setup directories
disp("Creating dynamic cutouts")

dir_cutout = fullfile(input_path, "cutouts");
dir_mask = fullfile(input_path, habitat_dir_name, dynam_str, "masks");
dir_mesh = fullfile(input_path, habitat_dir_name, dynam_str, "rgbs");
dir_output = fullfile(input_path, habitat_dir_name, dynam_str, "cutouts");

if ~exist(dir_output, 'dir')
   mkdir(dir_output)
end

%% create dynamic queries

files = dir(fullfile(dir_cutout, '*.jpg'));

for i = 1 : length(files)
    file = files(i).name;
    cutout_name = string(file(1:end-4));

    im_cutout = imread(fullfile(dir_cutout, cutout_name + '.jpg'));
    im_mask = imread(fullfile(dir_mask, cutout_name + '.png'));
    im_mesh = imread(fullfile(dir_mesh, cutout_name + '.jpg'));

    % create a mask
    mask = (im_mask > 0);
    mask = repmat(mask,[1 1 3]);

    im_dynamic = im_cutout;
    % add dynamic objects
    im_dynamic(mask) = im_mesh(mask);
    
%     figure();
%     imshow(im_dynamic)
    
    % save
    imwrite(im_dynamic, fullfile(dir_output, cutout_name + '.jpg'))

end

disp("Creating dynamic cutouts done!")

