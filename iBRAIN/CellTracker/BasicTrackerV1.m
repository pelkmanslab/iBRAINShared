function [strObjectToTrack] = BasicTrackerV1(handles)


% see Help for the Track Objects module of CP for short description:
% Category: Object Processing
% Tracking by measurements is not allowed yet. Not diplaying yet. Do not
% save the images
% Initialize a few variables


    %[MF]%%%%%%%
    
    strSettingBaseName = handles.TrackingSettings.strSettingBaseName;
    cellAllImages = handles.Measurements.Image.SegmentedFileNames';
    matTimepoints = handles.matMetaDataInfo(:,4);
    handles.matglobalLabelingSeq = [];
    handles.('tracking_sequence_matrix_Features'){1} = 'sequence of image set';
    handles.('tracking_sequence_matrix_Features'){2} = 'row number of the well ';
    handles.('tracking_sequence_matrix_Features'){3} = 'column number of the well';
    handles.('tracking_sequence_matrix_Features'){4} = 'site number';
    handles.('tracking_sequence_matrix_Features'){5} = 'timepoint';
    handles.('tracking_sequence_matrix_Features'){6} = 'index of the corresponding segmentated image';

    %%%%%%%%%%%%
    
    % here I have all the information to run the Tracker.
    %[NB]perhaps this code can be reduced to a cellfun rathe than a for loop.
numTotalSites = size(handles.structUniqueSiteID.matUniqueValues,1);
for iSites = 1:numTotalSites
        % find all the images that belong to iSites and put them in the correct
        % order
        matIndexSite = find(handles.structUniqueSiteID.matJ == iSites);
        strCurrentWell = handles.strWells(matIndexSite); strCurrentWell = char(strCurrentWell(1));
        fprintf('%s: Tracking Stage 2: Tracking site %d of %d. Well %s.\n',mfilename,handles.structUniqueSiteID.matUniqueValues(iSites,3),numTotalSites,strCurrentWell);
        [foo matOrderedTimePointIdx] = sort(matTimepoints(matIndexSite));
        clear foo
        matOrderedTimePointIdx = matIndexSite(matOrderedTimePointIdx);
        % Initialize values for the tracker
        
        if iSites == 1
            handles.Current.SetBeingAnalyzed = 1;
            handles.Current.NumberOfImageSets = size(matOrderedTimePointIdx,1);
            handles.Current.StartingImageSet = 1;
        else
            handles.Current.NumberOfImageSets = handles.Current.NumberOfImageSets + size(matOrderedTimePointIdx,1);
        end
        
        
TrackingMethod = handles.TrackingSettings.TrackingMethod;
ObjectName = handles.TrackingSettings.ObjectName;
PixelRadius = handles.TrackingSettings.PixelRadius;
OverlapFactorC = handles.TrackingSettings.OverlapFactorC;
OverlapFactorP = handles.TrackingSettings.OverlapFactorP;
StartingImageSet = handles.Current.StartingImageSet;
NumberOfImageSets = size(matOrderedTimePointIdx,1);

handles.Measurements.(ObjectName).(strcat('TrackObjectsMetaData_',strSettingBaseName,'Features')) = {'Row_Number','Column_Number','Site_Number','Time_point'};
TrackingMeasurementPrefix = strcat('TrackObjects_',strSettingBaseName);
handles.Measurements.(ObjectName).(strcat(TrackingMeasurementPrefix,'Features')) = {'ObjectID','ParentID','TrajectoryX','TrajectoryY','DistanceTraveled','IntegratedDistance','Linearity','Lifetime','GhostAge','FamilyID','CorrectedLocationX','CorrectedLocationY','MissegmentationHistory'};
handles.Measurements.Image.(strcat(TrackingMeasurementPrefix,'Features')) = {'LostObjectCount','NewObjectCount'};
SetBeingAnalyzed = 1;
maxPreviousLabel = 1;

%vito

MaxGhostAge = handles.TrackingSettings.MaxGhostAge;




