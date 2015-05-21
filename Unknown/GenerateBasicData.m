function generate_basic_data(strRootPath, strOutputPath)

    warning off all

    if nargin == 1
        strOutputPath = strRootPath;
    end


    BASICDATA = struct();
    BASICDATA.TotalCells = [];
    BASICDATA.InfectedCells = [];
    BASICDATA.InfectionIndex = [];
    BASICDATA.RelativeInfectionIndex = [];
    BASICDATA.Log2RelativeInfectionIndex = [];
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

    
    if nargin == 0
        strRootPath = '/Volumes/share-2-$/Data/Users/VSV_DG/070325_VSV_DG_batch3_CP046-1ab/BATCH/';
    end

    disp(sprintf('loading data from %s',strRootPath))    
    
    handles = struct();
    handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_FileNames.mat']);
    handles = LoadMeasurements(handles, [strRootPath,'Measurements_Nuclei_VirusScreen_ClassicalInfection_Overview2.mat']);
    handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_ObjectCount.mat']);
    handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_OutOfFocus.mat']);   
    handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_RescaledBlueSpectrum.mat']);        
    
    [matTotal, matInfected, matImagesPerWell, cellstrGenePerWell, matOligonumber, matPlatenumber, matReplicanumber, matBatchnumber, matCtrlInfectionIndices, matWellRow, matWellCol, matNoVirusCtrlInfectionIndices, cellstrGeneID] = ConvertHandlesTo384DG(strRootPath, handles);

    % set 0 infected to 1 to prevent -inf problems...
    matInfected(find(matInfected == 0)) = 1;

    matInfectionIndex = matInfected./matTotal;
    matRelativeInfectionIndex = matInfectionIndex / nanmedian(matCtrlInfectionIndices);
    matLog2RelativeInfectionIndex = log2(matRelativeInfectionIndex);

    matCtrlRelativeInfectionIndex = matCtrlInfectionIndices / nanmedian(matCtrlInfectionIndices);
    matCtrlLog2RelativeInfectionIndex = log2(matCtrlRelativeInfectionIndex);

    matZScores = (matLog2RelativeInfectionIndex-mean2(matCtrlLog2RelativeInfectionIndex))./std2(matCtrlLog2RelativeInfectionIndex);
    matMADs = (matLog2RelativeInfectionIndex-median2(matCtrlLog2RelativeInfectionIndex))./mad2(matCtrlLog2RelativeInfectionIndex);

    %                     [matZScores, matMADs] = bscore2(matLog2RelativeInfectionIndex)

    if isempty(BASICDATA.TotalCells)
        BASICDATA.TotalCells = matTotal;
        BASICDATA.InfectedCells = matInfected;
        BASICDATA.InfectionIndex = matInfectionIndex;   
        BASICDATA.RelativeInfectionIndex = matRelativeInfectionIndex;
        BASICDATA.Log2RelativeInfectionIndex = matLog2RelativeInfectionIndex;
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

    else
        BASICDATA.TotalCells = [BASICDATA.TotalCells; matTotal];
        BASICDATA.InfectedCells = [BASICDATA.InfectedCells; matInfected];
        BASICDATA.InfectionIndex = [BASICDATA.InfectionIndex; matInfectionIndex];
        BASICDATA.RelativeInfectionIndex = [BASICDATA.RelativeInfectionIndex; matRelativeInfectionIndex];
        BASICDATA.Log2RelativeInfectionIndex = [BASICDATA.Log2RelativeInfectionIndex; matLog2RelativeInfectionIndex];
        BASICDATA.ZScore = [BASICDATA.ZScore; matZScores];
        BASICDATA.MAD = [BASICDATA.MAD; matMADs];

        BASICDATA.Images = [BASICDATA.Images; matImagesPerWell];
        BASICDATA.GeneData = [BASICDATA.GeneData; cellstrGenePerWell];
        BASICDATA.GeneID = [BASICDATA.GeneID; cellstrGeneID];
        BASICDATA.OligoNumber = [BASICDATA.OligoNumber; matOligonumber];
        BASICDATA.PlateNumber = [BASICDATA.PlateNumber; matPlatenumber];
        BASICDATA.ReplicaNumber = [BASICDATA.ReplicaNumber; matReplicanumber];
        BASICDATA.BatchNumber = [BASICDATA.BatchNumber; matBatchnumber];
        BASICDATA.WellRow = [BASICDATA.WellRow; matWellRow];
        BASICDATA.WellCol = [BASICDATA.WellCol; matWellCol];

    end  

    % plate name
    intPlateNumber = unique(matPlatenumber(find(~isnan(matPlatenumber))));
    intReplicanumber = unique(matReplicanumber(find(~isnan(matReplicanumber))));
    if not(isnumeric(intPlateNumber)) || isempty(intPlateNumber) || intPlateNumber < 0; intPlateNumber = 0; end
    if not(isnumeric(intReplicanumber)) || isempty(intReplicanumber) || intReplicanumber < 0; intReplicanumber = 0; end    
    strFileNameBegin = sprintf('CP%03.0f-%1d_',intPlateNumber, intReplicanumber);
    
    %%% NOTE THAT BASICDATA IS STORED IN strRootPath, NOT IN strOutputPath
    disp(sprintf('processed %s',strRootPath))
    save(fullfile(strRootPath,['BASICDATA_', strFileNameBegin, '.mat']),'BASICDATA');
    disp(sprintf('saved data in %s',char(fullfile(strRootPath,['BASICDATA_', strFileNameBegin, '.mat']))))
    
    disp('generating plate overview.pdf')
    plot_plate_overview(strRootPath, strOutputPath, handles)
    
    % write out .csv file
    cellstrFieldNames = fieldnames(BASICDATA)';
    cellOutputData = cell(1,length(cellstrFieldNames));
    for field = 1:length(cellstrFieldNames)
        cellOutputData{1,field} = BASICDATA.(char(cellstrFieldNames{field}))';            
    end
    writelists(cellOutputData,fullfile(strOutputPath,[strFileNameBegin, 'plate_overview.csv']),cellstrFieldNames,';');
    disp(sprintf('saved data in %s',char(fullfile(strOutputPath,[strFileNameBegin, 'plate_overview.csv']))))    
    
end