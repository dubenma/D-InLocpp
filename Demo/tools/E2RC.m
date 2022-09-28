% [R,C] = E2RC(R,C) - E = [R*[I -C] [0 0 0 1]] -> R,C
	 
% (c) T. Pajdla, pajdla@gmail.com, 2017-02-03
function [R,C] = E2RC(E)
R = E(1:3,1:3);
C = -R\E(1:3,4);

