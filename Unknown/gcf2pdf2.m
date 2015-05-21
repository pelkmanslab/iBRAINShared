function strPrintName = gcf2pdf2(strFigureName)

    strPrintName = '';
    
    if nargin == 0
        strFigureName = 'CurrentFigure2PDF_';
    elseif nargin == 1
        strFigureName = 'CurrentFigure2PDF';
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
    strPrintName = [strFigureName,'_',num2str(filecounter),'.pdf'];
    filepresentbool = fileattrib([strFigureName,'_',num2str(filecounter),'.pdf']);
    while filepresentbool
        filecounter = filecounter + 1;    
        strPrintName = [strFigureName,'_',num2str(filecounter),'.pdf'];
        filepresentbool = fileattrib(strPrintName);
    end
    disp(sprintf('stored %s',strPrintName))
    print(gcf,'-dpdf',strPrintName);
%     close(gcf)
    
end