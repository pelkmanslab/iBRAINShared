function strWellNames = wellix2wellname(iRow,iCol)

strWellNames = {};
for i = 1:numel(iRow)
    strWellNames{i,1} = sprintf('%s%02d',char(64+iRow(i)),iCol(i));
end

if numel(strWellNames)==1
    strWellNames = strWellNames{1};
end

end