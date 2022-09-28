function [ info ] = parse_WUSTL_cutoutname( cutout_name )

info = struct();
[~, cutout_basename, ~] = fileparts(cutout_name);
cutout_split = strsplit(cutout_basename, '_');

info.scan_id = cutout_split{2};
info.theta = str2double(cutout_split{3});
info.phi = str2double(cutout_split{4});

end