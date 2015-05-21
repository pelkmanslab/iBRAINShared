function [h,ax,matCellNumberPerBin, matBinEdges, matDataBounds] = plotmean(varargin)

    % ok, make the plot I made for Eva but then fully in Matlab.
    %
    % if input is a cell, treat each cell as individual point on horizontal axis.
    %
    % if input is a two-column matrix, histogram bin the first column, and
    % treat each bin as an individual point on x.

    % return all object handles (median line, and fill handle)

    
    % optional noplot input argument, skips drawing.
    boolMakePlot = true;
    if any(strcmpi(varargin,'noplot'))
        boolMakePlot = false;
        % remove option from varargin
        varargin(strcmpi(varargin,'noplot')) = [];
    end    

    boolMakeCellNumberPlot = true;
    if any(strcmpi(varargin,'nocellnumberplot'))
        boolMakeCellNumberPlot = false;
        % remove option from varargin
        varargin(strcmpi(varargin,'nocellnumberplot')) = [];
    end        
    
    % check for user supplied number FaceAlpha property
    intFaceAlpha = 1;
    matPotentialAlphaIX = cellfun(@(x) numel(x)==1 & isnumeric(x) & mean(x(:))>0 & mean(x(:))<1,varargin);
    if any(matPotentialAlphaIX)
        intFaceAlpha = varargin{matPotentialAlphaIX};
        % remove option from varargin
        varargin(matPotentialAlphaIX) = [];
    end            

    % check for user supplied number of bins
    intNumOfBins = 15;
    matPotentialNumOfBinsIX = cellfun(@(x) numel(x)==1 & isnumeric(x) & isequal(round(x),x),varargin);
    if any(matPotentialNumOfBinsIX)
        intNumOfBins = varargin{matPotentialNumOfBinsIX};
        % remove option from varargin
        varargin(matPotentialNumOfBinsIX) = [];
    end            
    
    % check for user supplied color
    strColor = 'k';
    matPotentialColorStringIX = cellfun(@(x) numel(x)==1 & ischar(x),varargin);
    if any(matPotentialColorStringIX)
        strColor = varargin{matPotentialColorStringIX};
        % remove option from varargin
        varargin(matPotentialColorStringIX) = [];
    end                
    
    h = [];
    ax = [];
    boolHold = ishold;

    if numel(varargin)==1 && iscell(varargin{1})
        % we are dealing with a single cell-array input data.
        
        % remove NaNs and Infs
        varargin{1} = cellfun(@(x) x(~isinf(x) & ~isnan(x)),varargin{1},'UniformOutput',false);
        
        % note that fill does not handle NaNs well, so skip empty cells
        matOkIX = ~cellfun(@isempty,varargin{1});
        matDataBounds = cell2mat(cellfun(@(x) [nanmean(x)-nanstd(x), nanmean(x)-0.5*nanstd(x), nanmean(x), nanmean(x)+0.5*nanstd(x), nanmean(x)+nanstd(x)],varargin{1}(matOkIX)','UniformOutput',false));
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
        matBinEdges = linspace(quantile(matXData,0),quantile(matXData,1),intNumOfBins);
        
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
            % only count mean & std if there's more than 2 datapoints..
            if sum(matIX)>2
                matDataBounds(iBin,:) = [nanmean(matYData(matIX))-nanstd(matYData(matIX)),nanmean(matYData(matIX))-0.5*nanstd(matYData(matIX)), nanmean(matYData(matIX)), nanmean(matYData(matIX))+0.5*nanstd(matYData(matIX)), nanmean(matYData(matIX))+nanstd(matYData(matIX))];
            end
            matCellNumberPerBin(iBin) = sum(matIX);
            
        end

    end

    % if we don't want to plot anything, we are done.
    if ~boolMakePlot
        return
    end
    
    matBadIX = any(isnan(matDataBounds),2);
    if ~boolHold
        hold on
    end
    
    matPatchColor = [0.75 0.75 0.75; 0.6 0.6 0.6];
    switch lower(strColor)
        case 'r'
            matPatchColor = [0.75 0.5 0.5; 0.6 0.3 0.3];
        case 'g'
            matPatchColor = [0.5 0.75 0.5; 0.3 0.6 0.3];
        case 'b'
            matPatchColor = [0.5 0.5 0.75; 0.3 0.3 0.6];
    end
    
    h(2)=fill([matBinEdges(~matBadIX),fliplr(matBinEdges(~matBadIX))],[matDataBounds(~matBadIX,1)',fliplr(matDataBounds(~matBadIX,5)')],matPatchColor(1,:),'linestyle','none','FaceAlpha',intFaceAlpha);
    h(3)=fill([matBinEdges(~matBadIX),fliplr(matBinEdges(~matBadIX))],[matDataBounds(~matBadIX,2)',fliplr(matDataBounds(~matBadIX,4)')],matPatchColor(2,:),'linestyle','none','FaceAlpha',intFaceAlpha);
    h(4)=plot(matBinEdges,matDataBounds(:,3),'-o','color',strColor,'MarkerFaceColor',strColor,'MarkerSize',5);
    ax(1) = gca;
    
    if boolMakeCellNumberPlot
        ax(2)=axes();
        h(1)=plot(matBinEdges,matCellNumberPerBin,':o','color',strColor,'MarkerFaceColor',[1 1 1],'Color',[.3 .3 .3],'MarkerSize',5);    
        ylabel('cell number')
    
        matPositionFirstAxis = get(ax(1),'Position');
        set(ax(1),'Position',matPositionFirstAxis,'YAxisLocation','left');
        set(ax(2),'Position',matPositionFirstAxis,'YAxisLocation','right','Color','none','TickLength',[0 0],'YColor',[.3 .3 .3],'XTick',[],'XTickLabel',[])
    
        set(gcf,'CurrentAxes',ax(1))
    end

    if ~boolHold
        hold off
    end
    drawnow
end