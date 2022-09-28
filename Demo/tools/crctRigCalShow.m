% crctRigCalShow - Camera Rig Calibration Toolbox - Show Calibration Results
% T. Pajdla, pajdla@gmail.com, S. Steidl stanislav.steidl@gmail.com
% (c) 2016 - 2017
addpath tools

% rig calibration data file name
fn = dir('*.mat'); fn = fn.name;
% load the calibration data
Rig = load(fn);
% plot 3D target and the rig poses
subfig(2,3,1); hold;
for j=1:numel(Rig.W2B) % over poses
    for i=1:numel(Rig.B2C) % over cameras
        if ~isempty(Rig.Ext{i,j})
            plot3d(Rig.Ext{i,j}.X,'.k');
        end
    end
end
% plot camera rigs
C = cell2mat(fetchfields(Rig.B2C,'C')); % camera centers in the rig
s = mean(std(C,[],2))/2; % scale for plottign the coordinate systems
for p = 1:numel(Rig.W2B)
    rigplot(Rig.B2C,Rig.W2B{p},s);
end
axis equal; grid; xlabel('x');ylabel('y');zlabel('z');
% plot reprojections
for i=1:numel(Rig.B2C) % over cameras
    for j=1:numel(Rig.W2B) % over images
        if ~isempty(Rig.Ext{i,j})
            subfig(4,7,mod(i-1,4)*7+mod(j-1,7)+1); hold;
            title(sprintf('[%d %d]',i,j));
            if ~isempty(Rig.Ext{i,j}.u)
                plot3d(Rig.Ext{i,j}.u,'.b'); % plot detections
                if ~isempty(Rig.Ext{i,j})
                    title(sprintf('%s %d/%d ins',get(get(gca,'title'),'string'),sum(Rig.Ext{i,j}.in),size(Rig.Ext{i,j}.u,2)));
                    if sum(Rig.Ext{i,j}.in) > 0 && ~isempty(Rig.W2B{j}.C)
                        C = Rig.Ext{i,j}.C;
                        [C.R,C.C] = E2RC(RC2E(Rig.B2C{i})*RC2E(Rig.W2B{j}));
                        ui = Rig.Ext{i,j}.u(:,Rig.Ext{i,j}.in);
                        up = X2u(Rig.Ext{i,j}.X(:,Rig.Ext{i,j}.in),C); % reproject inliers
                        plot3d(up,'c.'); % plot inliers
                        upi = 10*(up-ui)+ui; line([ui(1,:);upi(1,:)],[ui(2,:);upi(2,:)],'color','m');
                    end
                end
            end
            
        end
    end
end


clear C upi ui up i j s fn