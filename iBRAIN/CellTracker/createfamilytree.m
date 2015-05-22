function handles = createfamilytree(handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% This function converts the family relationship encoded in the  handles
% into the phytree compatible format (stored in PhyTreeForm). It aditionally
% encodes additional informations (ObjectId, ParentID, Lifetime) of the nodes in the TreeNodeInfo, where the
% rows correspond to the id of the nodes in the PhyTreeForm.
% The Treeplot can be created by
% view(phytree(PhyTreeForm{iSites}{i},TreeNodeInfo{iSites}{i}(:,3))), with i = the family ID
%
% by VZ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


strSettingBaseName = handles.TrackingSettings.strSettingBaseName;
ObjectName = handles.TrackingSettings.ObjectName;
TrackingMeasurementPrefix = strcat('TrackObjects_',strSettingBaseName);
handles.Measurements.(ObjectName).(strcat(TrackingMeasurementPrefix,'TreeNodeInfo')) = {'ObjectID', 'ParentID','Lifetime','TimeofBirth'};

if strncmpi(handles.TrackingSettings.PhyTrees,'y',1); 
    
numTotalSites = size(handles.structUniqueSiteID.matUniqueValues,1);
    
for iSites = 1:numTotalSites
        
        % find all the images that belong to iSites and put them in the correct
        % order
        matIndexSite = find(handles.structUniqueSiteID.matJ == iSites);
        strCurrentWell = handles.strWells(matIndexSite); strCurrentWell = char(strCurrentWell(1));
        fprintf('%s: Tracking Stage 3.2: Create Phytrees %d of %d. Well %s.\n',mfilename,handles.structUniqueSiteID.matUniqueValues(iSites,3),numTotalSites,strCurrentWell);
       
        [foo matOrderedTimePointIdx] = sort(handles.matMetaDataInfo(matIndexSite,4));
        clear foo
        matOrderedTimePointIdx = matIndexSite(matOrderedTimePointIdx);
       



%%% Initiations
maxFamilyID = 1;
FamilyID = 0;
tmax = size(matOrderedTimePointIdx,1);

% Calculate trees for all families
while FamilyID < maxFamilyID
    
    FamilyID = FamilyID+1;
    
    
    notStart = 1;
    
    tStart = tmax+1;
    
    %%% Find the start point of the tree (corresponds to the timepoint
    %%% where the tree ends)
    
    while notStart && tStart > 1 %the while loop here is done to locate the familly number 'FamilyID' in the last time points
        
        tStart = tStart-1; %if not present in tStart, in the next loop checks at the previous tp
        curTimepoint = matOrderedTimePointIdx(tStart);
        CurrFamilyIDs = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){curTimepoint}(:,10);
        maxFamilyID = max(maxFamilyID,max(CurrFamilyIDs)); %checks the max family ID and if in the current there is a new max
        
        FamIDs = find(CurrFamilyIDs == FamilyID); %basically, tries here to see where is the current familly ID we are looking for
        
        
        % If the startpoint is found, initialize values
        if max(FamIDs)
            notStart = 0;
            
            % PhyTreeForm is the input for the phytree function
            PhyTreeForm{FamilyID} = [];
            % TreeNodeInfo contains Obj Info, Parent Info, the Lifetime. the
            % rownumber in this vector is equal to the nodeID in the PhyTreeForm matrix.
            TreeNodeInfo{FamilyID} = [];
            
        end
        
        
    end
    
    
    notEnd = 1;
    tCurr = tStart + 1;
    
    
    %%% Now go through all timepoints from the startpoint of the tree (we
    %%% are approaching the tree from the branches).
    while notEnd && tCurr > 1
        
        
        tCurr = tCurr-1;
        curTimepoint = matOrderedTimePointIdx(tCurr);
        CurrFamilyIDs = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){curTimepoint}(:,10);
        
        FamIDs = find(CurrFamilyIDs == FamilyID);
        
        
        if tCurr == tStart
            
            
            TreeNodeInfo{FamilyID} =  handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){curTimepoint}(FamIDs,[1,2,8,9]);
            FamObjectIDs = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){curTimepoint}(FamIDs,1);
            
            FamParentIDs = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){curTimepoint}(FamIDs,2);
            
            
        else
            
            % if no member of the family is found, this must be the start
            % of the tree
            if isempty(FamIDs)
                notEnd = 0;
                TreeNodeInfo{FamilyID}(TreeNodeInfo{FamilyID}(:,1),4) = tCurr-1;
                
                
                % if its not the start of the tree go on
            else
                FamObjectIDs = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){curTimepoint}(FamIDs,1);
                
                FamParentIDs = handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){curTimepoint}(FamIDs,2);
                
                newFamObjects = setdiff(FamObjectIDs, TreeNodeInfo{FamilyID}(:,1));
                
                if ~isempty(newFamObjects)
                    newFamObjectIDs = find(ismember(handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){curTimepoint}(:,1),newFamObjects));
                    
                    TreeNodeInfo{FamilyID} = [TreeNodeInfo{FamilyID}; handles.Measurements.(ObjectName).(TrackingMeasurementPrefix){curTimepoint}(newFamObjectIDs,[1,2,8,9])];
                end
                
            end
        end
        % Check wether a split happened just one slide before
        
        [~,uniFirst,~] = unique(FamParentIDs, 'first');
        
        if size(uniFirst,1) < size(FamObjectIDs,1);
            
            [~,uniLast,~] = unique(FamParentIDs, 'last');
            
            [~,child1] = setdiff(uniFirst,uniLast);
            [~,child2] = setdiff(uniLast,uniFirst);
            
            child1= sort(child1);
            child2= sort(child2);
            
            child1 =uniFirst(child1);
            child2 = uniLast(child2);
            
            % Save the information, when a branching
            % happended(tCurr) and which are the Childs (child 1&2)
            for i = 1:size(child1,1)
                child1ID= find(TreeNodeInfo{FamilyID}(:,1)==FamObjectIDs(child1(i)));
                child2ID= find(TreeNodeInfo{FamilyID}(:,1)==FamObjectIDs(child2(i)));
                
                TreeNodeInfo{FamilyID}(child1ID,2) = FamParentIDs(child1(i));
                TreeNodeInfo{FamilyID}(child2ID,2) = FamParentIDs(child2(i));
                TreeNodeInfo{FamilyID}(child1ID,4) = tCurr;
                TreeNodeInfo{FamilyID}(child2ID,4) = tCurr;
                
                
                PhyTreeForm{FamilyID} = [PhyTreeForm{FamilyID}; child1ID child2ID];
            end
            
        end
    end
    
    
