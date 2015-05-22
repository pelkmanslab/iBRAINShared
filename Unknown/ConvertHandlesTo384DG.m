function [matTotal, matInfected, matImagesPerWell, cellstrGenePerWell, matOligonumber, matPlatenumber, matReplicanumber, matBatchnumber, matCtrlInfectionIndices, matWellRow, matWellCol, matNoVirusCtrlInfectionIndices, cellstrGeneID, matCtrlCellNumbers, matRawImagesPerWell, cellImageIndicesPerWell] = ConvertHandlesTo384DG(strRootPath, handles)
    
    if nargin == 0
%         strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\David\Pictures\David_iBRAIN\Davidstestplate\BATCH\';
%         strRootPath = 'Z:\Data\Users\FLU_DG1\20071203185227_M2_20071203_FLU3V_DG_batch1_CP0139-1aa\BATCH\';
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Frank\iBRAIN\080815-Frank-VSV-pH-dyn\BATCH\';
        strRootPath = 'Y:\Data\Users\50K_final_reanalysis\Ad3_KY_NEW\070606_Ad3_50k_Ky_1_1_CP071-1aa\BATCH\';        
    end
    
    if nargin < 2
        if ischar(strRootPath)
            disp(sprintf('%s: creating new complete handles',mfilename))
            handles = struct();
            handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_FileNames.mat']);
            handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_ObjectCount.mat']);
            
            try
                handles = LoadMeasurements(handles, [strRootPath,'Measurements_Nuclei_VirusScreen_ClassicalInfection_Overview2.mat']);            
            catch
                disp(sprintf('%s: failed to load virus infection data from Measurements_Nuclei_VirusScreen_ClassicalInfection_Overview2',mfilename))
            end
            try
                handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_OutOfFocus.mat']);            
            catch
                disp(sprintf('%s: no image outoffocus data found',mfilename))
            end
        else
            error('ConvertHandlesTo384DG: the input path should be a string')
        end
    elseif nargin == 2

        if ~isfield(handles.Measurements.Image,'ObjectCount')
            disp(sprintf('%s: convert: loading handles, objectcount...',mfilename))
            handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_ObjectCount.mat'));        
        end
        
        if ~isfield(handles.Measurements.Image,'FileNames')
            disp(sprintf('%s: loading handles, filenames...',mfilename))
            handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_FileNames.mat'));        
        end
        
        if ~isfield(handles.Measurements,'Nuclei') || ~isfield(handles.Measurements.Nuclei,'VirusScreenInfection_Overview')
            try
                disp(sprintf('%s: loading handles, VirusScreenInfection_Overview...',mfilename))                
                handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Nuclei_VirusScreen_ClassicalInfection_Overview2.mat'));        
            catch
                 disp(sprintf('%s: no virus infection data found',mfilename))               
            end
        end
        
        if ~isfield(handles.Measurements.Image,'OutOfFocus')
            try
                disp(sprintf('%s: loading handles, outoffocus...',mfilename))
                handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_OutOfFocus.mat'));        
            catch
                disp(sprintf('%s: no image outoffocus data found',mfilename))                                
            end            
        end
    end

    matTotal = []; 
    matInfected = [];
    matImagesPerWell = [];
    matOligonumber = [];
    matPlatenumber = [];
    matReplicanumber = [];
    intMedianCtrlII = 0;
    matWellRow = [];
    matWellCol = [];
    
    str2match = []; 
    TotalInfectedIndex = [];
    OutOfFocusImage = [];
    cellFileNames = {};
    cellstrGeneSymbol = {};
    cellstrGeneID = {};
    
    matCtrlCellNumbers = [];
    
    matRawImagesPerWell = [];
    
    rowstodo = 1:16;
    colstodo = 1:24;
    
    matRows = cellstr(regexp(char(65:80),'\w','match'));
    matCols = regexp(sprintf('%.2d',1:24),'\d\d','match');
    
    if ~exist('handles','var')
        error('a valid cellprofiler handles variable is required')
        return
    end

    if ~isfield(handles,'Measurements')
        error('there are no measurements in your handles file')
        return
    end
    
    if isfield(handles.Measurements,'Nuclei')
        strObjectName = 'Nuclei';
    elseif isfield(handles.Measurements,'Cells')
        strObjectName = 'Cells';
    elseif isfield(handles.Measurements,'OrigNuclei')
        strObjectName = 'OrigNuclei';        
    else
        % otherwise, use the first object detected in the pipeline
        strObjectName = handles.Measurements.Image.ObjectCountFeatures{1,1};        
    end
    disp(sprintf('%s: using ''%s'' as cell count',mfilename,strObjectName))
    
    intObjectCountColumn = find(strcmp(handles.Measurements.Image.ObjectCountFeatures,strObjectName));
    
    % test if there is objectcount data for this object, if not, do looser
    % matching with strfind...
    if isempty(intObjectCountColumn)
        disp(sprintf('%s: WARNING: couldn''t find exact ObjectCount data math for %s... looking for more loose matches',mfilename,strObjectName))
        intObjectCountColumn = find(~cellfun(@isempty,strfind(handles.Measurements.Image.ObjectCountFeatures,strObjectName)));
        
        % report findings
        if ~isempty(intObjectCountColumn)
            disp(sprintf('%s: found looser match for object %s',mfilename,handles.Measurements.Image.ObjectCountFeatures{intObjectCountColumn}))        
        else
            error('   DON''T KNOW WHICH OBJECT TO USE AS PRIMARY OBJECT!!! ABORTING')                
        end
        
    end
    
    if isfield(handles.Measurements,strObjectName) 
        if isfield(handles.Measurements.(strObjectName),'VirusInfection')
           boolVirusData = 1;
           VirusInfectionFieldName = 'VirusInfection';
           TotalInfectedIndex = strfind(handles.Measurements.(strObjectName).VirusInfectionFeatures, 'TotalInfected');
           TotalInfectedIndex = find(~cellfun('isempty',TotalInfectedIndex));
        elseif isfield(handles.Measurements.(strObjectName),'VirusScreenInfection_Overview')
           boolVirusData = 1;
           VirusInfectionFieldName = 'VirusScreenInfection_Overview';   
           TotalInfectedIndex = strfind(handles.Measurements.(strObjectName).VirusScreenInfection_OverviewFeatures, 'TotalInfected');
           TotalInfectedIndex = find(~cellfun('isempty',TotalInfectedIndex));
        else
            boolVirusData = 0;            
        end
    else
        boolVirusData = 0;
    end   
    
    if boolVirusData
         disp(sprintf('%s: virus infection data found',mfilename))                       
    else
         disp(sprintf('%s: virus infection data NOT found',mfilename))                       
    end

    if isfield(handles.Measurements.Image,'OutOfFocus')
        boolOutOfFocusData = 1;
        OutOfFocusImage = handles.Measurements.Image.OutOfFocus;
    else
        boolOutOfFocusData = 0;
    end        

    %convert ImageNames to something we can index
    cellFileNames = cell(length(handles.Measurements.Image.FileNames),1);
    for l = 1:size(handles.Measurements.Image.FileNames,2)
        cellFileNames{l} = char(handles.Measurements.Image.FileNames{l}(1));
    end
    
    [matNumericalPlateList(1,1), matNumericalPlateList(1,2), matNumericalPlateList(1,3)] = filterplatedata(strRootPath);

    %%% BS, 080818, Get Image locations from filterimagenamedata, rather
    %%% than parsing the image names in here. Allows for more flexible
    %%% handling of different naming conventions.
    [matImageRow,matImageColumn]=cellfun(@filterimagenamedata,cellFileNames);

    if size(matNumericalPlateList,1) > 1
        matNumericalPlateList
        error('ConvertHandlesTo384DG: more then one plate layout detected in a single handles structure')
    end

    
    
