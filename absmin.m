function [intMinX, intMinXindex] = absmin(X,dim)
%
% [Berend Snijder]. Returns the absolute minimum value
%
% [intMinX, intMinXindex] = absmin(X)

if nargin==1
    dim=1;
end
    

[C,intMinXindex]=nanmin(abs(X),dim);

intMinX = X(intMinXindex);

end