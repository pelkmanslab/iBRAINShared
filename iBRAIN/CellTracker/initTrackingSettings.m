function [handles,strSettingBaseName] = initTrackingSettings(strRootPath,strSettingsFile) %#ok<STOUT>

%%% This function parses the SetTracking_ file, if no settings are
%%% specified then in returs default settings. It also initializes the
%%% handles structure which shall contains the results of the tracker.
%%%
%[NB] It could be good to separate the file arsing from the initialization
%of other parameters. it would make the code a bit more structured.

strRootPath = npc(strRootPath);
strSettingsFile = npc(strSettingsFile);

if isempty(strSettingsFile)
    error('%s: Setting file not found\n',mfilename)
end

if nargin==0
    error('No setting File specified in ParseSetTrackingFile.');
end

% we need the BATCH folder
strBatchPath = fullfile(strRootPath,'BATCH');
strTIFFPath = fullfile(strRootPath,'TIFF');
strSegmentPath = fullfile(strRootPath,'SEGMENTATION');
strTrackPath = fullfile(strRootPath,'TRACKING');

strSettingsFile = char(strSettingsFile);
% check if file exists
if ~fileattrib(strSettingsFile)
    error('%s: settingsfile %s does not exist',mfilename,strSettingsFile)
end

% Find the base name of the tracking file
strSettingBaseName = strSettingsFile(strfind(strSettingsFile,'SetTracker_'):end);
strSettingBaseName = strSettingBaseName(12:end-4);

%Get the tracking directories corresponding to the current setting file
%name
strTrackPath = fullfile(strRootPath,'TRACKING',strSettingBaseName,'DUMPSITES');

%Create required directories if they do not exist

if ~fileattrib(fullfile(strRootPath,'TRACKING')) 
    fprintf('%s: Tracking Stage 1: Creating "TRACKING" directory.\n',mfilename);
    mkdir(strRootPath,'TRACKING');
end 

if ~fileattrib(fullfile(strRootPath,'TRACKING',strSettingBaseName)) 
    fprintf('%s: Tracking Stage 1: Creating "%s" directory.\n',mfilename,strSettingBaseName);
    mkdir(fullfile(strRootPath,'TRACKING'),strSettingBaseName);
end 

if ~fileattrib(strTrackPath) 
    fprintf('%s: Tracking Stage 1: Creating "DUMPSITES" directory.\n',mfilename);
    mkdir(fullfile(strRootPath,'TRACKING',strSettingBaseName),'DUMPSITES');
end


% open file for reading
fid = fopen(strSettingsFile,'r');
% check if opening worked
if ~(fid>0)
    error('%s: failed to open %s',mfilename,strSettingsFile)
end

% variables required for counting measurement blocks in the new format
intBlockCounter = 1;
boolJustPorcessedBlock = false;

% Initialize the structure structTrackingSettings with default values
structTrackingSettings = struct();
structTrackingSettings.TrackingMethod = 'Distance';
structTrackingSettings.ObjectName = 'Nuclei';
structTrackingSettings.PixelRadius = 10;
structTrackingSettings.CollectStatistics = 'Yes'; % this option should be take out
structTrackingSettings.OverlapFactorC = 0.3;
structTrackingSettings.OverlapFactorP = 0.3;
structTrackingSettings.WavelengthID = 'none';
structTrackingSettings.CreateFrames = 'Yes';
structTrackingSettings.TailTime = 1; % this default is 1
structTrackingSettings.MaxGhostAge = 0;%per default the ghost method is not used
structTrackingSettings.PhyTrees = 'no';
structTrackingSettings.GlobalLabel = 'Yes';
structTrackingSettings.GlobalLabelMergeT = 40;
structTrackingSettings.GlobalLabelImsize = [];
structTrackingSettings.UsePreviousRun = '';
structTrackingSettings.TrackingDerivedParam = 'No';
structTrackingSettings.TimeResolutionSecs = 40*60;
structTrackingSettings.Well2Process = {'all'};

%%%
%[NB] we need to add the possibility of choosing the compression of the
%images for te basic tracker and discard the option of choosing not to
%save the outputs!

