function [cellObjectsToInclude, matIncludedFractionPerWell] = getObjectsToInclude(strRootPath, handles, structMiscSettings)

% [cellObjectsToInclude, matIncludedFractionPerWell] = getObjectsToInclude(strRootPath, handles, structMiscSettings)
%
% returns a cellArray per image with for the typical cell/nucleus object
% wether to include (true/1) or exclude (false/0) those objects.
%
% settings are loaded from structMiscSettings as it comes from
% initStructDataColumnsToUse(strSettingsFile) for a given settings file.
%
% regular-expression filename exclusion, image, and object exclusion is
% done by this function.
%
% The optional logical input structMiscSettings.requireConsistentObjectAmount
% will cause data of sites with inconsistent number of nuclei and/or cells
% and/or cytoplasms to be removed. Often this data would be corrupted.
% Another optional input structMiscSettings.ObjectCountsGroup can be used to specify
% any objects whose count consistency you wish to check. If absent, the default is nuclei, cytoplasm and cells.  

% output
cellObjectsToInclude = {};
matIncludedFractionPerWell = nan(16,24);

% objects to look for that represent the target object type.
cellstrTargetObjects = {'Nuclei','PreNuclei','Cells'};

if nargin==0
    strRootPath = npc('\\nas-unizh-imsb1.ethz.ch\share-3-$\Data\Users\HPV16_DG\2008-12-8_HPV16_batch3_CP064-1ec\BATCH');
    strSettingsFile = npc('Z:\Data\Users\SV40_DG\load_sliding_window_SVMInfectionDG.txt');
    
    fprintf('%s:  retreiving settings from %s\n',mfilename,strSettingsFile)
    [structDataColumnsToUse, structMiscSettings] = initStructDataColumnsToUse(strSettingsFile);     %#ok<ASGLU>
    
    %%% init handles
    handles = struct();
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_FileNames.mat'));
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_ObjectCount.mat'));
end

if isempty(handles)
    %%% init handles
    handles = struct();
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_FileNames.mat'));
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_ObjectCount.mat'));
end

fprintf('%s:  analyzing "%s"\n',mfilename,strRootPath)

% parse filename
cellImageNames = cat(1,handles.Measurements.Image.FileNames{:});
cellImageNames = cellImageNames(:,1);

% let's start by assuming all nuclei/cells should be included

% if the misc settings contains the field "ObjectCountName", which
% refers to a object for which we have an object count, use that,
% otherwise use the standard behaviour of the first match with the
% names in cellstrTargetObjects
intTargetobjectIX = 0;
if isfield(structMiscSettings,'ObjectCountName')
    if any(ismember(handles.Measurements.Image.ObjectCountFeatures,structMiscSettings.ObjectCountName))
        intTargetobjectIX = find(ismember(handles.Measurements.Image.ObjectCountFeatures,structMiscSettings.ObjectCountName),1,'first');
    end
end

% check for sites, where nuclei and cytoplasm amount differ.
[discardSitesInconsistentObjectAmount matSitesDifferentNucleiAndCytoplasm] = initializeComparisonNucleiAndCytoplasmAmount(handles,structMiscSettings);

% previous conditions not met, fall back on default behaviour
if intTargetobjectIX==0
    intTargetobjectIX = find(ismember(handles.Measurements.Image.ObjectCountFeatures,cellstrTargetObjects),1,'first');
end
% get object name
strTargetObjectName = handles.Measurements.Image.ObjectCountFeatures{intTargetobjectIX};

if isempty(intTargetobjectIX)
    cellstrTargetObjects %#ok<NOPRT>
    handles.Measurements.Image.ObjectCountFeatures
    error('%s: couldn''t find a match for the target object list!',mfilename)
end

% init cellObjectsToInclude as trues for each object for each image.
% Next, for each exclusion step we'll one-by-one set objects to 'false'
cellObjectsToInclude = cellfun(@(x) repmat(true,x(1,intTargetobjectIX),1), handles.Measurements.Image.ObjectCount,'UniformOutput',false);
% same for objects to include in model..
cellObjectsToIncludeInModel = cellObjectsToInclude;


