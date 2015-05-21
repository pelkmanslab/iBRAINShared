function Create_CellTypeOverview_iBRAIN(strRootPath)
    % default input options (works nice for testing)
    if nargin==0
        strRootPath = npc('/BIOL/imsb/fs2/bio3/bio3/Data/Users/SV40_DG/20080419033214_M1_080418_SV40_DG_batch2_CP001-1dh/BATCH/');
    end

    % checks on input parameters
    boolInputPathExists = fileattrib(strRootPath);
    if not(boolInputPathExists)
        error('%s: could not read input strRootPath %s',mfilename,strRootPath)    
    else
        disp(sprintf('%s: CREATING CELL TYPE OVERVIEW \n  %s \n ',mfilename,strRootPath))
    end

    % load plate BASICDATA
    load(char(SearchTargetFolders(strRootPath,'BASICDATA_*.mat')));

    handles = struct();
    % standard cell type SVM results
    handles = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_Nuclei_CellTypeClassificationPerColumn.mat'));
    % nucleus size information
    handles = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_Nuclei_AreaShape.mat'));
    % local cell density and cell colony edge information
    try
        handles = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_Nuclei_GridNucleiEdges.mat'));
        handles = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_Nuclei_GridNucleiCount.mat'));
        strDensityEdgeObject = 'Nuclei';
    catch foo
        handles = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_OrigNuclei_GridNucleiEdges.mat'));
        handles = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_OrigNuclei_GridNucleiCount.mat'));
        strDensityEdgeObject = 'OrigNuclei';
    end

    % well row and column information
    BASICDATA_CellType.WellRow=BASICDATA.WellRow;
    BASICDATA_CellType.WellCol=BASICDATA.WellCol;

    for well=1:size(BASICDATA.WellRow,2)

        % get the image indices per well
        matImageIndicesPerWell=BASICDATA.ImageIndices{1,well};

        % gather Mitotic, Apoptotic, Interphase & Others numbers per well
        Mitotic_number=nansum(cat(1,handles.Measurements.Nuclei.Mitotic{matImageIndicesPerWell}));
        Apoptotic_number=nansum(cat(1,handles.Measurements.Nuclei.Apoptotic{matImageIndicesPerWell}));
        Interphase_number=nansum(cat(1,handles.Measurements.Nuclei.Interphase{matImageIndicesPerWell}));
        Others_number=nansum(cat(1,handles.Measurements.Nuclei.Others{matImageIndicesPerWell}));

        % normalization factors, either all included cells (i.e. Cell_number)
        % or all detected objects, including all discarded objects (i.e.
        % Total_number)
        Cell_number=Mitotic_number+Apoptotic_number+Interphase_number;
        Total_number=Cell_number+Others_number;

        % look up mean and std of nucleus size (total area)
        CellSizeData=cat(1,handles.Measurements.Nuclei.AreaShape{matImageIndicesPerWell});
        CellSizeMean=nanmean(CellSizeData(:,1));
        CellSizeStd=nanstd(CellSizeData(:,1));

        % get mean + std local cell density
        LocalCellDensityData=cat(1,handles.Measurements.(strDensityEdgeObject).GridNucleiCount{matImageIndicesPerWell});
        LocalCellDensityMean=nanmean(LocalCellDensityData(:,1));
        LocalCellDensityStd=nanstd(LocalCellDensityData(:,1));

        % get the edge-index
        EdgeData=cat(1,handles.Measurements.(strDensityEdgeObject).GridNucleiEdges{matImageIndicesPerWell});
        EdgeIndex=nanmean(EdgeData(:,1));

        % add numbers to BASICDATA_CellType
        BASICDATA_CellType.CellSize_Mean(1,well) = CellSizeMean;
        BASICDATA_CellType.CellSize_Stdev(1,well) = CellSizeStd;
        BASICDATA_CellType.LocalCellDensity_Mean(1,well) = LocalCellDensityMean;
        BASICDATA_CellType.LocalCellDensity_Stdev(1,well) = LocalCellDensityStd;
        BASICDATA_CellType.EdgeIndex(1,well) = EdgeIndex;

        % Standard SVM celltype numbers
        BASICDATA_CellType.Mitotic_number(1,well)=Mitotic_number;
        BASICDATA_CellType.Apoptotic_number(1,well)=Apoptotic_number;
        BASICDATA_CellType.Interphase_number(1,well)=Interphase_number;
        BASICDATA_CellType.Others_number(1,well)=Others_number;
        BASICDATA_CellType.Cell_number(1,well)=Cell_number;
        BASICDATA_CellType.Total_number(1,well)=Total_number;

        % Standard SVM celltype indices
        BASICDATA_CellType.Others_index(1,well) = Others_number / Total_number;
        BASICDATA_CellType.Mitotic_index(1,well) = Mitotic_number / Cell_number;
        BASICDATA_CellType.Apoptotic_index(1,well) = Apoptotic_number / Cell_number;
        BASICDATA_CellType.Interphase_index(1,well) = Interphase_number / Cell_number;
        BASICDATA_CellType.Others_index(1,well) = Others_number / Total_number;    

    end

    % indi = BASICDATA.WellCol>2 & BASICDATA.WellCol<23;
    % Well indices to do the normalization on, those with images and with valid
    % GeneIDs
    indi = cellfun(@isnumeric,BASICDATA.GeneID) & BASICDATA.Images>0;

    % Z-Score normalization of all fields against specified indices
    BASICDATA_CellType.ZScore_Log2_Others_index=zscore_log2_normalize(BASICDATA_CellType.Others_index,indi);
    BASICDATA_CellType.ZScore_Log2_Mitotic_index=zscore_log2_normalize(BASICDATA_CellType.Mitotic_index,indi);
    BASICDATA_CellType.ZScore_Log2_Apoptotic_index=zscore_log2_normalize(BASICDATA_CellType.Apoptotic_index,indi);
    BASICDATA_CellType.ZScore_Log2_Interphase_index=zscore_log2_normalize(BASICDATA_CellType.Interphase_number,indi);
    BASICDATA_CellType.ZScore_Log2_Cell_index=zscore_log2_normalize(BASICDATA_CellType.Cell_number,indi);
    BASICDATA_CellType.ZScore_Log2_Mean_Cell_Size=zscore_log2_normalize(BASICDATA_CellType.CellSize_Mean,indi);
    BASICDATA_CellType.ZScore_Log2_Mean_Local_Cell_Density=zscore_log2_normalize(BASICDATA_CellType.LocalCellDensity_Mean,indi);
    BASICDATA_CellType.ZScore_Log2_Edge_Index=zscore_log2_normalize(BASICDATA_CellType.EdgeIndex,indi);
    BASICDATA_CellType.ZScore_Log2_Relative_Cell_Number=zscore_log2_normalize(BASICDATA.Log2RelativeCellNumber,indi);

    % saving data
    disp(sprintf('SAVING %s',fullfile(strRootPath,'Measurements_Nuclei_CellType_Overview.mat')))
    save(fullfile(strRootPath,'Measurements_Nuclei_CellType_Overview.mat'),'BASICDATA_CellType')


end

% zscore log2 normalize data against certain indices
function zscore_log2_data = zscore_log2_normalize(data,indi)
    data = log2(data); % log2 transformation
    data(isinf(data))=NaN; % convert Infs to NaNs
    data=data-nanmean(data(indi)); % substract mean
    data=data/nanstd(data(indi)); % divide by standard deviation
    zscore_log2_data = data; % return results
end