function [panoId,pano_poses,rot_C,rot_R] = readJsonPoses(file)
% output:
%     panoId len x 1
%     position len x 3
%     rotation len x 3

    in = jsondecode(fileread(file));
    len = size(in,1);
    
    %initialization
    panoId = [];
    position = zeros(len,3); rotation = position;
     
    for i=1:len
        panoId = [panoId; num2str(i)+".jpg"];
        position(i,:) = [in(i).position.x; in(i).position.y; in(i).position.z]';
        rotation(i,:) = [in(i).rotation.x in(i).rotation.y in(i).rotation.z]';
    end
    pano_poses = [position,rotation];
    
    Rx = @(a) [1 0 0; 0 cos(a) -sin(a); 0 sin(a) cos(a)];
    Ry = @(a) [cos(a) 0 sin(a); 0 1 0; -sin(a) 0 cos(a)];
    Rz = @(a) [cos(a) -sin(a) 0; sin(a) cos(a) 0 ; 0 0 1];
    
    Rx90 = Rx(-pi/2);
    
    rot_C = (Rx90' * position')';
    rot_R = cell(len,1);
    pano_R2 = rotation / 180 * pi;
    for i=1:len
        rot_R{i} = Rx(pano_R2(i,1)) * Ry(pano_R2(i,2)) * Rz(pano_R2(i,3)) * Rx90 ;
    end
end