function Gather_CellTypeData_iBRAIN(strRootPath)
    % Performs the SVM classification for objects, creating
    % Measurements_Nuclei_CellTypeClassificationPerColumn
    % and Measurements_Nuclei_CellType_Overview

    % default input options (works nice for testing)
    if nargin==0
        strRootPath = 'Y:\Data\Users\Prisca\090217_A431_Tf_EEA1\090217_A431_Tf_EEA1_CP392-1ae\BATCH';

        strRootPath = npc(strRootPath);
    end
    
    % checks on input parameters
    boolInputPathExists = fileattrib(strRootPath);
    if not(boolInputPathExists)
        error('%s: could not read input strRootPath %s',mfilename,strRootPath)    
    else
        disp(sprintf('%s: starting on %s',mfilename,strRootPath))
    end


    %--------------------------------------------------------------------
    % Interphase, mitotic, apoptotic overviews for infection screens

    % finding and load/parse the latest classifications for the following svm
    % classes
    classes{1}='interphase'; %Interphase
    classes{2}='mitotic'; %Mitotic
    classes{3}='apoptotic'; %Apoptotic
    classes{4}='blob'; %Blob
    classes{5}='infection'; %SVM infected
    
    % loop over all latest infection screen classes, and load data
    disp(sprintf('%s: parsing latest svm files ',mfilename))
    handles = struct();
    class_list = cell(1,length(classes));
    numPositiveClassNumbers = nan(1,length(classes));
    for i = 1:length(classes)
        [handles, class_list{i}, numPositiveClassNumbers(i)] = load_latest_svm_file(handles, strRootPath, classes{i},'newest');
    end

    % gatherting the full list SVM
    full_class_list={};
    files=dir(sprintf('%s*SVM*.mat',strRootPath));
    index=0;
    for i=1:size(files,1)
        name=files(i).name;
        if not(isempty(strfind(lower(name),'measurements_svm_')));
            index=index+1;
            full_class_list{index}=name(18:end-4);
        end
    end

    % load the full classification data
    for class=1:length(full_class_list)
        disp(sprintf('%s: loading %s',mfilename,fullfile(strRootPath,['Measurements_SVM_',full_class_list{class},'.mat'])))
        handles = LoadMeasurements(handles,fullfile(strRootPath,['Measurements_SVM_',full_class_list{class},'.mat']));
    end

    % loading the image filenames to determine the total image number

    handles = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_Image_FileNames.mat'));
    handles2 = struct();
    handles3 = struct();
    for iImage = 1:length(handles.Measurements.Image.FileNames)
        if not(isempty(class_list{1})) && not(isempty(class_list{2})) && not(isempty(class_list{3})) && not(isempty(class_list{4}))
            % set celltype classification matrices such that 1 matches the
            % phenotype, and 0 does not match the phenotype.
            matInterphaseIndices = handles.Measurements.SVM.(class_list{1}){iImage} == numPositiveClassNumbers(1);
            matMitoticIndices = handles.Measurements.SVM.(class_list{2}){iImage} == numPositiveClassNumbers(2);
            matApoptoticIndices = handles.Measurements.SVM.(class_list{3}){iImage} == numPositiveClassNumbers(3);
            matBlobIndices = handles.Measurements.SVM.(class_list{4}){iImage} == numPositiveClassNumbers(4);
            matInfectedSVMIndices = handles.Measurements.SVM.(class_list{5}){iImage} == numPositiveClassNumbers(5);
            
            data=[matBlobIndices,matInterphaseIndices,matMitoticIndices,matApoptoticIndices];
            ind{1}=ismember(data,[0 0 0 0],'rows');% -> other
            ind{2}=ismember(data,[0 0 0 1],'rows');% -> Apoptotic
            ind{3}=ismember(data,[0 0 1 0],'rows');% -> Mitotic
            ind{4}=ismember(data,[0 0 1 1],'rows');% -> Mitotic
            ind{5}=ismember(data,[0 1 0 0],'rows');% -> Interphase
            ind{6}=ismember(data,[0 1 0 1],'rows');% -> Interphase
            ind{7}=ismember(data,[0 1 1 0],'rows');% -> Interphase
            ind{8}=ismember(data,[0 1 1 1],'rows');% -> Interphase

            ind{9}=ismember(data,[1 0 0 0],'rows');% -> blob/other
            ind{10}=ismember(data,[1 0 0 1],'rows');% -> blob/other
            ind{11}=ismember(data,[1 0 1 0],'rows');% -> blob/other
            ind{12}=ismember(data,[1 0 1 1],'rows');% -> blob/other
            ind{13}=ismember(data,[1 1 0 0],'rows');% -> blob/other
            ind{14}=ismember(data,[1 1 0 1],'rows');% -> blob/other
            ind{15}=ismember(data,[1 1 1 0],'rows');% -> blob/other
            ind{16}=ismember(data,[1 1 1 1],'rows');% -> blob/other

            matInterphaseIndices=ind{5}|ind{6}|ind{7}|ind{8};
            matMitoticIndices=ind{3}|ind{4};
            matApoptoticIndices=ind{2};
            matOthers=ind{1}|ind{9}|ind{10}|ind{11}|ind{12}|ind{13}|ind{14}|ind{15}|ind{16};
            matInfectedSVM=(ind{2}|ind{3}|ind{4}|ind{5}|ind{6}|ind{7}|ind{8}) & ismember(matInfectedSVMIndices,1,'rows');
            
            handles2.Measurements.Nuclei.Apoptotic{iImage} = matApoptoticIndices;
            handles2.Measurements.Nuclei.Interphase{iImage} = matInterphaseIndices;
            handles2.Measurements.Nuclei.Mitotic{iImage} = matMitoticIndices;
            handles2.Measurements.Nuclei.Others{iImage} = matOthers;
            handles2.Measurements.Nuclei.InfectedSVM{iImage} = matInfectedSVM;

            if (sum(matApoptoticIndices) + sum(matInterphaseIndices) + sum(matMitoticIndices) + sum(matOthers)) ~= length(matOthers)
                error('OOHHH NOO, DOESN''T ADD UP!!!')
            end

            SVM_Set_Available=1;
        else
            SVM_Set_Available=0;
        end

        % Gathering the full SVM listing
        index=0;
        for class=1:length(full_class_list)
            sub_class_names=handles.Measurements.SVM.([full_class_list{class},'_Features']);
            for sub_class=1:length(sub_class_names)
                field_name=['SVM_',full_class_list{class},'_',strrep(strrep(sub_class_names{sub_class},'-','_'),' ','_')];
                handles3.(field_name)(iImage)=sum(handles.Measurements.SVM.(full_class_list{class}){iImage}==sub_class);
                index=index+1;
                class_index(index)=class; %this is needed later
            end
        end

    end

    % store handles2 as handles in Measurements_Nuclei_CellTypeClassificationPerColumn.mat
    clear handles
    handles = handles2;

    if SVM_Set_Available
        disp('SVM set (interphase, mitotic, apoptotic, blob) is available');
        disp(sprintf('SAVING %s',fullfile(strRootPath,'Measurements_Nuclei_CellTypeClassificationPerColumn.mat')))
        save(fullfile(strRootPath,'Measurements_Nuclei_CellTypeClassificationPerColumn.mat'),'handles')
    else
        disp('SVM set (interphase, mitotic, apoptotic, blob) is NOT available');
    end

    %--------------------------------------------------------------------
    % CellType Gathering

    full_SVM_names=fieldnames(handles3);

    % load plate BASICDATA
    load(char(SearchTargetFolders(strRootPath,'BASICDATA_*.mat')));

    handles = struct();
    
    if SVM_Set_Available
        % standard cell type SVM results
        handles = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_Nuclei_CellTypeClassificationPerColumn.mat'));
    end
      
    % cell intensity information
    cellMeasurementFiles = SearchTargetFolders(strRootPath,'Measurements_Cells_Intensity_*.mat');
    strIntensityObject = regexp(cellMeasurementFiles{1},'.*_(.*Cells)','tokens');
    strIntensityObject = char(strIntensityObject{1});
    if ~isempty(cellMeasurementFiles)
        for i=1:length(cellMeasurementFiles)
            handles = LoadMeasurements(handles,cellMeasurementFiles{i});
        end
    end
    
    % nucleus size information
    cellMeasurementFiles = SearchTargetFolders(strRootPath,'Measurements_*Nuclei_AreaShape.mat');
    strAreaSizeObject = regexp(cellMeasurementFiles{1},'.*_(.*Nuclei)','tokens');
    strAreaSizeObject = char(strAreaSizeObject{1});
    if ~isempty(cellMeasurementFiles)
        handles = LoadMeasurements(handles,cellMeasurementFiles{1});
    end
    
    % EDGE
    cellMeasurementFiles = SearchTargetFolders(strRootPath,'Measurements_*Nuclei_GridNucleiEdges.mat');
    if ~isempty(cellMeasurementFiles)
        handles = LoadMeasurements(handles,cellMeasurementFiles{1});
    end
    
    % LCD
    cellMeasurementFiles = SearchTargetFolders(strRootPath,'Measurements_*Nuclei_GridNucleiCount.mat');
    if ~isempty(cellMeasurementFiles)
        strDensityEdgeObject = regexp(cellMeasurementFiles{1},'.*_(.*Nuclei)','tokens');
        strDensityEdgeObject = char(strDensityEdgeObject{1});
        handles = LoadMeasurements(handles,cellMeasurementFiles{1});
    end


    % well row and column information
    BASICDATA_CellType.WellRow=BASICDATA.WellRow;
    BASICDATA_CellType.WellCol=BASICDATA.WellCol;

    for well=1:size(BASICDATA.WellRow,2)
        
        % get the image indices per well
        matImageIndicesPerWell=BASICDATA.ImageIndices{1,well};
       
        % look up mean of cell intensities for all channels
        strChannelNames=fieldnames(handles.Measurements.(strIntensityObject));
        channel_index=0;
        for channel=1:length(strChannelNames)
            if isempty(strfind(strChannelNames{channel},'Features'))
                channel_index=channel_index+1;
                strChannelColors{channel_index}=strChannelNames{channel};
                foo=regexp(strChannelColors{channel_index},'^.*_.*([A-Z].*)','tokens');
                strShortName{channel_index}=foo{1};        
            end
        end
       
        for channel=1:length(strChannelColors)
            CellIntensityData=cat(1,handles.Measurements.(strIntensityObject).(strChannelColors{channel}){matImageIndicesPerWell});
            if ~(isempty(CellIntensityData))
                CellIntensityMean.(strShortName{channel}{1})=nanmean(CellIntensityData(:,2));
            else
                CellIntensityMean.(strShortName{channel}{1})=NaN;
            end
            
            BASICDATA_CellType.(['Intensity_Mean_',strShortName{channel}{1}])(1,well)=CellIntensityMean.(strShortName{channel}{1});        
        end
     
        
        % following bit only if SVM_Set_Available is true
        if SVM_Set_Available        

            % gather Mitotic, Apoptotic, Interphase & Others numbers per well
            Mitotic_number=nansum(cat(1,handles.Measurements.Nuclei.Mitotic{matImageIndicesPerWell}));
            Apoptotic_number=nansum(cat(1,handles.Measurements.Nuclei.Apoptotic{matImageIndicesPerWell}));
            Interphase_number=nansum(cat(1,handles.Measurements.Nuclei.Interphase{matImageIndicesPerWell}));
            Others_number=nansum(cat(1,handles.Measurements.Nuclei.Others{matImageIndicesPerWell}));
            InfectedSVM_number=nansum(cat(1,handles.Measurements.Nuclei.InfectedSVM{matImageIndicesPerWell}));

            % normalization factors, either all included cells (i.e. Cell_number)
            % or all detected objects, including all discarded objects (i.e.
            % Total_number)
            Cell_number=Mitotic_number+Apoptotic_number+Interphase_number;
            Total_number=Cell_number+Others_number;

            % look up mean and std of nucleus size (total area)
            CellSizeData=cat(1,handles.Measurements.(strAreaSizeObject).AreaShape{matImageIndicesPerWell});
            if ~(isempty(CellSizeData))
                CellSizeMean=nanmean(CellSizeData(:,1));
                CellSizeStd=nanstd(CellSizeData(:,1));
            else
                CellSizeMean=NaN;
                CellSizeStd=NaN;
            end
            
            % get mean + std local cell density
            try
                LocalCellDensityData=cat(1,handles.Measurements.(strDensityEdgeObject).GridNucleiCount{matImageIndicesPerWell});
                LocalCellDensityMean=nanmean(LocalCellDensityData);
                LocalCellDensityStd=nanstd(LocalCellDensityData);
            catch foo
                LocalCellDensityMean=NaN;
                LocalCellDensityStd=NaN;
            end

            % get the edge-index
            try
                EdgeData=cat(1,handles.Measurements.(strDensityEdgeObject).GridNucleiEdges{matImageIndicesPerWell});
                EdgeIndex=nanmean(EdgeData);
            catch foo
                EdgeIndex=NaN;
            end

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
            BASICDATA_CellType.InfectedSVM_number(1,well)=InfectedSVM_number;
            BASICDATA_CellType.Others_number(1,well)=Others_number;
            BASICDATA_CellType.Cell_number(1,well)=Cell_number;
            BASICDATA_CellType.Total_number(1,well)=Total_number;

            % Standard SVM celltype indices
            BASICDATA_CellType.Others_index(1,well) = Others_number / Total_number;
            BASICDATA_CellType.Mitotic_index(1,well) = Mitotic_number / Cell_number;
            BASICDATA_CellType.Apoptotic_index(1,well) = Apoptotic_number / Cell_number;
            BASICDATA_CellType.Interphase_index(1,well) = Interphase_number / Cell_number;
            BASICDATA_CellType.InfectedSVM_index(1,well) = InfectedSVM_number / Cell_number;
            BASICDATA_CellType.Others_index(1,well) = Others_number / Total_number;    
        end
        
        % Create numbers per SVM for all available SVMs
        Total_Cells=zeros(1,length(full_SVM_names));
        for class=1:length(full_SVM_names);
            data=0;
            class_name=full_SVM_names{class};
            for image=1:BASICDATA.RawImages(well)
                data=data+handles3.(class_name)(BASICDATA.ImageIndices{1,well}(image));
            end       
            BASICDATA_CellType.([class_name,'_number'])(1,well)=data;
            BASICDATA_CellType.([class_name,'_index'])(1,well)=data;
            Cells(class)=data;
        end
        for class=1:length(full_SVM_names)
            c=class_index(class);
            class_name=full_SVM_names{class};
            total_cells_in_subclasses=sum(Cells(class_index==c));
            BASICDATA_CellType.([class_name,'_index'])(1,well)=BASICDATA_CellType.([class_name,'_index'])(1,well)/total_cells_in_subclasses;
            BASICDATA_CellType.([class_name,'_index'])(1,well);
        end
        
        
    end
    % GeneIDs
    indi = cellfun(@isnumeric,BASICDATA.GeneID) & BASICDATA.Images>0;
    
    for channel=1:length(strChannelColors)
        BASICDATA_CellType.(['ZScore_Log2_Intensity_Mean_',strShortName{channel}{1}])=...
            zscore_log2_normalize(BASICDATA_CellType.(['Intensity_Mean_',strShortName{channel}{1}]),indi);
    end

    if SVM_Set_Available
        % Well indices to do the normalization on, those with images and with valid


        % Z-Score normalization of all fields against specified indices
        % REMOVE FROM THIS CODE?!?!
        BASICDATA_CellType.ZScore_Log2_Others_index=zscore_log2_normalize(BASICDATA_CellType.Others_index,indi);
        BASICDATA_CellType.ZScore_Log2_Mitotic_index=zscore_log2_normalize(BASICDATA_CellType.Mitotic_index,indi);
        BASICDATA_CellType.ZScore_Log2_Apoptotic_index=zscore_log2_normalize(BASICDATA_CellType.Apoptotic_index,indi);
        BASICDATA_CellType.ZScore_Log2_Interphase_index=zscore_log2_normalize(BASICDATA_CellType.Interphase_index,indi);
        BASICDATA_CellType.ZScore_Log2_InfectedSVM_index=zscore_log2_normalize(BASICDATA_CellType.InfectedSVM_index,indi);
        BASICDATA_CellType.ZScore_Log2_Cell_index=zscore_log2_normalize(BASICDATA_CellType.Cell_number,indi);
        BASICDATA_CellType.ZScore_Log2_Mean_Cell_Size=zscore_log2_normalize(BASICDATA_CellType.CellSize_Mean,indi);
        BASICDATA_CellType.ZScore_Log2_Mean_Local_Cell_Density=zscore_log2_normalize(BASICDATA_CellType.LocalCellDensity_Mean,indi);
        BASICDATA_CellType.ZScore_Log2_Edge_Index=zscore_log2_normalize(BASICDATA_CellType.EdgeIndex,indi);
        BASICDATA_CellType.ZScore_Log2_Relative_Cell_Number=zscore_log2_normalize(BASICDATA.TotalCells / nanmedian(BASICDATA.TotalCells,2),indi);
    end
    
    % saving data
    disp(sprintf('SAVING %s',fullfile(strRootPath,'Measurements_CellType_Overview.mat')))
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