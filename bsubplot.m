function [i,h] = bsubplot(n,h,iMax,varargin)
    % find number of axes on current figure, and set i as 
    % number of axes + 1
    if nargin<2
        h = gcf;
    end
    if nargin<3
        iMax = 40;
    end
    matAxesHandles = findall(h,'type','axes');
    matAxesHandles(strcmpi(get(matAxesHandles,'Tag'),'legend')) = [];% gotta strip out legends
    matAxesHandles(strcmpi(get(matAxesHandles,'Tag'),'Colorbar')) = [];% gotta strip out Colorbars
    nAxes = numel(matAxesHandles);
    
    if nAxes >= iMax
        if any(strcmpi(varargin,'gcf2pdf'))
            figure(h)
            gcf2pdf('Y:\Data\Users\Prisca\endocytome\results\univariate_partial_pennetrance_adjusted_hill_fit\auto_find_interesting_gene_assay_sets')
            close(h)
        end
        drawnow
        h=figure();
        nAxes = numel(findall(h,'type','axes'));
    end
    i = nAxes + 1;
    s = getSubPlotDimensions(min(n,iMax));
    subplot(s(1),s(2),i,'parent',h)
end