for i = 1:NumberOfImageSets
    
    MetaData = handles.matMetaDataInfo(matOrderedTimePointIdx,:)';
    CollectStatistics = handles.TrackingSettings.CollectStatistics;
    CollectStatistics = strncmpi(CollectStatistics,'y',1);
    handles.Current.PreviousSetBeingAnalyzed = handles.Current.SetBeingAnalyzed;
    handles.Current.SetBeingAnalyzed = matOrderedTimePointIdx(i);
    
    %[MF]a little matrix that will simplify my life! >> I get here the
    %good succession of image set (and corresponding well & blabla) in the handle structure and this in a
    %single matrix, allowing me to not loop the global labelling module
    %column 1 sequence of imagesets
    %column 2 row number
    %column 3 col number
    %column 4 site number
    %column 5 time point
    %column 6 idx of corresponding segmented img in list 'cellAllSegmentedImages' of
    %the task dispatcher 
   
    
   
   if handles.Current.SetBeingAnalyzed == 1 && iSites == 1 ;
   handles.matglobalLabelingSeq = [handles.Current.SetBeingAnalyzed , MetaData(:,SetBeingAnalyzed)', matOrderedTimePointIdx(SetBeingAnalyzed)] ;
   else
   handles.matglobalLabelingSeq = [handles.matglobalLabelingSeq ; [handles.Current.SetBeingAnalyzed, MetaData(:,SetBeingAnalyzed)', matOrderedTimePointIdx(SetBeingAnalyzed)]];
   end
    
    % Start the analysis
    if SetBeingAnalyzed == StartingImageSet    
        % Initialize data structures
        
        % An additional structure is added to handles.Pipeline in order to keep
        % track of frame-to-frame changes
        
        % (1) Segmented, labeled image
        %TrackObjInfo.Current.SegmentedImage = CPretrieveimage(handles,['Segmented' ObjectName],ModuleName);
        TrackObjInfo.Current.SegmentedImage = imread(char(cellAllImages(matOrderedTimePointIdx(SetBeingAnalyzed))));
        
        % (2) Locations
        TrackObjInfo.Current.Locations{SetBeingAnalyzed} = handles.Measurements.(ObjectName).Location{handles.Current.SetBeingAnalyzed};
        
        % handles.Measurements.(ObjectName).Locations = {'CenterX','CenterY'};
        % tmp = regionprops(TrackObjInfo.Current.SegmentedImage,'Centroid');
        % Centroid = cat(1,tmp.Centroid);
        % note here we will repeat the info we already have. Perhaps we can
        % omit this. (Chack with berend)
        % handles.Measurements.(ObjectName).Location(handles.Current.SetBeingAnalyzed) = {Centroid};
        % TrackObjInfo.Current.Locations{SetBeingAnalyzed} = handles.Measurements.(ObjectName).Location{handles.Current.SetBeingAnalyzed};
        
        CurrentLocations = TrackObjInfo.Current.Locations{SetBeingAnalyzed};
        PreviousLocations = NaN(size(CurrentLocations));
        CorrPreviousLocations = NaN(size(CurrentLocations));
        % (3) Labels
        InitialNumObjs = size(TrackObjInfo.Current.Locations{SetBeingAnalyzed},1);
        CurrentLabels = (1:InitialNumObjs)';
        PreviousLabels = CurrentLabels;
        CurrHeaders = cell(size(CurrentLabels));
        [CurrHeaders{:}] = deal('');
        
        %%% VZ Initialize Ghost Age
        
       TrackObjInfo.Current.GhostAge = zeros(size(CurrentLabels));
       CurrentGhostAge = TrackObjInfo.Current.GhostAge;
       PreviousGhostAge = CurrentGhostAge;
       %%%  VZ Initialize the family ID
       
       TrackObjInfo.Current.FamilyIDs = CurrentLabels;
       CurrentFamilyIDs = CurrentLabels;
       
        if CollectStatistics
            [TrackObjInfo.Current.AgeOfObjects,TrackObjInfo.Current.SumDistance,TrackObjInfo.Current.MisSegHistory] = deal(zeros(size(CurrentLabels)));
            TrackObjInfo.Current.InitialObjectLocation = CurrentLocations;
            AgeOfObjects = TrackObjInfo.Current.AgeOfObjects;
            InitialObjectLocation = TrackObjInfo.Current.InitialObjectLocation;
            SumDistance = TrackObjInfo.Current.SumDistance;
            CurrMisSeg = TrackObjInfo.Current.MisSegHistory;
            %VZ
            [CentroidTrajectory,DistanceTraveled,SumDistance,AgeOfObjects,InitialObjectLocation,CorrCurrentLocations] = ComputeTrackingStatistics(CurrentLocations,PreviousLocations,CurrentLabels,PreviousLabels,SumDistance,AgeOfObjects,InitialObjectLocation,CorrPreviousLocations);
            TrackObjInfo.Current.AgeOfObjects = AgeOfObjects;
            TrackObjInfo.Current.SumDistance = SumDistance;
            TrackObjInfo.Current.InitialObjectLocation = InitialObjectLocation;
       
            
        end
    else
        % Extracts data from the handles structure
        TrackObjInfo = handles.Pipeline.TrackObjects.(ObjectName);
        
        % Create the new 'previous' state from the former 'current' state
        TrackObjInfo.Previous = TrackObjInfo.Current;
        
        % Get the needed variables from the 'previous' state
        PreviousLocations = TrackObjInfo.Previous.Locations{SetBeingAnalyzed-1};
        PreviousLabels = TrackObjInfo.Previous.Labels;
        MisSegHistory = TrackObjInfo.Previous.MisSegHistory;
        
        % VZ pass the Corrected Locations
        CorrPreviousLocations = CorrCurrentLocations;
        

        % [BS] hack: trying a imresize to speed up the tracker
        % PreviousSegmentedImage = TrackObjInfo.Previous.SegmentedImage;
        %PreviousSegmentedImageNR = TrackObjInfo.Previous.SegmentedImage;
        % [MF]edit: adapted for sCMOS images
        if length(TrackObjInfo.Previous.SegmentedImage) > 2000
        PreviousSegmentedImage = imresize(TrackObjInfo.Previous.SegmentedImage, 0.25,'nearest');
        else
        PreviousSegmentedImage = imresize(TrackObjInfo.Previous.SegmentedImage, 0.5,'nearest');
        end
        
        PrevHeaders = TrackObjInfo.Previous.Headers;
        
        % Get the needed variables from the 'current' state.
        % If using image grouping: The measurements are located in the actual
        % set being analyzed, so we break the grouping convention here
        % TrackObjInfo.Current.Locations{SetBeingAnalyzed} = handles.Measurements.(ObjectName).Location{handles.Current.SetBeingAnalyzed};
        % TrackObjInfo.Current.SegmentedImage = CPretrieveimage(handles,['Segmented' ObjectName],ModuleName);
        TrackObjInfo.Current.SegmentedImage = imread(char(cellAllImages(matOrderedTimePointIdx(SetBeingAnalyzed))));
        CurrentSegmentedImageNR = TrackObjInfo.Current.SegmentedImage;  
        TrackObjInfo.Current.Locations{SetBeingAnalyzed} = handles.Measurements.(ObjectName).Location{handles.Current.SetBeingAnalyzed};
              
        CurrentLocations = TrackObjInfo.Current.Locations{SetBeingAnalyzed};
        
        % [BS] hack: trying a imresize to speed up the tracker
        % CurrentSegmentedImage = TrackObjInfo.Current.SegmentedImage;
        % [MF]edit: adapted for sCMOS images
        if length(TrackObjInfo.Current.SegmentedImage) > 2000
        CurrentSegmentedImage = imresize(TrackObjInfo.Current.SegmentedImage, 0.25,'nearest');
        else
        CurrentSegmentedImage = imresize(TrackObjInfo.Current.SegmentedImage, 0.5,'nearest');
        end
        
        % VZ: Load the PreviousFamilyIDs
        
        PreviousFamilyIDs = TrackObjInfo.Previous.FamilyIDs;
        
        switch lower(TrackingMethod)
            case 'distance'
                % Create a distance map image, threshold it by search radius
                % and relabel appropriately
                
                [CurrentObjNhood,CurrentObjLabels] = bwdist(CurrentSegmentedImage);
                CurrentObjNhood = uint16(CurrentObjNhood < PixelRadius).*CurrentSegmentedImage(CurrentObjLabels);
                
                [PreviousObjNhood,previous_obj_labels] = bwdist(PreviousSegmentedImage);
                PreviousObjNhood = uint16(PreviousObjNhood < PixelRadius).*PreviousSegmentedImage(previous_obj_labels);
                
                % Compute overlap of distance-thresholded objects
                MeasuredValues = ones(size(CurrentObjNhood));
                [CurrentLabels, CurrHeaders, ParentMat, maxPreviousLabel, CurrentFamilyIDs, CurrMisSeg] = EvaluateObjectOverlap(CurrentObjNhood,PreviousObjNhood,PreviousLabels,PrevHeaders,MeasuredValues,OverlapFactorC,OverlapFactorP,maxPreviousLabel,PreviousFamilyIDs);
                
            case 'overlap'  % Compute object area overlap
                MeasuredValues = ones(size(CurrentSegmentedImage));
                [CurrentLabels, CurrHeaders, ParentMat, maxPreviousLabel, CurrentFamilyIDs, CurrMisSeg] = EvaluateObjectOverlap(CurrentSegmentedImage,PreviousSegmentedImage,PreviousLabels,PrevHeaders,MeasuredValues,OverlapFactorC,OverlapFactorP,maxPreviousLabel,PreviousFamilyIDs);
                
            otherwise
                % Get the specified featurename
                try
                    FeatureName = CPgetfeaturenamesfromnumbers(handles, ObjectName, MeasurementCategory, MeasurementFeature, ImageName, SizeScale);
                catch
                    error(['Image processing was canceled in the ', ModuleName, ' module because an error ocurred when retrieving the ' MeasurementFeature ' set of data. Either the category of measurement you chose, ', MeasurementCategory,', was not available for ', ObjectName,', or the feature number, ', num2str(MeasurementFeature), ', exceeded the amount of measurements.']);
                end
                
                % The idea here is to take advantage to MATLAB's sparse/full
                % trick used in EvaluateObjectOverlap by modifying the input
                % label matrices appropriately.
                % The big problem with steps (1-3) is that bwdist limits the distance
                % according to the obj neighbors; I want the distance threshold
                % to be neighbor-independent
                
                % (1) Expand the current objects by the threshold pixel radius
                [CurrentObjNhood,CurrentObjLabels] = bwdist(CurrentSegmentedImage);
                CurrentObjNhood = (CurrentObjNhood < PixelRadius).*CurrentSegmentedImage(CurrentObjLabels);
                
                % (2) Find those previous objects which fall within this range
                PreviousObjNhood = (CurrentObjNhood > 0).*PreviousSegmentedImage;
                
                % (3) Shrink them to points so the accumulation in sparse will
                % evaluate only a single number per previous object, the value
                % of which is assigned in the next step
                PreviousObjNhood = bwmorph(PreviousObjNhood,'shrink',inf).*PreviousSegmentedImage;
                
                % (4) Produce a labeled image for the previous objects in which the
                % labels are the specified measurements. The nice thing here is
                % that I can extend this to whatever measurements I want
                PreviousStatistics = handles.Measurements.(ObjectName).(FeatureName){SetBeingAnalyzed-1};
                PreviousStatisticsImage = (PreviousObjNhood > 0).*LabelByColor(PreviousSegmentedImage, PreviousStatistics);
                
                % (4) Ditto for the current objects
                CurrentStatistics = handles.Measurements.(ObjectName).(FeatureName){SetBeingAnalyzed};
                CurrentStatisticsImage = LabelByColor(CurrentObjNhood, CurrentStatistics);
                
                % (5) The values that are input into EvaluateObjectOverlap are
                % the normalized measured per-object values, ie, CurrentStatistics/PreviousStatistics
                warning('off','MATLAB:divideByZero');
                MeasuredValues = PreviousStatisticsImage./CurrentStatisticsImage;
                MeasuredValues(isnan(MeasuredValues)) = 0;
                % Since the EvaluateObjectOverlap is performed by looking at
                % the max, if the metric is > 1, take the reciprocal so the
                % result is on the range of [0,1]
                MeasuredValues(MeasuredValues > 1) = CurrentStatisticsImage(MeasuredValues > 1)./PreviousStatisticsImage(MeasuredValues > 1);
                warning('on','MATLAB:divideByZero');
                
                [CurrentLabels, CurrHeaders] = EvaluateObjectOverlap(CurrentObjNhood,PreviousObjNhood,PreviousLabels,PrevHeaders,MeasuredValues,PreviousFamilyIDs);
        end
        
        
       %%%%%%% VZ
       
       %%% Load previous GhostAge
       
       PreviousGhostAge = TrackObjInfo.Previous.GhostAge;

       %%% Determine which labels have disappeared in the current image and
       %%% are not parents
       [GhostLabels, gIds] = setdiff(PreviousLabels,[CurrentLabels;ParentMat]);
       


       %%% If the ghosts do not overlap with anything in the current
       %%% image and are not to old, stich them into the current segmentation image.
       %%%  The CurrentLocations, the CurrentLabels and the ParentMat are addapted
       %%% according to the new added ghost objects.
       
       
       CurrentGhostAge = zeros(size(CurrentLabels));
       
       for i=1:size(gIds,1)
           
           Ghosti = (TrackObjInfo.Previous.SegmentedImage == gIds(i));
           if max(CurrentSegmentedImageNR(Ghosti)) == 0 && PreviousGhostAge(gIds(i)) < MaxGhostAge;
               
               GhostiID = size(CurrentLabels,1) + 1;
               
               %%% Here the ghost cell is actually stitched in everywhere
               CurrentLabels(GhostiID,1) = GhostLabels(i);
               ParentMat(GhostiID,1) = GhostLabels(i);
               CurrentFamilyIDs(GhostiID,1) = PreviousFamilyIDs(gIds(i));
               CurrentGhostAge(GhostiID,1) = PreviousGhostAge(gIds(i))+1;
               CurrentLocations(GhostiID,1) = PreviousLocations(gIds(i),1); 
               CurrentLocations(GhostiID,2) = PreviousLocations(gIds(i),2);
               CurrMisSeg(GhostiID,1) = 0;
               CurrentSegmentedImageNR(Ghosti) = GhostiID;
               maxPreviousLabel = maxPreviousLabel + 1;
           end
       end
       

       %%% In the end, the IDs of the Ghost can be always identified by
       %%% CurrentLabels(ghostAge > 0)
       %%% or the also the indices: find(CurrentGhostAge > 0)
       
       %%% Save the changes
   
       TrackObjInfo.Current.SegmentedImage = CurrentSegmentedImageNR;
       TrackObjInfo.Current.GhostAge = CurrentGhostAge;
         
       TrackObjInfo.Current.Locations{SetBeingAnalyzed} = CurrentLocations;
       handles.Measurements.(ObjectName).Location{handles.Current.SetBeingAnalyzed} = CurrentLocations;
        
       
       %%% Save the ParentFamilyIds
       TrackObjInfo.Current.FamilyIDs = CurrentFamilyIDs;
           
       
       
       %%%% End VZ
       
       
        % Compute measurements
        % At this point, the following measurements are calculated: CentroidTrajectory
        % in <x,y>, distance traveled, AgeOfObjects
        % Other measurements that were previously included in prior versions of
        % TrackObjects were the following: CellsEnteredCount, CellsExitedCount,
        % ObjectSizeChange. These were all computed at the end of the analysis,
        % not on a per-cycle basis
        % TODO: Determine whether these measurements are useful and put them
        % back if they are
        if CollectStatistics
            AgeOfObjects = TrackObjInfo.Current.AgeOfObjects;
            InitialObjectLocation = TrackObjInfo.Current.InitialObjectLocation;
            SumDistance = TrackObjInfo.Current.SumDistance;
            [CentroidTrajectory,DistanceTraveled,SumDistance,AgeOfObjects,InitialObjectLocation,CorrCurrentLocations] = ComputeTrackingStatistics(CurrentLocations,PreviousLocations,CurrentLabels,PreviousLabels,SumDistance,AgeOfObjects,InitialObjectLocation,CorrPreviousLocations);
            TrackObjInfo.Current.AgeOfObjects = AgeOfObjects;
            TrackObjInfo.Current.SumDistance = SumDistance;
            TrackObjInfo.Current.InitialObjectLocation = InitialObjectLocation;
            
            % VZ: 120105
            % Add the MisSegHistory to the corresponding CurrMisSeg in order pass
            % the information how many missegmentations were in the lineage.
            
            %Find the childs which have a parent in the last frame
            ParIdx = intersect(PreviousLabels,ParentMat);
            
            % Add the History
            for k=1:length(ParIdx)
                parFilt = (ParentMat==ParIdx(k));
                CurrMisSeg(parFilt) = CurrMisSeg(parFilt) + MisSegHistory(PreviousLabels == ParIdx(k));
                
            end
            
            %Objects that are generated newly have allways no
            %missegmentation history.
            CurrMisSeg(~ismember(ParentMat,ParIdx)) = 0;
            
            %endVZ
            TrackObjInfo.Current.MisSegHistory = CurrMisSeg;
        end
        
        
        
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% SAVE DATA TO HANDLES STRUCTURE %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    
    TrackObjInfo.Current.Labels = CurrentLabels;
    TrackObjInfo.Current.Headers = CurrHeaders;
    
    % Saves the measurements of each tracked object
    if CollectStatistics
        TrackingMeasurementPrefix = strcat('TrackObjects_',strSettingBaseName);
        handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,1) = CurrentLabels(:);
        %handles = CPaddmeasurements(handles, ObjectName, TrackingMeasurementPrefix , 'ObjectID', CurrentLabels(:));
        
        if SetBeingAnalyzed == StartingImageSet
            handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,2) = CurrentLabels(:);
            %handles = CPaddmeasurements(handles, ObjectName, TrackingMeasurementPrefix , 'ParentID', CurrentLabels(:));
        else
            handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,2) = ParentMat(:);
            %handles = CPaddmeasurements(handles, ObjectName, TrackingMeasurementPrefix , 'ParentID', ParentMat(:));
        end
        
        handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,3) = CentroidTrajectory(:,1);
        %handles = CPaddmeasurements(handles, ObjectName, TrackingMeasurementPrefix, 'TrajectoryX', CentroidTrajectory(:,1));
        handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,4) = CentroidTrajectory(:,2);
        %handles = CPaddmeasurements(handles, ObjectName, TrackingMeasurementPrefix, 'TrajectoryY', CentroidTrajectory(:,2));
        handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,5) = DistanceTraveled(:);
        %handles = CPaddmeasurements(handles, ObjectName, TrackingMeasurementPrefix, 'DistanceTraveled', DistanceTraveled(:));
        
        %%% VZ: Save Corrected Locations
        
        handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,11) = CorrCurrentLocations(:,1);
        handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,12) = CorrCurrentLocations(:,2);
        
        
        %%% VZ: Save the MisSegmentationHistory
        handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,13) = CurrMisSeg(:);
        
        %%% VZ: Save GhostAge and FamilyIDs
        
        handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,9) = CurrentGhostAge(:);
        handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,10) = CurrentFamilyIDs(:);
        
        % Record the object lifetime, integrated distance and linearity once it disappears...
        %if SetBeingAnalyzed ~= NumberOfImageSets,
        [Lifetime,Linearity,IntegratedDistance] = deal(NaN(size(PreviousLabels)));
        [AbsentObjectsLabel,idx] = setdiff(PreviousLabels,CurrentLabels);
        % Count old objects that have dissappeared
        handles.Measurements.Image.(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,1) = length(AbsentObjectsLabel);
        %handles = CPaddmeasurements(handles, 'Image', TrackingMeasurementPrefix, CPjoinstrings('LostObjectCount',ObjectName),length(AbsentObjectsLabel));
        %VZ: Account for the fact that ghosts where already dead for
        %GhostAge time
        Lifetime(idx) = AgeOfObjects(AbsentObjectsLabel)-PreviousGhostAge(idx);
        IntegratedDistance(idx) = SumDistance(AbsentObjectsLabel);
        % Linearity: In range of [0,1]. Defined as abs[(x,y)_final - (x,y)_initial]/(IntegratedDistance).
        warning('off','MATLAB:divideByZero');
        if ~isempty(idx)
            mag =  sqrt(sum((InitialObjectLocation(AbsentObjectsLabel,:) - PreviousLocations(idx,:)).^2,2));
            Linearity(idx) = mag./reshape(SumDistance(AbsentObjectsLabel),size(mag));
        end
        warning('on','MATLAB:divideByZero');
        
        % Count new objects that have appeared
        NewObjectsLabel = setdiff(CurrentLabels,PreviousLabels);
        handles.Measurements.Image.(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,2) = length(NewObjectsLabel);
        %handles = CPaddmeasurements(handles, 'Image', TrackingMeasurementPrefix, CPjoinstrings('NewObjectCount',ObjectName),length(NewObjectsLabel));
        %else %... or we reach the end of the analysis
        
        
        if SetBeingAnalyzed ~= StartingImageSet
            IntegratedDistanceMeasurementName = 'IntegratedDistance';
            handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.PreviousSetBeingAnalyzed}(:,6) = IntegratedDistance(:);
            %handles = CPaddmeasurementsTracking(handles, ObjectName, TrackingMeasurementPrefix, IntegratedDistanceMeasurementName,IntegratedDistance(:));
            LinearityMeasurementName = 'Linearity';
            handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.PreviousSetBeingAnalyzed}(:,7) = Linearity(:);
            %handles = CPaddmeasurementsTracking(handles, ObjectName, TrackingMeasurementPrefix, LinearityMeasurementName,Linearity(:));
            LifetimeMeasurementName = 'Lifetime';
            handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.PreviousSetBeingAnalyzed}(:,8) = Lifetime(:);
            %handles = CPaddmeasurementsTracking(handles, ObjectName, TrackingMeasurementPrefix, LifetimeMeasurementName,Lifetime(:));
        end
        
        % If we reach the end of the analysis we need to fill in all the life
        % times etc
        if SetBeingAnalyzed == NumberOfImageSets,
            % VZ: Ghosts were already dead for GhostAge time
            CurrentGhostAge(CurrentGhostAge > 0) = CurrentGhostAge(CurrentGhostAge > 0)-1;
            Lifetime = AgeOfObjects(CurrentLabels)-CurrentGhostAge(:);
            IntegratedDistance = SumDistance(CurrentLabels);
            warning('off','MATLAB:divideByZero');
            mag = sqrt(sum((InitialObjectLocation(CurrentLabels,:) - CurrentLocations).^2,2));
            Linearity = mag./reshape(SumDistance(CurrentLabels),size(mag));
            warning('on','MATLAB:divideByZero');
            handles.Measurements.Image.(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,1) = 0;
            %handles = CPaddmeasurements(handles, 'Image', TrackingMeasurementPrefix, CPjoinstrings('LostObjectCount',ObjectName),0);
            handles.Measurements.Image.(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,2) = 0;
            %handles = CPaddmeasurements(handles, 'Image', TrackingMeasurementPrefix, CPjoinstrings('NewObjectCount',ObjectName),0);
            
            IntegratedDistanceMeasurementName = 'IntegratedDistance';
            handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,6) = IntegratedDistance(:);
            %handles = CPaddmeasurements(handles, ObjectName, TrackingMeasurementPrefix, IntegratedDistanceMeasurementName,IntegratedDistance(:));
            LinearityMeasurementName = 'Linearity';
            handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,7) = Linearity(:);
            %handles = CPaddmeasurements(handles, ObjectName, TrackingMeasurementPrefix, LinearityMeasurementName,Linearity(:));
            LifetimeMeasurementName = 'Lifetime';
            handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.Current.SetBeingAnalyzed}(:,8) = Lifetime(:);
            %handles = CPaddmeasurements(handles, ObjectName, TrackingMeasurementPrefix, LifetimeMeasurementName,Lifetime(:));
            
        end
    end
    

    
    
    handles.Measurements.(ObjectName).(strcat('TrackObjectsMetaData_',strSettingBaseName)){handles.Current.SetBeingAnalyzed} = MetaData(:,SetBeingAnalyzed)';
    % handles.Measurements.(ObjectName).MetaData{handles.Current.SetBeingAnalyzed}
    % Save the structure back to handles.Pipeline
    handles.Pipeline.TrackObjects.(ObjectName) = TrackObjInfo;
    SetBeingAnalyzed = SetBeingAnalyzed + 1;
    %fprintf('%s: Cycle Number = %d\n',mfilename,i)
    
