function [h,ax,matCellNumberPerBin] = plotquant2(varargin)

    % ok, make the plot I made for Eva but then fully in Matlab.
    %
    % if input is a cell, treat each cell as individual point on horizontal axis.
    %
    % if input is a two-column matrix, histogram bin the first column, and
    % treat each bin as an individual point on x.

    % return all object handles (median line, and fill handle)

    h = [];
    ax = [];    

    if numel(varargin)==1 && iscell(varargin{1})
        % we are dealing with a single cell-array input data.
        
        % remove NaNs and Infs
        varargin{1} = cellfun(@(x) x(~isinf(x) & ~isnan(x)),varargin{1},'UniformOutput',false);
        
        % note that fill does not handle NaNs well, so skip empty cells
        matOkIX = ~cellfun(@isempty,varargin{1});
        matDataBounds = cell2mat(cellfun(@(x) quantile(x,[0.25 0.375 0.5 0.625 0.75]),varargin{1}(matOkIX)','UniformOutput',false));
        matCellNumberPerBin = cellfun(@numel, varargin{1}(matOkIX)');
        numOfBins = sum(matOkIX);
        matBinEdges = find(matOkIX);

    else
        
        if numel(varargin)==1 && isnumeric(varargin{1}) && size(varargin{1},2)==2
            % if input is a single two-column matrix, treat first column as x
            % and second column as y data.
            matXData = varargin{1}(:,1);
            matYData = varargin{1}(:,2);
        elseif numel(varargin)==1 && isnumeric(varargin{1}) && size(varargin{1},2)>2
            % if input is a single more-than-two-column matrix, treat each
            % column index as the x-data, and treat values as y-data.
            matXData = lin(repmat(1:size(varargin{1},2),size(varargin{1},1),1));
            matYData = varargin{1}(:);
        elseif numel(varargin)==2 && isnumeric(varargin{1}) && isnumeric(varargin{2})
            % if there's two inputs, and both are matrices, treat first as X data and second as Y data.            
            matXData = varargin{1}(:);
            matYData = varargin{2}(:);
        else
            error('Input data is of an unknown format')
        end
        
        % mild outlier discarding... should otherwise be min/max.
        matBinEdges = linspace(quantile(matXData,0.001),quantile(matXData,0.999),15);
        
        [foo,matBinDataIX] = histc(matXData,matBinEdges);
        clear foo
        
        % set x-data to the middle value of each bin.
        matBinEdges = matBinEdges + median(diff(matBinEdges));
        matBinEdges(end) = [];
        
        numOfBins = numel(matBinEdges);
        matDataBounds = NaN(numOfBins,5);
        matCellNumberPerBin = NaN(1,numOfBins);
        for iBin = 1:numOfBins

            matIX = matBinDataIX==iBin;
            matDataBounds(iBin,:) = quantile(matYData(matIX),[0.25 0.375 0.5 0.625 0.75]);
            matCellNumberPerBin(iBin) = sum(matIX);
            
        end

    end
    hold on
    fill([matBinEdges,fliplr(matBinEdges)],[matDataBounds(:,1)',fliplr(matDataBounds(:,5)')],[0.75 0.75 0.75],'linestyle','none');
    fill([matBinEdges,fliplr(matBinEdges)],[matDataBounds(:,2)',fliplr(matDataBounds(:,4)')],[0.6 0.6 0.6],'linestyle','none');
    plot(matBinEdges,matDataBounds(:,3),'-ok','MarkerFaceColor','k','MarkerSize',5);
    hold off
    drawnow
end