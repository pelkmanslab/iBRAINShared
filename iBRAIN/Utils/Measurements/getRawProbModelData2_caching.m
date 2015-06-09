function [boolCacheLoaded, matCompleteData, strFinalFieldName, matCompleteMetaData, strCachePath, cellstrDataPaths] = getRawProbModelData2_caching(strRootPath, structDataColumnsToUse, structMiscSettings, strCachePath)
% this function does the following:
% 
% 1. Checks if results have been stored in local cache
% 2. Compare cached results against current query
% 3. Checks if cached results are newer than any dependcies (i.e.
%    functions, data directories, and measurement files)
%    [WARNING: However, does not search for new data directories!]
% 4. Loads cached results
%
% 5. If there are no cached results to store, we should after loading all
%    data, store the results and update the caching-overview-file, the
%    question is who does this...

boolCacheLoaded = false;
matCompleteData = [];
strFinalFieldName = [];
matCompleteMetaData = [];
strCachePath = '';
cellstrDataPaths = {};

if nargin==0
%     strRootPath = npc('\\nas-biol-imsb-1.d.ethz.ch\share-3-$\Data\Users\50K_final_reanalysis\SV40_MZ\');
%     strSettingsFile = npc('\\nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\ProbModel_Settings.txt');

    strRootPath = npc('Y:\Data\Users\Prisca\endocytome\090203_MZ_w2Tf_w3EEA1');
    strSettingsFile = npc('Y:\Data\Users\Prisca\endocytome\Settings_Cells_MeanIntensity_OrigGreen.txt');

    [structDataColumnsToUse, structMiscSettings] = initStructDataColumnsToUse(strSettingsFile);
%     strRootPath = npc('Y:\Data\Users\Prisca\090403_A431_Dextran_GM1_harlink1\');
%     strSettingsFile = npc('Y:\Data\Users\Prisca\090403_A431_Dextran_GM1_harlink1\ProbModel_Settings_QuantPlot.txt');
%     [structDataColumnsToUse, structMiscSettings] = initStructDataColumnsToUse(strSettingsFile);
end

% only works on windows machines!!
if ispc
    strCachePath = fullfile(tempdir,'getRawProbModelData2_caching', filesep);
% elseif isunix && strncmpi(getenv('HOSTNAME'),'brutus',6)
%     strCachePath = fullfile('/cluster/work/biol/bsnijder/','getRawProbModelData2_caching', filesep);
else
    fprintf('%s: Caching is only supported on windows machines or on the Brutus environment.\n',mfilename) 
    return
end

% indicate that we haven't found an appropriate cache file
boolMatchFound = false;

fprintf('%s: Checking cache ''%s''.\n',mfilename,strCachePath) 


% this file could contain a cell-array with the following data:
%
% for each cache file a separate row with the following columns
%
% 1. strRootPath (string)
% 2. strCacheFileName (string)
% 3. Date created (date number, as created by "datenum")
% 4. structDataColumnsToUse (struct)
% 5. structMiscSettings (struct)


% create it if the cache directory is not present
if ~fileattrib(strCachePath)
    [boolMakeDirSucces] = mkdir(strCachePath);
    if ~boolMakeDirSucces
       fprintf('%s: not allowed to create caching directory ''%s'', aborting.\n',mfilename,strCachePath) 
       return
    else
        fprintf('%s: created caching directory ''%s''.\n',mfilename,strCachePath) 
    end
end


% we're not doing a caching overview file, without it's much easier! just
% store 2 files, one containing description, and one containing the actual
% data, with same start of the file name.

% _overview.mat files contain the following information:
% 1. strRootPath (string)
% 2. structDataColumnsToUse (struct)
% 3. structMiscSettings (struct)

cellCacheFileList = CPdir(strCachePath);
cellCacheFileList = {cellCacheFileList(~[cellCacheFileList.isdir]).name};

% get list of overview files
cellCacheFileList = cellCacheFileList(~cellfun(@isempty,regexp(cellCacheFileList,'.*_overview.mat$','once')));

% if there are no cache files found, we're done here
if isempty(cellCacheFileList)
    fprintf('%s: cache directory is empty.\n',mfilename) 
    return
end

% inverse cache file list, as it is more likely something recently
% requested is being asked for again.
cellCacheFileList = fliplr(cellCacheFileList);

% load all overview files
for iFile = 1:length(cellCacheFileList)
    
    % get full path overview file
    strCacheOverviewFile = fullfile(strCachePath,cellCacheFileList{iFile});
    % get full path corresponding data file
    strCacheDataFile     = fullfile(strCachePath,strrep(cellCacheFileList{iFile},'_overview.mat','_data.mat'));

    % see if the corresponding data file is present, if not, remove
    % overview file and continue
    if ~fileattrib(strCacheDataFile)
        delete(strCacheOverviewFile)
        fprintf('%s: Found cache overview file without corresponding data file, removing ''%s''.\n',mfilename,strCacheOverviewFile)
        continue
    end    
    
    % try loading the overview file.
    try
        structOverview = load(strCacheOverviewFile);
    catch lastErrObj
        % failed to load overview file, perhaps we shold remove it.
        fprintf('%s: Removing corrupt cache files''%s''.\n',mfilename,strCacheOverviewFile)
        delete(strCacheOverviewFile)
        delete(strCacheDataFile)            
    end
    
    % remove trailing slashes from both
    if strcmpi(strRootPath(end),filesep)
        strRootPath=strRootPath(1:end-1);
    end
    if strcmpi(structOverview.strRootPath(end),filesep)
        structOverview.strRootPath=structOverview.strRootPath(1:end-1);
    end    
    
    % check if we have a match with target directory
    if strcmpi(structOverview.strRootPath,strRootPath)
        
        % see if we have a match with the settings files
        if isequal(structOverview.structDataColumnsToUse,structDataColumnsToUse) && ...
            isequal(structOverview.structMiscSettings,structMiscSettings)
            % if so, set flag to OK and stop searching
            boolMatchFound = true;
            break
        end
    end

    
%     % Here we could implement some basic cleaning of cache data. For
%     % instance, if a cache_data file has not been read for a long time
%     % (i.e. more than 100 days) we can safely delete the cached file. It
%     % will be recreated next time data is requested.
%     if getcolumn(datevec(now-getDatenumLastAccessed(strCacheDataFile)),3) > 100
%         fprintf('%s: Removing out-dated cache files ''%s''.\n',mfilename,strrep(cellCacheFileList{iFile},'_overview.mat',''))
%         delete(strCacheOverviewFile)
%         delete(strCacheDataFile)
%     end
end


% now we should check if the current file is up to date:
%
% compare cached file against date-last-changed of:
% 1. Functions
% 2. Measurements files (all the ones you can find)

% cache file last modified
intCacheFileModifiedDate = getDatenumLastModified(strCacheOverviewFile);



% stop if we did not find a match
if ~boolMatchFound
    fprintf('%s: Data not found in cache.\n',mfilename)
    return
else
    fprintf('%s: Found copy of data in cache from %s, checking validity...\n',mfilename,datestr(intCacheFileModifiedDate,0))
end


% 1. Functions

% list of functions that should be older (I'm not sure I like this option)
% cellDependentFunctions = {which('getRawProbModelData2'),which('initStructDataColumnsToUse'),which('getObjectsToInclude') };
cellDependentFunctions = {};

if ~all(intCacheFileModifiedDate > cellfun(@getDatenumLastModified, cellDependentFunctions))
    % if cache file is outdated compared to the functions that create it,
    % we should probably delete it!
    delete(strCacheOverviewFile)
    delete(strCacheDataFile)
    fprintf('%s: Functions are newer. Removing outdated cache file: ''%s''.\n',mfilename,strCacheOverviewFile)
    return
end

% toc

% 2. Measurement files.

% % Cached file is newer than the functions. So far so good, now search for
% % all BATCH directories that contain measurement files. 
% cellBatchDirectories = getbasedir(SearchTargetFolders(npc(strRootPath),'Measurements_Image_FileNames.mat'));

% In order to save time, we only search the target directory for new plates
% if we see that the target directory itself has changed since
% date-of-cache. Otherwise, we assume the list of plates stored in overview
% file is up to date.
if intCacheFileModifiedDate > getDatenumLastModified(strRootPath)
    cellBatchDirectories = structOverview.cellstrDataPaths;
else
    % let's first check if this is a valid project directory from the
    % ibrain database, if so, we get directory listing from there,
    % otherwise we look for it the hard way. we assume that ibrain is up to
    % date, as it checks itself for the existence of new plate directories.
    cellBatchDirectories = findPlates(strRootPath);
    if isempty(cellBatchDirectories)
        cellBatchDirectories = getPlateDirectoriesFromiBRAINDB(strRootPath);
    end

    % check if ibrain db gave something, otherwise, search hardway
    if isempty(cellBatchDirectories)
%         cellBatchDirectories = getbasedir(SearchTargetFolders(npc(strRootPath),'Measurements_Image_FileNames.mat'));
        cellBatchDirectories = findPlates(npc(strRootPath));
    end

    % simple check, if number of directories is different, 
    if length(cellBatchDirectories) ~= length(structOverview.cellstrDataPaths)
        delete(strCacheOverviewFile)
        delete(strCacheDataFile)
        fprintf('%s: Different number of plates found. Removing outdated cache file: ''%s''.\n',mfilename,strCacheOverviewFile)
        return
    end
end

% toc

% get a list of all the measurement files that are required for
% getRawProbModelData2 from the settings structures
cellMeasurementFileNames = {};
for i = fieldnames(structDataColumnsToUse)'
    if isfield(structDataColumnsToUse.(char(i)),'MeasurementsFileName')
        cellMeasurementFileNames = [cellMeasurementFileNames,structDataColumnsToUse.(char(i)).MeasurementsFileName];
    elseif isfield(structDataColumnsToUse.(char(i)),'FileName')
        cellMeasurementFileNames = [cellMeasurementFileNames,structDataColumnsToUse.(char(i)).FileName]; 
    end
end
cellMeasurementFileNames = unique(cellMeasurementFileNames);

% toc

% note that 'ObjectsToExclude' field can be missing
if isfield(structMiscSettings,'ObjectsToExclude')
    cellMeasurementFileNames = unique([cellMeasurementFileNames,{structMiscSettings.ObjectsToExclude.MeasurementsFileName}]);
end

% loop over each plate found
for iDir = 1:length(cellBatchDirectories)
    % format full path files for measurement files and current plate
    cellCurrentPlateFiles = cellfun(@(x) fullfile(cellBatchDirectories{iDir},x), cellMeasurementFileNames,'UniformOutput',false);

    % get date last modified from measurements. if NaN, than set to -inf.
    matDatesLastModified = cellfun(@getDatenumLastModified, cellCurrentPlateFiles);
    if any(isnan(matDatesLastModified))
%         fprintf('%s: Can''t determine date-last modified of all measurements - assuming cache is ok.\n',mfilename)
        matDatesLastModified(isnan(matDatesLastModified)) = -inf;
    end
    % if current cache file is not newer than all these measurement
    % files, remove cache file and quit.
    if ~all(intCacheFileModifiedDate > matDatesLastModified)
        delete(strCacheOverviewFile)
        delete(strCacheDataFile)
        fprintf('%s: Measurements are newer. Removing outdated cache file: ''%s''.\n',mfilename,strCacheOverviewFile)
        return
    end
end

% toc

% we came this far, so all measurements found are older than the cache
% file, all functions are older than the cache file, all settings are
% matched. Load data file, return data to user and quit. If loading fails,
% delete cache files.
try
    fprintf('%s: Loading data from cached file: ''%s''.\n',mfilename,strCacheDataFile)
    structCachedData = load(strCacheDataFile);

    % Return cached data as output.
    matCompleteData = structCachedData.matCompleteData;
    strFinalFieldName = structCachedData.strFinalFieldName;
    matCompleteMetaData = structCachedData.matCompleteMetaData;
    cellstrDataPaths = structOverview.cellstrDataPaths;
    
    boolCacheLoaded = true;
catch lastErrObj
    lastErrObj.identifier
    lastErrObj.message
    fprintf('%s: Failed to load data from cached file: ''%s''.\n',mfilename,strCacheDataFile)
    
    % Just to avoid confusion, set these back to empty.
    matCompleteData = [];
    strFinalFieldName = [];
    matCompleteMetaData = [];
    cellstrDataPaths = {};
        
    % Delete cache files? Probably yes.
    delete(strCacheOverviewFile)
    delete(strCacheDataFile)    
end

% toc