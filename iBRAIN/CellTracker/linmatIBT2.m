function [handles]=linmatIBT2(handles,BaseName)

if nargin == 1 && isfield(handles.TrackingSettings,'strSettingBaseName')
    strSettingBaseName = handles.TrackingSettings.strSettingBaseName;
elseif nargin == 2
    strSettingBaseName = BaseName;
else
    warning('%s: No file base name given. Base name set to "Nuclei11". Note this mau create errors.\n',mfilename)
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
cellSiteData = cellfun(@(x) x(:,[1 2 3 4 8 9 10]),cellSiteData,'uniformoutput',false);
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


%%%
% [NB] here maby we ca make a nuw function that works thorugh sites
for iSites = 1:length(cellSiteData)
    %cellLineage=cellfun(@(x) LinMatrixSubFun(x,tp),cellSiteData,'uniformoutput',false);
    fprintf('%s: Calculating matrix for site %d out of %d total sites.\n',mfilename,iSites,length(cellSiteData))
    cellLineage{iSites}=LinMatrixSubFun(cellSiteData{iSites},tp);    
end

handles.Measurements.(handles.TrackingSettings.ObjectName).cellLineage = cellLineage;
handles.Measurements.(handles.TrackingSettings.ObjectName).cellLineageMetaData = cellLineageMetaData;



%--------------------------------------------------------------------------
function [matLineage]=LinMatrixSubFun(data,tp)

%data = cellSiteData{15};
%number of images per timepoint:

cellObjIds=(cellfun(@(data) data(:,1),data,'UniformOutput',false));
cellParentIds=(cellfun(@(data) data(:,2),data,'UniformOutput',false));
cellX=(cellfun(@(data) data(:,3),data,'UniformOutput',false));
cellY=(cellfun(@(data) data(:,4),data,'UniformOutput',false));
cellLifeTime = (cellfun(@(data) data(:,5),data,'UniformOutput',false));
cellGhosts = (cellfun(@(data) data(:,6),data,'UniformOutput',false));
cellFamilyID = (cellfun(@(data) data(:,7),data,'UniformOutput',false));

%preallocate results matrices:
matNumObj=cell2mat(cellfun(@(cellObjIds) length(cellObjIds),cellObjIds,'UniformOutput',false));
matLineage=nan(2000,tp); %[NB] not it is larger than the time points this create dificulties later!

% j=1
% j=2
% j=3   j=4
for j=1:tp
    if j == 1
        %for the last frame: copy objects as they are
        %matLineage(1:size(cellObjIds{j}(~cellGhosts{j}),1),j) = cellObjIds{j}(~cellGhosts{j});
        matLineage(1:size(cellObjIds{j},1),j) = cellObjIds{j};
        
%     elseif j == 2
%         %for the frame before the last: copy parents of thelast frame as they are and add objects that disapear
%         IXParentToDisc = (cellParentIds{j-1}==cellObjIds{j-1}); % these are apearing objects in previous frame and hence the parents will not be represented in current frame
%         CurrentParent = cellParentIds{j-1}(~IXParentToDisc);
%         matLineage(1:size(cellParentIds{j-1}(~cellGhosts{j-1}),1),j) = cellParentIds{j-1}(~cellGhosts{j-1});
%         
%         %look for objects that disapear
%         DisIX = ~ismember(cellObjIds{j},cellParentIds{j-1});
%         matLineage(size(cellParentIds{j-1},1)+1:sum(DisIX)+size(cellParentIds{j-1},1),j) = cellObjIds{j}(DisIX);
%         
%         %just in case step
%         matLineage(matLineage == 0) = nan;
    else
        %for all the rest first look at the objects in the previous matLineage mapping
        %then look at the objects of the current frame that where not there
        %previously
        
