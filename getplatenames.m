function cellstrPlateNames = getplatenames(cellstrPathNames)

    if nargin==0
        cellstrPathNames = 'blablablab/PLATENAME_FUNKY/TIFF'
    end
    
    cellstrORIG = cellstrPathNames;
    
    % regular expression the plate-names out of there, assuming BATCH,
    % POSTANALYSIS, or TIFF dir is child of plate name.
    cellstrPlateNames = regexpi(cellstrPathNames,'.*[\\/](.*)[\\/](BATCH|POSTANALYSIS|TIFF)','tokens');
    
    % get those pesky nested cells out of there
    for i = 1:length(cellstrPlateNames)
        while iscell(cellstrPlateNames{i})
            if ~isempty(cellstrPlateNames{i})
                cellstrPlateNames{i} = cellstrPlateNames{i}{1};
            else
                cellstrPlateNames{i} = cellstrORIG{i};
            end
        end
    end
    
    % convert to string if it is only one plate
    if length(cellstrPlateNames) == 1
       cellstrPlateNames = char(cellstrPlateNames{1}); 
    end
end