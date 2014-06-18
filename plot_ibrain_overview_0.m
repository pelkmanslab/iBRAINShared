% function plot_ibrain_overview(strRootPath)

    if nargin == 0
        % strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\iBRAIN\logs';
        % strRootPath = '/Users/berendsnijder/Desktop/logs';
        strRootPath = '/mnt/nas/Data/iBRAIN/logs/';
    end

    logfilelist = dirc(strRootPath,'f');

    matTimestamps = [];
    matALL = [];
    matPENDING = [];
    matRUNNING = [];
    matNEW = [];

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
            end
        end    
        fclose(fid);
    end

    
    matTIMEDIFF = diff(matTimestamps); % get time differences between logfiles
%     intDISPLAYLIMIT = median(matTIMEDIFF) + iqr(matTIMEDIFF); % get the upper outlier threshold for time differences
%     matTIMEDIFF(find(matTIMEDIFF < intDISPLAYLIMIT)) = NaN; % don't display timedifferences below threshold
%     matTIMEDIFF(find(matTIMEDIFF >= intDISPLAYLIMIT)) = 1; % display straight line at 1 when timediff exceeds threshold

    clf
    subplot(5,1,[1 2 3])

    hold on    
    plot(matTimestamps,matPENDING,'-b','LineWidth',2)
    title(['iBRAIN: Hreidar usage statistics on ',datestr(now,0)]);        
    a1 = gca;
    set(a1,'YColor','b')
    legend('Pending jobs','Location','West')
    ylabel('number of pending jobs','Color','k')

    a2 = axes('Position',get(a1,'Position'));
    plot(matTimestamps,matRUNNING,'-g','LineWidth',1,'Color',[0 .8 0])
    legend('Running jobs','Location','NorthWest')
    set(a2,'Color','none','YAxisLocation','right','XTick',[],'XTickLabel',[],'YLim',[0,max(matRUNNING)+5],'YColor',[0 .8 0])
    ylabel('number of running jobs','Color','k')

%     a3 = axes('Position',get(a1,'Position'));
%     plot(matTimestamps,[0,matTIMEDIFF],'-','LineWidth',1,'Color',[1 .5 .5])
%     legend('Log-file continuity','Location','West')
%     set(a3,'Color','none','YTick',[],'XTick',[])

    cellstrXTicks = datestr(get(a1,'XTick'),1);
    set(a1,'XTickLabel',cellstrXTicks);
    hold off

    subplot(5,1,4)    
    hold on
    plot(matTimestamps,[0,matTIMEDIFF],'-','LineWidth',1)
    a3 = gca;
    legend('Log-file continuity','Location','NorthWest')
    cellstrXTicks = datestr(get(a3,'XTick'),1);
    set(a3,'XTickLabel',cellstrXTicks);
    hold off      
    
    subplot(5,1,5)    
    hold on
    plot(matTimestamps,[0,matTIMEDIFF],'-','LineWidth',1,'Color',[1 .5 .5])
    a3 = gca;
    legend('Log-file continuity','Location','NorthWest')
    cellstrXTicks = datestr(get(a3,'XTick'),1);
    set(a3,'XTickLabel',cellstrXTicks);
    hold off    
    
    
    
    
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

    print(gcf,'-dbmp',fullfile(strRootPath,'overview.bmp'));

    

% end
