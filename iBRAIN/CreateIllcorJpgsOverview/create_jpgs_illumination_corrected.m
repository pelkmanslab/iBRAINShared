function create_jpgs_illumination_corrected(strTiffPath, strOutputPath, strSearchString, ownMIPs)

    if nargin < 4
        ownMIPs=true;
    end

    if nargin == 0
        
        strTiffPath = '/share/nas/ethz-share4/Data/Users/Yauhen/iBrainProjects/zstack/TIFF/';
        strOutputPath = '/share/nas/ethz-share4/Data/Users/Yauhen/iBrainProjects/zstack/ILLCORJPG/';
        
    elseif nargin == 1 || isempty(strOutputPath)
        strOutputPath = strrep(strTiffPath,'TIFF','ILLCORJPG');
    end

    % change paths
    strTiffPath = npc(strTiffPath);
    strOutputPath = npc(strOutputPath);
        
    %%%%%%%%%%%%%%%%
    %%% Settings %%%
    
    % how much the images shold be shrunk for JPGs
    % intShrinkFactor = 1;
    
    % what are the target dimensions of the final jpg
    matTargetImageSize = [2000 3000];
    
    % maximum number of images to sample for rescale settings
    intMaxNumImagesPerChannel = 500;
    
    % quantile values for rescale lower and upper rescale settings
    matQuantileSettings = [0.01, 0.99];
    
    % fraction of images to sample for rescaling
    intImageSampleFractionPerChannel = 1;
    
    % jpg quality (scale of 1 to 100)
    intJpgQuality = 95;
    
    % filemask (via strSearchString regexp)
    if nargin<3
        if checkIfTiffDirHasZStacks(strTiffPath) 
            if ~ownMIPs
                % A regexp using "Negative lookahead assertion" will ignore
                % filenames with "_z00*" parts.
                fprintf('%s: ignoring z-stacks (if any), using only MIPs\n',mfilename);
                strSearchString = '^(?!(.*\_z\d+)).*(\.png|\.tif)$';
            else
                % A regexp to generate JPGs based after grouping and generating own
                % MIPs with matlab code. Take only filenames with "_z00*" parts.
                fprintf('%s: ignoring MIPs, using only z-stacks\n',mfilename);
                strSearchString = '^(?:(.*\_z\d+)).*(\.png|\.tif)$';
            end
        else
            % A regexp to generate JPGs for all images (rather blind).
            fprintf('%s: using all images found\n',mfilename);
            strSearchString = '.*(\.png|\.tif)$';
        end
    end
    %%% Settings %%%
    %%%%%%%%%%%%%%%%
    
    
    if nargin~=3 
        fprintf('%s: analyzing %s\n',mfilename,strTiffPath);
    else
        fprintf('%s: analyzing %s, searching for ''%s''\n',mfilename,strTiffPath,strSearchString);
    end

    % create output directory if it doesn't exist.
    if ~fileattrib(strOutputPath)
        disp(sprintf('%s:  creating %s',mfilename,strOutputPath));
        mkdir(strOutputPath)
    end

%     % let's try to do it in parallel
%     try
%         matlabpool(3)
%     end    
    
    
    % get list of files in tiff directory
    cellFileList = CPdir(strTiffPath);
    cellFileList = {cellFileList(~[cellFileList.isdir]).name};
    
