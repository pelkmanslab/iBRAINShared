function generate_basic_data(strRootPath, strOutputPath)

    warning off all

    if nargin == 0
%         strRootPath = npc('/BIOL/imsb/fs3/bio3/bio3/Data/Users/Prisca/endocytome/090217_A431_w2Tf_w3EEA1/090217_A431_Tf_EEA1_CP392-1ae/BATCH/');
        strRootPath = npc('http://www.ibrain.ethz.ch/share-3/Data/Users/Prisca/endocytome/091113_A431_w3GPIGFP/091113_A431GPIGFP_CP393-1be/BATCH/');
        strRootPath = npc(strRootPath);
        strOutputPath = strRootPath;
    end
    
    if nargin == 1
        strOutputPath = strRootPath;
    end

    disp(sprintf('%s: Loading data from %s',mfilename,strRootPath))    
    disp(sprintf('%s: MasterData is located in:',mfilename))        
    which('MasterData.mat')  
    load('MasterData.mat')
    
    BASICDATA = struct();
    BASICDATA.TotalCells = [];
    BASICDATA.InfectedCells = [];
    BASICDATA.InfectionIndex = [];
    BASICDATA.RelativeInfectionIndex = [];
    BASICDATA.Log2RelativeInfectionIndex = [];
    BASICDATA.Log2RelativeCellNumber = [];    
    
    BASICDATA.ZScore = [];
    BASICDATA.MAD = [];        

    BASICDATA.Images = [];
    BASICDATA.OligoNumber = [];
    BASICDATA.PlateNumber = [];
    BASICDATA.ReplicaNumber = [];        
    BASICDATA.BatchNumber = [];                
    BASICDATA.GeneData = {};
    BASICDATA.GeneID = {};    

    BASICDATA.WellRow = [];
    BASICDATA.WellCol = [];  
    BASICDATA.Path = {};
    BASICDATA.ImageIndices = {};    
    BASICDATA.RawImages = [];
        
    [matTotal, matInfected, matImagesPerWell, cellstrGenePerWell, matOligonumber, matPlatenumber, matReplicanumber, matBatchnumber, matCtrlInfectionIndices, matWellRow, matWellCol, matNoVirusCtrlInfectionIndices, cellstrGeneID, matCtrlCellNumbers, matRawImagesPerWell, cellImageIndicesPerWell] = ConvertHandlesTo384DG(strRootPath);

    % set 0 infected to 1, if there are cells, to prevent -inf problems...
    matInfected(find(matInfected == 0 & matTotal > 0)) = 1;

    % [BS: 2008-08-01] If there are gene-symbols, normalize against those
    % wells with gene-symbols, otherwise normalize against all wells.
    matNormalizationIndices = ~cellfun(@isempty,cellstrGenePerWell);
    if ~any(matNormalizationIndices)