%         ParentIX = arrayfun(@(x) find(cellObjIds{j-1} == x),matLineage(:,j-1),'uniformoutput',false); %the slowest line
%         emptyIX = cell2mat(cellfun(@isempty,ParentIX,'uniformoutput',false)); %the 2nd slowest line
%         ParentIX(emptyIX) = {nan};
%         ParentIX = cell2mat(ParentIX);
%         matLineage(~isnan(ParentIX),j) = cellParentIds{j-1}(ParentIX(~isnan(ParentIX)));
%         
%     size(cellParentIds{j-1}(ParentIX(~isnan(ParentIX))));
%         [NB] awsome new solution! makes fonction ten times faster...
%         [~,b,c] = intersect(cellObjIds{j-1},matLineage(:,j-1));
%         matLineage(c,j) = cellParentIds{j-1}(b); 
       
        %[NB] awsome new solution! makes fonction ten times faster...
        
        %get objects from previous frame
        CurrentArray = matLineage(:,j-1);
        CurrentArray(isnan(CurrentArray)) = 0; 
        
        %find indexes of previous objects
        [linUn.a foo linUn.b] = unique(CurrentArray);  
        %find indexes of previous objects
        %[ObjUn.a foo ObjUn.b] = unique([cellObjIds{j-1} cellParentIds{j-1}],'rows');
        [~, ObjUn.b] = sort(cellObjIds{j-1});
        ObjUn.b =[1;ObjUn.b+1];
        
%         %test if things are equal
%         test = [0;ObjUn.a];
%         test(~ismember(test,linUn.a))
%         
              
        
%         IXParentToDisc = (cellObjIds{j-1}==cellFamilyID{j-1}) &...
%         (cellParentIds{j-1}==cellObjIds{j-1}) &...       
%         (cellLifeTime{j-1} == 0) &...        
%         (cellX{j-1} == 0) &...
%         (cellY{j-1} == 0);
        
        CurrentParent = cellParentIds{j-1};
%         CurrentParent(IXParentToDisc) = nan;
        CurrentParent = [0;CurrentParent];
        matLineage(:,j) = CurrentParent(ObjUn.b(linUn.b)); 
        clear foo  
        matLineage(matLineage == 0) = nan; 
%         imagesc([matLineage(1:500,j) test(1:500,1)])
%         imagesc([linUn.a(~isnan(linUn.a)) ObjUn.a])
%        sum(~ismember(CurrentArray,[0;cellObjIds{j-1}]))

        %look for objects that disapear
        DisIX = ~ismember(cellObjIds{j},cellParentIds{j-1});
        %find the first unocupied place
        availIX = find(nansum(matLineage,2)==0,1);
        %check the found index is correct
        if availIX == size(matLineage,1)
            matLineage = [matLineage;nan(1000,size(matLineage,2))];
        end 
        
        
        if or(~isnan(matLineage(availIX,j)),~isnan(matLineage(availIX+1,j)))             
            error('%s: the availIX value should point to a place that contains the first unocupied place in the current column of the matLineage matrix. The actual value is %d!',mfilename,availIX);
        end
        if ~isempty(availIX)
        matLineage(availIX:sum(DisIX)+availIX-1,j) = cellObjIds{j}(DisIX);
        end 
        
        
        %correct the objects: delete the objects that have apeared in the
        %last frame
        matLineage(isnan(matLineage)) = 0;
        [linUn.a foo linUn.b] = unique(matLineage(:,j));  
        %find indexes of previous objects
        [ObjUn.a foo ObjUn.b] = unique(cellObjIds{j});
        ObjUn.b =[1;ObjUn.b+1];
        TempObjToBeRem = linUn.a(~ismember(linUn.a,[0;ObjUn.a]));
        matLineage(ismember(matLineage(:,j),TempObjToBeRem),j) = nan;
        
        temptest = linUn.a(~ismember([0;ObjUn.a],linUn.a));
        
        %just in case step
        matLineage(matLineage == 0) = nan;   
        
        
        
    end
    
    
end

% resize  and flip matLineage
availIX = find(nansum(matLineage,2)==0,1);
matLineage = matLineage(1:availIX-1,:);
matLineage = flipdim(matLineage,2);

%imagesc(matLineage+1000,[1000 max(matLineage(:))+1000])



