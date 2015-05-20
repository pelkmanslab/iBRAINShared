function [matCompleteData, strFinalFieldName, matCompleteMetaData, structDataColumnsToUse, structMiscSettings, cellstrDataPaths] = getRawProbModelData2vito(strRootPath,strSettingsFile,intNumOfDirs, structDataColumnsToUse, structMiscSettings)
% Usage: 
%
% [matCompleteData, strFinalFieldName, matCompleteMetaData, structDataColumnsToUse, structMiscSettings, cellstrDataPaths] = getRawProbModelData(strRootPath,strSettingsFile)
%
% matCompleteData contains single-object (nucleus or cell object, usually)
% data, with columns described in strFinalFieldName, and after object
% exclusion as described in the settings file.
% 
%
% Where matCompleteMetaData contains 
%     Well row, 
%     Well column, 
%     Plate number, 
%     Cell plate number, 
%     Replica number, 
%     Image number, 
%     Object number
%       VZ: Site
%       VZ: timepoint
%
%
% The general rules for the settings file are as follows:
%
% structDataColumnsToUse.FileName = 'filename.mat'   |   'filepart' (required)
% structDataColumnsToUse.Column = 1 |   [1,3]   |   'all' (optional, default = 'all')
% structDataColumnsToUse.ObjectName = 'Nuclei' (optional, default = what is present in measurement file)
% structDataColumnsToUse.MeasurementName = 'LocalCellDensity' (optional, default = what is present in measurement file)
% structDataColumnsToUse.DiscardNaNs = true   |   false (optional, default = true)
% 
% datablocks are separated by at least a single empty line.
% 
% If filenames do not resolve to an existing file, they are considered to
% be a "filepart", which gets searched via a regular expression as follows:
% "Measurements_.*filepart.*\.mat". If this resolves to a list of files
% with a number at the end, the file with the highest number is returned.
% Otherwise, the alphabetically last file is chosen.  
% 
% The fields ObjectName and MeasurementName can be left out if it is clear
% from the measurement file what you want to be loaded. 
% 
% structMiscSettings.ObjectCountName = 'Nuclei' (optional, defaults are 'Nuclei', 'PreNuclei' or 'Cells')
% structMiscSettings.RegExpImageName = '_[A-K](02|03|04)_' (optional regular expression, default is all images)
% 
% structMiscSettings.ObjectsToExclude.MeasurementsFileName = 'filename.mat'   |   'filepart' (required)
% structMiscSettings.ObjectsToExclude.ValueToKeep = 1 (required)
% structMiscSettings.ObjectsToExclude.ValueToKeepMethodString = '>5' (optional, get's evaluated)
% structMiscSettings.ObjectsToExclude.Column = 1 |   [1,3]   |   'all' (optional, default = 1)
% structMiscSettings.ObjectsToExclude.ObjectName = 'Nuclei' (optional, default = what is present in measurement file)
% structMiscSettings.ObjectsToExclude.MeasurementName = 'LocalCellDensity' (optional, default = what is present in measurement file)
%
%
% See also: getObjectsToInclude getRawProbModelData2_caching initStructDataColumnsToUse findPlates 
%
%
% Below follows an example of a settings file:
%
% %%%% BEGIN OF SETTINGS FILE
% %
% % allowed fields for new format = 'Column','FileName','DiscardNaNs','ObjectName','MeasurementName','Label'
% 
% structDataColumnsToUse = struct();
% 
% 
% structDataColumnsToUse.Column = 'all'; % can be 'all' | [1,2] | 1
% structDataColumnsToUse.FileName = 'Measurements_Cells_MeanIntensity_RescaledRedEEA1Vesicles.mat';   
% structDataColumnsToUse.DiscardNaNs = false
% 
% structDataColumnsToUse.Column = 1;
% structDataColumnsToUse.FileName = 'Measurements_Nuclei_LocalCellDensity.mat';
% 
% structDataColumnsToUse.Column = 1;
% structDataColumnsToUse.FileName = 'Measurements_Nuclei_Edge.mat';
% 
% structDataColumnsToUse.Column = 1;
% structDataColumnsToUse.FileName = 'Measurements_PreNuclei_AreaShape.mat';
% 
% structDataColumnsToUse.Column = [1,6];
% structDataColumnsToUse.FileName = 'Measurements_Cells_AreaShape.mat';
% 
% structDataColumnsToUse.Column = 2;
% structDataColumnsToUse.FileName = 'Measurements_PreNuclei_Intensity_OrigBlue.mat';
% structDataColumnsToUse.Label = 'My Label!!!';
% 
% structDataColumnsToUse.Column = 1;
% structDataColumnsToUse.FileName = 'SVM_BiNuclei'; 
% 
% 
% 
% structMiscSettings = struct();
% 
% structMiscSettings.RegExpImageNamesToInclude = '_[A-P](02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23)';%384 layout 
% 
% % we can now pass what object count to take. This setting now allows one to load measurements from vesicles or from any other object. Defaults are Nuclei, Cells or PreNuclei.
% % structMiscSettings.ObjectCountName = 'PreNuclei';
% 
% % Note,if column is missing, the first column is taken.
% % Object and Measurement handling is the same as above for structDataColumnsToUse.
% 
% % allowed fields for new format = 'MeasurementsFileName','Column','ObjectName','MeasurementName','ValueToKeep','ValueToKeepMethodString'
%
% % For instance, only include cells with less than 20 vesicles
% %structMiscSettings.ObjectsToExclude.Column = 1;
% %structMiscSettings.ObjectsToExclude.MeasurementsFileName = 'Measurements_Cells_MahalDistanceTot_OrigGreen.mat';
% %structMiscSettings.ObjectsToExclude.ValueToKeepMethodString = '>23'; % for instance
% 
% 
% % Only include cells that are scored by SVM as non badly segmented
% structMiscSettings.ObjectsToExclude.Column = 1;
% structMiscSettings.ObjectsToExclude.MeasurementsFileName = 'SVM_BigCells';
% structMiscSettings.ObjectsToExclude.ValueToKeep = 2;
% 
% % not consider cells that touch the border
% structMiscSettings.ObjectsToExclude.Column = 1;
% structMiscSettings.ObjectsToExclude.MeasurementsFileName = 'Measurements_Cells_BorderCells.mat';
% structMiscSettings.ObjectsToExclude.ValueToKeep = 0;    
% 
% % Only include cells that are scored by SVM as interphase
% structMiscSettings.ObjectsToExclude.Column = 1;
% structMiscSettings.ObjectsToExclude.MeasurementsFileName = 'SVM_interphase';
% structMiscSettings.ObjectsToExclude.ValueToKeep = 1;
% 
% % Only include cells that are scored by SVM as interphase
% structMiscSettings.ObjectsToExclude.Column = 1;
% structMiscSettings.ObjectsToExclude.MeasurementsFileName = 'SVM_BiNuclei';
% structMiscSettings.ObjectsToExclude.ValueToKeep = 2;
% 
% % Only include cells that are scored by SVM as non badly segmented
% structMiscSettings.ObjectsToExclude.Column = 1;
% structMiscSettings.ObjectsToExclude.MeasurementsFileName = 'SVM_OutofFocus';
% structMiscSettings.ObjectsToExclude.ValueToKeep = 2;
% 
% 
% % Only include cells that are scored by SVM as non badly segmented
% structMiscSettings.ObjectsToExclude.Column = 1;
% structMiscSettings.ObjectsToExclude.MeasurementsFileName = 'SVM_Mitotic';
% structMiscSettings.ObjectsToExclude.ValueToKeep = 2;
% 
% %%%% END OF SETTINGS FILE
%
%






    if nargin==0

        strRootPath = npc('Y:\Data\Users\Prisca\endocytome\');
        strSettingsFile = npc('Y:\Data\Users\Prisca\endocytome\090203_MZ_w2Tf_w3EEA1\getRawProbModData2_NEW_INPUT.txt');

    end

    if nargin <= 3

        disp(sprintf('%s:  retreiving settings from %s',mfilename,strSettingsFile))
        [structDataColumnsToUse, structMiscSettings] = initStructDataColumnsToUse(strSettingsFile);
        
    else
        
        fprintf('%s:  using directly applied settings',mfilename,strSettingsFile)
        
    end

   
    %%%
    % here we can implement caching, check if results have already been
    % gathered once, if they're up to date, return these rather than
    % regetting everything.
    % input should be the following: strRootPath,structDataColumnsToUse, structMiscSettings
    fprintf('%s:  checking local cache.\n',mfilename)
    [boolCacheLoaded, matCompleteData, strFinalFieldName, matCompleteMetaData, strCachePath, cellstrDataPaths] = getRawProbModelData2_caching(strRootPath, structDataColumnsToUse, structMiscSettings);
    if boolCacheLoaded
        fprintf('%s:  Succesfully loaded data from local cache.\n',mfilename)
        return
    else
        clear matCompleteData strFinalFieldName matCompleteMetaData cellstrDataPaths
    end
    %%%

    disp(sprintf('%s:  looking for plates in %s',mfilename,strRootPath))
    
    % first, try the iBRAIN database, if this doesnt return anything,
    % retry...
    cellstrDataPaths = findPlates(strRootPath); %looks for a BATCH
    if isempty(cellstrDataPaths)
        cellstrDataPaths = getPlateDirectoriesFromiBRAINDB(strRootPath);
%         cellstrDataPaths = getbasedir(SearchTargetFolders(strRootPath,'Measurements_Image_FileNames.mat'));
    end
    cellstrDataPaths = sort(cellstrDataPaths);
    
    
    if nargin < 3 || isempty(intNumOfDirs)
        disp(sprintf('%s:  found %d plates',mfilename,size(cellstrDataPaths,1)))
        intNumOfDirs = [1:size(cellstrDataPaths,1)];
    else
        fprintf('%s:  found %d plates, but taking only the following plate-number(s)\n',mfilename,size(cellstrDataPaths,1))
        fprintf('\t\t\tnumber %d\n',intNumOfDirs)
    end

    matCompleteData = [];
    matCompleteMetaData = [];
    cellLoadedFiles = cell(3,0);
    
    for iDir = intNumOfDirs

        matFinalData = [];
        matFinalMetaData = [];
        strFinalFieldName = {};
        matDiscardNaNs = true(0);
        
        strDataPath = cellstrDataPaths{iDir};    
        disp(sprintf('%s:  analyzing %s',mfilename,strDataPath))


        %%% INITIALIZE PLATEDATAHANDLES
        PlateDataHandles = struct();
        PlateDataHandles = LoadMeasurements(PlateDataHandles, fullfile(strDataPath,'Measurements_Image_FileNames.mat'));    
        PlateDataHandles = LoadMeasurements(PlateDataHandles, fullfile(strDataPath,'Measurements_Image_ObjectCount.mat'));

        % parse filenames
        cellImageNames = cat(1,PlateDataHandles.Measurements.Image.FileNames{:});
        cellImageNames = cellImageNames(:,1);
        
        % Check regular-expression, image, and object exclusion
        cellObjectsToInclude = getObjectsToInclude(strDataPath, PlateDataHandles, structMiscSettings);

        %%% GET PER IMAGE INFORMATION ON PLATE WELL LOCATION
        % VZ: I changed filterimagenamedata to output also timepoint & site
        [matImageNamePlateRows,matImageNamePlateColumns ,matImageNamePlateTimepoints,matImageNamePlateSites]=cellfun(@filterimagenamedataIBT,cellImageNames','UniformOutput',1);

        %%% FILTER PLATE DATA, GET CELL-PLATE AND REPLICA NUMBER
        [intCPNumber, intReplicaNumber] = filterplatedata(strDataPath);
        
        %%% LOOP OVER ALL FIELDNAMES IN STRUCTDATACOLUMNSTOUSE
        cellstrNucleiFieldnames = fieldnames(structDataColumnsToUse);

        for i = 1:length(cellstrNucleiFieldnames)%%% ORIGINAL
                
            % the name of the measurement block, which is no longer per se
            % the same as the measurement name (!)
            strMeasurementBlockName = char(cellstrNucleiFieldnames{i});
    
            % loop over multiple instances of the same 'parent' field
            for iiX = 1:length(structDataColumnsToUse.(strMeasurementBlockName))

                % get the measurement file name
                if isfield(structDataColumnsToUse.(strMeasurementBlockName)(iiX),'MeasurementsFileName')
                    strMeasurementFilePart = structDataColumnsToUse.(strMeasurementBlockName)(iiX).MeasurementsFileName;
                    strMeasurementFilePath = fullfile(strDataPath,structDataColumnsToUse.(strMeasurementBlockName)(iiX).MeasurementsFileName);
                elseif isfield(structDataColumnsToUse.(strMeasurementBlockName)(iiX),'FileName')
                    strMeasurementFilePart = structDataColumnsToUse.(strMeasurementBlockName)(iiX).FileName;
                    strMeasurementFilePath = fullfile(strDataPath,structDataColumnsToUse.(strMeasurementBlockName)(iiX).FileName);    
                else
                    warning('bsBla:NoFileFound','%s: settings file block contained no filename reference.',mfilename)
                    continue
                end                
                
                % check if the file exists, if not, or if it does not end
                % on .mat, we should check if it evaluates to a valid
                % measurement file
                if ~fileattrib(strMeasurementFilePath)
                    strLatestFile = find_best_matching_file(strDataPath,strMeasurementFilePart);
                    strMeasurementFilePath = fullfile(strDataPath,strLatestFile);
                end
                
                %%% IF THE CURRENT REQUIRED DATA IS NOT PRESENT, THEN LOAD
                %%% THE CORRESPONDING RAW DATA FILE 
                % if ~isfield(PlateDataHandles.Measurements,strObjectName) || ~isfield(PlateDataHandles.Measurements.(strObjectName),strMeasurementName)
                if ~ismember(strMeasurementFilePath,cellLoadedFiles(1,:))
                    if fileattrib(strMeasurementFilePath)
                        fprintf('%s:  +-- loading %s\n',mfilename,getlastdir(strMeasurementFilePath))
                        [PlateDataHandles, cellAvailableObjects, cellAvailableMeasurements] = LoadMeasurements(PlateDataHandles, strMeasurementFilePath);

                        % remove uwanted measurement names, like
                        % measurements ending with '...Features'.
                        cellAvailableMeasurements( ...
                            ~cellfun(@isempty,regexp(cellAvailableMeasurements,'.*Features$')) ...
                            ) = [];
                        % also remove the SVMp field, as it's never ever
                        % used...
                        cellAvailableObjects(strcmp(cellAvailableObjects,'SVMp')) = [];
                        % add to list of loaded files
                        cellLoadedFiles(1,end+1) = {strMeasurementFilePath}; %#ok<AGROW>
                        cellLoadedFiles{2,end} = cellAvailableObjects;
                        cellLoadedFiles{3,end} = cellAvailableMeasurements;

                    else
                        warning('bsBla:FileNotFound','%s: file ''%s'' does not exist in ''%s''.',mfilename,getlastdir(strMeasurementFilePath),getbasedir(strMeasurementFilePath))
                        continue
                    end
                else
                    % look up the objects and measurement naems
                    % associated with this file.
                    matLoadedFileIX = ismember(cellLoadedFiles(1,:),strMeasurementFilePath); %#ok<AGROW>
                    cellAvailableObjects = cellLoadedFiles(2,matLoadedFileIX);
                    cellAvailableMeasurements = cellLoadedFiles(3,matLoadedFileIX);
                end 

                % get object name, either from user, or from
                % measurement file
                if isfield(structDataColumnsToUse.(strMeasurementBlockName)(iiX),'ObjectName')
                    strObjectName = structDataColumnsToUse.(strMeasurementBlockName)(iiX).ObjectName;
                elseif size(cellAvailableObjects{1},1)==1
                    strObjectName = char(cellAvailableObjects{1});
                else
                    error('I do not know what object to take from this measurement file... please specify')
                end

                % get measurement name, either from user, or from
                % measurement file 
                if isfield(structDataColumnsToUse.(strMeasurementBlockName)(iiX),'MeasurementName')
                    strMeasurementName = structDataColumnsToUse.(strMeasurementBlockName)(iiX).MeasurementName;
                elseif size(cellAvailableMeasurements{1},1)==1
                    strMeasurementName = char(cellAvailableMeasurements{1});
                elseif ismember(strMeasurementBlockName,cellAvailableMeasurements{1})
                    strMeasurementName = strMeasurementBlockName;
                else
                    error('I do not know what measurement to take from this measurement file... please specify')
                end


                % get measurement in cell array
                cellMeasurement = PlateDataHandles.Measurements.(strObjectName).(strMeasurementName);                
                
                % if it's not a cell, let's convert it to one (OutOfFocus for
                % example...)
                if ~iscell(cellMeasurement);
                    cellMeasurement = arrayfun(@(x) {x},cellMeasurement);
                end
                    
                % check what column to work on. default is 'all'
                if ~isfield(structDataColumnsToUse.(strMeasurementBlockName)(iiX),'Column')
                    matColumnsIXToProcess = 1:max(cellfun(@(x) size(x,2),cellMeasurement));
                else
                    % if we request 'all' columns to be loaded, check how many
                    % columns there are
                    if strcmpi(structDataColumnsToUse.(strMeasurementBlockName)(iiX).Column,'all')
                        matColumnsIXToProcess = 1:max(cellfun(@(x) size(x,2),cellMeasurement));
                    else
                        matColumnsIXToProcess = structDataColumnsToUse.(strMeasurementBlockName)(iiX).Column;
                    end
                end
                
                % loop over each requested data column
                for ii = 1:size(matColumnsIXToProcess,2)

                    % get current column index
                    intColumnIX = matColumnsIXToProcess(ii);
                    
                    % create a default final field name
                    strFinalFieldName = [strFinalFieldName, sprintf('%s_%s_%d',strMeasurementName,strObjectName,intColumnIX)]; %#ok<AGROW>
                    % if label is given, overwrite fieldname with label
                    if isfield(structDataColumnsToUse.(strMeasurementBlockName)(iiX),'Label')
                        if ~isempty(structDataColumnsToUse.(strMeasurementBlockName)(iiX).Label)
                            strFinalFieldName{end} = structDataColumnsToUse.(strMeasurementBlockName)(iiX).Label;
                        end
                    end
                    
                    % kick out other columns than the selected one
                    matEmptyImages = cellfun(@isempty,cellMeasurement);% skip empty wells
                    % initialize as empty
                    cellCurrentMeasurementColumn = cell(size(cellMeasurement));
                    % fill in with just the right column
                    cellCurrentMeasurementColumn(~matEmptyImages) = cellfun(@(x) x(:,intColumnIX),cellMeasurement(~matEmptyImages),'UniformOutput',false);

                    % if we're dealing with an image-object, let's repeat the value for
                    % each object, so that the dimensions match.
                    if strcmpi(strObjectName,'Image')
                        cellCurrentMeasurementColumn = cellfun(@(x,y) repmat(y(1,1),x(1,intColumnIX),1), PlateDataHandles.Measurements.Image.ObjectCount(~matEmptyImages), cellCurrentMeasurementColumn(~matEmptyImages),'UniformOutput',false);
                    end
                    
                    fprintf('%s:  +-- processing Measurements.%s.%s column %d\n',mfilename,strObjectName,strMeasurementName,intColumnIX)
                    
                    % look up images with cells to include. unfortunately,
                    % sometimes cells with a single measurement are empty.
                    matNonEmptyImages = cellfun(@sum,cellObjectsToInclude)>1;
                    % get data from those images
                    matPlateData = cellfun(@(x,y) x(y,1), cellCurrentMeasurementColumn(matNonEmptyImages),cellObjectsToInclude(matNonEmptyImages),'UniformOutput',false);
                    matPlateData = cell2mat(matPlateData');

                    %%% LOG10 TRANSFORM DATA IF SETTINGS SAY TO DO SO                            
                    if isfield(structDataColumnsToUse.(strMeasurementBlockName)(iiX),'Log10Transform')
                       if structDataColumnsToUse.(strMeasurementBlockName)(iiX).Log10Transform
                            matPlateData = log10(matPlateData);
                            matPlateData(isinf(matPlateData)) = NaN;
                       end
                    end

                    % we really should pre-allocate this... :(
                    matFinalData = [matFinalData, matPlateData];
                    
                    % keep track if we shold discard NaNs
                    if isfield(structDataColumnsToUse.(strMeasurementBlockName)(iiX),'DiscardNaNs')
                        matDiscardNaNs = [matDiscardNaNs,structDataColumnsToUse.(strMeasurementBlockName)(iiX).DiscardNaNs]; %#ok<AGROW>
                    else
                        % default behaviour is true
                        matDiscardNaNs = [matDiscardNaNs,true]; %#ok<AGROW>
                    end

                    fprintf('%s:  +-- added feature %d: %d %s measurements from plate %d of %d\n',mfilename,size(matFinalData,2),size(matFinalData,1),strFinalFieldName{end},find(intNumOfDirs==iDir),length(intNumOfDirs))
                    
                end
            end
            

        end

        % create meta data where matCompleteMetaData contains 
        %     Row, 
        %     Column, 
        %     Plate number, 
        %     Cell Plate number, 
        %     Replica number, 
        %     Image number, 
        %     Object number                    
        matObjectCount = cellfun(@sum,cellObjectsToInclude(matNonEmptyImages));
        matObjectIX = cell2mat(cellfun(@find,cellObjectsToInclude(matNonEmptyImages),'UniformOutput',false)');
        matImageIX = find(matNonEmptyImages);

        % init meta data
       
        %matFinalMetaData = nan(size(matPlateData,1),7);
        matFinalMetaData = nan(size(matPlateData,1),9);
       
        
        matFinalMetaData(:,[1,2,6,8,9]) = cell2mat(arrayfun(@(a,b,c,d,e,f) repmat([a,b,c,d,e],f,1), ...
                matImageNamePlateRows(matNonEmptyImages), ...
                matImageNamePlateColumns(matNonEmptyImages), ...
                matImageIX, ...
                matImageNamePlateSites(matNonEmptyImages), ...
                matImageNamePlateTimepoints(matNonEmptyImages), ...
                matObjectCount ...
                ,'UniformOutput',false)');

        matFinalMetaData(:,3) = iDir;
        matFinalMetaData(:,4) = intCPNumber;
        matFinalMetaData(:,5) = intReplicaNumber;
        matFinalMetaData(:,7) = matObjectIX;

        
        % merge data from different plates
        try
            matCompleteData = [matCompleteData;matFinalData];
            matCompleteMetaData = [matCompleteMetaData;matFinalMetaData];
%             size(matCompleteData)
            if iDir == intNumOfDirs
                fprintf('%s:  total cell number: %d\n',mfilename,size(matCompleteData,1))            
            else
                fprintf('%s:  sub-total cell number: %d\n',mfilename,size(matCompleteData,1))            
            end
        catch foo
            warning('BSBla','%s: failed to add plate data to total data, probably out of memory',mfilename)
        end
    end

    % remove any cells with NaN values, if any of the columns shold be
    % nan-discarded
    if any(matDiscardNaNs)
        matNaNRowIndices = any(isnan(matCompleteData(:,find(matDiscardNaNs))),2);
        if sum(matNaNRowIndices) > 0
            fprintf('%s:  removing %d rows with NaN values\n',mfilename,sum(matNaNRowIndices))
            matCompleteData(matNaNRowIndices,:) = [];
            matCompleteMetaData(matNaNRowIndices,:) = [];
        end
    end

    %%%
    % If we do caching, and we've just loaded all this data, we should
    % store the results back to the local cache. (If we don't do caching,
    % the path will be empty!)
    if ~isempty(strCachePath)
        strCacheBaseName = sprintf('%s%s',datestr(now,30),datestr(now,'FFF'));
        save(fullfile(strCachePath, [strCacheBaseName,'_overview.mat']),'strRootPath','structDataColumnsToUse','structMiscSettings','cellstrDataPaths')
        save(fullfile(strCachePath, [strCacheBaseName,'_data.mat']),'matCompleteData','matCompleteMetaData','strFinalFieldName')
        fprintf('%s: Stored results in local cache.\n',mfilename)
    end
    %%%

    % done!    
    
end







function strSvmMeasurementName = find_best_matching_file(strRootPath, strSvmStrMatch)
% find svm files matching current searchstring, and return the one with the
% highest number

% get list of all matching files present
cellSvmDataFiles = findfilewithregexpi(strRootPath,sprintf('Measurements_.*%s.*\\.mat',strSvmStrMatch));

if isempty(cellSvmDataFiles)
    warning('bs:Bla','no files found in %s matching to %s',strRootPath,strSvmStrMatch)
    return
elseif ~iscell(cellSvmDataFiles) && ischar(cellSvmDataFiles)
    % only one hit found, use that...
    strSvmMeasurementName=  cellSvmDataFiles;
    return
end

% see if they all have a number at the end. if so, base pick on highest
% number
cellSvmPartMatches = regexpi(cellSvmDataFiles,'Measurements_.*_(\d*).mat','Tokens');

if all(~cellfun(@isempty,cellSvmPartMatches))
    matSvmNumbers = cellfun(@(x) str2double(x{1}),cellSvmPartMatches);

    % find highest number
    [~,intMaxIX] = max(matSvmNumbers);

    % return file name corresponding to highest number
    strSvmMeasurementName = cellSvmDataFiles{intMaxIX};
else
    
    % otherwise, pick the alphabetically last one... (works often for SVMs
    % for isntance)
    strSvmMeasurementName = cellSvmDataFiles{end};
end

end