end
end

    
    strObjectToTrack = handles.TrackingSettings.ObjectName;
    fprintf('%s: Tracking Stage 2: Tracking of %s completed.\n',mfilename,strObjectToTrack);
    
    fprintf('%s: Tracking Stage 5: Saving files to %s.\n',mfilename,handles.strBatchPath);
        
%[MF]saving is part of this code now

handles.OriginalTrackingSettings.GlobalDone = 'no';
saveTrckrOutPut(handles,TrackingMeasurementPrefix);

 fprintf('%s: Tracking Stage 5: Output files saved to %s.\n',mfilename,handles.strBatchPath);
%%%%%%%%%%%%%%%%%%%%%%
%%%% SUBFUNCTIONS %%%%
%%%%%%%%%%%%%%%%%%%%%%
function [CurrentLabels, CurrentHeaders,mainParents2,maxPreviousLabel, CurrentFamilyIDs,CurrMisSeg] = EvaluateObjectOverlap(CurrentLabelMatrix, PreviousLabelMatrix, PreviousLabels, PreviousHeaders, ChosenMetric,OverlapFactorC,OverlapFactorP,maxPreviousLabel,PreviousFamilyIDs)

%%%
%[NB] there is apperently a bug in the alocationof objects IDs. 1 in
%approx 1000 is guiven an ID that is already used!!!. Hopefully is fixed by
%passing maxPreviousLabels....

