function cellstrProjectNames = getprojectnames(cellstrPathNames)
    % regular expression the plate-names out of there, assuming BATCH or TIFF dir
    % is child of plate name, and plate is child of project
    
    cellstrProjectNames = regexpi(cellstrPathNames,'.*[\\/](.*)[\\/].*[\\/](BATCH|POSTANALYSIS|TIFF)','tokens');
    
    % get those pesky nested cells out of there
    for i = 1:length(cellstrProjectNames)
        while iscell(cellstrProjectNames{i})
            cellstrProjectNames{i} = cellstrProjectNames{i}{1};
        end
    end
    
    % convert to string if it is only one plate
    if length(cellstrProjectNames) == 1
       cellstrProjectNames = char(cellstrProjectNames{1}); 
    end
end