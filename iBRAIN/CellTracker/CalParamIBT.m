function [handles] = CalParamIBT(handles)

% this should be there all the time... as this are part of the default
% settings
if isfield(handles,'TrackingSettings')
strSettingBaseName = handles.TrackingSettings.strSettingBaseName;
ObjectName = handles.TrackingSettings.ObjectName;
numTimeInterval = handles.TrackingSettings.TimeResolutionSecs;
else 
    error('%s: TrackingSettings was not part of the handles structure. please make sure you add TrackingSettings to the handles structure.\n',mfilename)
end 

%check other variables
if isfield(handles.Measurements.(ObjectName),'cellLineage')
cellLineage = handles.Measurements.(ObjectName).cellLineage;
else 
    error('%s: cellLineage was not part of the handles structure. please make sure you add cellLineage to the handles structure.\n',mfilename)
end 

if isfield(handles.Measurements.(ObjectName),'cellLineageMetaData')
cellLineageMetaData = handles.Measurements.(ObjectName).cellLineageMetaData;
else 
    error('%s: cellLineageMetaData was not part of the handles structure. please make sure you add cellLineageMetaData to the handles structure.\n',mfilename)
end
    

%get general variables
matMetaDataToBeMatched = cell2mat(handles.Measurements.(ObjectName).(strcat('TrackObjectsMetaData_',strSettingBaseName))');
matTimePoints = 1:max(matMetaDataToBeMatched(:,4));



for iLin = 1:length(cellLineage)
    
    fprintf('%s: Working on site %d out of %d total sites.\n',mfilename,iLin,length(cellLineage));
tic
    
    %current site
    matTrajectoryMetadata = cellLineageMetaData{iLin};
    matCurrentLineage = cellLineage{iLin};
    
    matCurrentLineage = unique(matCurrentLineage,'rows');
    
    %get the X and Y locations for the trajectory    
    matX = nan(size(matCurrentLineage));
    matY = nan(size(matCurrentLineage));
    matLCD = nan(size(matCurrentLineage));
    matAREA = nan(size(matCurrentLineage));
    matIX = nan(size(matCurrentLineage));
    matMData = nan(1,size(matCurrentLineage,2));
    
    % loop time points
    for iTime = 1:length(matTimePoints)
    
        TempMetaData = [matTrajectoryMetadata matTimePoints(iTime)];
        TempIX  = find(ismember(matMetaDataToBeMatched,TempMetaData,'rows'));
        TempObjecTrackID = handles.Measurements.(ObjectName).(strcat('TrackObjects_',strSettingBaseName)){TempIX}(handles.Measurements.(ObjectName).(strcat('TrackObjects_',strSettingBaseName)){TempIX}(:,9) == 0,1);
        TempLineageObjectTrackID = matCurrentLineage(:,iTime);
        TempLineageObjectTrackID(isnan(TempLineageObjectTrackID)) = 0;
        Obtodis = handles.Measurements.(ObjectName).(strcat('TrackObjects_',strSettingBaseName)){TempIX}...
            (handles.Measurements.(ObjectName).(strcat('TrackObjects_',strSettingBaseName)){TempIX}(:,9) > 0,1);
        
        if ~isempty(Obtodis)
            for i = 1:length(Obtodis)
                TempLineageObjectTrackID(TempLineageObjectTrackID == Obtodis(i)) = 0;
            end
        end
        
        %save the indexes
        [linUn.a foo linUn.b] = unique(TempLineageObjectTrackID);
        [~, ObjUn.b] = sort(TempObjecTrackID);
        ObjUn.b =[1;ObjUn.b+1];
        tempX = [nan;handles.Measurements.(ObjectName).Location{TempIX}(:,1)];
        tempY = [nan;handles.Measurements.(ObjectName).Location{TempIX}(:,2)];
 
        
        %[a,b,c] = intersect(TempObjecTrackID,TempLineageObjectTrackID);
        matX(:,iTime) = tempX(ObjUn.b(linUn.b),1);
        matY(:,iTime) = tempY(ObjUn.b(linUn.b),1);
        matIX(:,iTime) = ObjUn.b(linUn.b)-1;
        matMData(1,iTime) = TempIX;
        
        if isfield(handles.Measurements.(ObjectName),'LocalCellDensity')
            tempLCD = [nan;handles.Measurements.(ObjectName).LocalCellDensity{TempIX}(:,1)];
            matLCD(:,iTime) = tempLCD(ObjUn.b(linUn.b),1);
            
            
        end
        
        if isfield(handles.Measurements.(ObjectName),'AreaShape')
            tempAREA = [nan;handles.Measurements.(ObjectName).AreaShape{TempIX}(:,1)];
            matAREA(:,iTime) = tempAREA(ObjUn.b(linUn.b),1);
            
        end
        
        
    end
    
    % calculate delta LCD if posible 
    if isfield(handles.Measurements.(ObjectName),'LocalCellDensity')
        matLCDPrev = [matLCD(:,1) matLCD(:,1:end-1)];
        matDeltaLCD =  matLCD - matLCDPrev;
    else
        matDeltaLCD =  matLCD;
    end
    
    
    
    % calculate delta LCD if posible
    if isfield(handles.Measurements.(ObjectName),'AreaShape')
        matAREAPrev = [matLCD(:,1) matAREA(:,1:end-1)];
        matDeltaAREA =  matAREA - matAREAPrev;      
    else
        matDeltaAREA =  matAREA;
    end
        
    
    %correct X and Y possition by interpolation
    matXPrev = [matX(:,1) matX(:,1:end-1)];
    matYPrev = [matY(:,1) matY(:,1:end-1)];
    
    % Calculate angles
    fprintf('%s: site %d: Claculating angle.\n',mfilename,iLin);
    matTan = (matY-matYPrev)./(matX-matXPrev);
    matAngle = atan(matTan);
    
    %get quadrant
    matdXpos = (matX-matXPrev) > 0;
    matdYpos = (matY-matYPrev) > 0;
    matQuadrant = nan(size(matY));
    matQuadrant(matdXpos & matdYpos) = 1;
    matQuadrant(~matdXpos & matdYpos) = 2;
    matQuadrant(~matdXpos & ~matdYpos) = 2; %note this is 3
    matQuadrant(matdXpos & ~matdYpos) = 4;
    
    %correct angles
    matAngle(matQuadrant==2) = matAngle(matQuadrant==2)+pi;
    matAngle(matQuadrant==4) = matAngle(matQuadrant==4)+(pi*2);
    
    % Calculate Final Displacement
    fprintf('%s: site %d: Claculating displacements and velocities.\n',mfilename,iLin);
   
    matDisplacement = ((matY-repmat(matY(:,1),1,size(matY,2))).^2+(matX-repmat(matX(:,1),1,size(matX,2))).^2).^(1/2);
    
    %Caldulate delta displacement    
    matPrevDis = [matDisplacement(:,1) matDisplacement(:,1:end-1)];
    matDeltaDisplacement =  matDisplacement - matPrevDis;
    
    
    % Calculate Integrated Displacement
    matTDis = (((matY-matYPrev).^2+(matX-matXPrev).^2).^(1/2));
    matTDis(isnan(matTDis)) = 0;
    matIntDisp = cumsum(matTDis,2);
    
    % Calculate Speed
    matSpeed = matTDis./numTimeInterval;
    
    % Calculate Acceleration
    matSpeedPrev = [matSpeed(:,1) matSpeed(:,1:end-1)];
    matAccel = (matSpeed-matSpeedPrev)./numTimeInterval;
    
    %calculate the mean square displacement fro all cells
    matSD = [];
    matTimeLags = 1:length(matTimePoints)-1;
    matMSD = [];%zeros(size(matX,1),length(matTimeLags));
    
    
    %calculate the MSD for all cells and partial rajectories
    fprintf('%s: site %d: Claculating MSD.\n',mfilename,iLin);
    cellMSD = {};
     
    %[NB] this part of the code is rather slow. It should be improved  
    for iCell = 1:size(matX,2)
        matTemppX = matX(:,1:iCell);
        matTemppY = matY(:,1:iCell);
        if iCell == 1
            matMSD = nan(size(matX(:,1)));
        else
            %         fprintf('%s: site %d: Claculating MSD. %d times out of %d.\n',mfilename,iLin,iCell,size(matX,2));
            matTimeLagsInit = 1:iCell-1;% matTimeLags = repmat(matTimeLags,size(matTemppX,1),1);
            for iLags = matTimeLagsInit
                matLag =  matTimeLagsInit+iLags;
                IXAllowed =   matLag < iCell+1;
                matSD = (matX(:,matLag(IXAllowed))-matX(:,matTimeLagsInit(IXAllowed))).^2+(matY(:,matLag(IXAllowed))-matY(:,matTimeLagsInit(IXAllowed))).^2;
                matMSD(:,iLags) = nanmean(matSD,2);
                matSD = [];
            end
        end
        cellMSD{iCell} = matMSD;
        matMSD = [];        
    end
    
    
    % matFinalMSD = cell2mat(cellfun(@(x) x(:,end),cellMSD,'uniformoutput',false));
    % reshape all measurements to be saved in the cell profiler format
    
    matTempData = [];
    cellAllConcData = {matDisplacement,matDeltaDisplacement,matIntDisp,matAngle,matSpeed,matAccel,matDeltaLCD,matDeltaAREA};
    
    
    fprintf('%s: site %d: Saving Data.\n',mfilename,iLin);
    for iTime = 1:length(matTimePoints)
        
        tFilt = matIX(:,iTime) == 0;
        tIX = matIX(~tFilt,iTime);
        tFeat = cell2mat(cellfun(@(a) a(~tFilt,iTime),cellAllConcData,'uniformoutput',false));
        tOrdFeat = nan(max(tIX),size(cellAllConcData,2));
        tOrdFeat(tIX,:) = tFeat;
        %save parameters
        cellTrackingStats{matMData(iTime)} = tOrdFeat;
        
        %now do the MSD
        TempMSD = cellMSD{iTime}(~tFilt,:);
        tOrdFeat = nan(max(tIX),size(TempMSD,2));
        tOrdFeat(tIX,:) = TempMSD;
        
        %save MSD
        cellTrackingMSD{matMData(iTime)} = tOrdFeat;
        
        
    end
toc    
end

cellTrackingStatsFeatures = {'Displacement',...
    'dt_Displacement',...
    'Integrated_Displacement',...
    'Movement_Angle',...
    'Movement_Speed',...
    'Movement_Acceleration',...
    'dt_LocalCellDensity',...
    'dt_Area'};

handles.Measurements.(ObjectName).TrackingStatsFeatures = cellTrackingStatsFeatures;
handles.Measurements.(ObjectName).TrackingStats = cellTrackingStats;
handles.Measurements.(ObjectName).TrackingMSD = cellTrackingMSD;