% Much of the following code is adapted from CPrelateobjects

% We want to choose a previous objects's progeny based on the most overlapping
% current object.  We first find all pixels that are in both a previous and a
% current object, as we wish to ignore pixels that are background in either
% labelmatrix
ForegroundMask = (CurrentLabelMatrix > 0) & (PreviousLabelMatrix > 0);
NumberOfCurrentObj = length(unique(CurrentLabelMatrix(CurrentLabelMatrix > 0)));
NumberOfPreviousObj = length(unique(PreviousLabelMatrix(PreviousLabelMatrix > 0)));

%save the overlap variables which are user defined
%OverlapFactorC=str2num(OverlapFactorC);
%OverlapFactorP=str2num(OverlapFactorP);

%save Parents
Parents=PreviousLabels;


%Calculate the area of Current and Previous objects
AreaPrevObj=histc(PreviousLabelMatrix(PreviousLabelMatrix > 0),unique(PreviousLabelMatrix(PreviousLabelMatrix > 0)));
AreaCurrObj=histc(CurrentLabelMatrix(CurrentLabelMatrix > 0),unique(CurrentLabelMatrix(CurrentLabelMatrix > 0)));

% Use the Matlab full(sparse()) trick to create a 2D histogram of
% object overlap counts
CurrentPreviousLabelHistogram = full(sparse(double(CurrentLabelMatrix(ForegroundMask)), double(PreviousLabelMatrix(ForegroundMask)), ChosenMetric(ForegroundMask), NumberOfCurrentObj, NumberOfPreviousObj));

