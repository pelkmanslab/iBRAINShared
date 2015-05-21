function TrackOvermultiplesitesV1(strRootPath,strSettingBaseName)


%Mat F in Pelkmans Lab 2011
%this module is part of iBrainTracker and is called in order to
%perform the tracking over multiple sites
%[MF] here is the code for relabelling over multiple sites, generating new
%global coordinates and finally identify objects that are splited over two
%sites, recognize them as single objects and labelling them accordingly


%Load its data if needed
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
%done


%checks if it was done before
if strcmpi(handles.OriginalTrackingSettings.GlobalDone, 'no') %#ok<NODEF>
    %if not checks if we want to do it!
    if strncmpi(handles.TrackingSettings.GlobalLabel,'y',1);
        
fprintf('%s: 2.1 Track over multiple sites for setting file SetTracker_%s.txt.\n',mfilename,handles.TrackingSettings.strSettingBaseName);        
        
        
cellAllSegmentedImages = handles.Measurements.Image.SegmentedFileNames';
threshold_merge = handles.TrackingSettings.GlobalLabelMergeT; 
imageSize = handles.TrackingSettings.GlobalLabelImsize;
ObjectName = handles.TrackingSettings.ObjectName;
matSites = handles.matMetaDataInfo(:,3);
matTimepoints = handles.matMetaDataInfo(:,4);
TrackingMeasurementPrefix = strcat('TrackObjects_',strSettingBaseName);
relatedSet1 = [];
relatedSet2 = [];

%Avoid errors if site numbering does not start at one
if min(matSites)~=1
   fprintf('%s: Site numbering does not start at 1, cannot calculate image snake, skipping %s\n',mfilename,mfilename);
   return 
end


% 011211 VZ: I made the positions where the ObjectIDs etc. are stored no
% longer hardlinked. The GlobalIDs are now appended to the previous matrix.

NameSeq = handles.Measurements.(ObjectName).(strcat(TrackingMeasurementPrefix,'Features'))(:);
ObjRow=strcmp(NameSeq,'ObjectID');
ParRow=strcmp(NameSeq,'ParentID');
FamRow=strcmp(NameSeq,'FamilyID');

ObjRow= find(ObjRow);
ParRow= find(ParRow);
FamRow= find(FamRow);

% %[MF] indeed familyIds can miss...
% if isempty(FamRow)
%     FamRow = size(NameSeq,1)+1;
%     for i=1:length(matglobalLabelingSeq)
%     handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){matglobalLabelingSeq(i,1)}(:,FamRow)=zeros(size(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){matglobalLabelingSeq(i,1)}(:,ParRow)));    
%     end
%     handles.Measurements.(ObjectName).(strcat(TrackingMeasurementPrefix,'Features'))(FamRow) = {'FamilyIDs'}; 
% end
% 
% NameSeq = handles.Measurements.(ObjectName).(strcat(TrackingMeasurementPrefix,'Features'))(:);
    
GObjRow=strcmp(NameSeq,'GlobalObjectID');
GParRow=strcmp(NameSeq,'GlobalParentID');
GFamRow=strcmp(NameSeq,'GlobalFamilyID');

GObjRow= find(GObjRow);
GParRow= find(GParRow);
GFamRow= find(GFamRow);

if isempty(GObjRow)
GObjRow = size(NameSeq,1)+1;
GParRow = size(NameSeq,1)+2;
GFamRow = size(NameSeq,1)+3;
end


%%Creates here the structure for relabelling, column GObjRow and GParRow of the existing structure are used for storing global current and parent labels

for i=1:length(handles.matglobalLabelingSeq)
    
    handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.matglobalLabelingSeq(i,1)}(:,GObjRow)=zeros(size(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.matglobalLabelingSeq(i,1)}(:,ObjRow)));
    handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.matglobalLabelingSeq(i,1)}(:,GParRow)=zeros(size(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.matglobalLabelingSeq(i,1)}(:,ParRow)));
    handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.matglobalLabelingSeq(i,1)}(:,GFamRow)=zeros(size(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){handles.matglobalLabelingSeq(i,1)}(:,FamRow)));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%before starting here some comment on the 'handles.matglobalLabelingSeq' matrix.

