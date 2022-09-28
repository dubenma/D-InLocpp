% f = fetchfields(s,fn) - extract field f from cell aray of struct s ({s.f} for celarrays od structs}

% (c) T. Pajdla, pajdla@gmail.com, 2017-02-04
function f = fetchfields(s,fn)
if iscell(s)
    f = cellfunuo(@(x) fetchfield(x,fn), s,'uniformoutput',false);
else
    f = arrayfun(@(x) x.(fn), s,'uniformoutput',false);
end
