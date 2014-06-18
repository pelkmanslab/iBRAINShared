
strRootPath = 'Y:\Data\Users\Frank\100126-10-8-VSV-Inh-EGF\100126-10-8-VSV-Inh-EGF\BATCH\';

cellstrBASICDATAFile = SearchTargetFolders(strRootPath,'BASICDATA_*.mat');

load(cellstrBASICDATAFile{1})

matWellNamesCol = BASICDATA.WellCol(~cellfun(@isempty,BASICDATA.Mean_Nuclei_AreaShape))';
matWellNamesRow = BASICDATA.WellRow(~cellfun(@isempty,BASICDATA.Mean_Nuclei_AreaShape))';

matMeanMeasurements = cat(1,BASICDATA.Mean_Nuclei_AreaShape{~cellfun(@isempty,BASICDATA.Mean_Nuclei_AreaShape)});

cellstrHeader = ['Well Column', 'Well Row', strcat('Mean_Measurements_',num2strcell([1:size(matMeanMeasurements,2)]))];

data = [cellstrHeader; mat2cell2(matWellNamesCol),mat2cell2(matWellNamesRow),mat2cell2(matMeanMeasurements)];
    
strFileName = fullfile(strRootPath,'meanmeasurements.xls');

fprintf('%s: storing %s',mfilename,strFileName)
xlswrite(strFileName,data)
  