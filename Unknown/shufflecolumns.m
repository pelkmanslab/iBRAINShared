function xOut = shufflecolumns(x)
%
% x = shufflecolumns(x)
%
% Randomly shuffle the order of all values in a matrix on the same row.
% Berend Snijder.

    [iRows,iCols] = size(x);
    
    [~,matRandSortIX] = sort(rand(size(x)),2);
    
    % get matrix indices that do column shuffling
    matRandSortIX2 = repmat((1:iRows)',[1,iCols]);
    matRandSortIX2(matRandSortIX==2) = matRandSortIX2(matRandSortIX==2) + iRows;
    matRandSortIX2(matRandSortIX==3) = matRandSortIX2(matRandSortIX==3) + (2*iRows);

    % create output
    xOut = x(matRandSortIX2);
end
