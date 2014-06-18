function cellLabels = createPlateLabels(intLayout)
% Help for createPlateLabels
% 
% Usage:
%
% cellLabels = createPlateLabels(intLayout)
%
% spits out a cell array with typical well labels for a 96 or 384 well
% plate layout.
%
% diggety.
%
% Berend Snijder


if nargin==0
    intLayout = 96;
end

if intLayout == 96
    matRows = 1:8;
    matCols = 1:12;
elseif intLayout == 384
    matRows = 1:16;
    matCols = 1:24;
else
    error('%s: unknown plate format!')
end

strLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

cellLabels = cell(max(matRows),max(matCols));

for iRow = matRows
    for iCol = matCols
        cellLabels(iRow,iCol) = {sprintf('%s%02d',strLetters(iRow),iCol)};
    end
end
