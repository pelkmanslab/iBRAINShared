function handles = iBrainTrackerV1(strRootPath,strSettingsFile)

%The call the function use:
%handles = iBrainTrackerV1(strRootPath,strSettingsFile)
%
%
%strRootPath refers to the folder of iBrain containing the BATCH, TIFF and SEGMENTATION subfolders.
%The setting file should be named SetTracker_***.txt, where  *** stands for
%any name, eg. SetTracker_Nuclei01.txt.
%
%
%The seting file should contain the follwing parameters:
%
% structTrackingSettings.TrackingMethod => can take the values 'Distance' or
% 'Overlap'. Default = 'Distance'.
% structTrackingSettings.ObjectName => can take any name corresponding to a
% object eg: 'Nuclei' or 'Cells'. Default = 'Nuclei'.
% structTrackingSettings.PixelRadius => for 'Distance': it corresponds to
% the object expansion in pixels. Default = 10.
% structTrackingSettings.OverlapFactorC => Correspond to the minimum overlap
% allowed to define children. Default = 0.3.
% structTrackingSettings.OverlapFactorP => Correspond to the minimum overlap
% allowed to define parents. Default = 0.3;
% structTrackingSettings.WavelengthID => corresponds to the wavelength ID
% of the segmentation images, eg: '_w1'. Default = 'none', in which case
% asumes the name of the first image in the
% 'Measurements_Image_FileNames.mat' file.
% structTrackingSettings.CreateFrames => 'Yes' or 'yes' or 'y' if you want to create frames
% for a visualization movie. Default =Default = 'Yes'.
% structTrackingSettings.TailTime => Corresponds to the number of
% timepoints the tail of the tracked cell is visualized. Default = 20.
% MaxGhostAge: time how long a ghost maximally exists, if =0: ghost
% correction not used
% PhyTree: Whether the family trees should be calculated or not
% GlobalLabel: Whether tracking over multiple sites and therefore global
% labeling should be performed.
% GlobalLabelMergeT: Threshold for merging at the global labeling step.
% GlobalLabelImsize: Image size for global labeling
% UsePreviousRun: If a previous run with the given name exists, data is
% loaded and the Tracking step is skiped (leave  empty ('') if not
% used!)
% TrackingDerivedParam: calculates displacement, mean squared displacement,
% speed, change in area and change in LCD
% TimeResolutionSecs: time resolution is seconds for speed calculation.
%
% Example of Setting file:
%
% structTrackingSettings.TrackingMethod = 'Distance';
% structTrackingSettings.ObjectName = 'Nuclei';
% structTrackingSettings.PixelRadius = 10;
% structTrackingSettings.OverlapFactorC = 0.3;
% structTrackingSettings.OverlapFactorP = 0.3;
% structTrackingSettings.WavelengthID = '_w1';
% structTrackingSettings.CreateFrames = 'Yes';
% structTrackingSettings.TailTime = 20;
% structTrackingSettings.MaxGhostAge = 5;
% structTrackingSettings.PhyTree = 'Yes';
% structTrackingSettings.GlobalLabel = 'Yes';
% structTrackingSettings.GlobalLabelMergeT = 40;
% structTrackingSettings.GlobalLabelImsize = [];
% structTrackingSettings.UsePreviousRun = 'nameofprevioussettingfile';
% structTrackingSettings.TrackingDerivedParam = 'No';
% structTrackingSettings.TimeResolutionSecs = 40*60;
% structTrackingSettings.Well2Process = {'all'};
%
%
%Aditional files required in the BATCH directory:
% 'Measurements_strObjectToTrack_Location.mat'
% 'Measurements_Image_FileNames.mat'
% 'Measurements_Image_ObjectCount.mat'
% Note: if such files do not exist the tracker will not work.
%
%VZ: Optional for use of previous run:
% 'TrackOutputHandle_nameofprevioussettingfile.mat'
%
%iBrainTrackerV2
%
% Nico Battich 22-08-2011
%
% Mathieu Fréchin 15-12-2011
% Tracking over multiple sites implemented.
% Mathieu Fréchin 03-04-2012
% Possibility to do a perwell tracking,Reorganization of the main code, optimization, simplification and new
% modules. In particular, I have added a save step after global labelling,
% in order to optimize the memory usage later, plus, the loading of
% previous data is done in the initialization step. Saving is done
% systematicaly by saveTrckOutPut.


% now get the settings file.
% strSettingsFile = SearchTargetFolders(strRootPath,'SetTracker_*.txt');


%% Tracking Stage 1. Initialization
fprintf('%s: Tracking Stage 1: initilizing tracking parameters.\n',mfilename);
[handles,strSettingBaseName] = initTrackingSettings(strRootPath,strSettingsFile);

 %% Tracking Stage 1.2 Initialization: sorting the wells to analyze
    
