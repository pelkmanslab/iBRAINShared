function Gather_CellTypeData_iBRAIN2(strRootPath)
% Performs the SVM classification for objects, creating
% Measurements_Nuclei_CellTypeClassificationPerColumn
% and Measurements_Nuclei_CellType_Overview

% default input options (works nice for testing)
if nargin==0
    strRootPath = 'Z:\Data\Users\50K_final_reanalysis\Ad3_MZ_NEW\070606_Ad3_50k_MZ_2_3_CP072-1ac\BATCH';

    strRootPath = npc(strRootPath);
end

% checks on input parameters
boolInputPathExists = fileattrib(strRootPath);
if not(boolInputPathExists)
    error('%s: could not read input strRootPath %s',mfilename,strRootPath)
else
    disp(sprintf('%s: starting on %s',mfilename,strRootPath))
end


%--------------------------------------------------------------------------------------------------------------------------------------------
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
files=dir(sprintf('%s%s*SVM*.mat',strRootPath,filesep));
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

handles0 = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_Image_FileNames.mat'));
handles  = handles0; % handles0 is needed later in CellType Gathering
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

clear handles
clear handles2


%-------------------------------------------------------------------------------------------------------------------------------------------------
% CellType Gathering

full_SVM_names=fieldnames(handles3);

% load plate BASICDATA
load(char(SearchTargetFolders(strRootPath,'BASICDATA_*.mat')));

if SVM_Set_Available
    % standard cell type SVM results
    handles0 = LoadMeasurements(handles0,fullfile(strRootPath,'Measurements_Nuclei_CellTypeClassificationPerColumn.mat'));
end

% nucleus size information
cellMeasurementFiles = SearchTargetFolders(strRootPath,'Measurements_*Nuclei_AreaShape.mat');
strAreaSizeObject = regexp(cellMeasurementFiles{1},'.*_(.*Nuclei)','tokens');
strAreaSizeObject = char(strAreaSizeObject{1});
if ~isempty(cellMeasurementFiles)
    handles0 = LoadMeasurements(handles0,cellMeasurementFiles{1});
end

% EDGE
cellMeasurementFiles = SearchTargetFolders(strRootPath,'Measurements_*Nuclei_GridNucleiEdges.mat');
if ~isempty(cellMeasurementFiles)
    handles0 = LoadMeasurements(handles0,cellMeasurementFiles{1});
end

% LCD
cellMeasurementFiles = SearchTargetFolders(strRootPath,'Measurements_*Nuclei_GridNucleiCount.mat');
if ~isempty(cellMeasurementFiles)
    strDensityEdgeObject = regexp(cellMeasurementFiles{1},'.*_(.*Nuclei)_GridNucleiCount','tokens');
    strDensityEdgeObject = char(strDensityEdgeObject{1});
    handles0 = LoadMeasurements(handles0,cellMeasurementFiles{1});
end

% OBJECT COUNT
cellMeasurementFiles = SearchTargetFolders(strRootPath,'Measurements_*Image_ObjectCount.mat');
if ~isempty(cellMeasurementFiles)
    handles0 = LoadMeasurements(handles0,cellMeasurementFiles{1});
end

% well row and column information
BASICDATA_CellType.WellRow=BASICDATA.WellRow;
BASICDATA_CellType.WellCol=BASICDATA.WellCol;