%     % temporary hack. only process certain columns at a time...
%     [matRow, matColumn] = cellfun(@filterimagenamedata,cellFileList);
%     matOkIX = matRow==2 & matColumn==10; % (6,4) or (4,10)
%     cellFileList = cellFileList(matOkIX);
   
    
    % only look at .png or .tif
    matNonImageIX = cellfun(@isempty,regexpi(cellFileList,strSearchString,'once'));
    cellFileList(matNonImageIX) = [];
    fprintf('%s:  found %d images\n',mfilename,length(cellFileList));
    
    % parse channel number and position number
    fprintf('%s:  parsing channel & position information\n',mfilename);
    matChannelNumber = cellfun(@check_image_channel,cellFileList);
    matPositionNumber = cellfun(@check_image_position,cellFileList);
        
    if all(matChannelNumber==0) | all(isnan(matChannelNumber))
        disp('all channels were 0 or NaN, setting all to 1')
        matChannelNumber=ones(size(matChannelNumber));
    end
    if all(matPositionNumber==0) | all(isnan(matPositionNumber))
        disp('all positions were 0 or NaN, setting all to 1')
        matPositionNumber=ones(size(matPositionNumber));
    end


    % find unparsable images and remove them from list
    matBadImageIX = matChannelNumber==0 | isnan(matChannelNumber) | matPositionNumber==0 | isnan(matPositionNumber);
    if any(matBadImageIX) & not(all(matBadImageIX))
        fprintf('%s:  removing %d unrecognized image formats\n',mfilename,sum(matBadImageIX));
        cellFileList(matBadImageIX) = [];
        matChannelNumber(matBadImageIX) = [];
        matPositionNumber(matBadImageIX) = [];
    end
    
    % if there is only one unique position, ignore position information and
    % make jpgs with only one site
    if numel(unique(matPositionNumber))==1
        fprintf('%s: only onse site (%d) per well present, treating all images as coming from site 1\n',mfilename,matPositionNumber(1));
        matPositionNumber(:) = 1;
    end
    
    % get image well row and column numbers
    [matImageRowNumber,matImageColumnNumber, matFoo, matTimePoints]=cellfun(@filterimagenamedata,cellFileList,'UniformOutput',false);
    clear matFoo
    matImageRowNumber = cell2mat(matImageRowNumber);
    matImageColumnNumber = cell2mat(matImageColumnNumber);
    matTimePoints = cell2mat(matTimePoints);
   


 
    % boolean to see if there is time resolved data
    boolTimeData = false;
    if length(unique(matTimePoints))>1
        boolTimeData = true;
    end
    
    % get all channel numbers present
    matChannelsPresent = unique(matChannelNumber);
    
    % get plate/project directory name
    strProjectName = getlastdir(strrep(strTiffPath,[filesep,'TIFF'],''));    

    if isempty(cellFileList)
        return
    end
    
    % get microscope type
    [foo,strMicroscopeType] = check_image_position(cellFileList{1});
    clear foo;
    
    % get image snake. special case if images come from Safia (thaminys).
    if ~isempty(strfind(strTiffPath,'thaminys'))
        [matImageSnake,matStitchDimensions] = get_image_snake_safia(max(matPositionNumber), strMicroscopeType);
    else
        [matImageSnake,matStitchDimensions] = get_image_snake(max(matPositionNumber), strMicroscopeType);
    end
        
   
    fprintf('%s:  microscope type "%s"\n',mfilename,strMicroscopeType);
    fprintf('%s:  %d images per well\n',mfilename,max(matPositionNumber));
    fprintf('\t \t \t \t channel %d present\n',matChannelsPresent);    
    
    % containing the rescaling settings
    matChannelIntensities = NaN(max(matChannelsPresent),2);
    
    % sample a test image outside the parfor loop
    tempImage = imread(fullfile(strTiffPath,cellFileList{1}));
    
    for iChannel = matChannelsPresent
        
        intCurrentChannelIX = find(matChannelNumber==iChannel);
        
        intNumberofimages = length(intCurrentChannelIX);
        
        intNumOfSamplesPerChannel = min(ceil(intNumberofimages*intImageSampleFractionPerChannel),intMaxNumImagesPerChannel);
        
        fprintf('%s: sampling %d random images from channel %d...',mfilename,intNumOfSamplesPerChannel,iChannel);
        
        % get randomized indices for all images coming from current
        % channel.
        matRandomIndices = randperm(intNumberofimages);
        matRandomIndices = intCurrentChannelIX(matRandomIndices);
        
        % contains lower and upper quantile intensity per image
        matQuantiles= NaN(intNumOfSamplesPerChannel,2);
        
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         %%%% WE COULD ADD ILLUMINATION CORRECTION HERE %%%% 
%         % for illumination correction
%         matMeanImage = [];
%         matStdevImage = [];
%         %%%%
        
% % %         fprintf('%s: \tprogress 0%%',mfilename)
        for i = 1:intNumOfSamplesPerChannel; 
            strImageName = cellFileList{matRandomIndices(i)}; %#ok<PFBNS>

