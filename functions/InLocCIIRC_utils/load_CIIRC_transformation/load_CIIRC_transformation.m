function P = load_CIIRC_transformation( transformation_path )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

P = zeros(4, 4);

fid =  fopen(transformation_path, 'r');
data_all = textscan(fid, '%s', 'Delimiter', '\n');
data_all = data_all{1};
fclose(fid);

P(1, :) = str2double(strsplit(data_all{1}));
P(2, :) = str2double(strsplit(data_all{2}));
P(3, :) = str2double(strsplit(data_all{3}));
P(4, :) = str2double(strsplit(data_all{4}));

end

