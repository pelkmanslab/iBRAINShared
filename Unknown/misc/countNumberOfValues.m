function [matCountPerValue,matUniqueValues,matIX2] = countNumberOfValues(x)

% usage:
%
% [matCountPerValue,matUniqueValues] = countNumberOfValues(x)
%
% bar(matUniqueValues,matCountPerValue)

    [x,matSortIX] = sort(x);
    
    if nargout==3
        [matUniqueValues,matIX,matIX2] = unique(x,'last');
        % sort back matIX2 so that it corresponds to the original unsorted
        % "x"
        [~,matSortIX] = sort(matSortIX);        
        matIX2 = matIX2(matSortIX);
    else
        [matUniqueValues,matIX] = unique(x,'last');
    end
    
    matCountPerValue = NaN(size(matUniqueValues));
    
    matPreviousIX = 0;
    for iValue = 1:numel(matUniqueValues)
        matCountPerValue(iValue) = matIX(iValue)-matPreviousIX;
        matPreviousIX = matIX(iValue);
    end
    
    
end
