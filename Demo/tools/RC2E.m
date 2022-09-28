% E = RC2E(R,C) - E = [R*[I -C] [0 0 0 1]]
%	 
% (c) T. Pajdla, pajdla@gmail.com, 2017-02-03
function E = RC2E(R,C)
if isstruct(R)
    C = R.C;
    R = R.R;
end
if ~isempty(R)
    if size(R,2)==4
        E = [R(1:3,:);[0 0 0 1]];
    else
        E = [R*[eye(3) -C];[0 0 0 1]];
    end
else
    E = [];
end

