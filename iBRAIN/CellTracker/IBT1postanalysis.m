function handles = IBT1postanalysis(handles,strSettingBaseName)

% calculate the tracking indexes trajectories
fprintf('%s: Calculating lineage matrices for Track IDs.\n',mfilename) 
[cellLineage,cellLineageMetaData]=linmatIBT1(handles,strSettingBaseName)

% to generate trees and related objects first delete trajectories which are
% not complete. Note: we need the original cellLineage to later compute the
% some statistics about the tracker. 
cellLineageFinal = cellfun(@(x) x(sum(not(isnan(x)),2) == size(x,2),:),cellLineage,'uniformoutput',false);
matTrueIdx = ~isempty(cellLineageFinal);
cellLineageFinal = cellLineageFinal(matTrueIdx);
cellLineageMetaDataFinal = cellLineageMetaData(matTrueIdx);

% compute cells which are related. 
fprintf('%s: Calculating cell relatedness.\n',mfilename)
[cellDividersFinal,cellChildrenFinal]=cellfun(@(x) SiblingGenerationIBT1(x),cellLineageFinal,'uniformoutput',false); 
% the same for cellLineage. this will seve to compute the total divisions.
% Note that segmentation errors will make this a very bad measure. perhaps
% is better to do this with svms
[cellDividers,cellChildren]=cellfun(@(x) SiblingGenerationIBT1(x),cellLineage,'uniformoutput',false); 


for iSites = 1:length(cellChildrenFinal)
    fprintf('%s: Site no. %d out of %d total sites.\n',mfilename,iSites,length(cellChildren))
    tic
    [cellMoveGen{iSites},cellLin{iSites}]=GenerationsIBT1(cellChildrenFinal{iSites},cellDividersFinal{iSites},cellLineageFinal{iSites}(:,1));
    toc
end

%filter for objects of the last frame
fprintf('%s: Calculating cell relatedness.\n',mfilename)
cellMoveGen_Last = cellfun(@(x) x(logical(x(:,1)),:),cellMoveGen,'uniformoutput',false); 


% save results to handles
handles.Measurements.(handles.TrackingSettings.ObjectName).cellLineage = cellLineage;
handles.Measurements.(handles.TrackingSettings.ObjectName).cellLineageFinal = cellLineageFinal;
handles.Measurements.(handles.TrackingSettings.ObjectName).cellDividersFinal = cellDividersFinal;
handles.Measurements.(handles.TrackingSettings.ObjectName).cellChildrenFinal = cellChildrenFinal;
handles.Measurements.(handles.TrackingSettings.ObjectName).cellDividers = cellDividers;
handles.Measurements.(handles.TrackingSettings.ObjectName).cellChildren = cellChildren;
handles.Measurements.(handles.TrackingSettings.ObjectName).cellMoveGen = cellMoveGen;
handles.Measurements.(handles.TrackingSettings.ObjectName).cellLin = cellLin;
handles.Measurements.(handles.TrackingSettings.ObjectName).cellMoveGen_Last = cellMoveGen_Last;
handles.Measurements.(handles.TrackingSettings.ObjectName).cellLineageMetaDataFinal = cellLineageMetaDataFinal;
handles.Measurements.(handles.TrackingSettings.ObjectName).cellLineageMetaData = cellLineageMetaData;