for well=1:size(BASICDATA.WellRow,2)
    % get the image indices per well
    matImageIndicesPerWell=BASICDATA.ImageIndices{1,well};
    
    % removing images that do not have any objects (a quality control step to avoid crashes etc)
    object_count=cat(1,handles0.Measurements.Image.ObjectCount{matImageIndicesPerWell});
    if not(isempty(object_count))
        object_count=object_count(:,1);
        matImageIndicesPerWell(object_count==0)=[];
    end
    
    if SVM_Set_Available
        images=length(matImageIndicesPerWell);
        
        % How big percentage of cells are in different images in the well
        Cell_Number_Normalization_Factors=1/images.*ones(1,images);

        % First checking which images might be out-of-focus or otherwise bad
        good_images=[];
        for i=1:length(matImageIndicesPerWell)
            good_images(i)=sum(handles0.Measurements.Nuclei.Others{matImageIndicesPerWell(i)})./length(handles0.Measurements.Nuclei.Others{matImageIndicesPerWell(i)});
        end
        good_images=good_images<0.75; % Discarding all images (only for total cell number readout) that have other cells more than 75%

        % gathering non SVM data first
        CellSizeData=cat(1,handles0.Measurements.(strAreaSizeObject).AreaShape{matImageIndicesPerWell});
        LocalCellDensityData=cat(1,handles0.Measurements.(strDensityEdgeObject).GridNucleiCount{matImageIndicesPerWell});
        EdgeData=cat(1,handles0.Measurements.(strDensityEdgeObject).GridNucleiEdges{matImageIndicesPerWell});
        good_cells=not(cat(1,handles0.Measurements.Nuclei.Others{matImageIndicesPerWell}));
        interphase_cells=cat(1,handles0.Measurements.Nuclei.Interphase{matImageIndicesPerWell});

        % no cells in well
        if isempty(CellSizeData)
            CellSizeData=NaN;
            LocalCellDensityData=NaN;
            EdgeData=NaN;
        end

        % Gathering Mitotic, Apoptotic, Interphase & Others numbers per well
        % All images are used, even if they are out-of-focus: normalization is done with total good cell number.
        Mitotic_number=nansum(cat(1,handles0.Measurements.Nuclei.Mitotic{matImageIndicesPerWell}));
        Apoptotic_number=nansum(cat(1,handles0.Measurements.Nuclei.Apoptotic{matImageIndicesPerWell}));
        Interphase_number=nansum(cat(1,handles0.Measurements.Nuclei.Interphase{matImageIndicesPerWell}));
        Others_number=nansum(cat(1,handles0.Measurements.Nuclei.Others{matImageIndicesPerWell}));
        InfectedSVM_number=nansum(cat(1,handles0.Measurements.Nuclei.InfectedSVM{matImageIndicesPerWell}));

        % all good cells (Cell_number)
        Cell_number=Mitotic_number+Apoptotic_number+Interphase_number;

        % Bad image normalized total cell number (Total_number)
        Total_number=length(cat(1,handles0.Measurements.Nuclei.Mitotic{matImageIndicesPerWell(good_images)}));
        Total_number=Total_number+round(sum(Total_number.*Cell_Number_Normalization_Factors(not(good_images))));

        % Total detected objects (including all crap cells)
        Total_number2=length(cat(1,handles0.Measurements.Nuclei.Mitotic{matImageIndicesPerWell}));

        % Mean of interphase nucleus size (total area)
        try % REMOVE THE TRY-CATCH WHEN THE "EDGE 1-Cell bug has been fixed"
            CellSizeMean=nanmean(CellSizeData(interphase_cells,1));
        catch
            CellSizeMean=NaN;
        end

        % Mean local cell density. Using all images and only good nuclei.
        try
            LocalCellDensityMean=nanmean(LocalCellDensityData(good_cells));
        catch
            LocalCellDensityMean=NaN;
        end

        % Edge-index. Using all images and only good nuclei.
        try
            EdgeIndex=nanmean(EdgeData(good_cells));
        catch
            EdgeIndex=NaN;
        end

        % adding numbers to BASICDATA_CellType
        BASICDATA_CellType.CellSize_Mean(1,well) = CellSizeMean;
        BASICDATA_CellType.LocalCellDensity_Mean(1,well) = LocalCellDensityMean;
        BASICDATA_CellType.Edge_index(1,well) = EdgeIndex;
        BASICDATA_CellType.Out_of_focus_images(1,well) = 9-sum(good_images);

        % Standard SVM celltype numbers
        BASICDATA_CellType.Mitotic_number(1,well)=Mitotic_number;
        BASICDATA_CellType.Apoptotic_number(1,well)=Apoptotic_number;
        BASICDATA_CellType.Interphase_number(1,well)=Interphase_number;
        BASICDATA_CellType.InfectedSVM_number(1,well)=InfectedSVM_number;
        BASICDATA_CellType.Others_number(1,well)=Others_number;
        BASICDATA_CellType.Cells_good(1,well)=Cell_number;
        BASICDATA_CellType.Cells_normalized(1,well)=Total_number;
        BASICDATA_CellType.Cells_allobjects(1,well)=Total_number2;

        % Standard SVM celltype indices
        BASICDATA_CellType.Others_index(1,well) = Others_number / Total_number2;
        BASICDATA_CellType.Mitotic_index(1,well) = Mitotic_number / Cell_number;
        BASICDATA_CellType.Apoptotic_index(1,well) = Apoptotic_number / Cell_number;
        BASICDATA_CellType.Interphase_index(1,well) = Interphase_number / Cell_number;
        BASICDATA_CellType.InfectedSVM_index(1,well) = InfectedSVM_number / Cell_number;

        % celltype indices without any clean-up steps (Absolute numbers can be get by multiplying with Cells_allobjects)
        BASICDATA_CellType.LocalCellDensity_Mean_unclean(1,well) = nanmean(LocalCellDensityData);
        BASICDATA_CellType.Edge_index_unclean(1,well) = nanmean(EdgeData);
        BASICDATA_CellType.CellSize_Mean_unclean(1,well) = nanmean(CellSizeData(:,1));
        BASICDATA_CellType.Interphase_index_unclean(1,well) = sum(cat(1,handles0.Measurements.SVM.(class_list{1}){matImageIndicesPerWell}) == numPositiveClassNumbers(1))./Total_number2;
        BASICDATA_CellType.Mitotic_index_unclean(1,well) = sum(cat(1,handles0.Measurements.SVM.(class_list{2}){matImageIndicesPerWell}) == numPositiveClassNumbers(2))./Total_number2;
        BASICDATA_CellType.Apoptotic_index_unclean(1,well) = sum(cat(1,handles0.Measurements.SVM.(class_list{3}){matImageIndicesPerWell}) == numPositiveClassNumbers(3))./Total_number2;
        BASICDATA_CellType.InfectedSVM_index_unclean(1,well) = sum(cat(1,handles0.Measurements.SVM.(class_list{5}){matImageIndicesPerWell}) == numPositiveClassNumbers(5))./Total_number2;

    end

    %Full SVM numbers
    for class=1:length(full_SVM_names)
        class_name=full_SVM_names{class};
        BASICDATA_CellType.([class_name,'_number'])(1,well)=sum(handles3.(class_name)(matImageIndicesPerWell));
    end
end


% saving data
disp(sprintf('SAVING %s',fullfile(strRootPath,'Measurements_CellType_Overview.mat')))
save(fullfile(strRootPath,'Measurements_Nuclei_CellType_Overview.mat'),'BASICDATA_CellType')

