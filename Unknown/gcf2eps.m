function strPrintName = gcf2eps(strRootPath,strFigureName)

    strPrintName = '';
    
    if nargin == 0
        if ispc
            strRootPath = 'C:\Documents and Settings\imsb\Desktop\';
        else
            strRootPath = '/Volumes/share-2-$/Data/Users/Herbert/';
        end
        strFigureName = 'CurrentFigure2PDF_';
    elseif nargin == 1
        strFigureName = 'CurrentFigure2PDF';
    end
    
    try
        fileattrib(strRootPath);
    catch
        error('%s is not a valid path',strRootPath)
    end

    figure(gcf)

    % prepare for pdf printing
    scrsz = [1,1,1920,1200];
    set(gcf, 'Position', [1 scrsz(4) scrsz(3) scrsz(4)]);     
    orient landscape
    shading interp
    set(gcf,'PaperPositionMode','auto', 'PaperOrientation','landscape')
    set(gcf, 'PaperUnits', 'normalized'); 
    printposition = [0 .2 1 .8];
    set(gcf,'PaperPosition', printposition)
    set(gcf, 'PaperType', 'a4');            
    orient landscape

    drawnow

    filecounter = 1;
    strPrintName = fullfile(strRootPath,[strFigureName,getlastdir(strRootPath),'_',num2str(filecounter),'.eps']);
    filepresentbool = fileattrib(fullfile(strRootPath,[strFigureName,getlastdir(strRootPath),'_',num2str(filecounter),'.eps']));
    while filepresentbool
        filecounter = filecounter + 1;    
        strPrintName = fullfile(strRootPath,[strFigureName,getlastdir(strRootPath),'_',num2str(filecounter),'.eps']);
        filepresentbool = fileattrib(strPrintName);
    end
    disp(sprintf('stored %s',strPrintName))
    print(gcf,'-depsc',strPrintName);
%     close(gcf)
    
end