%     return

    well = 0;
    
    cellstrGenePerWell = {1,384}; % GENE-SYMBOL | OLIGO-LETTER 
    
    cellImageIndicesPerWell = {1,384}; % ALL IMAGE INDICES MATCHING WELL
    
    matCtrlInfectionIndices = [];
    matNoVirusCtrlInfectionIndices = [];
    
    
    
    for rowNum = rowstodo

        for colNum = colstodo
            
            well = well + 1;

            %%% BS, 080819: Do filename matching using the
            %%% filterimagenamedata results
            matFileNameMatchIndices = find(matImageRow==rowNum & matImageColumn==colNum);
%             disp(sprintf('row %d col %d: %d image matches',rowNum,colNum,length(matFileNameMatchIndices)))

            
            %%% LOOK UP GENE DATA
            [genesymbol, oligonumber, geneid] = lookupwellcontent(matNumericalPlateList(1,1), rowNum, colNum);
            cellstrGenePerWell{1,well} = genesymbol;
            cellstrGeneID{1,well} = geneid;
            
            if isempty(oligonumber)
                matOligonumber(1,well) = 0;
            else
                matOligonumber(1,well) = oligonumber;                
            end
            
            matPlatenumber(1,well) = matNumericalPlateList(1,1);
            matReplicanumber(1,well) = matNumericalPlateList(1,2);
            matBatchnumber(1,well) = matNumericalPlateList(1,3);

            matWellRow(1,well) = rowNum;
            matWellCol(1,well) = colNum;            

            intImgTotal = 0;
            intImgTotalInfected = 0;
            intImgPerWell = 0;
            
            for i = 1:length(matFileNameMatchIndices)
                
                k = matFileNameMatchIndices(i);

                % if image is not out of focus, or if the out of focus data
                % is not present
                if (boolOutOfFocusData && not(OutOfFocusImage(1,k))) || not(boolOutOfFocusData)
                    intImgPerWell = intImgPerWell + 1;
                    intImgTotal = intImgTotal + handles.Measurements.Image.ObjectCount{1,k}(1,intObjectCountColumn);

                    % if infection data is present
                    if boolVirusData
                        intImgTotalInfected = intImgTotalInfected + handles.Measurements.(strObjectName).(VirusInfectionFieldName){k}(:,TotalInfectedIndex);
                    end
                end
            end
            
            
            matImagesPerWell(1,well) = intImgPerWell;
            matRawImagesPerWell(1,well) = length(matFileNameMatchIndices);
            
            cellImageIndicesPerWell{1,well} = matFileNameMatchIndices;
            
            if isempty(matFileNameMatchIndices)
                matTotal(1,well) = NaN; 
            else
                matTotal(1,well) = intImgTotal; 
            end
            
            if boolVirusData && ~isempty(matFileNameMatchIndices)
                matInfected(1,well) = intImgTotalInfected;
            else
                matInfected(1,well) = NaN;
            end

            if boolVirusData

                % BS,080108: Hardcoded 384 plate layout is NOT a good idea...
                if colNum > 2 && colNum < 23
                    matCtrlInfectionIndices = [matCtrlInfectionIndices, (intImgTotalInfected./intImgTotal)];
                    matCtrlCellNumbers = [matCtrlCellNumbers, intImgTotal];
                end
                if colNum == 1
                    matNoVirusCtrlInfectionIndices = [matNoVirusCtrlInfectionIndices, (intImgTotalInfected./intImgTotal)];
                end
            else
                matInfected(1,well) = NaN;
                matCtrlInfectionIndices = [matCtrlInfectionIndices, NaN];
                matCtrlCellNumbers = [matCtrlCellNumbers, intImgTotal];
                matNoVirusCtrlInfectionIndices = [matNoVirusCtrlInfectionIndices, (intImgTotalInfected./intImgTotal)];
            end
            
        end
    end
    
%     intMedianCtrlII = median2(matCtrlInfectionIndices);
    
end