% [MF]: new function, per well treatment, compatible with global labelling
% module. Done for speeding up cluster computing. A next update could
% be to implement a batch processing for the basic tracker function, and to
% treat each site independently at this stage. PerwellTracking contains
% part of the old code for ordering set of images for the tracking plus a
% new part doing the per well sorting if required by the user.

[handles] = perWellTracking(handles) ;   

fprintf('%s: Tracking Stage 1: initialization completed for %s.\n',mfilename,strRootPath);




if isempty(handles.TrackingSettings.UsePreviousRun)
    %% Tracking Stage 2. Tracking
    fprintf('%s: Tracking Stage 2: Tracking will be started for a total of %d sites.\n',mfilename,size(handles.structUniqueSiteID.matUniqueValues,1));
    
    %The data is saved in the disk directory in the basic tracker, to be
    %loaded later by the other modules
  
    [strObjectToTrack] = BasicTrackerV1(handles);
    
end
%% 2.1[MF] Track over multiple sites V2.0
%here is the code for relabelling over multiple sites, generating new
%global coordinates and finally identify objects that are splited over two
%sites, recognize them as single objects and labelling them accordingly,
%the data (handles structure plus measurements) is then saved in the batch
%directory. This code look in the batch directory to load its data.

TrackOvermultiplesitesV1(strRootPath,strSettingBaseName);

        

   

%% Tracking Stage 3. Post Tracking Modules
%[MF] Nico and Vito ideas are developed here, basically making the usage of post tracking modules cleaner
%and more modular, with less input and output variables (removing redundant ones, and there was quite a few). On top of it I am
%trying as much as I can, to load data from the disk, helping not overloading the
%memory of the node we are using. The loading of previous tracking data, if needed, is now
%done in the initialization module, and the code recognize if the global labeling was done,
%to skip it in this case (this guy is heavy...).

fprintf('%s: Tracking Stage 3. Post Tracking Modules for setting file SetTracker_%s.txt.\n',mfilename,strSettingBaseName);


%% 3.1 Create phylogenetic trees if asked

%[MF]Loads its data
if ~exist('handles','var')
    strBatchPath = fullfile(strRootPath,'BATCH');
    strMeasurementFileName = strcat('TrackOutputHandle_',strSettingBaseName);
    matData = fullfile(strBatchPath, strMeasurementFileName);
    matData = strcat(matData,'.mat');
    if ~fileattrib(matData)
        error('%s: initialization Stage: File %s does not exist. Imposible to load data from a previous run. Please check your setting file!',mfilename,fullfile(strBatchPath, strMeasurementFileName))
    end
        
    load(matData)
end
%Done

%[MF]: so now this function is independant and load the handles directly from the share 
handles = createfamilytree(handles);
    

%% 3.2 Calculate Derived Parameters 
%[NB] here we gene rate the trajectories matrix and compute different tracking parameters.

if strncmpi(handles.TrackingSettings.TrackingDerivedParam,'y',1);
    fprintf('%s: Tracking Stage 3.3: Calculate Tracking Statistics. Trajectory matrices.\n',mfilename);
    [handles]=linmatIBT2(handles);
    fprintf('%s: Tracking Stage 3.3: Calculate Tracking Statistics. Trajectory matrices completed.\n',mfilename);
    
    
    fprintf('%s: Tracking Stage 3.3: Calculate Tracking Statistics. Derived Parameters.\n',mfilename);
    % note this function is a bit slow  perhaps it could be improved
    [handles] = CalParamIBT(handles);
    fprintf('%s: Tracking Stage 3.3: Calculate Tracking Statistics. Derived Parameters.\n',mfilename);
    

    
    % save the measurements
    handles2 = struct();
    TrackingMeasurementPrefix = strcat('TrackingDerivedParam_',strSettingBaseName);
    handles2.Measurements.(strObjectToTrack).(TrackingMeasurementPrefix) = handles.Measurements.(strObjectToTrack).TrackingStats;
    handles2.Measurements.(strObjectToTrack).(strcat(TrackingMeasurementPrefix,'Features')) = handles.Measurements.(strObjectToTrack).TrackingStatsFeatures;
    
    % [BS] Store handles as measurement file in strBatchPath
    strMeasurementFileName = sprintf('Measurements_%s_%s.mat',strObjectToTrack,TrackingMeasurementPrefix);
    save(fullfile(handles.strBatchPath, strMeasurementFileName), 'handles2')
    
    % save the measurements
    handles2 = struct();
    TrackingMeasurementPrefix = strcat('Lineage_',strSettingBaseName);
    handles2.Measurements.(strObjectToTrack).(TrackingMeasurementPrefix) = handles.Measurements.(strObjectToTrack).cellLineage;
    %handles.Measurements.(strObjectToTrack).(strcat(TrackingMeasurementPrefix,'Features')) = PreviousHandles.Measurements.(strObjectToTrack).TrackingStatsFeatures;
    
    % [BS] Store handles as measurement file in strBatchPath
    strMeasurementFileName = sprintf('Measurements_%s_%s.mat',strObjectToTrack,TrackingMeasurementPrefix);
    save(fullfile(handles.strBatchPath, strMeasurementFileName), 'handles2')
    
    % save the measurements
    handles2 = struct();
    TrackingMeasurementPrefix = strcat('LineageMetaData_',strSettingBaseName);
    handles2.Measurements.(strObjectToTrack).(TrackingMeasurementPrefix) = handles.Measurements.(strObjectToTrack).cellLineageMetaData;
    %handles.Measurements.(strObjectToTrack).(strcat(TrackingMeasurementPrefix,'Features')) = PreviousHandles.Measurements.(strObjectToTrack).TrackingStatsFeatures;
    
    % [BS] Store handles as measurement file in strBatchPath
    strMeasurementFileName = sprintf('Measurements_%s_%s.mat',strObjectToTrack,TrackingMeasurementPrefix);
    save(fullfile(handles.strBatchPath, strMeasurementFileName), 'handles2')
    
     % save the measurements
    handles2 = struct();
    TrackingMeasurementPrefix = strcat('TrackingMSD_',strSettingBaseName);
    handles2.Measurements.(strObjectToTrack).(TrackingMeasurementPrefix) = handles.Measurements.(strObjectToTrack).TrackingMSD;
    %handles.Measurements.(strObjectToTrack).(strcat(TrackingMeasurementPrefix,'Features')) = PreviousHandles.Measurements.(strObjectToTrack).TrackingStatsFeatures;
    
    % [BS] Store handles as measurement file in strBatchPath
    strMeasurementFileName = sprintf('Measurements_%s_%s.mat',strObjectToTrack,TrackingMeasurementPrefix);
    save(fullfile(handles.strBatchPath, strMeasurementFileName), 'handles2')   
    
