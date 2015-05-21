function [X,cellLabels] = prepareCellForBoxplot(cellInputData, cellInputLabels)
% Help for prepareCellForBoxplot: 
%
% [X,cellLabels] = prepareCellForBoxplot(cellData, cellLabels)
%
% boxplot(X,cellLabels)
%
% puts all elements of a cell into a matrix with label-cell good for
% boxplot plotting, i.e. allows cell arrays to be boxplotted, with each
% cell it's own boxplot. (am i overlooking this option somewhere native???)
% 

Xpos = [0;cumsum(cellfun(@numel,cellInputData(:)))];
X = NaN(Xpos(end),1);
cellLabels = cell(Xpos(end),1);
for i = 1:length(cellInputData)
    X(Xpos(i)+1:Xpos(i+1),1) = cellInputData{i}(:);
    cellLabels(Xpos(i)+1:Xpos(i+1),1) = {cellInputLabels{i}};
end