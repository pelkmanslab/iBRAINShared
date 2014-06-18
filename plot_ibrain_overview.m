% function plot_ibrain_overview(strRootPath)

%     if nargin == 0
        strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Code\iBRAIN\logs';
%         strRootPath = '/hreidar/extern/bio3/Data/Code/iBRAIN/logs/';
%     end

    boolOverviewMatFileExists=fileattrib(fullfile(strRootPath,'overview.mat'));
    if boolOverviewMatFileExists
        load(fullfile(strRootPath,'overview.mat'))
    else
        matTimestamps = [];
        matALL = [];
        matPENDING = [];
        matRUNNING = [];
        matNEW = [];

        structJOBCOUNTS = struct();
        structJOBCOUNTTIMESTAMPS = struct();    

        matTOTAL=[];
        matUSED=[];
        matFREE=[];
    end

    logfilelist = dirc(strRootPath,'f');
    
    for fileindex = find(strcmp(logfilelist(:,3),'log'))'
        
%         disp(['20',char(logfilelist{fileindex,1})])
        
        if isempty(matTimestamps) || (datenum(['20',char(logfilelist{fileindex,1})], 'yyyymmddHHMMSS') >= max(matTimestamps)) 

            fid = fopen(fullfile(strRootPath,logfilelist{fileindex,1}));
            C = textscan(fid, '%s','BufSize',1000000);

            if size(C{1,1},1) > 17 && not(isempty(find(strcmp(C{1,1},'STATISTICS'),1)))

                % cluster usage data
                strDATE='';
                strTIME='';
                intALL=[];
                intRUNNING=[];
                intPENDING=[];
                intNEW=NaN;

                % disk usage data
                intTOTAL=NaN;
                strTOTAL_UNITS='';
                intUSED=NaN;
                strUSED_UNITS='';
                intFREE=NaN;
                strFREE_UNITS='';

                for line = size(C{1,1},1)-17:size(C{1,1},1)
                    strWord = char(C{1,1}(line,:));
                    if length(strWord) == 6 & size(str2num(strWord)) == [1,1]
                        strDATE = ['20',strWord];
                    elseif not(isempty(strfind(strWord, ':'))) & size(strWord) == [1,8]
                        strTIME = strrep(strWord,':','');
                    elseif not(isempty(strfind(strWord,'ALL=')))
                        intALL = sscanf(strWord, 'ALL=%d');
                    elseif not(isempty(strfind(strWord,'RUNNING=')))        
                        intRUNNING = sscanf(strWord, 'RUNNING=%d');
                    elseif not(isempty(strfind(strWord,'PENDING=')))        
                        intPENDING = sscanf(strWord, 'PENDING=%d');
                    elseif not(isempty(strfind(strWord,'NEW=')))        
                        intNEW = sscanf(strWord, 'NEW=%d');
                    elseif not(isempty(strfind(strWord,'TOTAL=')))        
                        intTOTAL = sscanf(strWord, 'TOTAL=%s[GT]');
                        intTOTAL = str2num(intTOTAL(1,1:end-1));                    
                        strTOTAL_UNITS = strWord(1,end);
                    elseif not(isempty(strfind(strWord,'USED=')))        
                        intUSED = sscanf(strWord, 'USED=%s[GT]');
                        intUSED = str2num(intUSED(1,1:end-1));               
                        strUSED_UNITS = strWord(1,end);
                    elseif not(isempty(strfind(strWord,'FREE=')))        
                        intFREE = sscanf(strWord, 'FREE=%s[GT]');  
                        intFREE = str2num(intFREE(1,1:end-1));
                        strFREE_UNITS = strWord(1,end);
                    end 
                end

                % if we have a valid timestamp, and it is newer data then already present, add data to overview
                if not(isempty(strDATE)) && not(isempty(strTIME)) 
                    
                    [strDATE,strTIME]
                    
                    if strcmp(strTOTAL_UNITS,'T');intTOTAL = intTOTAL * 1024;end
                    if strcmp(strUSED_UNITS,'T');intUSED = intUSED * 1024;end
                    if strcmp(strFREE_UNITS,'T');intFREE = intFREE * 1024;end                    
                    
                    matTimestamps(1,end+1) = datenum([strDATE,strTIME], 'yyyymmddHHMMSS');
                    matALL(1,end+1) = intALL;
                    matPENDING(1,end+1) = intPENDING;
                    matRUNNING(1,end+1) = intRUNNING;
                    matNEW(1,end+1) = intNEW;

                    matTOTAL(1,end+1) = intTOTAL;
                    matUSED(1,end+1) = intUSED;
                    matFREE(1,end+1) =  intFREE;


                    %%% EXTRACT PROJECT SPECIFIC JOBCOUNTS
                    matJOBCOUNTindices = find(~cellfun('isempty',strfind(C{1,1},'JOBCOUNT')));
                    for lineindex = matJOBCOUNTindices'
                        strWord = char(C{1,1}(lineindex,:));
                        [strJOBNAME, strJOBCOUNT] = strtok(strrep(strWord,'JOBCOUNT=',''), '=');
                        intJOBCOUNT = str2double(strrep(strJOBCOUNT,'=',''));

                        if intJOBCOUNT <= 0; intJOBCOUNT = NaN; end

                        %%% fieldnames can not begin with numbers!
                        if isnumeric(str2num(strJOBNAME(1,1))) && not(isempty(str2num(strJOBNAME(1,1))))
                           strJOBNAME = strcat('project_',strJOBNAME);
                        end
                        %%% fieldnames should not contain a -
                        strJOBNAME = strrep(strJOBNAME,'-','_');

                        if isfield(structJOBCOUNTS, strJOBNAME)
                            structJOBCOUNTS.(strJOBNAME) = [structJOBCOUNTS.(strJOBNAME), intJOBCOUNT];
                            structJOBCOUNTTIMESTAMPS.(strJOBNAME) = [structJOBCOUNTTIMESTAMPS.(strJOBNAME), datenum([strDATE,strTIME], 'yyyymmddHHMMSS')];
                        else
                            structJOBCOUNTS.(strJOBNAME) = intJOBCOUNT;
                            structJOBCOUNTTIMESTAMPS.(strJOBNAME) = datenum([strDATE,strTIME], 'yyyymmddHHMMSS');
                        end
                    end         
                end    

            end        

            fclose(fid);
        
        end

    end

