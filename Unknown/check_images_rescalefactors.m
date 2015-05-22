function create_jpgs(strTiffPath, strOutputPath)
    matChannelIntensities = [];

    if nargin == 0
        strTiffPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\50K_final\EV1_KY\070123_EV1_50K_KY_P1_1_1\TIFF\';
        strOutputPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\50K_final\EV1_KY\070123_EV1_50K_KY_P1_1_1\JPG\';        
    elseif nargin == 1
        strOutputPath = strrep(strTiffPath,'TIFF','JPG');
    end

    disp(sprintf('analyzing %s',strTiffPath));
    dircoutput = dirc(strTiffPath,'f');

    cellFileNames = cell(1,4);
    cellAllFileNames = {};
    matChannelAndPositionData = [];
    for i = 1:size(dircoutput,1)
        if strcmpi(dircoutput{i,3},'tif')
            intChannelNumber = check_image_channel(char(dircoutput{i,1}));
            intPositionNumber = check_image_position(char(dircoutput{i,1}));
            matChannelAndPositionData(i,:) = [intChannelNumber,intPositionNumber];
            cellFileNames{intChannelNumber} = [cellFileNames{intChannelNumber}; char(dircoutput{i,1})];
            cellAllFileNames = [cellAllFileNames;char(dircoutput{i,1})];
        end
    end

    strProjectName = getlastdir(strrep(strTiffPath,[filesep,'TIFF'],''));    

    disp(sprintf('  %d images per well',max(matChannelAndPositionData(:,2))));
    disp(sprintf('  channel %d present\n',unique(matChannelAndPositionData(:,1))));    
    
    matBins = logspace(0,log10(2^16),255);
    matBinCounts = zeros(2,length(matBins));
    
    h = figure();
    clf

    for channel = find(~cellfun('isempty',cellFileNames))
        disp(sprintf('sampling random images from channel %d',channel));
        intNumberofimages = length(cellFileNames{channel});
        randindices = randperm(intNumberofimages);
        for i = randindices(1:round(intNumberofimages*.004))
            strImageName = char(cellFileNames{channel}(i,:));
            intChannelNumber = check_image_channel(strImageName);
            disp(sprintf('  %s',strImageName))
            try
                tempImage = single(imread(fullfile(strTiffPath,strImageName)));
            catch
                warn('  failed to load image %s',strImageName)
            end
            for ii = 1:length(matBins)-1
                matBinCounts(intChannelNumber,ii) = matBinCounts(1,ii) + length(find(tempImage(:) > matBins(ii) &  tempImage(:) < matBins(ii+1)));
            end
        end

        intLowessSpanValue = 0.1;
        intLowessOrderValue = 1;
        
        % smooth the histogram to make gaussian fitting easier
        YSmooth = malowess(1:length(matBinCounts(channel,:)), matBinCounts(channel,:), 'Robust', 'true', 'span', intLowessSpanValue, 'Order',intLowessOrderValue);    

        % recreate original data (with x fold less data points) for
        % gaussian fitting
        tempData = [];
        YSmooth(YSmooth<0) = 0;
        for i = 1:length(matBins)
            tempData = [tempData;repmat(i,round(YSmooth(1,i)/1000),1)];
        end

        % do gaussian fitting
        [u,sig,t,iter,err] = fit_mix_gaussian( tempData, 2 );

        % plot original smoothed histogram and fitted gaussians
        subplot(1,2,channel);
        hold on 
        plot(1:length(YSmooth),YSmooth,'LineWidth',2,'Color','b');
        p = pdf('Normal',1:length(YSmooth),u(1),sig(1));
        plot(1:length(YSmooth),p*sum(YSmooth(:))*t(1),'Color','r','LineWidth',2);
        p = pdf('Normal',1:length(YSmooth),u(2),sig(2));        
        plot(1:length(YSmooth),p*sum(YSmooth(:))*t(2),'Color','r','LineWidth',2);
        title(['channel ',num2str(channel)]);

        %%% CHANNEL SPECIFIC THRESHOLDS
        matOrigIntensityThresholds = [];
        matSigmaDeviations = [...
            -2, +1;...
            -3, +0;...
            -2, +1;...
            ];

        matChannelIntensities(channel,:) = [matBins(1,round(u(1)+matSigmaDeviations(channel,1)*sig(1))), matBins(1,round(u(2)+matSigmaDeviations(channel,2)*sig(2)))];            
        matOrigIntensityThresholds(channel,:) = [u(1)+matSigmaDeviations(channel,1)*sig(1), u(2)+matSigmaDeviations(channel,2)*sig(2)];
        
        vline(matOrigIntensityThresholds(channel,1),'k',sprintf('%0.0d (%.0f*sigma)',round(matChannelIntensities(channel,1)),matSigmaDeviations(channel,1)));
        vline(matOrigIntensityThresholds(channel,2),'k',sprintf('%0.0d (%.1f*sigma)',round(matChannelIntensities(channel,2)),matSigmaDeviations(channel,2)));
        hold off

        drawnow

        %%% COULD ALTERNATIVELY BE DONE WITH BOXPLOT AND OUTLIER
        %%% DISCARDING... (1.5 x IQR UP AND DOWN AS THRESHOLD)
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% STORE RESCALE FACTORS %%%

    scrsz = [1,1,1920,1200];
    set(gcf, 'Position', [1 scrsz(4) scrsz(3) scrsz(4)]);     
    orient landscape
    shading interp
    set(gcf,'PaperPositionMode','auto')
    set(gcf, 'PaperUnits', 'inches'); 
    printposition = [-.6 0.2 scrsz(3)/160 scrsz(4)/160];
    set(gcf,'PaperPosition', printposition)
    set(gcf, 'PaperType', 'A4');
    drawnow
    print(gcf,'-dpdf',fullfile(strOutputPath,[strProjectName,'_rescale_settings.pdf']));  
    disp(sprintf('stored rescaling settings in %s',fullfile(strOutputPath,'rescale_settings.pdf')));    
    close(h)
    drawnow
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% START MERGE AND STITCH AND JPG CONVERSION %%%
    
    rowstodo = 2:8;
    colstodo = 2:11;
    
    matRows = cellstr(regexp(char(65:80),'\w','match'));
    matCols = regexp(sprintf('%.2d',1:24),'\d\d','match');
    
    matPlateImagesPerWell = zeros(16,24);

    matImageSize = size(tempImage)/2;
    
    if max(matChannelAndPositionData(:,2)) == 9 
        matImageSnake = [0,1,2,2,1,0,0,1,2;2,2,2,1,1,1,0,0,0];
    elseif max(matChannelAndPositionData(:,2)) == 25
        matImageSnake = [0,1,2,3,4,4,3,2,1,0,0,1,2,3,4,4,3,2,1,0,0,1,2,3,4;4,4,4,4,4,3,3,3,3,3,2,2,2,2,2,1,1,1,1,1,0,0,0,0,0];        
    end
    matChannelOrder = [3,2,1]; % BLUE, GREEN, RED
    
    disp(sprintf('start saving JPG''s in %s...',strOutputPath));        
    for rowNum = rowstodo
        for colNum = colstodo
            %'_' 'A' '01' should match well A01 depending on the
            %nomenclature of the microscope & images.

            Overlay = zeros(round(matImageSize(1,1)*3),round(matImageSize(1,2)*3),3, 'single');                
            
            for intChannel = 1:2

                cellFileNames2 = cellstr(cellFileNames{1,intChannel});
                str2match = strcat('_',matRows(rowNum), matCols(colNum));
                FileNameMatches = strfind(cellFileNames2, char(str2match));
                matFileNameMatchIndices = find(~cellfun('isempty',FileNameMatches));
            
                Patch = zeros(round(matImageSize(1,1)*3),round(matImageSize(1,2)*3), 'single');                
                    
                for k = matFileNameMatchIndices'
                    strImageName = cellFileNames2{k};