%         matNormalizationIndices = ones(size(cellstrGenePerWell));
        matNormalizationIndices = (matRawImagesPerWell > 0);
        disp(sprintf('%s: no gene-symbols found in data, normalizing against all wells',mfilename))        
    else
        disp(sprintf('%s: normalizing against %d wells with gene-symbols',mfilename,sum(matNormalizationIndices)))
    end

    matInfectionIndex = matInfected./matTotal;
    matRelativeInfectionIndex = matInfectionIndex / nanmedian(matInfectionIndex(matNormalizationIndices));
    matLog2RelativeInfectionIndex = log2(matRelativeInfectionIndex);
    matLog2RelativeCellNumber = log2(matTotal / nanmedian(matTotal(matNormalizationIndices)));
    matZScores = (matLog2RelativeInfectionIndex-nanmean(matLog2RelativeCellNumber(matNormalizationIndices)))./nanstd(matLog2RelativeCellNumber(matNormalizationIndices));
    matMADs = (matLog2RelativeInfectionIndex-nanmedian(matLog2RelativeCellNumber(matNormalizationIndices)))./mad2(matLog2RelativeCellNumber(matNormalizationIndices));


    % create BASICDATA structure
    BASICDATA.TotalCells = matTotal;
    BASICDATA.InfectedCells = matInfected;
    BASICDATA.InfectionIndex = matInfectionIndex;   
    BASICDATA.RelativeInfectionIndex = matRelativeInfectionIndex;
    BASICDATA.Log2RelativeInfectionIndex = matLog2RelativeInfectionIndex;
    BASICDATA.Log2RelativeCellNumber = matLog2RelativeCellNumber;     
    
    BASICDATA.ZScore = matZScores;
    BASICDATA.MAD = matMADs;               

    BASICDATA.Images = matImagesPerWell;
    BASICDATA.GeneData = cellstrGenePerWell;
    BASICDATA.GeneID = cellstrGeneID;
    BASICDATA.OligoNumber = matOligonumber;
    BASICDATA.PlateNumber = matPlatenumber;
    BASICDATA.ReplicaNumber = matReplicanumber;
    BASICDATA.BatchNumber = matBatchnumber;
    BASICDATA.WellRow = matWellRow;
    BASICDATA.WellCol = matWellCol;                    

    BASICDATA.Path = strRootPath;
    BASICDATA.RawImages = matRawImagesPerWell;
    BASICDATA.ImageIndices = cellImageIndicesPerWell;


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % also add average values per well for anything, but let's start with
    % selected measurements:
    
    % create list of measurements in BATCH directory, might take a while
    cellMeasurementFileNames = CPdir(strRootPath);
    cellMeasurementFileNames = {cellMeasurementFileNames(~[cellMeasurementFileNames(:).isdir]).name}';
    
    % get list of intensity measurements, remove any non-intensity and
    % non-infection measurement files from list.
    cellMeasurementFileNames( ... 
        cellfun(@isempty,regexpi(cellMeasurementFileNames,'^Measurements_.*_Intensity_.*\.mat')) & ...
        cellfun(@isempty,regexpi(cellMeasurementFileNames,'^Measurements_.*_AreaShape\.mat')) & ...
        cellfun(@isempty,regexpi(cellMeasurementFileNames,'^Measurements_BIN_.*\.mat')) & ...
        cellfun(@isempty,regexpi(cellMeasurementFileNames,'^Measurements_Nuclei_BinCorrectedInfection\.mat')) ...
    ) = [];

    % remove Well thingies from Prisca
    cellMeasurementFileNames( ... 
        ~cellfun(@isempty,regexpi(cellMeasurementFileNames,'^Measurements_Well_.*\.mat')) ...
        ) = [];
   

    if ~isempty(cellMeasurementFileNames)
        fprintf('%s: generating well averages for %d measurements\n',mfilename,length(cellMeasurementFileNames))
        
        for iMeasurement = 1:length(cellMeasurementFileNames)
            
            % load measurement file 
            fprintf('%s: \tloading %s\n',mfilename,cellMeasurementFileNames{iMeasurement})            
            handlesTemp = LoadMeasurements(struct(),fullfile(strRootPath,cellMeasurementFileNames{iMeasurement}));
            
            strObjectName = char(fieldnames(handlesTemp.Measurements));
            strMeasurementNames = cellstr(char(fieldnames(handlesTemp.Measurements.(strObjectName))));
            % we need to get the measurement field name (not the features,
            % etc.) Let's go for the field that has the most data in it.
            matDataPerField = cellfun(@(x) numel(handlesTemp.Measurements.(strObjectName).(x)),strMeasurementNames);
            [foo, intMaxFieldIX] = max(matDataPerField);
            
            % correct error...
            if ~isempty(strfind(strMeasurementNames{intMaxFieldIX},'Features'))
                strMeasurementNames(intMaxFieldIX) = [];
                matDataPerField = cellfun(@(x) numel(handlesTemp.Measurements.(strObjectName).(x)),strMeasurementNames);
                [foo, intMaxFieldIX] = max(matDataPerField);                
            end
            
            % put the measurement data in it's own cell array
            cellMeasurementData = handlesTemp.Measurements.(strObjectName).(strMeasurementNames{intMaxFieldIX});
            
            % clear this
            handlesTemp = struct();
            
            fprintf('%s: \tgenerating well average data for %d of %d: Measurements_%s_%s\n',mfilename,iMeasurement,length(cellMeasurementFileNames),strObjectName,strMeasurementNames{intMaxFieldIX})
            
            % add fieldname, and put in cell array with average
            % measurements per well
            BASICDATA.(['Mean_',strObjectName,'_',strMeasurementNames{intMaxFieldIX}]) = cellfun(@(x) nanmean(cat(1,cellMeasurementData{x}),1), cellImageIndicesPerWell,'UniformOutput',false);
            
        end
        
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

    % plate name
    intPlateNumber = unique(matPlatenumber(find(~isnan(matPlatenumber))));
    intReplicanumber = unique(matReplicanumber(find(~isnan(matReplicanumber))));
    if not(isnumeric(intPlateNumber)) || isempty(intPlateNumber) || intPlateNumber < 0; intPlateNumber = 0; end
    if not(isnumeric(intReplicanumber)) || isempty(intReplicanumber) || intReplicanumber < 0; intReplicanumber = 0; end    
    if intPlateNumber == 0 || intReplicanumber == 0
        strTemp = strrep(strRootPath,'BATCH','');
        strFileNameBegin = getlastdir(strTemp);
    else
        strFileNameBegin = sprintf('CP%03.0f-%1d',intPlateNumber, intReplicanumber);        
    end
    
    try
        %%% NOTE THAT BASICDATA IS STORED IN strRootPath, NOT IN strOutputPath
        disp(sprintf('%s: processed %s',mfilename,strRootPath))
        save(fullfile(strRootPath,['BASICDATA_', strFileNameBegin, '.mat']),'BASICDATA');
        disp(sprintf('%s: saved data in %s',mfilename,char(fullfile(strRootPath,['BASICDATA_', strFileNameBegin, '.mat']))))
    catch
        disp(sprintf('%s: FAILED: storing BASICDATA.mat',mfilename))
    end

    
    
    
    try
        % write out .csv file
        
        % only include the wells that had any images:
        
        matIncludedRows = find(BASICDATA.RawImages>0);
        
        cellstrFieldNames = fieldnames(BASICDATA)';
        cellOutputData = cell(1,length(cellstrFieldNames));
        for field = 1:length(cellstrFieldNames)
            if strcmpi(cellstrFieldNames{field},'Path') || ...
                strcmpi(cellstrFieldNames{field},'ImageIndices')
                cellOutputData{1,field} = [];
            else
                cellOutputData{1,field} = BASICDATA.(char(cellstrFieldNames{field}))(matIncludedRows)';                            
            end
        end

        %%% ADD WELL NAME AS FIRST COLUMN
        matRows = cellstr(regexp(char(65:80),'\w','match'));
        matCols = regexp(sprintf('%.2d',1:24),'\d\d','match');        
        cellWellNames = {strcat(matRows(BASICDATA.WellRow(matIncludedRows))',matCols(BASICDATA.WellCol(matIncludedRows))')};
        cellstrFieldNames = ['WellName',cellstrFieldNames];
        cellOutputData = [cellWellNames,cellOutputData];
        
        writelists(cellOutputData,fullfile(strOutputPath,[strFileNameBegin, '_plate_overview.csv']),cellstrFieldNames,';','%f');
%         writelists(cellOutputData,fullfile(strOutputPath,[strFileNameBegin, '_plate_overview_MAC.csv']),cellstrFieldNames,'\t');
        disp(sprintf('%s: saved data in %s',mfilename, char(fullfile(strOutputPath,[strFileNameBegin, '_plate_overview.csv']))))        
    catch
        disp(sprintf('%s: FAILED: generating storing .csv file',mfilename))
    end

    try
        disp(sprintf('%s: generating plate overview.pdf',mfilename))
        plot_plate_overview(strRootPath, strOutputPath, [], strFileNameBegin)
    catch
        disp(sprintf('%s: FAILED: generating plate overview.pdf',mfilename))
    end
    
end