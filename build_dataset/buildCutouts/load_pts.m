function [ pts ] = load_pts( file_path )
    [filepath,name,ext] = fileparts(file_path);
    if ext == '.ply'
    %LOAD_PTS - load pts from SIEMENS factory
        fileID = fopen(file_path,'r');
        line_ex = 0;
        num_verteces = 0;
        while ~strcmp(line_ex,'end_header') & line_ex ~= -1
            line_ex = fgetl(fileID);
            if length(line_ex) > 14 & strcmp('element vertex',line_ex(1:14))
                num_verteces = str2num(line_ex(16:end));
            end
        end
        f = fscanf(fileID,'%f')
        pts = reshape(fscanf(fileID,'%f'),7,num_verteces);
        fclose(fileID);
    elseif ext == '.xyz'
        dirs = split(filepath,'/');
        name = dirs{end-1};
        
    % load pointcloud from .xyz from matterport
        if isfile(fullfile(pwd,'tmp',[name '.mat']))
            load(fullfile(pwd,'tmp',[name '.mat']),'pts')
        else
            fileID = fopen(file_path,'r');
            pts_all = fscanf(fileID,'%f');
            pts = reshape(pts_all,6,length(pts_all)/6);
            len = length(pts);
            pts = [pts; ones(1,len)*255];
            fclose(fileID);
            save(fullfile('tmp', [name '.mat']),'pts')
        end      
    end
end