% Make sure there are overlapping current and previous objects
if any(CurrentPreviousLabelHistogram(:)),
    % For each current obj, we must choose a single previous obj parent. We will choose
    % this by maximum overlap, which in this case is maximum value in
    % the parents's column in the histogram.  sort() will give us the
    % necessary child (row) index as its second return argument.
    [OverlapCounts, CurrentObjIndexes] = sort(CurrentPreviousLabelHistogram,1);
    
    %Find the maximum number of found children per parent
    MaxNumOverlap = length(find(sum(OverlapCounts,2)));
    
    %Get the Overlap amount
    OverlapCounts = OverlapCounts(end-MaxNumOverlap+1:end, :);
    
    % Get the Child list.
    CurrentObjList = CurrentObjIndexes(end-MaxNumOverlap+1:end, :);
    
    % Handle the case of a zero overlap -> no current obj
    CurrentObjList(OverlapCounts(end-MaxNumOverlap+1:end, :) == 0) = 0;
    
    %Generate matrix of same dimensions as OverlapCounts and CurrentObjList
    %containing the current object areas
    CurrentObjArea=zeros(size(CurrentObjList));
    for j=1:numel(CurrentObjList)
        if CurrentObjList(j)~=0;
           CurrentObjArea(j)=AreaCurrObj(CurrentObjList(j));
        else
        end
    end
    
    %Relative area of current object as compared to previous object (useful
    %as mitotic events should generate relatively smaller objects, whilst
    %true children should be similar in size to their parent)
    RelObjArea=zeros(size(CurrentObjArea));
    for j=1:numel(CurrentObjArea)
        if CurrentObjArea(j)~=0;
           [~,c]=ind2sub(size(CurrentObjArea),j);
           RelObjArea(j)=CurrentObjArea(j)./AreaPrevObj(c);
        else
        end
    end
    
    %Relative area of previous object taken up by overlap
    RelPrevOverlapArea=zeros(size(OverlapCounts));
    for j=1:numel(OverlapCounts)
        if OverlapCounts(j)~=0;
           [~,c]=ind2sub(size(OverlapCounts),j);
           RelPrevOverlapArea(j)=OverlapCounts(j)./AreaPrevObj(c);
        else
        end
    end
    
    %Relative area of current object taken up by overlap
    RelCurrOverlapArea=OverlapCounts./CurrentObjArea;
    RelCurrOverlapArea(isnan(RelCurrOverlapArea))= 0;
    
    %Only allow overlapping values which are greater than the set factor
    RelCurrOverlapArea(RelCurrOverlapArea<OverlapFactorC)=0;
    RelPrevOverlapArea(RelPrevOverlapArea<OverlapFactorP)=0;
    
    %Create a matrix with the sum of both relative overlaps. Can be considered a "score"
    %of how likely a given parent is the parent of a child.
    TotRelOverlap=(RelCurrOverlapArea+RelPrevOverlapArea);
    
    %Only allow object IDs which exist after TotRelOverlap
    CurrentObjList(TotRelOverlap==0)=0;
    
    %Only the two highest values need to be kept
    [TotRelOverlap,TotRelOrder]=sort(TotRelOverlap,1);
    for j = 1:size(TotRelOrder,2)
        CurrentObjList(:,j) = CurrentObjList(TotRelOrder(:,j),j);
    end
    
    
   % VZ: if two parents are overlapping more than 0.8 each with a child,
   % this is a strong indication that an missegmentation did happen. It
   % can be a) be at the end of and oversegmentation or b) at the beginning
   % of an undersegmentation. Naturally this situation should 
   % occure almost never! 
   %Therefore information is saved here and later, as missegmentations mess
   %up the traking, used to get the parameter "MisSegmentHistory" which is then an
   % indicator about the quality of the tracking
    RelPrevOverlapAreaFull = RelPrevOverlapArea > 0.8;
    FullOverlapObj = CurrentObjList(RelPrevOverlapAreaFull);
    FullOverlapObj(FullOverlapObj==0) = [];
    FullOverlapObj = sort(FullOverlapObj);
    IdentObj = (diff(FullOverlapObj) == 0);    
    IdentObj = FullOverlapObj(IdentObj);
    
    
    CurrMisSeg = zeros(size(AreaCurrObj));
    CurrMisSeg(IdentObj) = 1;
    
 
    
    
    
    
    
    
    %If no mitotic events occur then the CurrentObjList will only be one
    %row high causing problems later on, so add the rows filled with 0s
    
    if size(CurrentObjList,1)==1
        CurrentObjList(2,:)=CurrentObjList(1,:);
        CurrentObjList(1,:)=zeros(1,size(CurrentObjList,2));
        TotRelOverlap(2,:)=TotRelOverlap(1,:);
        TotRelOverlap(1,:)=zeros(1,size(TotRelOverlap,2));
    else
        %We only want to save the two highest scoring rows, as cells can
        %only be parents of two cells at once
        CurrentObjList=CurrentObjList(end-1:end,:);
        TotRelOverlap=TotRelOverlap(end-1:end,:);
    end
    
    %Generate a complete list of objects so we can see if any two next to
    %eachother are the same
    vecCurrentObjList=CurrentObjList(CurrentObjList>0);

    

    
    
	% If two or more parents have the same child - then choose the one with the
	% largest intersection and set the other to zero.
	[sortedVals, indsOfVals] = sort(vecCurrentObjList);
	identicalVals = find(diff(sortedVals) == 0);

  
    
    %loop through the identical values, find the one which has the highest
    %score to be related and then set all data from the other one to 0
    %VZ: The previous code did not do that in cases a child has more than
    %two parents, which also can occur e.g. at out of focus images
    
    % VZ: Previous Code
    Vals =[];
	for j=1:length(identicalVals)
		curVal = sortedVals(identicalVals(j));
        Vals=[Vals,curVal];
        [row,AllParents]=find(CurrentObjList==curVal);
        Score=TotRelOverlap(CurrentObjList==curVal);
        NonParent=AllParents(Score==min(Score));
		row=row(Score==min(Score));
        CurrentObjList(row,NonParent)=0;
    end 
    
   
    
    
    
    

    %Reorrient the child matrix:
    CurrentObjList=CurrentObjList';
    
    % VZ: There is a rare case where the correction step above, where it
    % is checked that no child can have more then one parents, leads to the
    % case where the first child is deleted (=0). This leads to the
    % misclassification that a single child comes from mitosis, while it is
    % de facto a mainchild -> here I correct that
    
    noChild2 = CurrentObjList(:,1) > 0;
    noChild1 = CurrentObjList(:,2) > 0;
    
    noChild2 = noChild1+noChild2;
    noChild2 = noChild2 > 0;
    noChild2 = noChild2 - noChild1;
    corrIDx = find(noChild2);
    
    CurrentObjList(corrIDx,2) = CurrentObjList(corrIDx,1);
    CurrentObjList(corrIDx,1) = 0;
    

   
    %mainChildren are the children most likely to be related to their
    %parent column
    mainChildren=CurrentObjList(:,2);
    
    %mitoChildren includes all objectIds generated from mitosis
    mitoChildren=CurrentObjList(:,1);
    
    %here we remove any cells judged to be resulting from mitosis from
    %mainChildren resulting in the mainChildrenNM matrix
    mainChildrenNM=mainChildren.*(mitoChildren==0);
    
    %locmitoMain saves the objectIds of children which are a result of
    %mitosis in the mainChildren matrix
    locmitoMain=mainChildren.*(mitoChildren~=0);
    
    %Generate a matrix containing parents the size of that containing
    %children
    ParentsMatrix=[Parents,Parents];
    
    %filter out values where there are no children
    ParentsMatrix(CurrentObjList==0)=0;
    
    %Save parents of mainChildren and mitoChildren
    mainParents=ParentsMatrix(:,2);
    mitoParents=ParentsMatrix(:,1);
    
    %here we reorient the mainParents matrix so that mainParents are kept
    %with the same objectID as their children, if their 
    for j=1:length(mainChildrenNM)
        if mainChildrenNM(j)==0
        else
            mainParents2(mainChildrenNM(j),1)=mainParents(j);
            %VZ: pass familyIDs
            CurrentFamilyIDs(mainChildrenNM(j),1) = PreviousFamilyIDs(j);
        end
    end
    
        