% loop over each line
fprintf('%s: Parsing setting file %s.\n',mfilename,strSettingsFile);
while 1
    tline = fgetl(fid);
    if ~ischar(tline),   break,   end
    
    %%% hehe, this is higly insecure! ALMOST arbitrary code
    %%% execution, woot! :D
    tline = strtrim(tline);
    
    
    if isempty(tline) && boolJustPorcessedBlock
        % if we encounter an empty line, and we just had non-empty lines,
        % increment measurement block counter +1.
        intBlockCounter = intBlockCounter + 1;
        boolJustPorcessedBlock = false;
    end
    
    if ~strncmpi(tline, 'function ',9) && ...
            ~strncmpi(tline, 'end',3) && ...
            strncmpi(tline, 'structTrackingSettings.',23)
        
        % A setting was found. The default values will be changed
        strFieldName = regexpi(tline,'^structTrackingSettings.(\w{1,})','Tokens');
        strFieldName = char(strFieldName{:});
        
        if strncmp(strFieldName, 'TrackingMethod',14)...
                || strncmp(strFieldName, 'ObjectName',10)...
                || strncmp(strFieldName, 'PixelRadius',11)...
                || strncmp(strFieldName, 'CollectStatistics',17)...
                || strncmp(strFieldName, 'OverlapFactorC',14)...
                || strncmp(strFieldName, 'OverlapFactorP',14)...
                || strncmp(strFieldName, 'WavelengthID',12)...
                || strncmp(strFieldName, 'CreateFrames',12)...
                || strncmp(strFieldName, 'TailTime',8)...
                || strncmp(strFieldName, 'MaxGhostAge',11)...
                || strncmp(strFieldName, 'PhyTrees',8) ...
                || strncmp(strFieldName, 'GlobalLabel',11)...
                || strncmp(strFieldName, 'GlobalLabelMergeT',17)...  
                || strncmp(strFieldName, 'GlobalLabelImsize',17)...
                || strncmp(strFieldName, 'UsePreviousRun',14)...
                || strncmp(strFieldName, 'TrackingDerivedParam',20)...
                || strncmp(strFieldName, 'TimeResolutionSecs',18)...
                || strncmp(strFieldName, 'Well2Process',12)        
            
            strFieldName = sprintf('MeasurementBlock_%d',intBlockCounter);
            boolJustPorcessedBlock = true;
            
            fprintf('%s: Setting %s\n',mfilename,tline);
            
            eval(tline)
            
        else
            error('%s: Typing error at %s',mfilename,tline)
        end
    end
end
fclose(fid);

%add the strSettingBaseName to the structTrackingSettings.... [this should improve the coding of modules]
structTrackingSettings.strSettingBaseName = strSettingBaseName;


% what is the Object we are going to track?
strObjectToTrack = structTrackingSettings.ObjectName;


% intialize handles structue. Note: we must have the Object location and the ordered full Images names
strLocationFilePath = fullfile(strBatchPath,sprintf('Measurements_%s_Location.mat',strObjectToTrack));
strImagesFilePath = fullfile(strBatchPath,sprintf('Measurements_Image_FileNames.mat'));
strObjectCountFilePath = fullfile(strBatchPath,sprintf('Measurements_Image_ObjectCount.mat'));


% check if the files exist
if ~fileattrib(strLocationFilePath) ...
        || ~fileattrib(strImagesFilePath)...
        || ~fileattrib(strObjectCountFilePath)
    error('%s: One of the following files could not be found in the %s folder:\nMeasurements_Image_FileNames.mat\nMeasurements_Image_ObjectCount.mat\n%s\nThe files above must exist for the Tracking to Proceed!!',mfilename,strBatchPath,sprintf('Measurements_%s_Location.mat',strObjectToTrack))
end

% Create handles and load the two files [MF fix]: care at case sensitive
% crashes
handles = struct();
handles = LoadMeasurements(handles,strLocationFilePath);
handles = LoadMeasurements(handles,strImagesFilePath);
handles = LoadMeasurements(handles,strObjectCountFilePath);



