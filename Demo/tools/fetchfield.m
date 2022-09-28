% f = fetchfield(s,fn) - extract field f from struct s, return [] is f not in s or s empty

% (c) T. Pajdla, pajdla@gmail.com, 2016-04-24
function f = fetchfield(s,fn)
if isfield(s,fn)
    f = s.(fn);
else
    f = [];
end
