function [K] = buildK(focalLength, sensorWidth, sensorHeight)
    K = eye(3);
    K(1,1) = focalLength;
    K(2,2) = focalLength;
    K(1,3) = sensorWidth/2.0;
    K(2,3) = sensorHeight/2.0;
end