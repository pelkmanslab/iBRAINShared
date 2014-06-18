function [matCellNumberPerBin,matDataBounds] = plotmean_calculateonly_tcn(matData,matBinEdges)

matXData = matData(:,1);
matYData = matData(:,2);
        
[~,matBinDataIX] = histc(matXData,matBinEdges);
clear foo

% set x-data to the middle value of each bin.
matBinEdges = matBinEdges + median(diff(matBinEdges));
matBinEdges(end) = [];


numOfBins = numel(matBinEdges);
matDataBounds = NaN(numOfBins,5);
matCellNumberPerBin = NaN(1,numOfBins);
for iBin = 1:numOfBins

    matIX = matBinDataIX==iBin;
    
    matDataBounds(iBin,:) = [nanmean(matYData(matIX))-nanstd(matYData(matIX)),nanmean(matYData(matIX))-0.5*nanstd(matYData(matIX)), nanmean(matYData(matIX)), nanmean(matYData(matIX))+0.5*nanstd(matYData(matIX)), nanmean(matYData(matIX))+nanstd(matYData(matIX))];

%     matDataBounds(iBin,:) = [nanmedian(matYData(matIX))-mad(matYData(matIX)),nanmedian(matYData(matIX))-0.5*mad(matYData(matIX)), nanmedian(matYData(matIX)), nanmedian(matYData(matIX))+0.5*mad(matYData(matIX)), nanmedian(matYData(matIX))+mad(matYData(matIX))];
    
    matCellNumberPerBin(iBin) = sum(matIX);




end
