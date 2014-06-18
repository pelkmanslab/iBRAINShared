% function plot_ibrain_overview2(strRootPath)

    if nargin == 0
        strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\iBRAIN\logs';
%         strRootPath = '/Users/berendsnijder/Desktop/logs';
%         strRootPath = '/mnt/nas/Data/iBRAIN/logs/';
%         strRootPath = '/hreidar/extern/bio3/Data/iBRAIN/logs/';
    end

    logfilelist = flipud(dirc(strRootPath,'f'));

    matTimestamps = [];
    matALL = [];
    matPENDING = [];
    matRUNNING = [];
    matNEW = [];
    
    structJOBCOUNTS = struct();
    structJOBCOUNTTIMESTAMPS = struct();    
    
    for fileindex = find(strcmp(logfilelist(:,3),'log'))'
        fid = fopen(fullfile(strRootPath,logfilelist{fileindex,1}));
        C = textscan(fid, '%s','BufSize',1000000);
        
        if size(C{1,1},1) > 10 && not(isempty(find(strcmp(C{1,1},'STATISTICS'),1)))

            strDATE='';
            strTIME='';
            intALL=[];
            intRUNNING=[];
            intPENDING=[];
            intNEW=[];

            for line = size(C{1,1},1)-10:size(C{1,1},1)
                strWord = char(C{1,1}(line,:));
                if length(strWord) == 6 & size(str2num(strWord)) == [1,1]
                    strDATE = ['20',strWord];
                elseif not(isempty(strfind(strWord, ':')))
                    strTIME = strrep(strWord,':','');
                elseif not(isempty(strfind(strWord,'ALL=')))
                    intALL = sscanf(strWord, 'ALL=%d');
                elseif not(isempty(strfind(strWord,'RUNNING=')))        
                    intRUNNING = sscanf(strWord, 'RUNNING=%d');
                elseif not(isempty(strfind(strWord,'PENDING=')))        
                    intPENDING = sscanf(strWord, 'PENDING=%d');
                elseif not(isempty(strfind(strWord,'NEW=')))        
                    intNEW = sscanf(strWord, 'NEW=%d');
                end 
            end

            % if we have a valid timestamp, add data to overview
            if not(isempty(strDATE)) && not(isempty(strTIME))
                matTimestamps(1,end+1) = datenum([strDATE,strTIME], 'yyyymmddHHMMSS');
                matALL(1,end+1) = intALL;
                matPENDING(1,end+1) = intPENDING;
                matRUNNING(1,end+1) = intRUNNING;

                if not(isempty(intNEW))
                    matNEW(1,end+1) = intNEW;
                else
                    matNEW(1,end+1) = NaN;
                end
                
                %%% EXTRACT PROJECT SPECIFIC JOBCOUNTS
                matJOBCOUNTindices = find(~cellfun('isempty',strfind(C{1,1},'JOBCOUNT')));
                for lineindex = matJOBCOUNTindices'
                    strWord = char(C{1,1}(lineindex,:));
                    [strJOBNAME, strJOBCOUNT] = strtok(strrep(strWord,'JOBCOUNT=',''), '=');
                    intJOBCOUNT = str2double(strrep(strJOBCOUNT,'=',''));
                    
                    if intJOBCOUNT == 0; intJOBCOUNT = NaN; end

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

%     return
    
    matTIMEDIFF = diff(matTimestamps); % get time differences between logfiles
%     intDISPLAYLIMIT = median(matTIMEDIFF) + iqr(matTIMEDIFF); % get the upper outlier threshold for time differences
%     matTIMEDIFF(find(matTIMEDIFF < intDISPLAYLIMIT)) = NaN; % don't display timedifferences below threshold
%     matTIMEDIFF(find(matTIMEDIFF >= intDISPLAYLIMIT)) = 1; % display straight line at 1 when timediff exceeds threshold

    clf
    subplot(6,1,[1 2])

    hold on    
    plot(matTimestamps,matPENDING,'-b','LineWidth',2)
    title(['iBRAIN: Hreidar usage statistics on ',datestr(now,0)]);        
    a1 = gca;
    legend('Total pending jobs','Location','NorthWest')
%     ylabel('total pending jobs','Color','k','FontSize',8)
    cellstrXTicks = datestr(get(a1,'XTick'),1);
    set(a1,'XTickLabel',cellstrXTicks,'YAxisLocation','right');
    hold off

    subplot(6,1,[4 5])
    hold on    
    plot(matTimestamps,matRUNNING,'-g','LineWidth',2)
    a2 = gca;
    set(a2,'YLim',[0,max(matRUNNING)+5])
    legend('Total running jobs','Location','NorthWest')
%     ylabel('total running jobs','Color','k','FontSize',8)
    cellstrXTicks = datestr(get(a1,'XTick'),1);
    set(a2,'XTickLabel',cellstrXTicks,'YAxisLocation','right');
    hline(median(matRUNNING(:)),'g','median')
    hold off    
    
    subplot(6,1,6)    
    hold on
    plot(matTimestamps,[0,matTIMEDIFF],'-','LineWidth',1)
    a3 = gca;
    legend('Log-file continuity','Location','NorthWest')
%     ylabel('response time','Color','k','FontSize',8)    
    cellstrXTicks = datestr(get(a3,'XTick'),1);
    set(a3,'XTickLabel',cellstrXTicks,'YAxisLocation','right');
    hold off      
        
    cellstrColors = {'y','m','c','r','g','b','w','k','y','m','c','r','g','b','w','k','y','m','c','r','g','b','w','k'};
    projects = fieldnames(structJOBCOUNTS);
    subplot(6,1,3)        
    a = [];
    hold on    
    for projectindx = 1:size(projects,1)
        plot(structJOBCOUNTTIMESTAMPS.(char(projects(projectindx))),structJOBCOUNTS.(char(projects(projectindx))),'-','LineWidth',2,'Color',cellstrColors{projectindx})
        a(projectindx) = gca;
        if projectindx == 1
            set(a(projectindx),'XLim',get(a1,'XLim'))
            cellstrXTicks = datestr(get(a1,'XTick'),1);
            set(a(1),'XTickLabel',cellstrXTicks,'Color','w','YAxisLocation','right');            
        else
            set(a(projectindx),'Color','w','Position',get(a(1),'Position'))            
        end
    end
    legend(strrep(projects,'_','\_'),'Location','NorthWest','FontSize',8)
%     ylabel('jobs per project','Color','k','FontSize',8)

    hold off

    drawnow

    
    
    % scrsz = get(0, 'ScreenSize');
    scrsz = [1,1,1920,1200];
    
    set(gcf, 'Position', [1 scrsz(4) scrsz(3) scrsz(4)]);     
    orient portrait
    shading interp
    set(gcf,'PaperPositionMode','auto')
    set(gcf, 'PaperUnits', 'inches'); 
    printposition = [-.6 0.2 scrsz(3)/160 scrsz(4)/160];
    set(gcf,'PaperPosition', printposition)
    set(gcf, 'PaperType', 'A4');            

%     print(gcf,'-dbmp',fullfile(strRootPath,'overview.bmp'));
    print(gcf,'-dpng',fullfile(strRootPath,'overview'));    

    

% end
