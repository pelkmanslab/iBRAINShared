function gcf2pdfall(varargin)
    openFigures=findobj(allchild(0),'flat','Visible','on')';
    % go over each figure in reverse order (i.e. oldest first)
    for ii = fliplr(openFigures)
        figure(ii)
        gcf2pdf(varargin{:})
        close(ii)
    end
end