%                     strImagePosition = str2double(strrep(regexp(strImageName,[char(str2match),'f\d\d'],'Match'),[char(str2match),'f'],''))+1;
                    strImagePosition = check_image_position(strImageName);
%                     intChannelNumber = check_image_channel(char(dircoutput{i,1}));                                

                    xPos=(matImageSnake(1,strImagePosition)*matImageSize(1,2))+1:((matImageSnake(1,strImagePosition)+1)*matImageSize(1,2));
                    yPos=(matImageSnake(2,strImagePosition)*matImageSize(1,1))+1:((matImageSnake(2,strImagePosition)+1)*matImageSize(1,1));

                    matImage = imresize(imread(fullfile(strTiffPath,strImageName)),.5);
    %                     size(matImage)
    %                     length(xPos)
    %                     length(yPos)                    

                    Patch(yPos,xPos) = (matImage - matChannelIntensities(intChannel,1)) * (2^16/(matChannelIntensities(intChannel,2)-matChannelIntensities(intChannel,1)));
                end
                Patch(Patch<0) = 0;
                Patch(Patch>2^16) = 2^16;                
                Overlay(:,:,matChannelOrder(intChannel)) = Patch/2^16;
            end
            strfilename = [strProjectName,char(str2match),'_RGB.jpg'];
            disp(sprintf('  storing %s',strfilename))
            imwrite(Overlay,fullfile(strOutputPath,strfilename),'jpg','Quality',70);        
        end
    end      
