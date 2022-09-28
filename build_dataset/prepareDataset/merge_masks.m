close all

% hospital
src_path = "/local1/homes/dubenma1/data/inloc_dataset/habitat + matlab dataset/hospital/semantic_h/";

% livinglab
% src_path = "/local1/homes/dubenma1/data/inloc_dataset/habitat + matlab dataset/livinglab/-120:30:-60/semantic_l/"

dyn1_path = fullfile(src_path, "dynamic_1", "masks");
dyn2_path = fullfile(src_path, "dynamic_2", "masks");

files = dir(dyn2_path);

for i = 1 : length(files)
   
   if length(files(i).name) > 4
       files(i).name
       mask1 = imread(fullfile(dyn1_path, files(i).name));
       mask2 = imread(fullfile(dyn2_path, files(i).name));

       new_mask = mask1+mask2;

       new_mask(new_mask > 255) = 255;
%        figure();imshow(mask1);
%        figure();imshow(mask2);
%        figure();imshow(new_mask);
       imwrite(new_mask, fullfile(dyn2_path, files(i).name))
   end
    
end