% [NB] If Calculate tracking statistics is YES try to up lad the LCD and the
% AREA information
if strncmpi(structTrackingSettings.TrackingDerivedParam,'y',1)
    strLCDFilePath = fullfile(strBatchPath,sprintf('Measurements_%s_LocalCellDensity.mat',strObjectToTrack));
    strAreaShapeFilePath = fullfile(strBatchPath,sprintf('Measurements_%s_AreaShape.mat',strObjectToTrack));
    
    %check if the files exist, if not give a warning
    if ~fileattrib(strLCDFilePath)
        warning('%s: Note that dt_LocalCellDensity will not be calculated as\n%s\ndoes not exist.\n',mfilename,strLCDFilePath)
    else
        handles = LoadMeasurements(handles,strLCDFilePath);
    end
    
    %check if the AreaShape file exists, if not give a warning
    if ~fileattrib(strAreaShapeFilePath)
        warning('%s: Note that dt_Area will not be calculated as\n%s\ndoes not exist.\n',mfilename,strLCDFilePath)
    else
        handles = LoadMeasurements(handles,strAreaShapeFilePath);
    end    
end



% generate fullpaths for each image
% Note we need to deal with more than one image filename
if strncmpi(structTrackingSettings.WavelengthID, 'none',4)
    handles.Measurements.Image.BaseMovieFileNames = cellfun(@(x) char(x(1)),handles.Measurements.Image.FileNames,'uniformoutput',false);
else
    cellImagesIndexes = cellfun(@(x) cell2mat(cellfun(@(y) ~isempty(strfind(y,structTrackingSettings.WavelengthID)),...
        x,'uniformoutput',false)),handles.Measurements.Image.FileNames,'uniformoutput',false);
    
    if ~sum(cell2mat(cellImagesIndexes)) == size(handles.Measurements.Image.FileNames,2)
        warning('%s: There is a mismatch between the number of images that contain "%s" and the total number of sites.',mfilename,structTrackingSettings.WavelengthID)
    end
    
    handles.Measurements.Image.BaseMovieFileNames = cellfun(@(x,y) char(x(y)),handles.Measurements.Image.FileNames,cellImagesIndexes,'uniformoutput',false);
end





handles.Measurements.Image.FileNames = cellfun(@(x) char(x(1)),handles.Measurements.Image.FileNames,'uniformoutput',false);
handles.Measurements.Image.SegmentedFileNames = cellfun(@(x) fullfile(strSegmentPath,strcat(x(1:end-4),sprintf('_Segmented%s.png',strObjectToTrack))),...
    handles.Measurements.Image.BaseMovieFileNames,'uniformoutput',false);
handles.Measurements.Image.TrackedFileNames = cellfun(@(x) fullfile(strTrackPath,strcat(x(1:end-4),sprintf('_Tracked%s.png',strSettingBaseName))),...
    handles.Measurements.Image.FileNames,'uniformoutput',false);
handles.Measurements.Image.FileNames = cellfun(@(x) fullfile(strTIFFPath,x),handles.Measurements.Image.FileNames,'uniformoutput',false);
handles.Measurements.Image.BaseMovieFileNames = cellfun(@(x) fullfile(strTIFFPath,x),handles.Measurements.Image.BaseMovieFileNames,'uniformoutput',false);



handles.Current = struct();
handles.Pipeline = struct();
handles.TrackingSettings = structTrackingSettings;


