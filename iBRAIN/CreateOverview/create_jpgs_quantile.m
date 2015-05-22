function create_jpgs(strTiffPath, strOutputPath)
    matChannelIntensities = [];

    if nargin == 0
        strTiffPath = 'D:\091027_Eva_Laurdan_3\TIFF\';
        strOutputPath = 'D:\091027_Eva_Laurdan_3\JPG\';        
       
        
%         strOutputPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\50K_final\EV1_KY\070123_EV1_50K_KY_P1_1_1\JPG\';        
        strTiffPath = npc(strTiffPath);
        strOutputPath = npc(strOutputPath);    
        
    elseif nargin == 1
        strOutputPath = strrep(strTiffPath,'TIFF','JPG');
    end


    
    disp(sprintf('%s:  analyzing %s',mfilename,strTiffPath));
    dircoutput = dirc(strTiffPath,'f');

    cellFileNames = cell(1,4);
    cellAllFileNames = {};
    matChannelAndPositionData = [];
    for i = 1:size(dircoutput,1)
        if strcmpi(dircoutput{i,3},'tif') || strcmpi(dircoutput{i,3},'png')
            try
                intChannelNumber = check_image_channel(char(dircoutput{i,1}));
                intPositionNumber = check_image_position(char(dircoutput{i,1}));
                if intChannelNumber > 0
                    matChannelAndPositionData(i,:) = [intChannelNumber,intPositionNumber];
                    cellFileNames{intChannelNumber} = [cellFileNames{intChannelNumber}; {char(dircoutput{i,1})}];
                    cellAllFileNames = [cellAllFileNames;{char(dircoutput{i,1})}];
                end
            catch
                disp(sprintf('%s: unknown file name: %s',mfilename,char(dircoutput{i,1})))
            end
        end
    end

    strProjectName = getlastdir(strrep(strTiffPath,[filesep,'TIFF'],''));    

    [foo,strMicroscopeType] = check_image_position(cellAllFileNames{1,1});
    clear foo;
    disp(sprintf('%s:  microscope type "%s"',mfilename,strMicroscopeType));
    
    disp(sprintf('%s:  %d images per well',mfilename,max(matChannelAndPositionData(:,2))));
    disp(sprintf('\t \t \t \t channel %d present\n',unique(matChannelAndPositionData(:,1))));    


    matChannels = find(~cellfun('isempty',cellFileNames));
    intNumOfChannels = length(matChannels);
        
    for channel = find(~cellfun('isempty',cellFileNames))
        disp(sprintf('%s: sampling random images from channel %d',mfilename,channel));
        intNumberofimages = size(cellFileNames{channel},1);
        intNumOfSamplesPerChannel = (round(intNumberofimages*0.2)+1);
        
        randindices = randperm(intNumberofimages);
        
        matLowerQuantiles = NaN(1,intNumOfSamplesPerChannel);
        matUpperQuantiles = NaN(1,intNumOfSamplesPerChannel);
        
        for i = 1:intNumOfSamplesPerChannel; 
            strImageName = char(cellFileNames{channel}(randindices(i),:));
            intChannelNumber = check_image_channel(strImageName);
            disp(sprintf('%s:  %s',mfilename,strImageName))
            try
                tempImage = single(imread(fullfile(strTiffPath,strImageName)));
            catch
                warning('matlab:bsBla','%s:  failed to load image %s',mfilename,strImageName)
            end

            % get average lower and upper 5% quantiles per sampled image
            matLowerQuantiles(1,i) = quantile(tempImage(:),0.05);
            matUpperQuantiles(1,i) = quantile(tempImage(:),0.99);
        end

        % make medians of those quantiles the new lower and upper bounds
        matChannelIntensities(channel,:) = [nanmedian(matLowerQuantiles), nanmedian(matUpperQuantiles)];
    end
    

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% START MERGE AND STITCH AND JPG CONVERSION %%%
    
    rowstodo = 1:16;
    colstodo = 1:24;
    
    matRows = cellstr(regexp(char(65:80),'\w','match'));
    matCols = regexp(sprintf('%.2d',1:24),'\d\d','match');
    
    matPlateImagesPerWell = zeros(16,24);

    matImageSize = size(tempImage)/2;
   
    [matImageSnake,matStitchDimensions] = get_image_snake(max(matChannelAndPositionData(:,2)), strMicroscopeType);

    matChannelOrder = [3,2,1,1]; % BLUE, RED, RED, RED
%     matChannelOrder = [3,2,1,1]; % BLUE, GREEN, RED, RED
    
    disp(sprintf('%s: start saving JPG''s in %s',mfilename,strOutputPath));        
    for rowNum = rowstodo
        for colNum = colstodo

            %%% CHECK IF THERE ARE ANY MATCHING IMAGES FOR THIS WELL...
            str2match = strcat('_',matRows(rowNum), matCols(colNum));
            FileNameMatches = strfind(cellAllFileNames, char(str2match));
            matAllFileNameMatchIndices = find(~cellfun('isempty',FileNameMatches));
            
            if not(isempty(matAllFileNameMatchIndices))    
                intIncludedImages = 0;
                Overlay = zeros(round(matImageSize(1,1)*matStitchDimensions(1)),round(matImageSize(1,2)*matStitchDimensions(2)),3, 'single');                
                for intChannel = matChannels
                    cellFileNames2 = cellstr(cellFileNames{1,intChannel});
                    str2match = strcat('_',matRows(rowNum), matCols(colNum));
                    FileNameMatches = strfind(cellFileNames2, char(str2match));
                    matFileNameMatchIndices = find(~cellfun('isempty',FileNameMatches));
                    Patch = zeros(round(matImageSize(1,1)*matStitchDimensions(1)),round(matImageSize(1,2)*matStitchDimensions(2)), 'single');                
                    for k = matFileNameMatchIndices'
                        strImageName = cellFileNames2{k};
                        strImagePosition = check_image_position(strImageName);
                        xPos=(matImageSnake(1,strImagePosition)*matImageSize(1,2))+1:((matImageSnake(1,strImagePosition)+1)*matImageSize(1,2));
                        yPos=(matImageSnake(2,strImagePosition)*matImageSize(1,1))+1:((matImageSnake(2,strImagePosition)+1)*matImageSize(1,1));
                        try
                            matImage = imresize(imread(fullfile(strTiffPath,strImageName)),.5);
                            intIncludedImages = intIncludedImages + 1; % keep track if we included any images
                        catch caughtError
                            caughtError.identifier
                            caughtError.message
                            warning('matlab:bsBla','%s: failed to load image ''%s''',mfilename,fullfile(strTiffPath,strImageName));
                            matImage = zeros(matImageSize);
                        end
                        Patch(yPos,xPos) = (matImage - matChannelIntensities(intChannel,1)) * (2^16/(matChannelIntensities(intChannel,2)-matChannelIntensities(intChannel,1)));
                    end
                    Patch(Patch<0) = 0;
                    Patch(Patch>2^16) = 2^16;                
                    Overlay(:,:,matChannelOrder(intChannel)) = Patch/2^16;
                end
                strfilename = [strProjectName,char(str2match),'_RGB.jpg'];
%                 if length(unique(Overlay(:))) > 1
                if intIncludedImages > 0
                    
                    disp(sprintf('%s:  storing %s',mfilename,strfilename))                
                    imwrite(Overlay,fullfile(strOutputPath,strfilename),'jpg','Quality',90);
                else
                    disp(sprintf('%s:s  NOT storing %s',mfilename,strfilename))                
                end
                drawnow
            
            end
        end
    end      
