function [matTotal, matInfected, matImagesPerWell, cellstrGenePerWell, matOligonumber, matPlatenumber, matReplicanumber, matBatchnumber, matCtrlInfectionIndices, matWellRow, matWellCol] = ConvertHandlesTo384DG_noninfctrl(strRootPath, handles)
    
    if nargin == 0
        strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\VSV_DG\070314_VSV_DG_batch1_CP001-1ac\DATAFUSION\';
    end
    
%     if nargin == 1
        if ischar(strRootPath)
            handles = struct();
            handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_FileNames.mat']);
            handles = LoadMeasurements(handles, [strRootPath,'Measurements_Nuclei_VirusScreen_ClassicalInfection_Overview2_noninfctrl.mat']);
            handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_ObjectCount.mat']);
            handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_OutOfFocus.mat']);            
        else
            error('ConvertHandlesTo384DG: the input path should be a string')
        end
%     end

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
    
    rowstodo = 1:16;
    colstodo = 1:24;
    
    matRows = cellstr(regexp(char(65:80),'\w','match'));
    matCols = regexp(sprintf('%.2d',1:24),'\d\d','match');
    
    if ~exist('handles','var')
        warndlg('a valid cellprofiler handles variable is required')
        return
    end

    if ~isfield(handles,'Measurements')
        warndlg('there are no measurements in your handles file')
        return
    end
    
    if isfield(handles.Measurements,'Nuclei')
        strObjectName = 'Nuclei';
    elseif isfield(handles.Measurements,'Cells')
        strObjectName = 'Cells';
    else
        warndlg('there are no Cells or Nuclei objects in your handles file')
        return
    end

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
    
% % %     %%% CONVERT IMAGE OR FOLDER NAME TO CP-NUMBER, REPLICATE-NUMBER, AND
% % %     %%% BATCH-NUMBER, ASSUMING ALL IMAGES HAVE SAME FOLDER NAMES
% % %     strPlateName = strRootPath;
% % %     strPlateName = strrep(strPlateName,'\BATCH','');
% % %     strPlateName = strrep(strPlateName,'\DATAFUSION','');    
% % %     strPlateName = getlastdir(strPlateName);  
% % % %     matNumericalPlateList = zeros(size(cellFileNames,1),3);
% % % %     for i = 1:size(cellFileNames,1)
% % % %         strPlateName = char(cellFileNames(i));
% % %         i = 1;
% % %         disp(sprintf('parsing filename %s',strPlateName))
% % %         
% % %         if isempty(regexp(strPlateName,'batch\dCP', 'ONCE'))
% % %             platenumindx = strfind(strPlateName,'_CP')+3:strfind(strPlateName,'-')-1;
% % %         else
% % %             platenumindx = strfind(strPlateName,'CP')+2:strfind(strPlateName,'-')-1;
% % %         end
% % %         batchnumindx = strfind(strPlateName,'_batch')+6;
% % % 
% % % %         y = strfind(strPlateName,'-');
% % % %         x = strfind(strPlateName(y:end),'_');
% % % %         replicaindx = y+1:x(1)+y-2;
% % %         replicaindx = length(strPlateName);
% % % 
% % % 
% % % %         [platenumindx]
% % % %         strPlateName([platenumindx])
% % %         matNumericalPlateList(i,1) = str2double(strPlateName([platenumindx])); % CP NUMBER
% % %         matNumericalPlateList(i,2) = strPlateName(replicaindx(end)) - 96; % CP REPLICATE NUMBER
% % %         if isnan(str2double(strPlateName(batchnumindx)))
% % %             matNumericalPlateList(i,3) = 0; % BATCH NUMBER
% % %         else
% % %             matNumericalPlateList(i,3) = str2double(strPlateName(batchnumindx)); % BATCH NUMBER
% % %         end
% % %         matNumericalPlateList
%     end
% 
%     % CHECK IF THERE IS ONE UNIQUE PLATE LAYOUT
%     matNumericalPlateList = unique(matNumericalPlateList, 'rows');
    if size(matNumericalPlateList,1) > 1
        matNumericalPlateList
        error('ConvertHandlesTo384DG: more then one plate layout detected in a single handles structure')
    end

    
    
%     return

    well = 0;
    
    cellstrGenePerWell = {1,384}; % GENE-SYMBOL | OLIGO-LETTER 
    
    matCtrlInfectionIndices = [];
    
    for rowNum = rowstodo

        for colNum = colstodo
            
            well = well + 1;
            %'_' 'A' '01' should match well A01 depending on the
            %nomenclature of the microscope & images.
            
            str2match = strcat('_',matRows(rowNum), matCols(colNum));
            FileNameMatches = strfind(cellFileNames, char(str2match));
            matFileNameMatchIndices = find(~cellfun('isempty',FileNameMatches));

            %%% LOOK UP GENE DATA
            [genesymbol, oligonumber] = lookupwellcontent(matNumericalPlateList(1,1), rowNum, colNum);
            cellstrGenePerWell{1,well} = genesymbol;
            
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
                if not(OutOfFocusImage(1,k)) | not(boolOutOfFocusData)
                    intImgPerWell = intImgPerWell + 1;
                    intImgTotal = intImgTotal + handles.Measurements.Image.ObjectCount{1,k}(1,1);

                    % if infection data is present
                    if boolVirusData
                        intImgTotalInfected = intImgTotalInfected + handles.Measurements.(strObjectName).(VirusInfectionFieldName){k}(:,TotalInfectedIndex);
                    end
                end
            end
            
            
            matImagesPerWell(1,well) = intImgPerWell;
            matTotal(1,well) = intImgTotal; 
            
            %%% filter out minimal cell numbers
            if boolVirusData & (intImgTotal > 650)
                matInfected(1,well) = intImgTotalInfected;
                
                if colNum > 2 && colNum < 23
                    matCtrlInfectionIndices = [matCtrlInfectionIndices, (intImgTotalInfected./intImgTotal)];
                end
            else
                matInfected(1,well) = NaN;
                if colNum > 2 && colNum < 23
                    matCtrlInfectionIndices = NaN;
                end
            end
            
        end
    end
    
%     intMedianCtrlII = median2(matCtrlInfectionIndices);
    
    
    
    
    
    
    
end