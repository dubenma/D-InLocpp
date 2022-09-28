% P = P2KRC(K,R,C) - Camera matrix P = K*R*[I -C]
%	 
%	P	    = camera calibration matrix ; size = 3x4
%	K	    = matrix of internal camera parameters
%	R	    = rotation matrix
%	C	    = camera center
%   or 
%   K       = struct K.K, K.R, K.C

% (c) T. Pajdla, pajdla@gmail.com, 2015-08-26
function P = KRC2P(K,R,C)
if isstruct(K)
   if isfield(K,'type') && strcmp(K.type,'radtan')
       K.K = K.K * [K.k(2) 0      K.k(4);
                    0      K.k(3) K.k(5);
                    0      0      1];
   end
    R = K.R;
    C = K.C;
    K = K.K;
   
end
P = K*R*[eye(3) -C];