% Let's make backward compatibility with old settings file. Translate
% 'ImagesToExclude' to ObjectsToExclude block, assuming outoffocus.mat
% measurement (or similar format - [VG])
if isfield(structMiscSettings,'ImagesToExclude')
    fprintf('%s: found ''ImagesToExclude'' field. Updating to new format.\n',mfilename)
    for i = 1:size(structMiscSettings.ImagesToExclude,2) % [VG] can now take multiple image exclusion measurements
        intObjBlockCount = length(structMiscSettings.ObjectsToExclude) + 1;
        structMiscSettings.ObjectsToExclude(intObjBlockCount).ObjectName = structMiscSettings.ImagesToExclude(1,i).ObjectName;
        structMiscSettings.ObjectsToExclude(intObjBlockCount).MeasurementsFileName = structMiscSettings.ImagesToExclude(1,i).MeasurementsFileName;
        structMiscSettings.ObjectsToExclude(intObjBlockCount).MeasurementName = structMiscSettings.ImagesToExclude(1,i).MeasurementName; % [VG] made general
        structMiscSettings.ObjectsToExclude(intObjBlockCount).Column = structMiscSettings.ImagesToExclude(1,i).Column;
        % Assume value to keep is '0', assuming standard
        % Measurements_Image_OutOfFocus.mat measurement.
        structMiscSettings.ObjectsToExclude(intObjBlockCount).ValueToKeep = 0;
    end
end

if ~isfield(structMiscSettings,'ObjectsToExclude')
    return
end

% let's load all (unique) exclusion data files
% also, we need to make smart guess as to object and measurement names,
% as in getRawProbModelData2.m
cellstrMeasurementFileList = unique(cat(1,{structMiscSettings.ObjectsToExclude(:).MeasurementsFileName}));

% see if we can load the measurement directly, or if we need to find
% the latest matching file...
cellstrMeasurementFileList2 = cellstrMeasurementFileList;
for iExclObj = 1:length(cellstrMeasurementFileList)
    strMeasurementFilePath = fullfile(strRootPath,cellstrMeasurementFileList{iExclObj});
    
    % if this isnt an esiting file, do the lookup, and store that result
    if ~fileattrib(strMeasurementFilePath)
        strLatestFile = find_best_matching_file(strRootPath,cellstrMeasurementFileList{iExclObj});
        cellstrMeasurementFileList2{iExclObj} = strLatestFile;
    end
end

