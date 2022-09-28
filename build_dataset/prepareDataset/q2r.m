% R = q2r(q) - rotation matrix to unit quaternion
%
% q = unit quaternion
% R = 3 x 3 rotation matrix 

% Tomas Pajdla, pajdla@cmp.felk.cvut.cz
% 2001-03-12
function R = q2r(q)

q = q/vnorm(q);
R = [q(1)^2+q(2)^2-q(3)^2-q(4)^2   2*(q(2)*q(3)-q(1)*q(4))      2*(q(2)*q(4)+q(1)*q(3))
     2*(q(2)*q(3)+q(1)*q(4))       q(1)^2-q(2)^2+q(3)^2-q(4)^2  2*(q(3)*q(4)-q(1)*q(2))
     2*(q(2)*q(4)-q(1)*q(3))       2*(q(3)*q(4)+q(1)*q(2))      q(1)^2-q(2)^2-q(3)^2+q(4)^2];