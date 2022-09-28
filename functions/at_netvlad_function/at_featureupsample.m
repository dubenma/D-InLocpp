function f1 = at_featureupsample(f1,fsz,isz)

scale = isz(1:2)./fsz(1:2);
% if scale(1) ~= scale(2)
%     error('Cannot upsample feature!\n');
%     return
% end
f1 = scale(2)*f1;