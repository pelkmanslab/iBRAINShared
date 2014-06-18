function m = nancell2mat(c)
%CELL2MAT2 Convert the contents of a cell array into a single matrix, BUT
%is robust tot non-number input. these are converted to NaN
%
% By Berend Snijder. Diggety!

% look up not-numbers
isNaN = ~cellfun(@isnumeric, c);

% overwrite to NaNs
c(isNaN) = {NaN};

% convert to matrix
m = cell2mat(c);

end