end



%% 3.x Movie creation

if strncmpi(handles.TrackingSettings.CreateFrames,'y',1);
    numTotalSites = size(handles.structUniqueSiteID.matUniqueValues,1);
    
    for iSites = 1:numTotalSites
        
        % find all the images that belong to iSites and put them in the correct
        % order
        matIndexSite = find(handles.structUniqueSiteID.matJ == iSites);
        strCurrentWell = handles.strWells(matIndexSite); strCurrentWell = char(strCurrentWell(1));
        fprintf('%s: Tracking Stage 3.x: Movie Creation %d of %d. Well %s.\n',mfilename,handles.structUniqueSiteID.matUniqueValues(iSites,3),numTotalSites,strCurrentWell);
        
        [foo matOrderedTimePointIdx] = sort(handles.matMetaDataInfo(matIndexSite,4));
        clear foo
        matOrderedTimePointIdx = matIndexSite(matOrderedTimePointIdx);
        
        fprintf('%s: Tracking Stage 3.x: Creating site frames for movie visualization. Find this files in the DUMPSITES directory. Site %d of %d. Well %s.\n',mfilename,handles.structUniqueSiteID.matUniqueValues(iSites,3),numTotalSites,strCurrentWell);
        
         
        %%%
        %[NB] Here the Visualization hapens. It will save the images
        %of frames in a TRACKING folder in the IBrain directory. Note it is the
        %slower step of the tracker!! imwrite == BAD!!
        
        % [VZ]: Attention! In case that data from a previous run is used,
        % the frames are saved in Tracking directory 
        % according to the file name of the setTracker settings of the
        % original tracking.
        
        handles = getframesformovie(handles,matOrderedTimePointIdx,strSettingBaseName);
        
    end
    
    
    fprintf('%s: 3.x Movie creation: Starting movie creation for setting file SetTracker_%s.txt.\n',mfilename,strSettingBaseName);
    
    % get the current tracking path
    strTrackingPath = fullfile(strRootPath,'TRACKING',strSettingBaseName);
    % check if directory exist
    if ~fileattrib(strTrackingPath)
        error('%s: Tracking Stage 3: Directory %s does not exist. Imposible to create well frames if site frames do not exist',mfilename,strTrackingPath)
    end
    mergepngmovieV1(strTrackingPath);
    
    % Now create the movies, two formats per each movie so that we can up load
    % them to any browser
    generatemoviesV1(strTrackingPath);
    fprintf('%s: Tracking Stage 3.x: Movie creation completed.\n',mfilename);
    
    
    
else
    fprintf('%s: Tracking Stage 3: Skipping movie creation for setting file %s.\n',mfilename,strSettingBaseName);
end


%% Tracking Stage 4. Saving Results Files after post tracking modules
%[NB] this we could also change and do the saving if the analysis is
%run....

saveTrckrOutPut(handles,TrackingMeasurementPrefix);

fprintf('%s: Tracking Stage 5: Output files saved to %s.\n',mfilename,handles.strBatchPath);


fprintf('%s: Tracking completed for data in %s\n',mfilename,strRootPath)
