function [intMaxX, intMaxXindex] = absmax(X)
%
% [Berend Snijder]. Returns the absolute maximum value
%
% [intMaxX, intMaxXindex] = absmax(X)

[C,intMaxXindex]=nanmax(abs(X));

intMaxX = X(intMaxXindex);

end