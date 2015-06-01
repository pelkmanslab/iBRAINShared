function plot_plate_overview(strRootPath, strOutputPath, handles, strFileNameBegin)

    warning off all
    
    figure
    clf
    
%     set(gcf,'Renderer','zbuffer')
    
    if nargin == 0
        strRootPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\VV_rescreen\082412_dharmacon_vv_opti\BATCH\';
    end    
    
    if nargin <= 1
        strOutputPath = strRootPath;
    end

    if nargin < 3 || ~isstruct(handles)
        handles = struct();
        handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_FileNames.mat']);
        handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_ObjectCount.mat']);

        boolINFECTIONData = 1;           
        try
            handles = LoadMeasurements(handles, [strRootPath,'Measurements_Nuclei_VirusScreen_ClassicalInfection_Overview2.mat']);        
        catch
            boolINFECTIONData = 0;
        end

        boolOOFData = 1;        
        try
            handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_OutOfFocus.mat']);
        catch
            boolOOFData = 0;            
        end
            
        try
            handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_RescaledBlueSpectrum.mat']);    
        catch
            try
                handles = LoadMeasurements(handles, [strRootPath,'Measurements_Image_OrigBlueSpectrum.mat']);                
            catch
                boolOOFData = 0;
            end
        end
    end
    
%     [matTotal, matInfected, matImagesPerWell, cellstrGenePerWell, matOligonumber, matPlatenumber, matReplicanumber, matBatchnumber, matCtrlInfectionIndices, matWellRow, matWellCol, matNoVirusCtrlInfectionIndices] = ConvertHandlesTo384DG(strRootPath, handles);
    [matTotal, matInfected, matImagesPerWell, cellstrGenePerWell, matOligonumber, matPlatenumber, matReplicanumber, matBatchnumber, matCtrlInfectionIndices, matWellRow, matWellCol, matNoVirusCtrlInfectionIndices, cellstrGeneID, matCtrlCellNumbers, matRawImagesPerWell] = ConvertHandlesTo384DG(strRootPath);
    
    matInfected(find(matImagesPerWell == 0)) = NaN;
    matTotal(find(matTotal == 0)) = NaN;

    intPlateNumber = unique(matPlatenumber(find(~isnan(matPlatenumber))));
    intBatchnumber = unique(matBatchnumber(find(~isnan(matBatchnumber))));
    intReplicanumber = unique(matReplicanumber(find(~isnan(matReplicanumber))));
    
    if not(isnumeric(intPlateNumber)) || isempty(intPlateNumber) || intPlateNumber < 0; intPlateNumber = 0; end
    if not(isnumeric(intBatchnumber)) || isempty(intBatchnumber) || intBatchnumber < 0; intBatchnumber = 0; end
    if not(isnumeric(intReplicanumber)) || isempty(intReplicanumber) || intReplicanumber < 0; intReplicanumber = 0; end    

    intPctOOF = (1-sum(matImagesPerWell(:)) / sum(matRawImagesPerWell(:)))*100;

