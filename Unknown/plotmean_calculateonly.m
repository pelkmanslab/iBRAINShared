function [matDataBounds,matCellNumberPerBin] = plotmean_calculateonly(matData,matBinEdges)

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
    
%     matDataBounds(iBin,:) = [nanmean(matYData(matIX))-nanstd(matYData(matIX)),nanmean(matYData(matIX))-0.5*nanstd(matYData(matIX)), nanmean(matYData(matIX)), nanmean(matYData(matIX))+0.5*nanstd(matYData(matIX)), nanmean(matYData(matIX))+nanstd(matYData(matIX))];

%     % with SEM instead of STD...
%     matDataBounds(iBin,:) = [nanmean(matYData(matIX))-nanstd(matYData(matIX))/sqrt(sum(matIX)),nanmean(matYData(matIX))-0.5*(nanstd(matYData(matIX))/sqrt(sum(matIX))), nanmean(matYData(matIX)), nanmean(matYData(matIX))+0.5*(nanstd(matYData(matIX))/sqrt(sum(matIX))), nanmean(matYData(matIX))+(nanstd(matYData(matIX))/sqrt(sum(matIX)))];

    % with SEM instead of STD...
    matDataBounds(iBin,:) = quantile(matYData(matIX),[0.4,0.45,0.5,0.55,0.6]);


%     matDataBounds(iBin,:) = [nanmedian(matYData(matIX))-mad(matYData(matIX)),nanmedian(matYData(matIX))-0.5*mad(matYData(matIX)), nanmedian(matYData(matIX)), nanmedian(matYData(matIX))+0.5*mad(matYData(matIX)), nanmedian(matYData(matIX))+mad(matYData(matIX))];
    
    matCellNumberPerBin(iBin) = sum(matIX);




end
