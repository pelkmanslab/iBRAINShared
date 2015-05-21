function [BASICDATA] = fuse_basic_data_v2(strRootPath, BASICDATA)

    warning off all;
    
    if nargin == 0
        strRootPath = '\\Nas-biol-imsb-1\share-3-$\Data\Users\HPV16_DG\';
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\Philip\221007_Philip_Tfn_S6Kp_DAPI_CP0001-1aa\';
        
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\Philip\50K_Tfn\';
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Lilli\adhesome_screen_data\';
    end

    if nargin < 2
        % INITIALIZE BASICDATA
        BASICDATA = struct();
    end
    
    % LOOK FOR TARGET FOLDERS
    disp(sprintf('Looking for target folders in %s',strRootPath))            
    [cellstrFolderList] = SearchTargetFolders(strRootPath,'BASICDATA_*.mat');
    intNumOfFolders = size(cellstrFolderList,1);
    disp(sprintf('Found %d target folders',intNumOfFolders))

    for iDir = 1:intNumOfFolders

        %%% LOAD BASICDATA
        disp(sprintf('Loading %s',cellstrFolderList{iDir}))
        PLATE_BASICDATA = load(cellstrFolderList{iDir});
        PLATE_BASICDATA = PLATE_BASICDATA.BASICDATA;

        strPlateDirectory = strrep(getbasedir(cellstrFolderList{iDir}),[filesep,'BATCH'],'');

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% CHECK IF THERE IS MODEL CORRECTED DATA PER WELL, AND ADD TO PLATE_BASICDATA IF SO
        %%% ProbModel_TensorCorrectedData.mat
        
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
            % MODEL PREDICTED
            PLATE_BASICDATA.ModelPredictedII = PLATE_CORRECTEDDATA.TensorCorrectedData.ModelPredicted.II;
            PLATE_BASICDATA.ModelPredictedInfected = PLATE_CORRECTEDDATA.TensorCorrectedData.ModelPredicted.Infected;
            PLATE_BASICDATA.ModelPredictedLOG2RII = PLATE_CORRECTEDDATA.TensorCorrectedData.ModelPredicted.LOG2RII;
            PLATE_BASICDATA.ModelPredictedRII = PLATE_CORRECTEDDATA.TensorCorrectedData.ModelPredicted.RII;
            PLATE_BASICDATA.ModelPredictedZSCORELOG2RII = PLATE_CORRECTEDDATA.TensorCorrectedData.ModelPredicted.ZSCORELOG2RII;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% CHECK IF THERE IS MODEL DATA FROM ENTIRE PLATE, AND ADD TO PLATE_BASICDATA IF SO
        %%% ProbModel_Tensor.mat
        [cellstrFolderList4] = SearchTargetFolders(strPlateDirectory,'ProbModel_Tensor.mat');
        if ~(isempty(cellstrFolderList4))

            % LOAD THE ONE WITH THE LEAST FILESEPS IN THE PATH, I.E. THE
            % HIGHEST IN THE FILESYSTEM
            [foo,bar]=sort(cellfun(@numel,strfind(cellstrFolderList4,filesep)));            
            disp(sprintf('        %s',cellstrFolderList4{bar(1)}))
            PLATE_TENSORMODEL = load(cellstrFolderList4{bar(1)});
            
            PLATE_BASICDATA.ModelDataPerPlateRSquared = str2double(PLATE_TENSORMODEL.Tensor.Model.Description.PearsonsR2);
            PLATE_BASICDATA.ModelDataPerPlateParameters = PLATE_TENSORMODEL.Tensor.Model.Params';
            PLATE_BASICDATA.ModelDataPerPlateFeatures = PLATE_TENSORMODEL.Tensor.Model.Features';
            PLATE_BASICDATA.ModelDataPerPlatePValues = PLATE_TENSORMODEL.Tensor.Model.p';
        end        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% CHECK IF THERE IS MODEL PARAMETER DATA PER WELL, AND ADD TO PLATE_BASICDATA IF SO        
        %%% ProbModel_TensorDataPerWell.mat
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% CHECK IF THERE IS Measurements_Nuclei_CellType_Overview DATA PER WELL, AND ADD TO PLATE_BASICDATA IF SO        
        %%% Measurements_Nuclei_CellType_Overview.mat
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

            PLATE_BASICDATA.CellTypeOverviewApoptoticIndex = PLATE_CellTypeData.BASICDATA_CellType.Apoptotic_index;
            PLATE_BASICDATA.CellTypeOverviewApoptoticNumber = PLATE_CellTypeData.BASICDATA_CellType.Apoptotic_number;
            PLATE_BASICDATA.CellTypeOverviewCellNumber = PLATE_CellTypeData.BASICDATA_CellType.Cell_number;
            PLATE_BASICDATA.CellTypeOverviewInterphaseNumber = PLATE_CellTypeData.BASICDATA_CellType.Interphase_number;
            PLATE_BASICDATA.CellTypeOverviewMitoticIndex = PLATE_CellTypeData.BASICDATA_CellType.Mitotic_index;
            PLATE_BASICDATA.CellTypeOverviewMitoticNumber = PLATE_CellTypeData.BASICDATA_CellType.Mitotic_number;
            PLATE_BASICDATA.CellTypeOverviewOthersNumber = PLATE_CellTypeData.BASICDATA_CellType.Others_number;
            PLATE_BASICDATA.CellTypeOverviewTotalNumber = PLATE_CellTypeData.BASICDATA_CellType.Total_number;
            PLATE_BASICDATA.CellTypeOverviewZScoreLog2ApoptoticIndex = PLATE_CellTypeData.BASICDATA_CellType.ZScore_Log2_Apoptotic_index;
            PLATE_BASICDATA.CellTypeOverviewZScoreLog2MitoticIndex = PLATE_CellTypeData.BASICDATA_CellType.ZScore_Log2_Mitotic_index;
            
            PLATE_BASICDATA.CellTypeOverviewSizeMean = PLATE_CellTypeData.BASICDATA_CellType.SizeMean;
            PLATE_BASICDATA.CellTypeOverviewSizeStd = PLATE_CellTypeData.BASICDATA_CellType.SizeStd;
            PLATE_BASICDATA.CellTypeOverviewLocalCellDensityMean = PLATE_CellTypeData.BASICDATA_CellType.LocalCellDensityMean;
            PLATE_BASICDATA.CellTypeOverviewLocalCellDensityStd = PLATE_CellTypeData.BASICDATA_CellType.LocalCellDensityStd;
            PLATE_BASICDATA.CellTypeOverviewEdgeNumber = PLATE_CellTypeData.BASICDATA_CellType.EdgeNumber;
            PLATE_BASICDATA.CellTypeOverviewNonEdgeNumber = PLATE_CellTypeData.BASICDATA_CellType.NonEdgeNumber;
            PLATE_BASICDATA.CellTypeOverviewEdgeRatio = PLATE_CellTypeData.BASICDATA_CellType.EdgeRatio;
            
            PLATE_BASICDATA.CellTypeOverviewMitoticInfected = PLATE_CellTypeData.BASICDATA_CellType.MitoticInfected;
            PLATE_BASICDATA.CellTypeOverviewApoptoticInfected = PLATE_CellTypeData.BASICDATA_CellType.ApoptoticInfected;
            PLATE_BASICDATA.CellTypeOverviewZScoreLog2MitoticII= PLATE_CellTypeData.BASICDATA_CellType.ZScoreLog2MitoticII;
            PLATE_BASICDATA.CellTypeOverviewZScoreLog2ApoptoticII = PLATE_CellTypeData.BASICDATA_CellType.ZScoreLog2ApoptoticII;
            PLATE_BASICDATA.CellTypeOverviewZScoreLog2EdgeII = PLATE_CellTypeData.BASICDATA_CellType.ZScoreLog2EdgeII;
            PLATE_BASICDATA.CellTypeOverviewZScoreLog2NonEdgeII= PLATE_CellTypeData.BASICDATA_CellType.ZScoreLog2NonEdgeII;
            


        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        
        %%% (IF THERE ARE MORE FILES TO BE PARSED INTO BASICDATA, ADD HERE)
       
        
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
        disp('**** CREATING BASICDATA.csv')                
        Convert_BASICDATA_to_csv(strRootPath)            
    catch 
        err1 = lasterror
        msg = err1.message;
        disp(sprintf('*** creating and saving BASICDATA.csv failed on %s. \n\n%s',strRootPath, msg))                                                                
    end


    try
        disp('**** CREATING ADVANCEDDATA.csv')                
        \\Nas-biol-imsb-1\share-2-$\Data\Code\(strRootPath)            
    catch 
        err1 = lasterror        
        msg = err1.message;
        disp(sprintf('*** creating and saving ADVANCEDDATA.csv failed on %s. \n\n%s',strRootPath, msg))                                                
    end        
    
end%end of function