%     map=[ [sqrt(linspace(1,0,32)'),zeros(32,1),zeros(32,1)] ; [zeros(32,1),sqrt(linspace(0,1,32)'),zeros(32,1)]];    
    map=[ [linspace(1,0,32)',zeros(32,1),zeros(32,1)] ;[zeros(32,1),(linspace(0,1,32)'),zeros(32,1)]];
    colormap(map)    
 
    cellstrFigureTitle = sprintf('%s   -  CP%03.0f-%1d  -  batch %d  -  OOF %.0f%%  -  ii %.2f  -  cells %.0f',strrep(strRootPath,'_','\_'),intPlateNumber,intReplicanumber,intBatchnumber,intPctOOF,nanmedian(matCtrlInfectionIndices),nanmedian(matTotal));
    
    %%%%%%%%%%%%%%%%%
    %%% PLOT DATA %%%    
    
    matPlateLog2RII = log2((reshape(matInfected,24,16) ./ reshape(matTotal,24,16))/nanmedian(matCtrlInfectionIndices))';
    matPlateTotalCells = reshape(matTotal,24,16)';
    matPlateLog2RCN = log2( ( reshape(matTotal,24,16)' / nanmedian(matTotal) ) );    
    matPlateII = (reshape(matInfected,24,16) ./ reshape(matTotal,24,16))';      
    
    
    
    subplot(3,3,[1])
    imagesc(matPlateII)
    a(1) = gca;    
    title('plate: infection index','FontSize',8,'FontName','Arial','FontWeight','bold')
  
    
    subplot(3,3,[2])
    imagesc(matPlateLog2RII)
    a(2) = gca;    
    title('plate: log2 relative infection index','FontSize',8,'FontName','Arial','FontWeight','bold')    

    subplot(3,3,[3])
    imagesc(matPlateTotalCells)
    a(3) = gca;    
    title('plate: total cells','FontSize',8,'FontName','Arial','FontWeight','bold')    
    
    subplot(3,4,9)
    hold on
    hist(matInfected ./ matTotal,50)
    h = findobj(gca,'Type','patch');
    set(h,'FaceColor',[.7 .7 1],'EdgeColor','w')
    set(gca,'FontSize',6)    
    vline(nanmedian(matCtrlInfectionIndices),'k',['median of RNAi wells']);
    title(sprintf('infection index per well  (%.3f)',nanmedian(matCtrlInfectionIndices)),'FontSize',8,'FontName','Arial')     
    hold off
    
    intMedianLog2riiNoVirusCtrls = nanmedian(log2(matNoVirusCtrlInfectionIndices/nanmedian(matCtrlInfectionIndices)));
    
    subplot(3,4,10)
    hold on
    hist(matPlateLog2RII(find(~isinf(matPlateLog2RII) & ~isnan(matPlateLog2RII))),50,'FontSize',6)
    h = findobj(gca,'Type','patch');
    set(h,'FaceColor',[.7 .7 1],'EdgeColor','w')    
    set(gca,'FontSize',6)    
    vline(intMedianLog2riiNoVirusCtrls,'k', 'no virus ctrl');
    title(sprintf('log2rii per well'),'FontSize',8,'FontName','Arial')
    hold off
    
    subplot(3,4,11)
    hold on
    hist(matTotal,50)
    h = findobj(gca,'Type','patch');
    set(h,'FaceColor',[.7 .7 1],'EdgeColor','w') 
    set(gca,'FontSize',6)
    vline(nanmedian(matTotal),'k',['median']);
    title(sprintf('plate: total cells per well  (%.0f)',nanmedian(matTotal)),'FontSize',8,'FontName','Arial')         
    hold off
    
    subplot(3,4,12)
    hold on
    scatter(matPlateLog2RCN(find(~isinf(matPlateLog2RII) & ~isnan(matPlateLog2RII))),matPlateLog2RII(find(~isinf(matPlateLog2RII) & ~isnan(matPlateLog2RII))),'.r')
    set(gca,'FontSize',6)
    title(sprintf('log2(rii):log2(rcn)',nanmedian(matTotal)),'FontSize',8,'FontName','Arial')         
    hold off    


    subplot(3,3,4)    

    
% check which objects are present
    if isfield(handles.Measurements,'Nuclei')
        strObjectName = 'Nuclei';
    elseif isfield(handles.Measurements,'Cells')
        strObjectName = 'Cells';
    elseif isfield(handles.Measurements,'OrigNuclei')
        strObjectName = 'OrigNuclei';        
    else
        % otherwise, use the first object detected in the pipeline
        strObjectName = handles.Measurements.Image.ObjectCountFeatures{1,1};        
    end

    intObjectCountColumn = find(strcmp(handles.Measurements.Image.ObjectCountFeatures,strObjectName));
    
    % test if there is objectcount data for this object, if not, do looser
    % matching with strfind...
    if isempty(intObjectCountColumn)
        disp(sprintf('WARNING: couldn''t find exact ObjectCount data math for %s... looking for more loose matches',strObjectName))
        intObjectCountColumn = find(~cellfun(@isempty,strfind(handles.Measurements.Image.ObjectCountFeatures,strObjectName)));
        
        % report findings
        if ~isempty(intObjectCountColumn)
            disp(sprintf('   found looser match for object %s',handles.Measurements.Image.ObjectCountFeatures{intObjectCountColumn}))        
        else
            error('   DON''T KNOW WHICH OBJECT TO USE AS PRIMARY OBJECT!!! ABORTING')                
        end
        
    end

    
    
    matImageObjectCount = cell2mat(handles.Measurements.Image.ObjectCount');     
    matImageObjectCount = matImageObjectCount(:,intObjectCountColumn);
    
    if boolOOFData
        %%% LOOK FOR CORRECT SPECTRUM DATA FIELD
        cellstrtemp = fieldnames(handles.Measurements.Image);
        rescaledindx = find(~cellfun('isempty',strfind(cellstrtemp,'SpectrumFeatures')));
        cellstrtemp = cellstrtemp{rescaledindx',1};
        strRescaledBlueSpectrum = char(strrep(cellstrtemp,'Features',''));

        matImageGrans = cell2mat(handles.Measurements.Image.(strRescaledBlueSpectrum)');
        matImageGrans = max(matImageGrans');

        colormatrix = zeros(length(handles.Measurements.Image.OutOfFocus),3);
        colormatrix(:,3) = 1;
        colormatrix(handles.Measurements.Image.OutOfFocus == 1,1) = 1;
        colormatrix(handles.Measurements.Image.OutOfFocus == 1,3) = 0;

        hold on        
        scatter(matImageObjectCount,matImageGrans,'.b');
        xlabel('total cells per image','FontSize',6)
        ylabel('max image granularity per image','FontSize',6)
        title('out of focus detection','FontSize',8,'FontName','Arial')
        set(gca, 'FontSize',6, 'YLim', [0 50], 'XLim',[0 3000]);
        line([0 1700 1700 2500 2500 3000],[18 18 16 16 15 15],'LineStyle','-','Color','r')
        hold off   
        drawnow   
    end
    
    
    subplot(3,3,5)
    imagesc(reshape(matImagesPerWell,24,16)')
    a(4) = gca;    
    title(sprintf('images per well  (%.0f%% OOF)',intPctOOF),'FontSize',8,'FontWeight','bold','FontName','Arial')    
    
   
    
    try
        [Zscore, MAD, Bscore, SmoothBscore, correctionfactor, smoothedcorrectionfactor] = bscore2(matPlateLog2RII(:,3:22));

        subplot(3,3,6)
        imagesc(correctionfactor)
        a(5) = gca;    
        set(a(5),'XTickLabel',(get(a(5),'XTick')+2))
        title('plate effects: b-score correction (log2rii)','FontSize',8,'FontName','Arial')
    catch
        subplot(3,3,6)
        a(5) = gca;
        disp(sprintf('%s: failed to do bscore2',mfilename))
    end
    
%     subplot(3,4,12)
%     imagesc(smoothedcorrectionfactor)
%     a(6) = gca;    
%     set(a(6),'XTickLabel',(get(a(6),'XTick')+2))
%     title('smoothed b-score correction factor log2rii','FontSize',8,'FontName','Arial')    

    drawnow 

    
    %%%%%%%%%%%%%%%%%
    %%% PRINT PDF %%%
    
    scrsz = [1,1,1920,1200];
    
    set(gcf, 'Position', [1 scrsz(4) scrsz(3) scrsz(4)]);     
    %             rect = [left, bottom, width, height]
    
    orient landscape
    shading interp
    set(gcf,'PaperPositionMode','auto', 'PaperOrientation','landscape')
    set(gcf, 'PaperUnits', 'normalized'); 
    printposition = [0 .2 1 .8];
    set(gcf,'PaperPosition', printposition)
    set(gcf, 'PaperType', 'a4');            
    orient landscape

    drawnow
    
    for i = 1:5
        set(a(i),'YTick',[2,4,6,8,10,12,14,16])
        set(a(i),'YTickLabel',cellstr(char((get(a(i),'YTick')+64)'))')
        set(a(i),'FontSize',6,'FontName','Arial')
        colorbar('peer',a(i),'FontSize',6)
    end    
    
%     for i = 4:5
%         set(a(i),'YTick',[2,4,6,8,10,12,14,16])        
%         set(a(i),'YTickLabel',cellstr(char((get(a(i),'YTick')+64)'))')
%         set(a(i),'FontSize',6,'FontName','Arial')
%         colorbar('peer',a(i),'FontSize',6,'Location','SouthOutside')
%     end    
    
    drawnow
    
    
    hold on
    axes('Color','none','Position',[0,0,1,.95])
    axis off
    title(cellstrFigureTitle)
    hold off
    drawnow    

    if nargin < 4
        strFileNameBegin = sprintf('CP%03.0f-%1d',intPlateNumber, intReplicanumber);
    end
    
%     try
%         print(gcf,'-dpdf',fullfile(strOutputPath,[strFileNameBegin,'_plate_overview']));
%     catch
%         subplot(3,4,[9])
%         axes()
%     end
    

%%% UNIX CLUSTER HACK, TRY PRINTING DIFFERENT PRINT FORMATS UNTIL ONE
%%% SUCCEEDS, IN ORDER OF PREFERENCE
    
    cellstrPrintFormats = {...
        '-dpdf',...
        '-depsc2',...      
        '-depsc',...      
        '-deps2',...        
        '-deps',...        
        '-dill',...
        '-dpng',...   
        '-tiff',...
        '-djpeg'};
        
    boolPrintSucces = 0;
    for i = 1:length(cellstrPrintFormats)
        if boolPrintSucces == 1
            continue
        end        
        try
            print(gcf,cellstrPrintFormats{i},fullfile(strOutputPath,[strFileNameBegin,'_plate_overview']));    
            disp(sprintf('PRINTED %s FILE',cellstrPrintFormats{i}))        
            boolPrintSucces = 1;
        catch
            disp(sprintf('FAILED TO PRINT %s FILE',cellstrPrintFormats{i}))
            boolPrintSucces = 0;            
        end
    end
    close(gcf)        



    