else
    % No overlapping objects
    CurrentObjList = zeros(NumberOfPreviousObj, 1);
    CurrentFamilyIDs = zeros(NumberOfCurrentObj,1);
    mainParents2 = zeros(NumberOfCurrentObj,1);
    mainChildrenNM = [];
    
end

% Check wether there are only new objects

if ~exist('mitoChildren')
    mitoChildren = [];
end

if ~exist('locmitoMain')
    locmitoMain = [];
end

% Disappeared: Obj in CurrentObjList set to 0, so drop label from list

CurrentLabels = zeros(NumberOfCurrentObj,1);
CurrentLabels(mainChildrenNM(mainChildrenNM > 0)) = PreviousLabels(mainChildrenNM > 0);

% Newly appeared: Missing index in CurrentObjList, so add new label to list
idx = setdiff((1:NumberOfCurrentObj)',mainChildrenNM);
if ~isempty(PreviousLabels)
	maxLabels = max(PreviousLabels);
    maxPreviousLabel = max([maxPreviousLabel;maxLabels]);
else
	maxLabels = 0;
end
CurrentLabels(idx) = maxPreviousLabel + reshape(1:length(idx),size(CurrentLabels(idx)));


%if this new label is in the position of a mitotic event, set the parent as
%the parent of that mitotic event from the previous image. If it is a
%popping in event, save the parent as equal to the value of the new label.
for j=1:length(idx)
    [r1,~]=find(mitoChildren==idx(j));
    [r2,~]=find(locmitoMain==idx(j));
    r1=[r1;r2];
    if isempty(r1);
        mainParents2(idx(j),1)=CurrentLabels(idx(j));
        %VZ: create familyIDs
        CurrentFamilyIDs(idx(j),1) = CurrentLabels(idx(j));
    else
        mainParents2(idx(j),1)=mitoParents(r1);
        %VZ: pass familyIDs
        CurrentFamilyIDs(idx(j),1) = PreviousFamilyIDs(r1);
    end
end


CurrentHeaders(idx) = {''};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SUBFUNCTION - LabelByColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ColoredImage = LabelByColor(LabelMatrix, CurrentLabel)
% Relabel the label matrix so that the labels in the matrix are consistent
% with the text labels

LookupTable = [0; CurrentLabel(:)];
ColoredImage = LookupTable(LabelMatrix+1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SUBFUNCTION - UpdateTrackObjectsDisplayImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [LabelMatrixColormap, ObjToColorMapping] = UpdateTrackObjectsDisplayImage(LabelMatrix, CurrentLabels, PreviousLabels, LabelMatrixColormap, ObjToColorMapping, DefaultLabelColorMap)

NumberOfColors = 256;

if isempty(LabelMatrixColormap),
    % If just starting, create a 256-element colormap
    colormap_fxnhdl = str2func(DefaultLabelColorMap);
    NumOfRegions = double(max(LabelMatrix(:)));
    cmap = [0 0 0; colormap_fxnhdl(NumberOfColors-1)];
    is2008b_or_greater = ~CPverLessThan('matlab','7.7');
    if is2008b_or_greater,
        defaultStream = RandStream.getDefaultStream;
        savedState = defaultStream.State;
        RandStream.setDefaultStream(RandStream('mt19937ar','seed',0));
    else
        rand('seed',0);
    end
    index = rand(1,NumOfRegions)*NumberOfColors;
    if is2008b_or_greater, defaultStream.State = savedState; end
    
    % Save the colormap and indices into the handles
    LabelMatrixColormap = cmap;
    ObjToColorMapping = index;
else
    % See if new labels have appeared and assign them a random color
    NewLabels = setdiff(CurrentLabels,PreviousLabels);
    ObjToColorMapping(NewLabels) = rand(1,length(NewLabels))*NumberOfColors;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SUBFUNCTION - ComputeTrackingStatistics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CentroidTrajectory,DistanceTraveled,SumDistance,AgeOfObjects,InitialObjectLocation, CorrCurrentLocations] = ComputeTrackingStatistics(CurrentLocations,PreviousLocations,CurrentLabels,PreviousLabels,SumDistance,AgeOfObjects,InitialObjectLocation,CorrPreviousLocations)
   
CentroidTrajectory = zeros(size(CurrentLocations));
[OldLabels, idx_previous, idx_current] = intersect(PreviousLabels,CurrentLabels);
CentroidTrajectory(idx_current,:) = CurrentLocations(idx_current,:) - PreviousLocations(idx_previous,:);
DistanceTraveled = sqrt(sum(CentroidTrajectory.^2,2));
DistanceTraveled(isnan(DistanceTraveled)) = 0;

AgeOfObjects(OldLabels) = AgeOfObjects(OldLabels) + 1;
[NewLabels,idx_new] = setdiff(CurrentLabels,PreviousLabels);
AgeOfObjects(NewLabels) = 1;

%VZ: Try to correct the locations of the objects for the stage movement. To
%achieve this the mean displacement (= the mean CentroidTrajectory) is
%subtracted from the locations

%Do not use ghost data in this case, as this can bias the mean displacement
%(the trajectory of ghosts is allways == 0)


curmeanTrajectory=mean(CentroidTrajectory(CentroidTrajectory(:,1) ~= 0,:),1);

% The trajectory corrections are additive, therefore we have to determine
% the correction factor previously applied and add it to the current factor

if ~isnan(PreviousLocations)

prevTrajectoryCorrection = max(CorrPreviousLocations-PreviousLocations);

curTrajectoryCorrection = prevTrajectoryCorrection + curmeanTrajectory;

curTrajectoryCorrection = repmat(curTrajectoryCorrection,size(CurrentLocations,1),1);

CorrCurrentLocations = CurrentLocations + curTrajectoryCorrection; 

else
    
    CorrCurrentLocations = CurrentLocations;
end


SumDistance(OldLabels) = SumDistance(OldLabels) + reshape(DistanceTraveled(idx_current),size(SumDistance(OldLabels)));

SumDistance(NewLabels) = 0;

InitialObjectLocation(NewLabels,:) = CurrentLocations(idx_new,:);
