function [intMaxXindex, intMaxX] = findmax(X)
%
% [Berend Snijder]. Returns the absolute maximum value
%
% [intMaxX, intMaxXindex] = absmax(X)

[intMaxX, intMaxXindex]=nanmax(abs(X));

end