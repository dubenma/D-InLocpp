% h = cs3plot(E[,s]) - 3D coordinate system plotting
%
% E = 3x4 (4x4) transform [R -R*T] or E.R, E.T
% s = scale [1]
%
% h = plot handles
%     h(1) = center
%     h(2) = first axis
%     h(3) = seconf axis
%     h(4) = third axis

% (c) T. Pajdla, pajdla@gmail.com, 2015-09-04
function h = cs3plot(E,s)
if nargin>0
    if nargin<2, s = 1; end
    if isempty(E), h = []; return; end
    if isstruct(E)
        R = s*E.R; C = P.C;
    else
        R = E(1:3,1:3); C = -R\E(1:3,4);
    end
    x = [s*inv(R) C]*a2h([zeros(3,1) eye(3)]);
    if ~ishold, hold; unhold=true; else unhold=false; end
    h(2) = plot3d(x(:,[1 2]),'b','linewidth',2);
    h(3) = plot3d(x(:,[1 3]),'r','linewidth',2);
    h(4) = plot3d(x(:,[1 4]),'g','linewidth',2);
    h(1) = plot3d(x(:,1),'k.','markersize',15);    
    if unhold, hold; end
else % unit tests
    % Test 1 = projection
    subfig(3,4,1);
    R = eye(3); C = [0;0;0];
    h = cs3plot(RC2E(R,C));
    view(3); axis equal;grid
    subfig(3,4,2);
    h = cs3plot(RC2E(R,C)); set(h,'color','k');
    view(3); axis equal;grid
    h = true;
end
