function matLastFrameIdx=getLastFrameIndex(cellX)

%finds the las frames of a movie input is:
%cellX = handles.Measurements.Nuclei.TrackObjectsMetaData_***;

matCellX = cell2mat(cellX'); 
%maxTime = cell2mat(cellX');
maxTime = max(matCellX(:,end));
matLastFrameIdx = find(cell2mat(cellfun(@(x) x(end) == maxTime,cellX,'uniformoutput',false)))';

%now orderthem acording to site number and well
[foo matIndx] = sortrows(matCellX(matLastFrameIdx,1:end-1),[1 -3]);
matIndx=flipdim(matIndx,1);
matLastFrameIdx=matLastFrameIdx(matIndx)';