end



handles.Measurements.(ObjectName).PhyTreeForm{iSites} = PhyTreeForm;
handles.Measurements.(ObjectName).TreeNodeInfo{iSites} = TreeNodeInfo;
end
%[MF] addition of a saving step

% save the measurements
handles2 = struct();
handles2.Measurements.(ObjectName).PhyTreeForm = handles.Measurements.(ObjectName).PhyTreeForm; 
        
% [BS] Store handles as measurement file in strBatchPath
strMeasurementFileName = sprintf('Measurements_%s_%s.mat',ObjectName,['PhyTreeForm' TrackingMeasurementPrefix]);
save(fullfile(handles.strBatchPath, strMeasurementFileName), 'handles2')

% save the measurements
handles2 = struct();
handles2.Measurements.(ObjectName).TreeNodeInfo = handles.Measurements.(ObjectName).TreeNodeInfo; 
handles2.Measurements.(ObjectName).('TreeNodeInfoFeatures') = handles.Measurements.(ObjectName).(strcat(TrackingMeasurementPrefix,'TreeNodeInfo'));

% [BS] Store handles as measurement file in strBatchPath
strMeasurementFileName = sprintf('Measurements_%s_%s.mat',ObjectName,['TreeNodeInfo' TrackingMeasurementPrefix]);
save(fullfile(handles.strBatchPath, strMeasurementFileName), 'handles2')

end


