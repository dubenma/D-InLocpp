% h = text3d(X,T,pars) - single matrix 3 x N text in 3D
% 
% X    ... single matrix 3 x N
% T    ... text labels, cellarray or padded matrix with a string per row
% pars ... other text pars
%
% See also text

% (c) T. Pajdla, pajdla@gmail.com, 2015-09-26
function h = text3d(varargin)

X = varargin{1};
if size(X,1)==3
h0 = text(X(1,:),X(2,:),X(3,:),varargin{2:end});
elseif size(X,1)==2
    h0 = text(X(1,:),X(2,:),varargin{2:end});
else
    h0 = text(varargin{1:end});
end
if nargout>0
    h=h0;
end