% a little matrix that will simplify my life! >> I get here the
%good succession of image set (and corresponding well & blabla) in the handle structure and this in a
%single matrix, allowing me to not loop the global labelling module
%column 1 sequence of imagesets
%column 2 row number
%column 3 col number
%column 4 site number
%column 5 time point
%column 6 idx of corresponding segmented img in list 'cellAllSegmentedImages' of
%the task dispatcher (iBrainTrackerV1)

%You can see in the next part of the code that I will trim it down for
%following the good image set sequence, following a per well/per time
%point and finally per site structure.


%numberOftimepoints = max(matTimepoints);
maxTimepoints=max(matTimepoints);
minTimepoints=min(matTimepoints);
%numberOfsites = max(matSites);
maxSites = max(matSites);
minSites = min(matSites);
strWellList = unique(handles.strWells);
numberOfwells = length(strWellList);


for iWells = 1:numberOfwells
    
wellID = strWellList(iWells);
wellID = wellID{1};
rowNumberID = double(wellID(1))-64;
colNumberID = str2double(wellID(2:3));

    %matrestrictedsets contains only the image sets corresponding to the
    %well we are interrested in
    
matWellRestrictedSets = handles.matglobalLabelingSeq(handles.matglobalLabelingSeq(:,2) == rowNumberID & handles.matglobalLabelingSeq(:,3) == colNumberID,:); 
Well = handles.strWells(matWellRestrictedSets(1,1));

    
    %%% some initialisation
    maxGlobalLabel= 1;
    cellVisited = java.util.HashMap;
    counter = [];
    
    for timeFrame = minTimepoints:maxTimepoints
        fprintf('Stage 2 : overMultipleSites tracking: global labelling of well %s at timepoint %d .\n',Well{1},timeFrame);
        
        %Same logic here
        matWellandTpRestrictedSets = matWellRestrictedSets(matWellRestrictedSets(:,5) == timeFrame,:) ;
        
        
        %%create global labels the first time
        
        if timeFrame==minTimepoints
            
            for i=minSites:maxSites
                
                %Same logic here, basically matWellTpAndSiteRestrictedSets
                %contains only one line corresponding to the current set to
                %treat
                
                matWellTpAndSiteRestrictedSets = matWellandTpRestrictedSets(matWellandTpRestrictedSets(:,4) == i,:);
                
                                
                %calculate the number of nuclei in the site
                [numNuclei,~]=size(handles.Measurements.Nuclei.(TrackingMeasurementPrefix){matWellTpAndSiteRestrictedSets(1)}(:,ObjRow));
                %create global labels local_label
                
                newGlobalLabels=(maxGlobalLabel:(maxGlobalLabel+numNuclei-1))' ;
                handles.Measurements.Nuclei.(TrackingMeasurementPrefix){matWellTpAndSiteRestrictedSets(1)}(:,GObjRow)=newGlobalLabels;
                handles.Measurements.Nuclei.(TrackingMeasurementPrefix){matWellTpAndSiteRestrictedSets(1)}(:,GParRow)=newGlobalLabels;
                %[VZ]
                handles.Measurements.Nuclei.(TrackingMeasurementPrefix){matWellTpAndSiteRestrictedSets(1)}(:,GFamRow)=newGlobalLabels;
                
                
                handles.Measurements.Nuclei.([TrackingMeasurementPrefix,'Features']){GObjRow} = 'GlobalObjectID';
                handles.Measurements.Nuclei.([TrackingMeasurementPrefix,'Features']){GParRow} = 'GlobalParentID';
                handles.Measurements.Nuclei.([TrackingMeasurementPrefix,'Features']){GFamRow} = 'GlobalFamilyID';
                
                maxGlobalLabel=maxGlobalLabel+numNuclei;
                
                %intialise the border cell column, a border cell in this case
                %is a cell that is cut between two sites an reconstructed by
                %this code
                handles.Measurements.(ObjectName).BorderCell{matWellTpAndSiteRestrictedSets(1)} = zeros(size(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){matWellTpAndSiteRestrictedSets(1)}(:,FamRow)));
                
                clear numNuclei
              
                
            end
        else
            
            for jsites = minSites:maxSites
                
                %Same logic here, basically matWellTpAndSiteRestrictedSets
                %contains only one line corresponding to the current set to
                %treat
                
                matWellTpAndSiteRestrictedSets =matWellandTpRestrictedSets(matWellandTpRestrictedSets(:,4) == jsites,:) ;
                i = matWellTpAndSiteRestrictedSets(1);                                             %% i is the current set to treat
                %j = matWellTpAndSiteRestrictedSets(4);                                            %% j is the number of the site, used for labeling
                
                %Very handy for having access to previous timepoint
                %information
                
                previoustimeFrame = timeFrame - 1 ;
                matWellandPreviousTpRestrictedSets = matWellRestrictedSets(matWellRestrictedSets(:,5) == previoustimeFrame,:);
                matWellPreviousTpAndSiteRestrictedSets = matWellandPreviousTpRestrictedSets(matWellandPreviousTpRestrictedSets(:,4) == matSites(i),:);
                
                
                k = (matWellPreviousTpAndSiteRestrictedSets(1));                                                        %% k is the set at the previous frame, used for calling previous image information
                
                
                
                %%%just little specification here about how the labels are
                %%%stored in handles.Measurements.(ObjectName).(TrackingMeasurementPrefix)
                %%%so first column are the current labels
                %%%second one is the parent labels. column GObjRow is the global
                %%%current labels, column GParRow the global parent labels
                
                %initialise the border cell column
                handles.Measurements.(ObjectName).BorderCell{i} = zeros(size(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,ObjRow))); %%the border cells of this time point, over all sites of course
                
                
                
                
                
                
                %%the correspondence between local current&Parents labels and global current&Parents labels at
                %%the previous timepoint is made here. THis matrix is very
                %%important for keeping track of the overall logic of global labelling
                %%especially for new labels of the same time points that will
                %%impact all the global labelling
                
                %keep in mind, k is the previous time point, kk the t-2.
                
                matchingCurrent = zeros(max(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){k}(:,ObjRow)),1);
                matchingParents = zeros(max(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){k}(:,ParRow)),1);
                matchingFamily  = zeros(max(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){k}(:,FamRow)),1);
                %for current labels: the position in the matrix refers to
                %the local label, the number at this position is the
                %corresponding global label.
                
                for ii= 1:length(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){k}(:,GObjRow))
                    jj= handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){k}(ii,ObjRow);
                    matchingCurrent(jj) = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){k}(ii,GObjRow);
                end
                
                %the same for parents
                for ii= 1:length(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){k}(:,GParRow))
                    jj= handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){k}(ii,ParRow);
                    matchingParents(jj) = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){k}(ii,GParRow);
                end
                
                %[VZ] the same for the family
                for ii= 1:length(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){k}(:,GFamRow))
                    jj= handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){k}(ii,FamRow);
                    matchingFamily(jj) = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){k}(ii,GFamRow);
                end
                
                
                
                %%Let's use the matching matrix for dealing the global labels at the right position a the current time point
                %%Keep in mind, i is the current time point.
                
                global_current = zeros(length(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,ObjRow)),1);
                global_parents = zeros(length(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,ParRow)),1);
                % [VZ]
                global_family =  zeros(length(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,FamRow)),1);
                %%a problem can appear here, matching labels 'jj' can sometime
                %%be absent, so it would crash. This is due to segmentation
                %%artefacts (nuclei at this timepoint is not detected etc...) and should idealy not appear, but world's not
                %%ideal and segmentation will always fail on some objects...
                %%111121>Update: check vito's ghost trick, should not create
                %%any problem
                %%Wrong, it improves, but the problem is still here.
                
                
                %%Update 111125, some NaN can be inserted, the reason is the
                %%following, if at previous time point a label is missing
                %%inside the succession of labels, the gap in matchingCurrent
                %%matrixes is filled by an Nan, cause they are initialized by
                %%NaN, which helps me to differentiate new labels from reapearing labels
                
                %For Current
                
                for ii = 1:length (handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,ObjRow))
                    jj = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(ii,ObjRow);
                    
                    %I deal the good labels
                    if jj <= length(matchingCurrent)
                        global_current(ii) = matchingCurrent(jj);
                    else
                        global_current(ii) = 0;
                        counter = counter + 1;
                    end
                end
                
                %For Parent
                
                for ii = 1:length (handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,ParRow))
                    jj = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(ii,ParRow);
                    
                    %I deal the good global parent labels
                    if jj <= length(matchingParents)
                        global_parents(ii) = matchingParents(jj);
                    else
                        global_parents(ii) = 0;
                    end
                end
                clear matchingParents
                
                %For Family
                
                for ii = 1:length (handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,FamRow))
                    jj = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(ii,FamRow);
                    
                    %I deal the good global family labels
                    if jj <= length(matchingFamily)
                        global_family(ii) = matchingFamily(jj);
                    else
                        global_family(ii) = 0;
                    end
                end
                
                clear ii jj
                
                %%Of course the new global labels (compared to previous time point), comming from division of cells or cells comming from another site are O in the global labels matrix now,
                %%so...
                
                num_new_labels=length(find(global_current==0));
                
                new_global_current=(maxGlobalLabel:(maxGlobalLabel+num_new_labels-1))';
                
                
                %incrementation to keep track at the new time point of the new
                %labels.
                
                if ~isempty (global_parents == 0)
                    maxGlobalLabel = (maxGlobalLabel + num_new_labels);
                end
                
                clear num_new_labels
                
                global_current(global_current==0)=new_global_current;
                
                clear new_global_current
                
                %%Here I label the zero parents as follow, first I check which
                %%local parents labels are corresponding to the zero positions
                %%at the actual time point , I check in the 'matchingCurrent' matrix(in previous timepoint), to which
                %%global labels it refers, then insert these global labels in
                %%the matrix 'global_parents', if there is no correspondence,
                %%there was a problem of segmentation/nuclei detection, I thus
                %%restart the lineage with the global label, like at time point
                %%1. >>> this is a problem to fix at the segmentation levels,
                %%we can't really get rid of it, although the tracker must be
                %%able to deal with it.
                %%%the solution I will implement is basically to go at t-2 or
                %%%3 to see if I can pick up the number in a previous timepoint.
                
                if ~isempty(find(global_parents==0,1))
                    localparents_i = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,ParRow);
                    
                    %which local parent label is corresponding to the global
                    %label 0, in order to find in the previous timepoint matrix the
                    %correspondence.(keep in mind, i is the current timepoint set, k the previous timepoint set)
                    
                    zeroLocalparentsLabels_i = localparents_i(global_parents==0);
                    for iii = 1 : length(zeroLocalparentsLabels_i)
                        jjj = zeroLocalparentsLabels_i(iii);
                        if jjj <= length(matchingCurrent)
                            correspondingGlobalCurrent_k(iii) = matchingCurrent(jjj);
                        else
                            correspondingGlobalCurrent_k(iii) = 0;
                        end
                    end
                    
                    clear matchingCurrent iii jjj zeroLocalparentsLabels_i localparents_i
                    
                    global_parents(global_parents==0)= correspondingGlobalCurrent_k; %%we can still keep here some 0, this corresponds to a loss of the lineage
                    global_parents(global_parents==0)= global_current(global_parents==0); %%I replace here the remaining zeros by the correspondig global label in order to restart the leanage
                    clear correspondingGlobalCurrent_k 
                    
                end
                
                if ~isempty(find(global_family==0,1))
                    
                    localfamily_i = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,FamRow);
                    zeroLocalfamilyLabels_i = localfamily_i(global_family==0);
                    for iii = 1 : length(zeroLocalfamilyLabels_i)
                        jjj = zeroLocalfamilyLabels_i(iii);
                        if jjj <= length(matchingFamily)
                            correspondingGlobalCurrentfam_k(iii) = matchingFamily(jjj);
                        else
                            correspondingGlobalCurrentfam_k(iii) = 0;
                        end
                    end
                    clear matchingFamily iii jjj localfamily_i zeroLocalfamilyLabels_i
                    
                    global_family(global_family==0)= correspondingGlobalCurrentfam_k; %%we can still keep here some 0, this corresponds to a loss of the lineage
                    global_family(global_family==0)= global_current(global_family==0); %%I replace here the remaining zeros by the correspondig global label in order to restart the leanage
                    clear correspondingGlobalCurrentfam_k
                    
                end
                %refresh the columns
                
                handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,GObjRow)= global_current ;
                handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,GParRow)= global_parents ;
                handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,GFamRow)= global_family ;
                clear global_parents global_current global_family;
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Has been done and is sent as a function input, but it is good to keep it
        %as a comment in case of.
        
        %     [matRows, matColumns, ~, matTimepoints] = cellfun(@filterimagenamedata,cellFileNames_Current,'UniformOutput',false);
        %     matRows = cell2mat(matRows);
        %     matColumns = cell2mat(matColumns);
        %     matTimepoints = cell2mat(matTimepoints);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%let's place the file names of the images in the order they were
        %%treated, in accordance to the succession of the image sets.
        
        cellAllSegmentedImagesReordered = cellAllSegmentedImages(matWellandTpRestrictedSets(:,6));
        
        
        % lookup image positions
        [intImagePosition,strMicroscopeType] = cellfun(@check_image_position,cellAllSegmentedImagesReordered,'UniformOutput',false);
        clear cellAllSegmentedImagesReordered
        intImagePosition = cell2mat(intImagePosition);
        strMicroscopeType = unique(strMicroscopeType);
        % get image snake
        [matImageSnake,~] = get_image_snake(max(intImagePosition),strMicroscopeType);
        clear strMicroscopeType
        
        % matImageSnake(1,:) = max(matImageSnake(1,:)) - matImageSnake(1,:)
        % matImageSnake(2,:) = max(matImageSnake(2,:)) - matImageSnake(2,:)
        
        % get image size
        
        if(length(imageSize)==2)
            matImageSize = imageSize;
        else
            matImageSize = [1040 1392];
        end
        
        
        % keep meta data track, i.e. image-index and object-index
        cellNucleiMetaData = cell(size(handles.Measurements.(ObjectName).Location));
        % add offsets to nuclei positions
        for i = 1:length(handles.Measurements.(ObjectName).Location)
            if ~isempty(handles.Measurements.(ObjectName).Location{i}(:,ObjRow))
                % meta data: image-index & object-index
                cellNucleiMetaData{i} = NaN(size(handles.Measurements.(ObjectName).Location{i}(:,ObjRow)));
                cellNucleiMetaData{i}(:,1) = i;
                cellNucleiMetaData{i}(:,2) = 1:size(handles.Measurements.(ObjectName).Location{i}(:,ObjRow),1);
            end
        end
        
        
        
        %map to global coordinates
        
        handles.Measurements.(ObjectName).Location_Global = handles.Measurements.(ObjectName).Location;
        
        % calculate new origins for each image, use these as offsets.
        matNucleusOffsetX = matImageSnake(1,intImagePosition) * matImageSize(1,2);% width
        matNucleusOffsetY = matImageSnake(2,intImagePosition) * matImageSize(1,1);% height
        
        matNucleusOffsetX = matNucleusOffsetX - (matImageSnake(1,intImagePosition));
        matNucleusOffsetY = matNucleusOffsetY - (matImageSnake(2,intImagePosition));
        clear intImagePosition matImageSnake
        %     %  get max well dimensions, for 2D binning later
        %     intMaxWelPosX = (max(matImageSnake(1,:))+1) * matImageSize(1,2) - max(matImageSnake(1,:));% max well width
        %     intMaxWelPosY = (max(matImageSnake(2,:))+1) * matImageSize(1,1) - max(matImageSnake(2,:));% max well height
        
        % get nuclei positions, this one was tricky to fix for CP104553 structure!!
        
        XY = cat(1,handles.Measurements.(ObjectName).Location);
        for i = 1:length(XY)
            xloc{i} = XY{i}(:,1);
            yloc{i} = XY{i}(:,2);
        end
        cellNucleiPositions = cellfun(@(x,y) [x,y],xloc,yloc,'UniformOutput',false);
        clear yloc xloc XY
        
        %all global coordinates in one array
        cellNucleiGlobalCoordinates=[];
        %indices to which site global coordinates belong to
        cellNucleiGlobalSiteIndices=[];
        
        %globalLabels=[];
        
        for jsites = minSites:maxSites
            
            
            
            %Same logic here, basically matWellTpAndSiteRestrictedSets
            %contains only one line corresponding to the current set to
            %treat
            
            matWellTpAndSiteRestrictedSets = matWellandTpRestrictedSets(matWellandTpRestrictedSets(:,4) == jsites,:) ;
            i = matWellTpAndSiteRestrictedSets(1);                                                                  %% i is the current set to treat
            j = matWellTpAndSiteRestrictedSets(4);                                                                  %% j is the number of the site, used for labeling
            
            
            if ~isempty(cellNucleiPositions{i})
                
                %convert to global coordinates
                handles.Measurements.(ObjectName).Location_Global{i}(:,1) = round(handles.Measurements.(ObjectName).Location{i}(:,1)  + matNucleusOffsetX(j)); %%check point here
                handles.Measurements.(ObjectName).Location_Global{i}(:,2) = round(handles.Measurements.(ObjectName).Location{i}(:,2)  + matNucleusOffsetY(j));
                
                %find number of objects
                [numNucSite,~]=size(handles.Measurements.(ObjectName).Location_Global{i}(:,ObjRow));
                
                %save all global coordinates into a single array
                cellNucleiGlobalCoordinates=[cellNucleiGlobalCoordinates;handles.Measurements.(ObjectName).Location_Global{i}(:,1),...
                    handles.Measurements.(ObjectName).Location_Global{i}(:,2),ones(numNucSite,1)*(j)];
                
                
                %save the indices of the site for every nuclei
                cellNucleiGlobalSiteIndices=[cellNucleiGlobalSiteIndices;[ones(numNucSite,1)*(j),(1:numNucSite)']];
                
                %save all the labels in the frame
                %globalLabels=[globalLabels;handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){i}(:,GObjRow)];
                
            end
        end
        
        clear matNucleusOffsetX matNucleusOffsetY
        %the trick here is to reduce memory usage due to using the function pdist over many sites:
        %first generating an image to deal all the centroids
        matTMPimg = zeros(max(cellNucleiGlobalCoordinates(:,1))+10,max(cellNucleiGlobalCoordinates(:,2))+10);        
        for i = 1:size(cellNucleiGlobalCoordinates,1)
            %For safety in case two cells have the same centroid, yes, it
            %happened already :)
            if matTMPimg(cellNucleiGlobalCoordinates(i,1),cellNucleiGlobalCoordinates(i,2)) == 0
            matTMPimg(cellNucleiGlobalCoordinates(i,1),cellNucleiGlobalCoordinates(i,2)) = i;
            elseif matTMPimg(cellNucleiGlobalCoordinates(i,1)+1,cellNucleiGlobalCoordinates(i,2)+1) == 0
            matTMPimg(cellNucleiGlobalCoordinates(i,1)+1,cellNucleiGlobalCoordinates(i,2)+1) = i;
            else
            matTMPimg(cellNucleiGlobalCoordinates(i,1)-1,cellNucleiGlobalCoordinates(i,2)-1) = i;
            end
            
        end
        
        %little initialization
        matCorresponding2merge = zeros(size(cellNucleiGlobalCoordinates,1),3);
        
        %here is the trick, for each object I cut an object centered patch of the image were
        %all centroids of objects are, therefore filtering out already
        %many other centroids that are not close enough
        for i = 1:size(cellNucleiGlobalCoordinates,1)
            
            %I define coordinates to cut out the good patch
            if cellNucleiGlobalCoordinates(i,1)>(6*threshold_merge)
            coor1(1,1) = cellNucleiGlobalCoordinates(i,1)-(6*threshold_merge);
            else
            coor1(1,1) = 1;
            end
            if cellNucleiGlobalCoordinates(i,2)>(6*threshold_merge)
            coor1(1,2) = cellNucleiGlobalCoordinates(i,2)-(6*threshold_merge);
            else
            coor1(1,2) = 1;
            end
            
            if cellNucleiGlobalCoordinates(i,1)+(6*threshold_merge) < max(cellNucleiGlobalCoordinates(:,1))
            coor2(1,1) = cellNucleiGlobalCoordinates(i,1)+(6*threshold_merge);
            else
            coor2(1,1) = max(cellNucleiGlobalCoordinates(:,1));
            end
            if cellNucleiGlobalCoordinates(i,2)+(6*threshold_merge) < max(cellNucleiGlobalCoordinates(:,2))
            coor2(1,2) = cellNucleiGlobalCoordinates(i,2)+(6*threshold_merge);
            else
            coor2(1,2) = max(cellNucleiGlobalCoordinates(:,2));
            end
            %effective cutting
            matCUTaround_i = matTMPimg(coor1(1,1):coor2(1,1),coor1(1,2):coor2(1,2));
            matCUTaround_i = unique(matCUTaround_i);
            matCUTaround_i(matCUTaround_i==0)=[];
            %if there is no objects around no need to continue
            if size(matCUTaround_i,1)>1
                %all of a sudden pdist is not that heavy anymore!
                matTMPcellNucleiGlobalCoordinates = cellNucleiGlobalCoordinates(matCUTaround_i,:);
                matTMPdistances = squareform(pdist(matTMPcellNucleiGlobalCoordinates));
                matTMPdistances = matTMPdistances(matCUTaround_i==i,:)';
                %Conditions: I am interrested in objects that are close
                %enough, not the same,and not comming from the same site of course.
                for IX = 1:size(matTMPdistances,1)
                    if matTMPdistances(IX) < threshold_merge && i ~= matCUTaround_i(IX)...
                    && matTMPcellNucleiGlobalCoordinates(matCUTaround_i==i,3) ~= matTMPcellNucleiGlobalCoordinates(IX,3)
                        if matCorresponding2merge(i,3) == 0 || matCorresponding2merge(i,3) >= matTMPdistances(IX)
                        matCorresponding2merge(i,1) = i;
                        matCorresponding2merge(i,2) = matCUTaround_i(IX);
                        matCorresponding2merge(i,3) = matTMPdistances(IX);
                        end
                    end
                end
            end
        end
       
        %removing positions that are not concerned
        matCorresponding2merge(matCorresponding2merge(:,1)==0,:) = [] ;      
        %init. the hashMap   
        hMap = java.util.HashMap;
        hMap2 = java.util.HashMap;
        hKeys=[];
        
        for ind = 1:size(matCorresponding2merge,1)

        hMap.put(matCorresponding2merge(ind,1),matCorresponding2merge(ind,2));
        hMap2.put(matCorresponding2merge(ind,1),matCorresponding2merge(ind,3));
        hKeys=[hKeys,matCorresponding2merge(ind,1)]; %%If You call the object you are interrested in,it gives you the closest cell 

        end
        
        
        
        
        
        for toglue_ind= 1:length(hKeys) %%for each object that was cut
            
            Part1_ind = hKeys(toglue_ind);
            
            Part2_ind=hMap.get(Part1_ind); %%get the counterpart from hMap
            dist=hMap2.get(Part1_ind);
            
            other_cell_ind = hMap.get(Part2_ind);%%get the other cells that are close of the counterpart
            dist_other=hMap2.get(Part2_ind);
            
            cell_visited=cellVisited.containsKey(Part1_ind);%%Was the first part already listed
            matching_cell_visited=cellVisited.containsKey(Part2_ind);%%Was the second part already listed
            
            if ((dist <= dist_other) && cell_visited==0 && matching_cell_visited==0)
                 
                maxGlobalLabel = maxGlobalLabel+1;
                
                %find the first indexes
                ObjectCutPart1 = cellNucleiGlobalSiteIndices(Part1_ind,:);
                siteObjectCutPart1 = ObjectCutPart1(1); % site of the part 1
                labelObjectCutPart1= ObjectCutPart1(2); % label of the part 1
                
                %find the second indexes
                ObjectCutPart2 = cellNucleiGlobalSiteIndices(Part2_ind,:);
                siteObjectCutPart2 = ObjectCutPart2(1);
                labelObjectCutPart2 = ObjectCutPart2(2);
                
                matPositions = matWellandTpRestrictedSets(:,4) == siteObjectCutPart1; %I restrict the matrix to the sets containing the site of counter part 1, for this time point.
                relatedSet1 = matWellandTpRestrictedSets(matPositions,:);
                relatedSet1 = relatedSet1(1); %and get the set number
                
                matPositions = matWellandTpRestrictedSets(:,4) == siteObjectCutPart2;
                relatedSet2 = matWellandTpRestrictedSets(matPositions,:);
                relatedSet2 = relatedSet2(1);
                
                
                %insert the new global label for both nuclei
                
                
                %                  if(numberOfsites>=10)
                newLabelOverSites=str2num([num2str(maxGlobalLabel)]);
                handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet1}(labelObjectCutPart1,GObjRow)=newLabelOverSites;
                handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet2}(labelObjectCutPart2,GObjRow)=newLabelOverSites;
                %                  else
                %                     %only one digit add zero
                %                     newLabelWithSites=str2num([num2str(maxGlobalLabel),'0',num2str(numberOfsites+1)]);
                %                     handles.Measurements.(ObjectName).TrackObjects_Label_global{relatedSet1}(nucleiIndex1)=newLabelWithSites;
                %                     handles.Measurements.(ObjectName).TrackObjects_Label_global{relatedSet2}(nucleiIndex2)=newLabelWithSites;
                %                  end
                
                
                %%%in the case one of the two parts of the object has no
                %%%parents(meaning it just came in the site), I give him
                %%%the parent of the other part
                if(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet1}(labelObjectCutPart1,GParRow)==0)
                    handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet1}(labelObjectCutPart1,GParRow)=handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet2}(labelObjectCutPart2,GParRow);
                    %[VZ]analog for family
                    handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet1}(labelObjectCutPart1,GFamRow)=handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet2}(labelObjectCutPart2,GFamRow);
                elseif (handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet2}(labelObjectCutPart2,GParRow)==0)
                    handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet2}(labelObjectCutPart2,GParRow)=handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet1}(labelObjectCutPart1,GParRow);
                    %[VZ]
                    handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet2}(labelObjectCutPart2,GFamRow)=handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet1}(labelObjectCutPart1,GFamRow);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %I can eventually need them
                %local_label1=handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet1}(labelObjectCutPart1,1);
                %local_label2=handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){relatedSet2}(labelObjectCutPart2,1);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                %mark both cells as border cells
                handles.Measurements.(ObjectName).BorderCell{relatedSet1}(labelObjectCutPart1)=1;
                handles.Measurements.(ObjectName).BorderCell{relatedSet2}(labelObjectCutPart2)=1;
                
                cellVisited.put(Part1_ind,1);
                cellVisited.put(Part2_ind,1);
            end
        end
        clear ('cellNucleiGlobalCoordinates', 'cellNucleiGlobalSiteIndices')
    end
    
end
handles.TrackingSettings.GlobalDone = 'yes';
%[MF]saving step(could even differentiate them):
%[MF]then save the global labelling too, has not to be rerun again:
saveTrckrOutPut(handles,TrackingMeasurementPrefix);
    end
else
     fprintf('%s: global labeling was already done\n',mfilename);
end
end