%[MF]finally inserted in initTracking, but still some improvement to do:
%%Load Tracker data if necessary
handles.OriginalTrackingSettings.GlobalDone = 'no';
handles.TrackingSettings.GlobalDone = 'no';
previousSettingName = handles.TrackingSettings.UsePreviousRun;
% When the Basictracker has not run, all the necessary information has to
% be loaded
if ~isempty(previousSettingName)
    
    SetHandles = handles;
    fprintf('%s: initialization Stage try to load the previous measurements etc.\n',mfilename);
    
    strMeasurementFileName = strcat('TrackOutputHandle_',previousSettingName);
    previousTracker = fullfile(strBatchPath, strMeasurementFileName);
    previousTracker = strcat(previousTracker,'.mat');
    if ~fileattrib(previousTracker)
        error('%s: initialization Stage: File %s does not exist. Imposible to load data from a previous run. Please check your setting file!',mfilename,fullfile(strBatchPath, strMeasurementFileName))
    end
        
    load(previousTracker)
    
    


    fprintf('%s: Reset TrackingSettingsDomains.\n',mfilename);
    tempOldSettings = handles.TrackingSettings; %back up old handles settings
    handles.TrackingSettings = SetHandles.TrackingSettings;
    
    if isfield(tempOldSettings,'strSettingBaseName')
        handles.TrackingSettings.strSettingBaseName =  tempOldSettings.strSettingBaseName;
        strSettingBaseName = tempOldSettings.strSettingBaseName;
    elseif isfield(handles,'OriginalstrSettingBaseName')
        handles.TrackingSettings.strSettingBaseName =  handles.OriginalstrSettingBaseName;
        strSettingBaseName = handles.OriginalstrSettingBaseName;
    end
    
    handles.TrackingSettings.strSettingBaseNameLoading =  SetHandles.TrackingSettings.strSettingBaseName;
    
    matglobalLabelingSeq = handles.matglobalLabelingSeq;
    TrackingMeasurementPrefixTrack = handles.Measurements.(strObjectToTrack).('TrackingMeasurementPrefixTrack') ;
    
    strSettingBaseNameCurr = handles.TrackingSettings.strSettingBaseNameLoading; %[NB] this information is repeated sooooo many times!! we should make this better too...
    
else
    strSettingBaseNameCurr = strSettingBaseName;
end

%%%
%[NB] There probably will be a problem if we define the measurement matrces
%before. Unless we further fix the tracker code so not to use
%CPaddmeasurements. This we can do later...
%%%
%[NB] Create the Measurement matrices only if the statistics will be
%generated, else there is no point. Note the number of measurement colums
%will be hardcoded, perhaps this can be changed at some point
% munCollectStatistics = strncmpi(structTrackingSettings.CollectStatistics,'y',1);
% 
% if munCollectStatistics
%
%     intNumOfMeasurementColumns = 8;
%
%     %%%
%     %[NB] this is not the best. If many matches are found to the object, just
%     %take the 1st match which starts in the first character to avoid problems
%     %with Nuclei and PreNuclei type of code. Perhaps this code can be
%     %simplified
%     numIndexObjectToTrack = cell2mat(cellfun(@(x) strncmp(x,strObjectToTrack,size(strObjectToTrack,2)),handles.Measurements.Image.ObjectCountFeatures, 'uniformoutput',false));
%     numIndexObjectToTrack = find(numIndexObjectToTrack);
%     numIndexObjectToTrack = numIndexObjectToTrack(1);
%
%     matObjectCountPerImage =  cell2mat(handles.Measurements.Image.ObjectCount(numIndexObjectToTrack,:))
%     
%
%     %define the TrackObject measurementy domain
%     cellMeasurements = arrayfun(@(x) NaN(x,intNumOfMeasurementColumns) , matObjectCountPerImage,'UniformOutput',false);
%     handles.Measurements.(strObjectToTrack).(strcat('TrackObjects_',strSettingBaseName)) = cellMeasurements;
%
%     %define the TrckObjectMetaData domain
%     cellMeasurements = arrayfun(@(x) NaN(x,1) , (zeros(1,size(matObjectCountPerImage,2))+4),'UniformOutput',false);
%     handles.Measurements.(strObjectToTrack).(strcat('TrackObjectsMetaData_',strSettingBaseName)) = cellMeasurements;
% end

handles.strBatchPath = strBatchPath;
handles.strSettingsFile = strSettingsFile;

% sanity checks
if ~exist('structTrackingSettings','var')
    fprintf('%s: %s did not produce desired output, using standard settings\n',mfilename,strSettingsFile)
else
    fprintf('%s: extracted settings from %s\n',mfilename,strSettingsFile)
    return
end 




end