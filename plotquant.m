function [h,ax,matCellNumberPerBin,matOuterPatchDimensions,matEndPos] = plotquant(varargin)

    % ok, make the plot I made for Eva but then fully in Matlab.
    %
    % if input is a cell, treat each cell as individual point on horizontal axis.
    %
    % if input is a two-column matrix, histogram bin the first column, and
    % treat each bin as an individual point on x.

    % return all object handles (median line, and fill handle)

    h = [];
    ax = [];
    matCellNumberPerBin = [];
    
    boolHold = ishold;
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
    
    % check for user supplied color
    strColor = 'k';
    matPotentialColorStringIX = cellfun(@(x) (numel(x)==1 & ischar(x)) || (isequal(size(x),[1,3])),varargin);
    if any(matPotentialColorStringIX)
        strColor = varargin{matPotentialColorStringIX};
        % remove option from varargin
        varargin(matPotentialColorStringIX) = [];
    end                
    if ischar(strColor)
        matPatchColors = [0.75 0.75 0.75; 0.6 0.6 0.6];
    else
        matPatchColors = [strColor+0.25; strColor+0.1];
        matPatchColors(matPatchColors>1)=1;
    end
        
    
    % check for user supplied number of bins
    intNumOfBins = 15;
    matPotentialNumOfBinsIX = cellfun(@(x) numel(x)==1 & isnumeric(x),varargin);
    if any(matPotentialNumOfBinsIX)
        intNumOfBins = varargin{matPotentialNumOfBinsIX};
        % remove option from varargin
        varargin(matPotentialNumOfBinsIX) = [];
    end            
    
    

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
        matBinEdges = linspace(quantile(matXData,0.001),quantile(matXData,0.999),intNumOfBins);
        
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

    if nargout>3
        matOuterPatchDimensions = [[matBinEdges,fliplr(matBinEdges)];[matDataBounds(:,1)',fliplr(matDataBounds(:,5)')]];
    end
    
    
    if boolMakePlot
    % matCellNumberPerBin
    % matBinEdges
    % matDataBounds(:,3)
        if ~boolHold
            hold on
        end
        matNonNanIX = all(~isnan(matDataBounds),2);
        
        h(2)=fill([matBinEdges(matNonNanIX),fliplr(matBinEdges(matNonNanIX))],[matDataBounds(matNonNanIX,1)',fliplr(matDataBounds(matNonNanIX,5)')],matPatchColors(1,:),'linestyle','none','facealpha',intFaceAlpha);
        h(3)=fill([matBinEdges(matNonNanIX),fliplr(matBinEdges(matNonNanIX))],[matDataBounds(matNonNanIX,2)',fliplr(matDataBounds(matNonNanIX,4)')],matPatchColors(2,:),'linestyle','none','facealpha',intFaceAlpha);
        h(4)=plot(matBinEdges(matNonNanIX),matDataBounds(matNonNanIX,3),'-o','MarkerFaceColor',strColor,'Color',strColor,'MarkerSize',5);
        matEndPos = [matBinEdges(end),matDataBounds(find(~isnan(matDataBounds(:,3)),1,'last'),3)];

        ax(1) = gca;

        if boolMakeCellNumberPlot
            ax(2)=axes();
            h(1)=plot(matBinEdges,matCellNumberPerBin,':ok','MarkerFaceColor',[1 1 1],'Color',[.3 .3 .3],'MarkerSize',5);    
            ylabel('cell number','fontsize',5)

            matPositionFirstAxis = get(ax(1),'Position');
            set(ax(1),'Position',matPositionFirstAxis,'YAxisLocation','left','fontsize',6);
            set(ax(2),'Position',matPositionFirstAxis,'YAxisLocation','right','fontsize',6,'Color','none','TickLength',[0 0],'YColor',[.3 .3 .3],'XTick',[],'XTickLabel',[])

            set(gcf,'CurrentAxes',ax(1))
        end

    %     [h2,l1,l2]=plotyy(matBinEdges(:),matDataBounds(:,3),matBinEdges(:),matCellNumberPerBin(:));
    %     set(l1,'MarkerFaceColor','k','Marker','o')        
    %     set(l2,'Marker','*') 
    %     h(3)=plot(matBinEdges,matDataBounds(:,3),'-ok','MarkerFaceColor','k');

        if ~boolHold
            hold off
        end
        drawnow
    end
end