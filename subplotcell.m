function [matSubplotHandles, cellH] = subplotcell(cellData,varargin)
% plot's the contents of a 2D cell array each in it's own subplot.
%
% Syntax:
% 
%   cellH = subplotcell(cellData,varargin)
%
% cellH returns the handles for each subplot axis handle.
%
% An example:
%
% % make random data in a cell of size 8x12
% cellData = cellfun(@(x) randn(3,2), cell(8,12),'UniformOutput',false)
% figure()
% matHs = subplotcell(cellData,'bar');
% arrayfun(@(x) set(x,'XTick',[1:3],'XTickLabel',{'bla1','bla2','bla3'},'YLim',[-1, 1],'fontsize',7),matHs)
%
% diggety. Berend Snijder 2010.

    % get cell size
    [iRows,iCols] = size(cellData);
    
    % init output
    cellH = cell(iRows,iCols);
    matSubplotHandles = NaN(iRows,iCols);
    
    % transpose to match subplot numbering
    cellData = cellData';
    
    % if varargin contains a valid function handle, use that instead of
    % bar() to plot the data
    if exist(varargin{1})==2 || exist(varargin{1})==5 %#ok<EXIST>
        strPlotFunction = varargin{1};
    else
        strPlotFunction = 'bar';
    end
    
    % for each index in the cell array
    for i = 1:numel(cellData)
        
        % activate subplot
        subplot(iRows,iCols,i)
        
        % evaluate plot function
        eval(sprintf('cellH{i}=%s(cellData{i});',strPlotFunction));
        
        % store subplot handle
        matSubplotHandles(i) = gca;

    end
    drawnow


end