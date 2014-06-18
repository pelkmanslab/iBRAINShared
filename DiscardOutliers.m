function [matOutput, matDiscardedValues, matDiscardedIndices] = DiscardOutliers(matInput, factor, strDirection)
% [matOutput, matDiscardedValues, matDiscardedIndices] = DiscardOutliers(matInput, factor)
% 
%   DiscardOutliers does simple outlier discarding dependent on the inter
%   quartile range of the data. Values lower and higher then 1.5 times the
%   IQR from the median are discarded, and filtered data is returned in
%   matOutput. The discarded values are returned in matDiscarded.
% 
%   BS, 070511 bugfix for matDiscardedIndices and NaN handling...
%
%   BS, 120327 added strDirection third input arguments: lower, upper, both

    if nargin == 1
        factor = 1.5;
    end
    
    if nargin<3
        strDirection = 'both';
    end

    matOutput = [];
    matDiscardedValues = [];
    matDiscardedIndices = [];    

    matSize = size(matInput);
    if matSize(1,1) == 1
        matInput = matInput';
    end



%     [y,IX] = sort(matInput(find(~isnan(matInput))))
    [y,IX] = sort(matInput);

    % compute 25th percentile (first quartile)
    Q(1) = nanmedian(y(find(y<nanmedian(y))));

    % compute 50th percentile (second quartile)
    Q(2) = nanmedian(y);

    % compute 75th percentile (third quartile)
    Q(3) = nanmedian(y(find(y>nanmedian(y))));

    % compute Interquartile Range (IQR)
    IQR = Q(3)-Q(1);

    % determine extreme Q1 outliers (e.g., x < Q1 - factor*IQR)
    matLowerOutliers = find(y<Q(1)-factor*IQR);

    % determine extreme Q3 outliers (e.g., x > Q1 + factor*IQR)
    matUpperOutliers = find(y>Q(3)+factor*IQR);

    switch lower(strDirection)
        case 'both'
            matOutput = y(find(y<Q(3)+factor*IQR & y>Q(1)-factor*IQR));
            matDiscardedValues = [y(matLowerOutliers);y(matUpperOutliers)];
            matDiscardedIndices = [IX(matLowerOutliers); IX(matUpperOutliers)];
        case 'lower'
            matOutput = y(find(y>Q(1)-factor*IQR));
            matDiscardedValues = [y(matLowerOutliers)];
            matDiscardedIndices = [IX(matLowerOutliers)];
        case 'upper'
            matOutput = y(find(y<Q(3)+factor*IQR));
            matDiscardedValues = [y(matUpperOutliers)];
            matDiscardedIndices = [IX(matUpperOutliers)];
    end
    
    

end