function [handles] = perWellTracking(handles)

cellAllSegmentedImages = handles.Measurements.Image.SegmentedFileNames';
strObjectToTrack = handles.TrackingSettings.ObjectName;

fprintf('%s: Tracking Stage 1: objects to be tracked: %s.\n',mfilename,strObjectToTrack);


% get the number of wells, the number of timepoints and the number of
% sites.
[matRows, matColumns, strWells, matTimepoints] = cellfun(@filterimagenamedata,cellAllSegmentedImages,'UniformOutput',false);
matRows = cell2mat(matRows);
matColumns = cell2mat(matColumns);
matTimepoints = cell2mat(matTimepoints);

% Check that there is more than one timepoint
if sum(matTimepoints > 1) == 0
    error('%s: There is only one timepoint. Please check that the PATH to the movie is correct. ',mfilename)
end

% Now get the sites!!
[matSites, ~] = cellfun(@check_image_position,cellAllSegmentedImages,'UniformOutput',false);
matSites = cell2mat(matSites);

% Asign unique ID to sites in the whole plate
[structUniqueSiteID.matUniqueValues foo structUniqueSiteID.matJ]= unique([matRows, matColumns, matSites],'rows');
clear foo






% [MF]: new function, per well treatment, compatible with global labelling
% module, cool. Done for speeding up cluster computing. A next update could
% be to implement a batch processing for the basic tracker function, and to
% treat each site independently at this stage.

if ~strcmp(handles.TrackingSettings.Well2Process{1},'all') && size(handles.TrackingSettings.Well2Process,2) == 1

    % [MF]I trim down to keep only informations of the
    % well we are interrested in.    
structUniqueSiteID.matUniqueValues = structUniqueSiteID.matUniqueValues(structUniqueSiteID.matUniqueValues(:,1) == (double(handles.TrackingSettings.Well2Process{1}(1,1))-64)...
    & structUniqueSiteID.matUniqueValues(:,2)== (str2double(handles.TrackingSettings.Well2Process{1}(1,2:3))),:);
tmpPos = strcmp(strWells, handles.TrackingSettings.Well2Process{1});
structUniqueSiteID.matJ = structUniqueSiteID.matJ(tmpPos);

%this step is very important, indeed the well sorting induces a sorting of
%the sites, which is needed, but in CP raw data, sites are not well
%dependent e.g if there is 3 wells acquired with 12 sites each, sites will
%be 1 to 36. then if I process only the second well, in structUniqueSiteID.matJ
%I will have sites num.13 to 24, and I want 1 to 12, I fix this here.
matNumOfSites=length(unique(structUniqueSiteID.matJ));
matMaxSite = max(unique(structUniqueSiteID.matJ));
matRatio = matMaxSite/matNumOfSites; 

if matNumOfSites ~= matMaxSite
    for i = 1:length(structUniqueSiteID.matJ)
        sVal = structUniqueSiteID.matJ(i);
        newsVal = sVal-(matNumOfSites*(matRatio-1));
        structUniqueSiteID.matJ(i) = newsVal;
    end
end

matRows = matRows(tmpPos);
matColumns = matColumns(tmpPos);
matTimepoints = matTimepoints(tmpPos);
strWells = strWells(tmpPos);
matSites = matSites(tmpPos);
cellAllSegmentedImages = cellAllSegmentedImages(tmpPos);
handles.Measurements.Nuclei.Location = handles.Measurements.Nuclei.Location(tmpPos);
handles.Measurements.Image.FileNames = handles.Measurements.Image.FileNames(tmpPos);
handles.Measurements.Image.ObjectCount = handles.Measurements.Image.ObjectCount(tmpPos);
handles.Measurements.Image.BaseMovieFileNames = handles.Measurements.Image.BaseMovieFileNames(tmpPos);


clear tmpPos matNumOfSites matMaxSite matRatio

% [MF]but if there is more than one well to process:
elseif ~strcmp(handles.TrackingSettings.Well2Process{1},'all') && size(handles.TrackingSettings.Well2Process,2) > 1

    muvIX = zeros(size(structUniqueSiteID.matUniqueValues,1),1);
    mJIX = zeros(size(structUniqueSiteID.matJ,1),1);
    for i = 1:size(handles.TrackingSettings.Well2Process,2)
    tmpPos = structUniqueSiteID.matUniqueValues(:,1)==(double(handles.TrackingSettings.Well2Process{i}(1,1))-64)...
        & structUniqueSiteID.matUniqueValues(:,2)==(str2double(handles.TrackingSettings.Well2Process{i}(1,2:3)));
    tmpPos2 = strcmp(strWells, handles.TrackingSettings.Well2Process{i});
    muvIX = muvIX + tmpPos;
    mJIX  = mJIX  + tmpPos2;
    end
    
structUniqueSiteID.matUniqueValues = structUniqueSiteID.matUniqueValues(muvIX,:);
structUniqueSiteID.matJ = structUniqueSiteID.matJ(mJIX);

%As we process more than one well here, the problem is a bit more complex
tmpSiteList = sort(unique(structUniqueSiteID.matJ));
matNumOfSites=length(tmpSiteList);
matMaxSite = max(tmpSiteList);

if matNumOfSites ~= matMaxSite
hMap = java.util.HashMap;


    for i = 1:matNumOfSites
        hMap.put(tmpSiteList(i),i);
    end


    for i = 1:length(structUniqueSiteID.matJ)
        sVal = structUniqueSiteID.matJ(i);
        newsVal = hMap.get(sVal);
        structUniqueSiteID.matJ(i) = newsVal;
    end
end


matRows = matRows(mJIX);
matColumns = matColumns(mJIX);
matTimepoints = matTimepoints(mJIX);
strWells = strWells(mJIX);
matSites = matSites(mJIX);
cellAllSegmentedImages = cellAllSegmentedImages(mJIX);
handles.Measurements.Nuclei.Location = handles.Measurements.Nuclei.Location(tmpPos);
handles.Measurements.Image.FileNames = handles.Measurements.Image.FileNames(tmpPos);
handles.Measurements.Image.ObjectCount = handles.Measurements.Image.ObjectCount(tmpPos);
handles.Measurements.Image.BaseMovieFileNames = handles.Measurements.Image.BaseMovieFileNames(tmpPos);


clear mJIX tmpPos tmpPos2 muvIX hMap hKeys matMaxSite matNumOfSites tmpSiteList
end

matMetaDataInfo = [matRows, matColumns, matSites ,matTimepoints];
handles.Measurements.Image.SegmentedFileNames = cellAllSegmentedImages';
handles.structUniqueSiteID = structUniqueSiteID;
handles.matMetaDataInfo = matMetaDataInfo;
handles.strWells = strWells;

end

