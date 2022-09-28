% h = rigplot(B2C,T2B[,s]) - 3D coordinate system rig plotting
%
% rig = B2C{i}.R, B2C{i}.C or B2C{i} = [R1 -R1*C1]
%       T2B.R, T2B.C or T2B = [R2 -R2*C2]
% s = scale [1]
%
% h = plot handles
%     h{1} = handle to rig frame plot 
%     h{2:end} cs3plot handles 

% (c) T. Pajdla, pajdla@cvut.cz, 2015-09-04
function h = rigplot(B2C,T2B,s)
if nargin>0
    if isempty(T2B) || isempty(T2B.R) || isempty(T2B.C) h = []; return; end
    if nargin<3, s = 1; end
    if ~ishold, hold; unhold=true; else unhold=false; end
    x = zeros(3,numel(B2C));
    for i=1:numel(B2C)
        E = RC2E(B2C{i})*RC2E(T2B);
        h{i+1} = cs3plot(E,s);
        x(:,i) = [get(h{i+1}(1),'xdata');get(h{i+1}(1),'ydata');get(h{i+1}(1),'zdata')];
    end
    h{1} = plot3d(x(:,[1:end 1]),'k');
    if unhold, hold; end
else % unit tests
    % Test 1 = projection
    subfig(3,4,1);
    B2C = {RC2E(eye(3),[0;0;0]),RC2E(eye(3),[1;0;0]),RC2E(eye(3),[1;1;0]),RC2E(eye(3),[0;1;0])};
    T2B = RC2E(eye(3),[0;0;0]);
    h = rigplot(B2C,T2B);
    view(3); axis equal;grid
    h = true;
end
