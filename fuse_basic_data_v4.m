function [BASICDATA] = fuse_basic_data_v4(strRootPath, BASICDATA)

warning off all;

if nargin == 0
    
%     strRootPath = 'W:\Data\Users\Frank\iBRAIN\081120-VSV-DYRK3INH-DDX6-20x\'     
%     strRootPath = 'Y:\Data\Users\Frank\090116-9-7-DYRK3INH-DDX6-PABP\'
%     strRootPath = npc('/BIOL/imsb/fs3/bio3/bio3/Data/Users/Eva/BS_iBRAIN\') 
%     strRootPath = npc('Z:\Data\Users\Cameron\CHOL-LBPA_HELAMZ_QIAGEN_Druggable\') 
    strRootPath = npc('\\nas-biol-imsb-1\share-2-$\Data\Users\Cameron\CHOL-LBPA_A431_Dharmacon_WG');
%     strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\VV_DG\';
%     strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\Philip\221007_Philip_Tfn_S6Kp_DAPI_CP0001-1aa\';

%     strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\Philip\50K_Tfn\';
%     strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Lilli\adhesome_screen_data\';
%     strRootPath = 'Z:\Data\Users\Martina\Martina_SVM\tfsynchr_sirnaoffset0_030609Martina_strongdapi2\';
end

if nargin < 2
    % INITIALIZE BASICDATA
    BASICDATA = struct();
end

% LOOK FOR TARGET FOLDERS
disp(sprintf('Looking for target folders in %s',strRootPath))
[cellstrFolderList] = SearchTargetFolders2(strRootPath,'BASICDATA_*.mat');
% [cellstrFolderList] = findPlates(strRootPath);

% CHECK TO PREVENT LOADING BASICDATA_...MAT FILES FROM strRootPath
% REMOVE THEM FROM THE LIST
matRootBasicdataIndices = strcmpi(getlastdir(strRootPath),getlastdir(getbasedir(cellstrFolderList)));
disp(sprintf('Excluding %d BASICDATA_*.mat files in root from project',length(find(matRootBasicdataIndices))))
% matRootBasicdataIndices = strcmpi(strRootPath,getbasedir(cellstrFolderList));
cellstrFolderList = cellstrFolderList(~matRootBasicdataIndices);

% check number of basicdatas found
intNumOfFolders = size(cellstrFolderList,1);
disp(sprintf('Found %d target folders',intNumOfFolders))

for iDir = 1:intNumOfFolders

    % CHECK TO PREVENT LOADING BASICDATA_...MAT FILES FROM strRootPath
    % DIRECTLY
    if strcmpi(getlastdir(strRootPath),getlastdir(getbasedir(cellstrFolderList{iDir})))
       continue 
    end
    
    %%% LOAD BASICDATA
    disp(sprintf('Loading %s',cellstrFolderList{iDir}))
    PLATE_BASICDATA = load(cellstrFolderList{iDir});
    PLATE_BASICDATA = PLATE_BASICDATA.BASICDATA;

    strPlateDirectory = strrep(getbasedir(cellstrFolderList{iDir}),[filesep,'BATCH'],'');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% CHECK IF THERE IS MODEL CORRECTED DATA PER WELL, AND ADD TO PLATE_BASICDATA IF SO
    %%% ProbModel_TensorCorrectedData.mat
%     try
        [cellstrFolderList2] = SearchTargetFolders(strPlateDirectory,'ProbModel_TensorCorrectedData.mat');
        if ~(isempty(cellstrFolderList2))

            % LOAD THE ONE WITH THE LEAST FILESEPS IN THE PATH, I.E. THE
            % HIGHEST IN THE FILESYSTEM
            [foo,bar]=sort(cellfun(@numel,strfind(cellstrFolderList2,filesep)));
            disp(sprintf('        %s',cellstrFolderList2{bar(1)}))
            PLATE_CORRECTEDDATA = load(cellstrFolderList2{bar(1)});

            if sum(PLATE_BASICDATA.WellCol == PLATE_CORRECTEDDATA.TensorCorrectedData.WellColNumber) ~= 384 || ...
                    sum(PLATE_BASICDATA.WellRow == PLATE_CORRECTEDDATA.TensorCorrectedData.WellRowNumber) ~= 384
                error('ProbModel_TensorCorrectedData plate layouts does not match BASICDATA plate layout!!!')
            end

            % MODEL RAW (= SVM CORRECTED)
            PLATE_BASICDATA.ModelRawII = PLATE_CORRECTEDDATA.TensorCorrectedData.Raw.II;
            PLATE_BASICDATA.ModelRawInfected = PLATE_CORRECTEDDATA.TensorCorrectedData.Raw.Infected;
            PLATE_BASICDATA.ModelRawLOG2RII = PLATE_CORRECTEDDATA.TensorCorrectedData.Raw.LOG2RII;
            PLATE_BASICDATA.ModelRawRII = PLATE_CORRECTEDDATA.TensorCorrectedData.Raw.RII;
            PLATE_BASICDATA.ModelRawTotalCellNumber = PLATE_CORRECTEDDATA.TensorCorrectedData.Raw.TotalCellNumber;
            PLATE_BASICDATA.ModelRawZSCORELOG2RII = PLATE_CORRECTEDDATA.TensorCorrectedData.Raw.ZSCORELOG2RII;
            % MODEL CORRECTED
            PLATE_BASICDATA.ModelCorrectedLOG2RII = PLATE_CORRECTEDDATA.TensorCorrectedData.ModelCorrected.LOG2RII;
            PLATE_BASICDATA.ModelCorrectedZSCORELOG2RII = PLATE_CORRECTEDDATA.TensorCorrectedData.ModelCorrected.ZSCORELOG2RII;
            % TENSOR/BIN CORRECTED, BOTH PER PLATE AND PER PROJECT
            PLATE_BASICDATA.ProjectTensorCorrectedLOG2RII = PLATE_CORRECTEDDATA.TensorCorrectedData.ProjectTensorCorrected.LOG2RII;
            PLATE_BASICDATA.ProjectTensorCorrectedZSCORELOG2RII = PLATE_CORRECTEDDATA.TensorCorrectedData.ProjectTensorCorrected.ZSCORELOG2RII;
            PLATE_BASICDATA.PlateTensorCorrectedLOG2RII = PLATE_CORRECTEDDATA.TensorCorrectedData.PlateTensorCorrected.LOG2RII;
            PLATE_BASICDATA.PlateTensorCorrectedZSCORELOG2RII = PLATE_CORRECTEDDATA.TensorCorrectedData.PlateTensorCorrected.ZSCORELOG2RII;
            
            
            % MODEL PREDICTED
            PLATE_BASICDATA.ModelPredictedII = PLATE_CORRECTEDDATA.TensorCorrectedData.ModelPredicted.II;
            PLATE_BASICDATA.ModelPredictedInfected = PLATE_CORRECTEDDATA.TensorCorrectedData.ModelPredicted.Infected;
            PLATE_BASICDATA.ModelPredictedLOG2RII = PLATE_CORRECTEDDATA.TensorCorrectedData.ModelPredicted.LOG2RII;
            PLATE_BASICDATA.ModelPredictedRII = PLATE_CORRECTEDDATA.TensorCorrectedData.ModelPredicted.RII;
            PLATE_BASICDATA.ModelPredictedZSCORELOG2RII = PLATE_CORRECTEDDATA.TensorCorrectedData.ModelPredicted.ZSCORELOG2RII;
        end
%     catch caughtError
%         caughtError.identifier        
%         caughtError.message
%         disp(sprintf('error while adding %s from %s','ProbModel_TensorCorrectedData',strPlateDirectory))
%     end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% CHECK IF THERE IS MODEL DATA FROM ENTIRE PLATE, AND ADD TO PLATE_BASICDATA IF SO
    %%% ProbModel_Tensor.mat
    try
        [cellstrFolderList4] = SearchTargetFolders(strPlateDirectory,'ProbModel_Tensor.mat');
        if ~(isempty(cellstrFolderList4))

            % LOAD THE ONE WITH THE LEAST FILESEPS IN THE PATH, I.E. THE
            % HIGHEST IN THE FILESYSTEM
            [foo,bar]=sort(cellfun(@numel,strfind(cellstrFolderList4,filesep)));
            disp(sprintf('        %s',cellstrFolderList4{bar(1)}))
            PLATE_TENSORMODEL = load(cellstrFolderList4{bar(1)});
            if isfield(PLATE_TENSORMODEL.Tensor,'Model')
                PLATE_BASICDATA.ModelDataPerPlateRSquared = str2double(PLATE_TENSORMODEL.Tensor.Model.Description.PearsonsR2);
                PLATE_BASICDATA.ModelDataPerPlateParameters = PLATE_TENSORMODEL.Tensor.Model.Params';
                PLATE_BASICDATA.ModelDataPerPlateFeatures = PLATE_TENSORMODEL.Tensor.Model.Features';
                PLATE_BASICDATA.ModelDataPerPlatePValues = PLATE_TENSORMODEL.Tensor.Model.p';
            end
        end
    catch caughtError
        caughtError.identifier        
        caughtError.message
       disp(sprintf('error while adding %s from %s','ProbModel_Tensor',strPlateDirectory))
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% CHECK IF THERE IS MODEL PARAMETER DATA PER WELL, AND ADD TO PLATE_BASICDATA IF SO
    %%% ProbModel_TensorDataPerWell.mat
    try
        [cellstrFolderList3] = SearchTargetFolders(strPlateDirectory,'ProbModel_TensorDataPerWell.mat');
        if ~(isempty(cellstrFolderList3))

            % LOAD THE ONE WITH THE LEAST FILESEPS IN THE PATH, I.E. THE
            % HIGHEST IN THE FILESYSTEM
            [foo,bar]=sort(cellfun(@numel,strfind(cellstrFolderList3,filesep)));
            disp(sprintf('        %s',cellstrFolderList3{bar(1)}));
            PLATE_MODELDATAPERWELL = load(cellstrFolderList3{bar(1)});

            if sum(PLATE_BASICDATA.WellCol == PLATE_MODELDATAPERWELL.TensorDataPerWell.PerGene.WellCol) ~= 384 || ...
                    sum(PLATE_BASICDATA.WellRow == PLATE_MODELDATAPERWELL.TensorDataPerWell.PerGene.WellRow) ~= 384
                error('ProbModel_TensorDataPerWell plate layouts does not match BASICDATA plate layout!!!')
            end

            PLATE_BASICDATA.ModelDataPerWellFeatures = PLATE_MODELDATAPERWELL.TensorDataPerWell.Features;
            PLATE_BASICDATA.ModelDataPerWellParameters = PLATE_MODELDATAPERWELL.TensorDataPerWell.PerGene.ModelParameters;
            PLATE_BASICDATA.ModelDataPerWellRSquared = PLATE_MODELDATAPERWELL.TensorDataPerWell.PerGene.RSquared;
        end
    catch caughtError
        caughtError.identifier        
        caughtError.message
       disp(sprintf('error while adding %s from %s','ProbModel_TensorDataPerWell',strPlateDirectory))
    end      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% CHECK IF THERE IS Measurements_Nuclei_CellType_Overview DATA PER WELL, AND ADD TO PLATE_BASICDATA IF SO
    %%% Measurements_Nuclei_CellType_Overview.mat
    try
        [cellstrFolderList4] = SearchTargetFolders(strPlateDirectory,'Measurements_Nuclei_CellType_Overview.mat');
        if ~(isempty(cellstrFolderList4))

            % LOAD THE ONE WITH THE LEAST FILESEPS IN THE PATH, I.E. THE
            % HIGHEST IN THE FILESYSTEM
            [foo,bar]=sort(cellfun(@numel,strfind(cellstrFolderList4,filesep)));
            disp(sprintf('        %s',cellstrFolderList4{bar(1)}));
            PLATE_CellTypeData = load(cellstrFolderList4{bar(1)});

            if sum(PLATE_BASICDATA.WellCol == PLATE_CellTypeData.BASICDATA_CellType.WellCol) ~= 384 || ...
                    sum(PLATE_BASICDATA.WellRow == PLATE_CellTypeData.BASICDATA_CellType.WellRow) ~= 384
                error('Measurements_Nuclei_CellType_Overview plate layouts does not match BASICDATA plate layout!!!')
            end

            %%% automatically add all fieldnames (fieldnames slightly renamed),
            %%% they are all numerical matrices (double)
            cellFieldNames = fieldnames(PLATE_CellTypeData.BASICDATA_CellType);
            for iFieldName = cellFieldNames'
                % Skip WellRow, WellCol fields
                strFieldName = char(iFieldName);
                if ~strcmpi(strFieldName,'wellrow') && ~strcmpi(strFieldName,'wellcol')
                    % remove underscores, capitalize "index" and "number"
                    strNewFieldName = strrep(strFieldName,'_','');
                    strNewFieldName = strrep(strNewFieldName,'index','Index');
                    strNewFieldName = strrep(strNewFieldName,'number','Number');                
                    strNewFieldName = ['CellTypeOverview',strNewFieldName]; %#ok<AGROW>
                    PLATE_BASICDATA.(strNewFieldName) = PLATE_CellTypeData.BASICDATA_CellType.(strFieldName);
                end
            end

        end
    catch caughtError
        caughtError.identifier        
        caughtError.message
       disp(sprintf('error while adding %s from %s','Measurements_Nuclei_CellType_Overview',strPlateDirectory))
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% CHECK IF THERE IS OPTIMIZED_INFECTION, AND ADD TO PLATE_BASICDATA IF SO
    %%% OPTIMIZED_INFECTION.mat
    
%     OPTIMIZED_INFECTION = struct();
%     OPTIMIZED_INFECTION.WellColumn = matWellCol;
%     OPTIMIZED_INFECTION.WellRow = matWellRow;
%     OPTIMIZED_INFECTION.TotalCellsPerWell = PlateOptimizedInfection.matTotalCellsPerWell(:,maxSettings(i));
%     OPTIMIZED_INFECTION.InfectedCellsPerWell = PlateOptimizedInfection.matInfectedCellsPerWell(:,maxSettings(i));
%     OPTIMIZED_INFECTION.InfectionIndexPerWell = PlateOptimizedInfection.matInfectionIndexPerWell(:,maxSettings(i));
%     OPTIMIZED_INFECTION.ZscoreLog2RIIPerWell = PlateOptimizedInfection.matZscoreLog2RIIPerWell(:,maxSettings(i));
    
    try
        [cellstrFolderList7] = SearchTargetFolders(strPlateDirectory,'OPTIMIZED_INFECTION.mat');
        if ~(isempty(cellstrFolderList7))

            % LOAD THE ONE WITH THE LEAST FILESEPS IN THE PATH, I.E. THE
            % HIGHEST IN THE FILESYSTEM
            [foo,bar]=sort(cellfun(@numel,strfind(cellstrFolderList7,filesep)));
            disp(sprintf('        %s',cellstrFolderList7{bar(1)}));
            PLATE_OptimizedInfection = load(cellstrFolderList7{bar(1)});
            PLATE_OptimizedInfection = PLATE_OptimizedInfection.OPTIMIZED_INFECTION;

            PLATE_BASICDATA.OptimizedInfectionInfectedCells = NaN(1,384);
            PLATE_BASICDATA.OptimizedInfectionInfectionIndex = NaN(1,384);
            PLATE_BASICDATA.OptimizedInfectionTotalCells = NaN(1,384);
            PLATE_BASICDATA.OptimizedInfectionZscoreLog2RIIPerWell = NaN(1,384);
            PLATE_BASICDATA.OptimizedInfectionNumOfPeaks = PLATE_OptimizedInfection.NumOfPeaks;
            PLATE_BASICDATA.OptimizedInfectionBoolFirstPeakIsUsed = PLATE_OptimizedInfection.boolFirstPeakIsUsed;            
            
            for row=1:16
                for col=1:24
                    index1=find(PLATE_BASICDATA.WellRow==row & PLATE_BASICDATA.WellCol==col);
                    index2=find(PLATE_OptimizedInfection.WellRow==row & PLATE_OptimizedInfection.WellColumn==col);
                    if ~isempty(index1) & ~isempty(index2)
                        PLATE_BASICDATA.OptimizedInfectionInfectedCells(1,index1) = PLATE_OptimizedInfection.InfectedCellsPerWell(index2);
                        PLATE_BASICDATA.OptimizedInfectionInfectionIndex(1,index1) = PLATE_OptimizedInfection.InfectionIndexPerWell(index2);
                        PLATE_BASICDATA.OptimizedInfectionTotalCells(1,index1) = PLATE_OptimizedInfection.TotalCellsPerWell(index2);
                        PLATE_BASICDATA.OptimizedInfectionZscoreLog2RIIPerWell(1,index1) = PLATE_OptimizedInfection.ZscoreLog2RIIPerWell(index2);
                    end
                end
            end
        end
    catch caughtError
        caughtError.identifier        
        caughtError.message
       disp(sprintf('error while adding %s from %s','OPTIMIZED_INFECTION',strPlateDirectory))
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
    %%% (IF THERE ARE MORE FILES TO BE PARSED INTO BASICDATA, ADD HERE)


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% CHECK IF THERE IS ControlLayout per plate or per screen, AND ADD TO PLATE_BASICDATA IF SO

    % check the per plate controllayout file
    try
        [cellstrFolderList5] = SearchTargetFolders(strPlateDirectory,'ControlLayout.mat');
        if (isempty(cellstrFolderList5))
            % if there is no control layout file per plate, load the default
            % one from the rootpath
            p=[strRootPath,'ControlLayout.mat'];
            if fileattrib(p)
                cellstrFolderList5{1} = p;
            end
        end

        % if there is a control layout file in either the plate dir or in the
        % project dir, proces it.
        if ~(isempty(cellstrFolderList5))
            % LOAD THE ONE WITH THE LEAST FILESEPS IN THE PATH, I.E. THE
            % HIGHEST IN THE FILESYSTEM
            [foo,bar]=sort(cellfun(@numel,strfind(cellstrFolderList5,filesep)));
            disp(sprintf('        %s',cellstrFolderList5{bar(1)}));
            PLATE_ControlLayout = load(cellstrFolderList5{bar(1)});

            if sum(PLATE_BASICDATA.WellCol == PLATE_ControlLayout.BASICDATA_controls.WellCol) ~= 384 || ...
                    sum(PLATE_BASICDATA.WellRow == PLATE_ControlLayout.BASICDATA_controls.WellRow) ~= 384
                error('ControlLayout plate layouts does not match BASICDATA plate layout!!!')
            end

            for row=1:16
                for col=1:24
                    index=find(PLATE_BASICDATA.WellRow==row & PLATE_BASICDATA.WellCol==col);
                    control=PLATE_ControlLayout.BASICDATA_controls.Control{1,index};
                    if ~isempty(control)
                        PLATE_BASICDATA.GeneData{1,index}=control;
                        PLATE_BASICDATA.GeneID{1,index}=PLATE_ControlLayout.BASICDATA_controls.GeneID(1,index);
                    end
                end
            end
        end
    catch caughtError
        caughtError.identifier        
        caughtError.message
       disp(sprintf('error while adding %s from %s','Measurements_Nuclei_CellType_Overview',strPlateDirectory))
    end     

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% MERGE ALL FIELDS IN PLATE_BASICDATA TO BASICDATA %%%

    % LIST ALL FIELDNAMES IN PLATE_BASICDATA
    cellstrCurrentFieldNames = fieldnames(PLATE_BASICDATA);

    % LOOP OVER ALL FIELDNAMES, AND MERGE TO BASICDATA
    for sField = cellstrCurrentFieldNames'
        strFieldName = char(sField);

        intNumOfColumns = size(PLATE_BASICDATA.(strFieldName),2);
        intNumOfRows = size(PLATE_BASICDATA.(strFieldName),1);

        % CHECK IF FIELD IS ALREADY PRESENT, IF NOT, INITIALIZE IT
        % ACCORDING TO CLASS IN BASICDATA
        if ~isfield(BASICDATA,strFieldName)

            if isa(PLATE_BASICDATA.(strFieldName), 'char')
                BASICDATA.(strFieldName) = cell(intNumOfFolders,1);
            elseif isa(PLATE_BASICDATA.(strFieldName), 'numeric') && (intNumOfRows == 1)
                BASICDATA.(strFieldName) = NaN(intNumOfFolders,intNumOfColumns);
            elseif isa(PLATE_BASICDATA.(strFieldName), 'numeric') && (intNumOfRows > 1)
                BASICDATA.(strFieldName) = cell(intNumOfFolders,1);
            elseif isa(PLATE_BASICDATA.(strFieldName), 'cell')
                BASICDATA.(strFieldName) = cell(intNumOfFolders,intNumOfColumns);
            elseif isa(PLATE_BASICDATA.(strFieldName), 'struct')
                BASICDATA.(strFieldName) = cell(intNumOfFolders,intNumOfColumns);
            end
        end

        if isa(PLATE_BASICDATA.(strFieldName), 'char')
            BASICDATA.(strFieldName){iDir,:} = PLATE_BASICDATA.(strFieldName);
        elseif isa(PLATE_BASICDATA.(strFieldName), 'numeric') && (intNumOfRows > 1)
            BASICDATA.(strFieldName){iDir,:} = PLATE_BASICDATA.(strFieldName);
        else
            BASICDATA.(strFieldName)(iDir,:) = PLATE_BASICDATA.(strFieldName);
        end
    end
end


try
    disp(sprintf('\n%d plates gathered',size(BASICDATA.TotalCells,1)))
    disp(sprintf('Saving %s',fullfile(strRootPath,'BASICDATA.mat')))
    save(fullfile(strRootPath,'BASICDATA.mat'),'BASICDATA');
catch
    err1 = lasterror
    msg = err1.message;
    disp(sprintf('   !!! Saving BASICDATA failed on %s. \n\n%s',strRootPath, msg))
end


try
    disp('**** CREATING ADVANCEDDATA')
    ADVANCEDDATA = convert_basic_to_advanced_data(BASICDATA);
    disp('**** SAVING ADVANCEDDATA')
    save(fullfile(strRootPath,'ADVANCEDDATA.mat'),'ADVANCEDDATA');
catch
    err1 = lasterror
    msg = err1.message;
    disp(sprintf('*** creating and saving ADVANCEDDATA failed on %s. \n\n%s',strRootPath, msg))
end

try
    disp('**** CREATING ADVANCEDDATA2')
    Create_ADVANCEDDATA2_iBRAIN(strRootPath);
catch
    err1 = lasterror
    msg = err1.message;
    disp(sprintf('*** creating and saving ADVANCEDDATA2 failed on %s. \n\n%s',strRootPath, msg))
end

try
    disp('**** CREATING BASICDATA.csv')
    Convert_BASICDATA_to_csv(strRootPath)
catch
    err1 = lasterror
    msg = err1.message;
    disp(sprintf('*** creating and saving BASICDATA.csv failed on %s. \n\n%s',strRootPath, msg))
end


try
    disp('**** CREATING ADVANCEDDATA_html.csv')
%     Convert_ADVANCEDDATA_to_csv(strRootPath)
    Convert_ADVANCEDDATA_to_csv_HTML(strRootPath)
catch
    err1 = lasterror
    msg = err1.message;
    disp(sprintf('*** creating and saving ADVANCEDDATA_html.csv failed on %s. \n\n%s',strRootPath, msg))
end

try
    disp('**** CREATING ADVANCEDDATA2.csv')
    Convert_ADVANCEDDATA2_to_full_csv_iBRAIN(strRootPath)
catch
    err1 = lasterror
    msg = err1.message;
    disp(sprintf('*** creating and saving ADVANCEDDATA.csv failed on %s. \n\n%s',strRootPath, msg))
end

end%end of function