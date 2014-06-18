function cellOut = cell2expandedcell(cellData)
cellEntries = cellfun(@numel,cellData);
cols = size(cellData,2);
cellOut = cell(max(cellEntries),cols);
for i = 1:cols
    cellOut(1:cellEntries(i),i) = cellData{i};
end