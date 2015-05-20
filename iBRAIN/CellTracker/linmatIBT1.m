function [cellLineage,cellLineageMetaData]=linmatIBT1(handles,strSettingBaseName)

if nargin == 1
    warning('%s: No file base name guiven. Base name set to "Nuclei11". Note this mau create errors.\n',mfilename)
    strSettingBaseName = 'Nuclei11';
end 
%%%
%[NB] This code was first writen by James. Here we addapt linMatrix_v3 to
%iBrainTrackerV1.
% note that it works but it is rather slow

%We need to add the indexing matrix.

%strPath = 'Z:\Data\Users\Berend\Prisca\081202_H2B_GPI_movies_F07\081202_H2B_GPI_movies_F07\BATCH';
% get the metadata from handles. we need to sor the wells!!!!
matMetaData=cell2mat(handles.Measurements.(handles.TrackingSettings.ObjectName).(strcat('TrackObjectsMetaData_',strSettingBaseName))');

%%%
%[NB] we need to deal with different wells
[structUniWell.matValues structUniWell.matI structUniWell.matJ]= unique(matMetaData(:,1:3),'rows');

%now get the data for the first well.... to many cellfun! horrible code
matPossibleJ = 1:size(structUniWell.matValues,1);
cellSiteIndexes = arrayfun(@(x) (structUniWell.matJ == x),matPossibleJ,'uniformoutput',false);
cellSiteData=handles.Measurements.(handles.TrackingSettings.ObjectName).(strcat('TrackObjects_',strSettingBaseName));
cellSiteData = cellfun(@(x) x(:,1:2),cellSiteData,'uniformoutput',false); 
cellSiteData = cellfun(@(x) cellSiteData(x),cellSiteIndexes,'uniformoutput',false);
cellSiteMetaData = cellfun(@(x) matMetaData(x,:),cellSiteIndexes,'uniformoutput',false);
cellLineageMetaData = cellfun(@(x) x(1,1:3),cellSiteMetaData,'uniformoutput',false);

%order data acording to time point
[~,cellIndex]=cellfun(@(x) sortrows(x,4),cellSiteMetaData,'uniformoutput',false); 
cellSiteData = cellfun(@(x,y) x(y),cellSiteData,cellIndex,'uniformoutput',false);
cellSiteData=cellfun(@fliplr,cellSiteData,'uniformoutput',false);

%get the number of timepoints. this might be buggy, if images are
%incomplete... should be the made robusts 
tp = size(cellSiteData{1},2);



% get data from handles
%cellData=cellData(1016:1218);

%save # of timepoints:
% empty=cellfun('isempty',strfind(dataStruct.Settings.ModuleNames,'InputForTrackObjects_v1'));
% modRow=find(~empty);
% tp=dataStruct.Settings.VariableValues{modRow,13};\

%save number of images:
%numIm=dataStruct.Current.NumberOfImageSets;
%numIm=203;



%As our first column will be the last object Ids it makes sense to reverse
%the order of both the object and parent Ids.
%flipped global Object Ids:
%data=fliplr(cellData);

%%%
% [NB] here maby we ca make a nuw function that works thorugh sites 
for iSites = 1:length(cellSiteData)
%cellLineage=cellfun(@(x) LinMatrixSubFun(x,tp),cellSiteData,'uniformoutput',false);
fprintf('%s: Calculating matrix for site %d out of %d total sites.\n',mfilename,iSites,length(cellSiteData)) 
tic
cellLineage{iSites}=LinMatrixSubFun(cellSiteData{iSites},tp);
toc
end
 

%--------------------------------------------------------------------------
function [matLineage]=LinMatrixSubFun(data,tp)


%number of images per timepoint:
imSetLen=1;


cellObjIds=cellfun(@(data) data(:,1),data,'UniformOutput',false);
cellParentIds=cellfun(@(data) data(:,2),data,'UniformOutput',false);

%preallocate results matrices:
matNumObj=cell2mat(cellfun(@(cellObjIds) length(cellObjIds),cellObjIds,'UniformOutput',false));
matLineage=zeros(max(matNumObj),tp+1);
matPreLineage=matLineage(:,3:end);
matCatObjIds=zeros(imSetLen*max(matNumObj),tp);
matCatParentIds=zeros(imSetLen*max(matNumObj),tp);

%Concatenate all time points together:
for j=1:tp
    vCatObj=vertcat(cellObjIds{(j-1)*imSetLen+1:j*imSetLen});
    vCatPar=vertcat(cellParentIds{(j-1)*imSetLen+1:j*imSetLen});
    matCatObjIds(1:length(vCatObj),j)=vCatObj;
    matCatParentIds(1:length(vCatPar),j)=vCatPar;
end

%Ids of timepoint previous to one being observed
matCatPrevObjIds=matCatObjIds(:,2:end);
matCatPrevParentIds=matCatParentIds(:,2:end);

%save last time point object Ids in first column of matLineage:
matLineage(1:length(matCatObjIds(:,1)),1)=matCatObjIds(:,1);
matLineage(1:length(matCatParentIds(:,1)),2)=matCatParentIds(:,1);

%save locations of objectIds and find parents:
for j=1:tp-1
    %matFound contains the row position of current time point parent Ids in
    %previous time point object Ids
    matFound=[];
    
    %as no matPrevPar exists initally, and our starting point includes all
    %the parent Ids of the final time point we begin different depending on
    %the value of j
    %matFind finds the parent Id from timepoint x in the object Ids of
    %timepoint x-1
    if j==1
        matFound=matFind(matCatPrevObjIds(:,j),matCatParentIds(:,j));
    else
        matFound=matFind(matCatPrevObjIds(:,j),matPrevPar);
    end
    
    %reinitialise matPrevPar
    matPrevPar=[];
    
    %matPosFind finds the parent of the object Id in time point x-1, and
    %therefore the parent of the parent in timepoint x
    matPrevPar=matPosFind(matCatPrevParentIds(:,j),matFound);
    
    %save the data in preoutput matrices
    matPreLineage(1:length(matPrevPar),j)=matPrevPar;
    
end

matLineage(1:size(matPreLineage,1),3:end)=matPreLineage;
matLineage(matLineage==0)=nan;


%--------------------------------------------------------------------------
%transform the Id matrix in to an index matrix(will allow for ploting of the
%measurement of diferent trajectories.... though it will not allow for
%easier mapping of the final results from james fuctions o the actul odject
%ID rather than the track ID.








% 
% 
% %cellObjIds=cellfun(@(data) data(:,1),data,'UniformOutput',false);
% %cellParentIds=cellfun(@(data) data(:,2),data,'UniformOutput',false);
% 
% %preallocate results matrices:
% cellNumObj=cellfun(@(y) (cell2mat(cellfun(@(x) size(x,1),y,'UniformOutput',false))),cellSiteData,'UniformOutput',false);
% cellLineage=cellfun(@(x) zeros(max(x),tp+1),cellNumObj,'UniformOutput',false);
% cellPreLineage=cellfun(@(x) x(:,3:end),cellLineage,'uniformoutput',false);
% cellCatObjIds=cellfun(@(x) zeros(max(x),tp),cellNumObj,'uniformoutput',false); 
% %matCatObjIds=zeros(imSetLen*max(matNumObj),tp);
% %matCatParentIds=zeros(imSetLen*max(matNumObj),tp);
% cellCatParentIds = cellCatObjIds;
% 
% 
% 
% 
% %Concatenate all time points together:
% for j=1:tp
%     vCatObj=vertcat(cellObjIds{(j-1)*imSetLen+1:j*imSetLen});
%     vCatPar=vertcat(cellParentIds{(j-1)*imSetLen+1:j*imSetLen});
%     matCatObjIds(1:length(vCatObj),j)=vCatObj;
%     matCatParentIds(1:length(vCatPar),j)=vCatPar;
% end
% 
% %Ids of timepoint previous to one being observed
% matCatPrevObjIds=matCatObjIds(:,2:end);
% matCatPrevParentIds=matCatParentIds(:,2:end);
% 
% %save last time point object Ids in first column of matLineage:
% matLineage(1:length(matCatObjIds(:,1)),1)=matCatObjIds(:,1);
% matLineage(1:length(matCatParentIds(:,1)),2)=matCatParentIds(:,1);
% 
% %save locations of objectIds and find parents:
% for j=1:tp-1
%     %matFound contains the row position of current time point parent Ids in
%     %previous time point object Ids
%     matFound=[];
%     
%     %as no matPrevPar exists initally, and our starting point includes all
%     %the parent Ids of the final time point we begin different depending on
%     %the value of j
%     %matFind finds the parent Id from timepoint x in the object Ids of
%     %timepoint x-1
%     if j==1
%         matFound=matFind(matCatPrevObjIds(:,j),matCatParentIds(:,j));
%     else
%         matFound=matFind(matCatPrevObjIds(:,j),matPrevPar);
%     end
%     
%     %reinitialise matPrevPar
%     matPrevPar=[];
%     
%     %matPosFind finds the parent of the object Id in time point x-1, and
%     %therefore the parent of the parent in timepoint x
%     matPrevPar=matPosFind(matCatPrevParentIds(:,j),matFound);
%     
%     %save the data in preoutput matrices
%     matPreLineage(1:length(matPrevPar),j)=matPrevPar;
%     
% end
% 
% matLineage(1:size(matPreLineage,1),3:end)=matPreLineage;
% matLineage(matLineage==0)=nan;




%matFind attempts to find the row position of matLookFor in matLookIn
function [matFound]=matFind(matLookIn,matLookFor)

%get rid of zeros which are there due to the preallocation step
matLookForNon0=find(matLookFor);
matLookFor=matLookFor(matLookForNon0);
matLookInNon0=find(matLookIn);
matLookIn=matLookIn(matLookInNon0);

%generate a cell containing the locations in matLookIn of values in
%matLookFor
cellFound=arrayfun(@(matLookFor) find(matLookIn==matLookFor),matLookFor,'UniformOutput',false);

%find the location of empty matrices (i.e. unfound values of matLookFor0
%which could have resulted from popping in events
emptyFound=find(cell2mat(cellfun(@(cellFound) isempty(cellFound),cellFound,'UniformOutput',false)));

%instead of losing information about popping in save these empty cells as
%nans-not 0s as we used 0s for preallocating matrices
for j=1:length(emptyFound)
    cellFound{emptyFound(j)}=nan;
end

%save the output in a matrix
matFound=cell2mat(cellFound);

%we should account for popping out events too
%stillIn indicates the values of matLookFor which are members of matLookIn
stillIn=ismember(matLookIn,matLookFor);

%if a member of matLookFor (tp=x) is not a member of matLookIn (tp=x-1)
%this indicates that between the timepoints the cell popped out
popOut=find(~stillIn);

%add the location of any cell which popped out between tp=x and x-1 to the 
%end of matFound
if ~isempty(popOut)
    col=size(matFound,1);
    extraCol=size(popOut,1);
    matFound(col+1:col+extraCol,1)=popOut;
else
end

%matPosFind looks for the value of matLookIn in the position specified by
%matPosition
function [matPosFound]=matPosFind(matLookIn,matPosition)
%get rid of 0s in the inputs which are the result of preallocation
matPositionNon0=find(matPosition);
matPosition=matPosition(matPositionNon0);
matLookInNon0=find(matLookIn);
matLookIn=matLookIn(matLookInNon0);

%attempts to find the value of matLookIn at position matPosition
for j=1:length(matPosition)
    try
    matPosFound(j,1)=matLookIn(matPosition(j,1));
    %as we specified popping out events as nans, and this would usually
    %crash the function, we catch the error and set matPosFound at this
    %point also equal to a nan
    catch
        matPosFound(j,1)=nan;
    end
end