% we should check if we have already stored these settings in the BATCH
% directory
strObjectDiscardingMeasurementFile = fullfile(strRootPath,sprintf('Measurements_%s_ObjectsToInclude.mat',strTargetObjectName));
strWellObjectDiscardingMeasurementFile = fullfile(strRootPath,sprintf('Measurements_Well_%sObjectsToInclude.mat',strTargetObjectName));
if fileattrib(strObjectDiscardingMeasurementFile)
    foo = load(strObjectDiscardingMeasurementFile);
    % we can store the settings (structMiscSettings) in the Features
    % field. I.e., if these are equal we can just load it from this
    % file (hmm... assuming files have not changed...)
    if isequal(structMiscSettings,foo.handles.Measurements.(strTargetObjectName).ObjectsToIncludeFeatures)
        
        cellstrMeasurementPaths = cellfun(@(x) fullfile(strRootPath,x),cellstrMeasurementFileList2,'UniformOutput',false);
        matDatesLastModified = cellfun(@getDatenumLastModified, cellstrMeasurementPaths);
        
        % if current resultfile is newer than all measurement files,
        % just use this...
        if all(getDatenumLastModified(strObjectDiscardingMeasurementFile) > matDatesLastModified)
            cellObjectsToInclude = foo.handles.Measurements.(strTargetObjectName).ObjectsToInclude;
            fprintf('%s:  - loaded results from ''%s''\n',mfilename,strObjectDiscardingMeasurementFile)
            fprintf('%s: including %d %s\n',mfilename,sum(cell2mat(cellObjectsToInclude')),strTargetObjectName)
            
            % also calculate second output, as this is not stored in
            % the file itself
            if nargout==2
                if fileattrib(strWellObjectDiscardingMeasurementFile)
                    load(strWellObjectDiscardingMeasurementFile)
                else
                    [intRow, intColumn] = cellfun(@filterimagenamedata,cellImageNames);
                    matImagePosData = [intRow, intColumn];
                    matIncludedFractionPerWell = NaN(16,24);
                    for iPos = unique(matImagePosData,'rows')'
                        matImageIX = ismember(matImagePosData,iPos','rows');
                        matIncludedFractionPerWell(iPos(1),iPos(2)) = nanmean(cat(1,cellObjectsToInclude{matImageIX}));
                    end
                    save(strWellObjectDiscardingMeasurementFile,'matIncludedFractionPerWell');
                end
            end
            
            return
        end
        
    end
end


% if there is a regular expression for image-name exlcusion
if isfield(structMiscSettings,'RegExpImageNamesToInclude')
    % look which images to exclude from the regular expression
    matImageIndicesToExclude = cellfun(@isempty,regexp(cellImageNames,structMiscSettings.RegExpImageNamesToInclude));
    fprintf('%s:  - excluding %d images (%.0f%%) with regular expression = "%s"\n',mfilename,sum(matImageIndicesToExclude(:)),100*mean(matImageIndicesToExclude(:)),structMiscSettings.RegExpImageNamesToInclude)
    
    % exclude objects from images that are not included in the regular
    % expression
    cellObjectsToInclude(matImageIndicesToExclude) = cellfun(@(x) ~x(x), cellObjectsToInclude(matImageIndicesToExclude),'UniformOutput',false);
    fprintf('%s:  - excluding %.0f%% (%d) of the %s with this regular expression\n',mfilename,100*mean(~cell2mat(cellObjectsToInclude')),sum(~cell2mat(cellObjectsToInclude')),strTargetObjectName)
end

%     % if there is a regular expression for image-name exlcusion
%     if isfield(structMiscSettings,'RegExpImageNamesToInclude')
%         % look which images to exclude from the regular expression
%         matImageIndicesToExclude = cellfun(@isempty,regexp(cellImageNames,structMiscSettings.RegExpImageNamesToInclude));
%         fprintf('%s:  - excluding %d images (%.0f%%) with regular expression = "%s"\n',mfilename,sum(matImageIndicesToExclude(:)),100*mean(matImageIndicesToExclude(:)),structMiscSettings.RegExpImageNamesToInclude)
%
%         % exclude objects from images that are not included in the regular
%         % expression
%         cellObjectsToInclude(matImageIndicesToExclude) = cellfun(@(x) ~x(x), cellObjectsToInclude(matImageIndicesToExclude),'UniformOutput',false);
%         fprintf('%s:  - excluding %.0f%% (%d) of the %s with this regular expression\n',mfilename,100*mean(~cell2mat(cellObjectsToInclude')),sum(~cell2mat(cellObjectsToInclude')),strTargetObjectName)
%     end
%     cellObjectsToIncludeInModel

% if there is no ObjectsToExclude field for object exclusion, we're
% done
if ~isfield(structMiscSettings,'ObjectsToExclude')
    fprintf('%s: Finished: settings file did not contain objects to exclude settings.\n',mfilename)
    return
end


% loop over each measurement, and load and parse the measurements
cellLoadedFiles = cell(3,0);
fprintf('%s:  - loading %d measurement files\n',mfilename,size(cellstrMeasurementFileList,2))
for iExclObj = 1:length(cellstrMeasurementFileList)
    
    
    % check if the file exists, if not, or if it does not end
    % on .mat, we should check if it evaluates to a valid
    % measurement file
    strMeasurementFilePath = fullfile(strRootPath,cellstrMeasurementFileList{iExclObj});
    if ~fileattrib(strMeasurementFilePath)
        strMeasurementFilePath = fullfile(strRootPath,cellstrMeasurementFileList2{iExclObj});
        [handles,cellAvailableObjects, cellAvailableMeasurements] = LoadMeasurements(handles,strMeasurementFilePath);
        fprintf('%s:    - %s (%s)\n',mfilename,cellstrMeasurementFileList2{iExclObj},cellstrMeasurementFileList{iExclObj})
    else
        [handles,cellAvailableObjects, cellAvailableMeasurements] = LoadMeasurements(handles,strMeasurementFilePath);
        fprintf('%s:    - %s\n',mfilename,cellstrMeasurementFileList{iExclObj})
    end
    
    % remove uwanted measurement names, like
    % measurements ending with '...Features'.
    cellAvailableMeasurements( ...
        ~cellfun(@isempty,regexp(cellAvailableMeasurements,'.*Features$')) ...
        ) = [];
    cellAvailableObjects(strcmp(cellAvailableObjects,'SVMp')) = [];
    
    % add to list of loaded files
    cellLoadedFiles(1,end+1) = cellstrMeasurementFileList2(iExclObj); %#ok<AGROW>
    cellLoadedFiles{2,end} = unique(cellAvailableObjects);
    cellLoadedFiles{3,end} = unique(cellAvailableMeasurements);
    
end



% for each ObjectsToExclude field
for iExclObj = 1:length(structMiscSettings.ObjectsToExclude)
    
    %%% NOTE TO SELF %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% MAKE IT WORK WITHOUT OBJECTNAME AND MEASUREMENTNAME! %%%
    matLoadedFileIX = strcmpi(cellstrMeasurementFileList,structMiscSettings.ObjectsToExclude(iExclObj).MeasurementsFileName);
    cellAvailableObjects = cellLoadedFiles{2,matLoadedFileIX};
    cellAvailableMeasurements = unique(cellLoadedFiles{3,matLoadedFileIX});
    
    
    % get object name, either from user, or from
    % measurement file
    strObjectName = '';
    if isfield(structMiscSettings.ObjectsToExclude(iExclObj),'ObjectName')
        strObjectName = structMiscSettings.ObjectsToExclude(iExclObj).ObjectName;
    end
    if isempty(strObjectName) && size(cellAvailableObjects{1},1)==1
        strObjectName = cellAvailableObjects{1};
    elseif isempty(strObjectName) && size(cellAvailableObjects{1},1)>1
        error('I do not know what object to take from this measurement file... please specify')
    end
    
    % get measurement name, either from user, or from
    % measurement file
    strMeasurementName = '';
    if isfield(structMiscSettings.ObjectsToExclude(iExclObj),'MeasurementName')
        strMeasurementName = structMiscSettings.ObjectsToExclude(iExclObj).MeasurementName;
    end
    if isempty(strMeasurementName) && size(cellAvailableMeasurements{1},1)==1
        strMeasurementName = cellAvailableMeasurements{1};
    elseif isempty(strMeasurementName) && size(cellAvailableMeasurements{1},1)>1
        error('I do not know what measurement to take from this measurement file... please specify')
    end
    
    % default column to number 1.
    intColumnIX = [];
    if isfield(structMiscSettings.ObjectsToExclude(iExclObj),'Column')
        intColumnIX = structMiscSettings.ObjectsToExclude(iExclObj).Column;
    end
    if isempty(intColumnIX)
        intColumnIX = 1;
    end
    
    cellMeasurement = handles.Measurements.(strObjectName).(strMeasurementName);
    % if it's not a cell, let's convert it to one (OutOfFocus for
    % example...)
    if ~iscell(cellMeasurement);
        cellMeasurement = arrayfun(@(x) {x},cellMeasurement);
    end
    % kick out other columns than the selected one
    matSitesToIgnore = cellfun(@isempty,cellMeasurement);% skip empty wells
    cellMeasurement(~matSitesToIgnore) = cellfun(@(x) x(:,intColumnIX),cellMeasurement(~matSitesToIgnore),'UniformOutput',false);
    
    % if we're dealing with an image-object, let's repeat the value for
    % each object, so that dimensions match.
    if strcmpi(strObjectName,'Image')
        cellMeasurement = cellfun(@(x,y) repmat(y(1,1),x(1,intTargetobjectIX),1), handles.Measurements.Image.ObjectCount, cellMeasurement,'UniformOutput',false);
    end
    
    % default to 'value to keep' is 1
    intValueToKeep = 1;
    if isfield(structMiscSettings.ObjectsToExclude(iExclObj),'ValueToKeep')
        if ~isempty(structMiscSettings.ObjectsToExclude(iExclObj).ValueToKeep)
            intValueToKeep = structMiscSettings.ObjectsToExclude(iExclObj).ValueToKeep;
        end
    end
    
    % note that ValueToKeepMethodString overrules ValueToKeep
    strValueToKeepMethod = '';
    if isfield(structMiscSettings.ObjectsToExclude(iExclObj),'ValueToKeepMethodString')
        strMethod = structMiscSettings.ObjectsToExclude(iExclObj).ValueToKeepMethodString;
        if ~isempty(strMethod)
            % let's parse out nonsense to keep stuff save, we are
            % going to eval this string after all :-)
            strMethod = strrep(strMethod,' ','');
            strMethod = regexp(strMethod,'([<=>]{1,}[-?\d.]{1,})','Tokens');
            strMethod = strMethod{1}{1};
            strValueToKeepMethod = strMethod;
        end
    end
    
    % do object exclusion, remember that strValueToKeepMethod overrules
    % intValueToKeep
    
    matEmptyImages = cellfun(@isempty,cellObjectsToInclude);% skip empty wells
    matSitesToIgnore = matEmptyImages;
    
    if discardSitesInconsistentObjectAmount == true
        if any(matSitesDifferentNucleiAndCytoplasm)
            matSitesToIgnore = matSitesToIgnore | matSitesDifferentNucleiAndCytoplasm;
        end
    end
    
    if isempty(strValueToKeepMethod)
        cellObjectsToInclude(~matSitesToIgnore) = cellfun(@(x,y) x==intValueToKeep & y, cellMeasurement(~matSitesToIgnore), cellObjectsToInclude(~matSitesToIgnore), 'UniformOutput',false);
        % report object exclusion
        fprintf('%s:  - excluding %02.0f%% (%d) of the %s (from remaining images) by keeping Measurement.%s.%s(:,%d)==%d',mfilename,100*mean(~cell2mat(cellObjectsToInclude(~matImageIndicesToExclude)')),sum(~cell2mat(cellObjectsToInclude(~matImageIndicesToExclude)')),strTargetObjectName,strObjectName,strMeasurementName,intColumnIX,intValueToKeep)
    else
        cellObjectsToInclude(~matSitesToIgnore) = cellfun(@(x,y) eval(sprintf('x%s',strValueToKeepMethod)) & y, cellMeasurement(~matSitesToIgnore), cellObjectsToInclude(~matSitesToIgnore), 'UniformOutput',false);
        % report object exclusion
        fprintf('%s:  - excluding %02.0f%% (%d) of the %s (from remaining images) by keeping Measurement.%s.%s(:,%d)%s',mfilename,100*mean(~cell2mat(cellObjectsToInclude(~matImageIndicesToExclude)')),sum(~cell2mat(cellObjectsToInclude(~matImageIndicesToExclude)')),strTargetObjectName,strObjectName,strMeasurementName,intColumnIX,strValueToKeepMethod)
    end
    % report Feature description for field
    if isfield(handles.Measurements.(strObjectName),([strMeasurementName,'Features']))
        strFieldDescription = handles.Measurements.(strObjectName).([strMeasurementName,'Features']){1,intColumnIX};
        fprintf(' (%s)\n',strFieldDescription)
    elseif isfield(handles.Measurements.(strObjectName),([strMeasurementName,'_Features']))
        strFieldDescription = handles.Measurements.(strObjectName).([strMeasurementName,'_Features']){intValueToKeep};
        fprintf(' (%s)\n',strFieldDescription)
    else
        fprintf('\n')
    end
    
end

% also discarding measurements from images with only one object. the
% measurements from CellProfiler from these images are sometimes weird.
% (also my own fault).
cellObjectsToInclude(cellfun(@numel,cellObjectsToInclude)<=1) = {false};


% Remove objects that are within sites with inconsistent object number
if discardSitesInconsistentObjectAmount == true
    if any(matSitesDifferentNucleiAndCytoplasm)
        ObjectsPerSite = cell2mat(cellfun(@(x) numel(x), cellObjectsToInclude,'UniformOutput',false));
        SitesInconsistentNucleiAndCytoplasm = find(matSitesDifferentNucleiAndCytoplasm);
        for j=1:length(SitesInconsistentNucleiAndCytoplasm)
            cellObjectsToInclude{SitesInconsistentNucleiAndCytoplasm(j)} = ...
                false(ObjectsPerSite(j),1);
        end
        fprintf('%s: Excluding %d site(s), because amount of Nuclei and/or Cytoplasm and/or Cells is different. \n', mfilename, sum(matSitesDifferentNucleiAndCytoplasm));
    end
end



fprintf('%s: including %d %s\n',mfilename,sum(cell2mat(cellObjectsToInclude')),strTargetObjectName)

% store results as measurement file, which we load if the settings are
% new enough
handles = struct();
handles.Measurements.(strTargetObjectName).ObjectsToIncludeFeatures = structMiscSettings;
handles.Measurements.(strTargetObjectName).ObjectsToInclude = cellObjectsToInclude;
save(strObjectDiscardingMeasurementFile,'handles')
fprintf('%s: stored results in %s\n',mfilename,getlastdir(strObjectDiscardingMeasurementFile))



% let's write a PDF file with an overview of where did we discard the
% cells from
[intRow, intColumn] = cellfun(@filterimagenamedata,cellImageNames);
matImagePosData = [intRow, intColumn];
matIncludedFractionPerWell = NaN(16,24);
for iPos = unique(matImagePosData,'rows')'
    matImageIX = ismember(matImagePosData,iPos','rows');
    matIncludedFractionPerWell(iPos(1),iPos(2)) = nanmean(cat(1,cellObjectsToInclude{matImageIX}));
end
save(strWellObjectDiscardingMeasurementFile,'matIncludedFractionPerWell');
fprintf('%s: stored well overview results in %s\n',mfilename,getlastdir(strWellObjectDiscardingMeasurementFile))

% create figure and store as PDF
h = figure();
imagesc(matIncludedFractionPerWell,[0,1])
title(sprintf('Fraction of included cells per well. Median %% = %d',round(100*nanmedian(matIncludedFractionPerWell(:)))))
suptitle(sprintf('%s',getplatenames(strRootPath)))
colorbar
drawnow
strFileName = gcf2pdf(strrep(strRootPath,'BATCH','POSTANALYSIS'),sprintf('%s_overview',mfilename),'overwrite');
fprintf('%s: stored PDF in %s\n',mfilename,strFileName)
close(h)


end% end of function



function strSvmMeasurementName = find_best_matching_file(strRootPath, strSvmStrMatch)
% find svm files matching current searchstring, and return the one with the
% highest number

% get list of all matching files present
warning('bs:Bla','No exact file named ''%s'' found, looking for less exact matches...',strSvmStrMatch)
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



function [discardSitesInconsistentObjectAmount, matSitesDifferentNucleiAndCytoplasm] = initializeComparisonNucleiAndCytoplasmAmount(handles,structMiscSettings)

if isfield(structMiscSettings,'requireConsistentObjectAmount')
    if structMiscSettings.requireConsistentObjectAmount == 1;
        requireConsistentObjectAmount = true;
    elseif strcmpi(structMiscSettings.requireConsistentObjectAmount,'1');
        requireConsistentObjectAmount = true;
    elseif strcmpi(structMiscSettings.requireConsistentObjectAmount,'1;');
        requireConsistentObjectAmount = true;
    elseif strcmpi(structMiscSettings.requireConsistentObjectAmount,'true');
        requireConsistentObjectAmount = true;
    elseif strcmpi(structMiscSettings.requireConsistentObjectAmount,'true;');
        requireConsistentObjectAmount = true;
    elseif structMiscSettings.requireConsistentObjectAmount == true;
        requireConsistentObjectAmount = true;
    elseif structMiscSettings.requireConsistentObjectAmount == 0;
        requireConsistentObjectAmount = false;
    elseif strcmpi(structMiscSettings.requireConsistentObjectAmount,'0');
        requireConsistentObjectAmount = false;
    elseif strcmpi(structMiscSettings.requireConsistentObjectAmount,'0;');
        requireConsistentObjectAmount = false;
    elseif strcmpi(structMiscSettings.requireConsistentObjectAmount,'false');
        requireConsistentObjectAmount = false;
    elseif strcmpi(structMiscSettings.requireConsistentObjectAmount,'false;');
        requireConsistentObjectAmount = false;
    elseif structMiscSettings.requireConsistentObjectAmount == false;
        requireConsistentObjectAmount = false;
    end
    OptionIsPresent = true;
else
    fprintf('%s: structMiscSettings.requireConsistentObjectAmount not specified. Use default: false . \n', mfilename);
    discardSitesInconsistentObjectAmount = false;
    OptionIsPresent = false;
end

% Obtain indices of Nuclei and Cytoplasm
if isfield(structMiscSettings,'ObjectCountsGroup') %[VG]
    ObjectCountsGroup = structMiscSettings.ObjectCountsGroup;
else
    ObjectCountsGroup = {'Nuclei';'Cytoplasm';'Cells'};
    fprintf('%s: structMiscSettings.ObjectCountsGroup not specified. Use default: Nuclei, Cytoplasm and Cells . \n', mfilename);
end
ObjIX = ismember(handles.Measurements.Image.ObjectCountFeatures,ObjectCountsGroup);
if sum(ObjIX) == 0
    fprintf('%s: skipping consistency check because could neither find Nuclei, Cytoplasm or Cells objects. \n', mfilename);
    discardSitesInconsistentObjectAmount = false;
    matSitesDifferentNucleiAndCytoplasm = [];
elseif sum(ObjIX) == 1
    fprintf('%s: skipping consistency check because only one object group present (Nuclei, Cytoplasm or Cells). \n', mfilename);
    discardSitesInconsistentObjectAmount = false;
    matSitesDifferentNucleiAndCytoplasm = [];
elseif sum(ObjIX) > 1
    matSitesDifferentNucleiAndCytoplasm = cell2mat(cellfun(@(x) length(unique(x(ObjIX)))~=1,handles.Measurements.Image.ObjectCount,'UniformOutput',false));
    
    if any(matSitesDifferentNucleiAndCytoplasm)
        sumDifferentNucleiAndCytoplasm = sum(matSitesDifferentNucleiAndCytoplasm);
        
        if OptionIsPresent == false
            fprintf('%s: %d site(s) have different amount of Nuclei and/or Cytoplasm and/or Cells. Please consider the option requireConsistentObjectAmount to fix resulting errors! \n Very likely faulty and/or wrongly assigned data is currently loaded without any error message or clear indication! \n', mfilename, sumDifferentNucleiAndCytoplasm);
        elseif sumDifferentNucleiAndCytoplasm > 0
            discardSitesInconsistentObjectAmount = true;
        end
    else
        discardSitesInconsistentObjectAmount = false;
    end
    % if required: crash
elseif requireConsistentObjectAmount == true
    error('Failed to compare amount of Nuclei and/or Cytoplasm and/or Cells because object counts for Nuclei and/or Cytoplasm and/or Cells are absent');
end
end