%     return
    
    matTIMEDIFF = diff(matTimestamps); % get time differences between logfiles
%     intDISPLAYLIMIT = median(matTIMEDIFF) + iqr(matTIMEDIFF); % get the upper outlier threshold for time differences
%     matTIMEDIFF(find(matTIMEDIFF < intDISPLAYLIMIT)) = NaN; % don't display timedifferences below threshold
%     matTIMEDIFF(find(matTIMEDIFF >= intDISPLAYLIMIT)) = 1; % display straight line at 1 when timediff exceeds threshold

    clf
    subplot(6,1,[1 2])

    hold on    
    plot(matTimestamps,matPENDING,'-b','LineWidth',2)
    title(['iBRAIN: Hreidar and NAS usage statistics on ',datestr(now,0)]);        
    a1 = gca;
    legend(['Total pending jobs (',num2str(matPENDING(end)),')'],'Location','NorthWest')
%     ylabel('total pending jobs','Color','k','FontSize',8)
    cellstrXTicks = datestr(get(a1,'XTick'),1);
    set(a1,'XTickLabel',cellstrXTicks,'YAxisLocation','right','FontSize',6, 'XMinorTick','on');
    hold off

    subplot(6,1,[5])
    hold on    
    plot(matTimestamps,matRUNNING,'-g','LineWidth',2)
    a2 = gca;
    set(a2,'YLim',[0,max(matRUNNING)+5])
    legend(['Total running jobs (',num2str(matRUNNING(end)),')'],'Location','NorthWest')
%     ylabel('total running jobs','Color','k','FontSize',8)
    cellstrXTicks = datestr(get(a1,'XTick'),1);
    set(a2,'XTickLabel',cellstrXTicks,'YAxisLocation','right','FontSize',6, 'XMinorTick','on');
%     hline(median(matRUNNING(:)),'--r','median')
    
    YSmooth = malowess(matTimestamps, matRUNNING,'Order',2,'Robust','true');
    plot(matTimestamps,YSmooth,':','LineWidth',1,'Color',[0 .4 0])
    
    hold off    
    
