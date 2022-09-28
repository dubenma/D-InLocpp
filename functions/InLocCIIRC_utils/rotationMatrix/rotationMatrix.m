function R = rotationMatrix(xyz, order)
% xyz: rotation vector around the specified axis in radians
% right-handed coordinate system is assumed
% 'XYZ' order means 'Z' rotation will be first, 'Y' rotation second and 'X' rotation third.
% WARNING: this order seems to be the opposite from scipy.spatial.transform.Rotation.from_euler
% WARNING: the rotation is clockwise in scipy.spatial.transform.Rotation.from_euler, here it is CCW

x = xyz(1);
y = xyz(2);
z = xyz(3);

Rx = eye(3);
Rx(2,2) = cos(x);
Rx(2,3) = -sin(x);
Rx(3,2) = sin(x);
Rx(3,3) = cos(x);

Ry = eye(3);
Ry(1,1) = cos(y);
Ry(1,3) = sin(y);
Ry(3,1) = -sin(y);
Ry(3,3) = cos(y);

Rz = eye(3);
Rz(1,1) = cos(z);
Rz(1,2) = -sin(z);
Rz(2,1) = sin(z);
Rz(2,2) = cos(z);

% note that the order is not commutative
% note that the order of matrix multiplication in Matlab is left-to-right

switch lower(order)
    case 'xyz'
        R = Rx * (Ry * Rz);
    case 'zyx'
        R = Rz * (Ry * Rx);
    case 'yxz'
        R = Ry * (Rx * Rz);
end