% % %             % report progress in %
% % %             if ~mod(i,floor(intNumOfSamplesPerChannel/10))
% % %                 fprintf(' %d%%',round(100*(i/intNumOfSamplesPerChannel)))
% % %             end
            
            try
                tempImage = imread(fullfile(strTiffPath,strImageName)); %#ok<PFTIN,PFTUS>
            catch %#ok<CTCH>
                warning('matlab:bsBla','%s:  failed to load image %s',mfilename,strImageName)
            end

            % get average lower and upper 5% quantiles per sampled image
            matQuantiles(i,:) = quantile(single(tempImage(:)),matQuantileSettings)';

        end
        fprintf(' done\n')
        
        % make medians of those quantiles the new lower and upper bounds
        matChannelIntensities(iChannel,:) = [nanmin(matQuantiles(:,1)),nanmax(matQuantiles(:,2))];
    end
    

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% START MERGE AND STITCH AND JPG CONVERSION %%%
    
    % calculate shrink factor dynamically to approach target jpg dimensions
    intShrinkFactor = floor(max((size(tempImage).*matStitchDimensions) ./ matTargetImageSize));
    if intShrinkFactor < 2; intShrinkFactor = 2; end
    fprintf('%s: dynamically determined shrinkfactor to be %d.\n',mfilename,intShrinkFactor);
    
    %matImageSize = round(size(tempImage)/intShrinkFactor);
    matImageSize = size(imresize(tempImage,1/intShrinkFactor));
    
    if length(matChannelsPresent) == 4
        matChannelOrder = [3,2,1,0; ... % BLUE, GREEN, RED, nothing
                           3,2,0,1]; % BLUE, GREEN, nothing, RED
        fprintf('%s: four channels found, producing two different JPGs\n',mfilename);
    else
        matChannelOrder = [3,2,1,1]; % BLUE, GREEN, RED, RED (this usually works)
        if length(matChannelsPresent)>4
            matChannelOrder = [matChannelOrder,zeros(1,length(matChannelsPresent)-4)];
        end
    end
    
    % if there is no well information, fake as different wells and timepoints    
    matAllPos = [matImageRowNumber',matImageColumnNumber',matTimePoints'];
    if any(all(isnan(matAllPos)))
        disp('no well row, column or time information found, parsing all as different time points')
        matTmp = all_possible_combinations2([16, 24, ceil(numel(matImageRowNumber)/384)]);
        matAllPos = matTmp(1:numel(matImageRowNumber),:);
        boolTimeData = true;
        %matAllPos(:,3) = 1:size(matAllPos,1);
    end
    matPosToProcess = unique(matAllPos,'rows')';

    fprintf('%s: start saving JPG''s in %s\n',mfilename,strOutputPath);
    for iPos = matPosToProcess

        % lookup which images belong to current well
        matCurrentWellIX = ismember(matAllPos,iPos','rows');

        cellChannelPatch = cell(1,4);
        
        % init matPatch
        matPatch = zeros(round(matImageSize(1,1)*matStitchDimensions(1)),round(matImageSize(1,2)*matStitchDimensions(2)), 'single');
        
        for intChannel = matChannelsPresent

            % initialize current channel image
            matPatch = zeros(round(matImageSize(1,1)*matStitchDimensions(1)),round(matImageSize(1,2)*matStitchDimensions(2)), 'single');

            % look for current well and current channel information
            matCurrentWellAndChannelIX = (matCurrentWellIX & matChannelNumber'==intChannel);

            for k = find(matCurrentWellAndChannelIX)'

                % get current image name
                strImageName = cellFileList{k};
                
                % get current image subindices in whole well matPatch 
                xPos=(matImageSnake(1,matPositionNumber(k))*matImageSize(1,2))+1:((matImageSnake(1,matPositionNumber(k))+1)*matImageSize(1,2));
                yPos=(matImageSnake(2,matPositionNumber(k))*matImageSize(1,1))+1:((matImageSnake(2,matPositionNumber(k))+1)*matImageSize(1,1));

                try
                    fprintf('%s: \treading image %s\n',mfilename,strImageName);

                    %  matImage =
                    %  imresize(imread(fullfile(strTiffPath,strImageName)),(1/intShrinkFactor));%
                    %  [TSSI 150911 : insert illumination correction at
                    %  reading of images];
                    pathToImage = fullfile(strTiffPath,strImageName);
                    matImage = imread_shrunken_illumination_corrected(pathToImage, intShrinkFactor);                   

                catch caughtError
                    caughtError.identifier
                    caughtError.message
                    warning('matlab:bsBla','%s: failed to load image ''%s''',mfilename,fullfile(strTiffPath,strImageName));
                    matImage = zeros(matImageSize,'single');
                end
                % do image rescaling
                matPatch(yPos,xPos) = (matImage - matChannelIntensities(intChannel,1)) * (2^16/(matChannelIntensities(intChannel,2)-matChannelIntensities(intChannel,1)));
            end
            matPatch(matPatch<0) = 0;
            matPatch(matPatch>2^16) = 2^16;                
            cellChannelPatch{intChannel} = matPatch/2^16;
        end

        for intChannelCombination = 1:size(matChannelOrder,1)            
            % make sure different channel combinations do not overwrite
            % eachother
            if ~boolTimeData
                if size(matChannelOrder,1)>1
                    strFileName = sprintf('%s_%s%02d_RGB%d.jpg',strProjectName,char(iPos(1)+64),iPos(2),intChannelCombination);
                else
                    strFileName = sprintf('%s_%s%02d_RGB.jpg',strProjectName,char(iPos(1)+64),iPos(2));
                end
            else
                if size(matChannelOrder,1)>1
                    strFileName = sprintf('%s_%s%02d_t%04d_RGB%d.jpg',strProjectName,char(iPos(1)+64),iPos(2),iPos(3),intChannelCombination);
                else
                    strFileName = sprintf('%s_%s%02d_t%04d_RGB.jpg',strProjectName,char(iPos(1)+64),iPos(2),iPos(3));
                end
            end
            
            strFileName = fullfile(strOutputPath,strFileName);
            
            % final RGB image
            Overlay = zeros(size(matPatch,1),size(matPatch,2),3, 'single');
            for iChannel = matChannelsPresent
                % skip empty channels or channels that are not in the
                % current RRGB set.
                if ~matChannelOrder(intChannelCombination,iChannel), continue, end
                % put ChannelPatch in Overlay in the right position
                Overlay(:,:,matChannelOrder(intChannelCombination,iChannel)) = cellChannelPatch{iChannel};
            end
            
            fprintf('%s: storing %s\n',mfilename,strFileName)
            
            imwrite(Overlay,strFileName,'jpg','Quality',intJpgQuality);        

            drawnow

        end % intChannelCombination
        
    end % iPos
end


function has_zstacks = checkIfTiffDirHasZStacks(strTiffPath)
    has_zstacks = false;
    strBatchPath = strrep(strTiffPath, 'TIFF', 'BATCH');
    if ~fileattrib(strBatchPath)
        return 
    end
    if fileattrib([strBatchPath filesep 'has_zstacks'])
        has_zstacks = true;
        return
    end
end



function corr_image = imread_shrunken_illumination_corrected(strImage, intShrinkFactor)

% resize for final output image: note avoid excess computation and thus 
% speed up by resizing prior application of illumination correction
shrinkFun = @(x) imresize(x, 1/intShrinkFactor, 'nearest'); 

% always cache to prevent blocking transfer SoNaS to Brutus
shallCacheCorrection = true; 

% Get BATCH directory corresponding to current image
strImageDir  = fileparts(strImage);
strBatchDir = strrep(strImageDir,'TIFF','BATCH');

% Get illumination correction 
iChannel = check_image_channel(strImage);
[matMeanImage, matStdImage, hasIlluminationCorrection] = getIlluminationReference(strBatchDir,iChannel,shallCacheCorrection);

% Shrink image, and apply illumination corection
if hasIlluminationCorrection == false % check if illumination correction is present
    error('could not find illumination correction')
else
    matMeanImage = shrinkFun(matMeanImage);
    matStdImage = shrinkFun(matStdImage);
    
    Image = double(shrinkFun(imread(strImage)));
    
    isLog = 1; % has been default for years now
    corr_image = IllumCorrect(Image,matMeanImage,matStdImage,isLog);    
end

end