%     subplot(6,1,6)    
%     hold on
%     plot(matTimestamps,[0,matTIMEDIFF],'-','LineWidth',1)
%     a3 = gca;
%     legend('Log-file continuity','Location','NorthWest')
%     cellstrXTicks = datestr(get(a3,'XTick'),1);
%     set(a3,'XTickLabel',cellstrXTicks,'YAxisLocation','right','FontSize',6);
%     hold off      
        
    cellstrColors = {'y','m','c','r','g','b','w','k','y','m','c','r','g','b','w','k','y','m','c','r','g','b','w','k'};
    cellstrColors = repmat(cellstrColors,1,15);
    projects = fieldnames(structJOBCOUNTS);
    subplot(6,1,[3 4])        
    a = [];
    hold on    
    for projectindx = 1:size(projects,1)
        plot(structJOBCOUNTTIMESTAMPS.(char(projects(projectindx))),structJOBCOUNTS.(char(projects(projectindx))),'-','LineWidth',2,'Color',cellstrColors{projectindx})
        a(projectindx) = gca;
        if projectindx == 1
            set(a(projectindx),'XLim',get(a1,'XLim'))
            cellstrXTicks = datestr(get(a1,'XTick'),1);
            set(a(1),'XTickLabel',cellstrXTicks,'Color','w','YAxisLocation','right','FontSize',6, 'XMinorTick','on');            
        else
            set(a(projectindx),'Color','w','Position',get(a(1),'Position'),'FontSize',6)            
        end
    end
    legend(strrep(projects,'_','\_'),'Location','NorthWest','FontSize',5)
%     ylabel('jobs per project','Color','k','FontSize',8)
    hold off

    subplot(6,1,6)    
    hold on
    plot(matTimestamps,matTOTAL,'-b');
    plot(matTimestamps,matFREE,'-g');
    plot(matTimestamps,matUSED,'-r');
    a3 = gca;
    legend({sprintf('Total (%.1fT)',(matTOTAL(end)/1024)),sprintf('Free (%.0fG)',(matFREE(end))),sprintf('Total (%.1fT)',(matUSED(end)/1024))},'Location','NorthWest')
%     ylabel('response time','Color','k','FontSize',8)    
    cellstrXTicks = datestr(get(a3,'XTick'),1);
    set(a3,'XTickLabel',cellstrXTicks,'YAxisLocation','right','FontSize',6, 'XMinorTick','on');
    hold off       
    
    drawnow

    
    
    % scrsz = get(0, 'ScreenSize');
    scrsz = [1,1,1920,1200];
    
     set(gcf, 'Position', [1 scrsz(4) scrsz(3) scrsz(4)]);     
     orient landscape
     shading interp
     set(gcf,'PaperPositionMode','auto', 'PaperOrientation','landscape')
     set(gcf, 'PaperUnits', 'inches'); 
     printposition = [-.6 0.2 scrsz(3)/160 scrsz(4)/160];
     set(gcf,'PaperPosition', printposition)
     set(gcf, 'PaperType', 'A4');            

    % print(gcf,'-dbmp','-r300',fullfile(strRootPath,'overview_bmp'));
    % print(gcf,'-dpng','-r600',fullfile(strRootPath,'overview_png'));    
    % print(gcf,'-depsc','-r600',fullfile(strRootPath,'overview_epsc'));
    % print(gcf,'-depsc2','-r600',fullfile(strRootPath,'overview_epsc2'));
    % print(gcf,'-djpeg','-r600',fullfile(strRootPath,'overview_jpeg'));
    % print(gcf,'-dtiff','-r600',fullfile(strRootPath,'overview_tiff'));
    % print(gcf,'-dbmp16m','-r600',fullfile(strRootPath,'overview_bmp16m'));
    
    
    print(gcf,'-dpdf',fullfile(strRootPath,'overview'));
    close(gcf)

    save(fullfile(strRootPath,'overview'),'structJOBCOUNTS', 'structJOBCOUNTTIMESTAMPS','matTimestamps','matALL','matNEW','matPENDING','matRUNNING','matTOTAL','matUSED','matFREE')

% end