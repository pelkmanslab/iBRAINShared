function measure_illcor_stats(strPathName, strBatchDir)
%MEASURE_ILLCOR_STATS learn statistics used for the illumination correction
% method.
%
%   MEASURE_ILLCOR_STATS STRPATHNAME STRBATCHDIR
%
%   Requires: 
%       @check_image_channel
%       +illunimator
%       @RunningStatVec
%
%   Authors: 
%       Yauhen Yakimovich <yauhen.yakimovich@uzh.ch>
%       Berend Snijder <berend.snijder@imls.uzh.ch>
%
%   See also check_image_channel, illunimator, RunningStatVec.

%   Copyright 2012 Pelkmans group.

    if nargin==0
        % Default input directory for debugging purposes. Change at will.
        if ispc
            strPathName = 'C:\Users\Pelkmans\Desktop\example\example_dataset';
        else
            strPathName = npc('P:\Data\Users\Prisca\endocytome\090203_MZ_w2Tf_w3EEA1\090203_Mz_Tf_EEA1_CP392-1ad\TIFF');
        end
    end

    % If output directory is not passed, and data is iBRAIN format, store
    % output in BATCH directory, otherwise store output in intput
    % directory.    
    if nargin<2
        if strcmp(getlastdir(strPathName),'TIFF')
            strBatchDir = fullfile(getbasedir(strPathName),'BATCH');
            strFigureDir = fullfile(getbasedir(strPathName),'POSTANALYSIS');
        else
            strBatchDir = strPathName;
            strFigureDir = strPathName;
        end
    elseif nargin>=2
        strFigureDir = strBatchDir;    
    end

    % Maximum number of images per channel that will be processed.
    numMaxImagesPerChannelProcessed = 10000;
    
    % Log input and output directories.
    log_msg('%s: learning stats of images for:\n         input = ''%s''\n        output = ''%s''\n figure output = ''%s''\n',mfilename,strPathName,strBatchDir,strFigureDir)
    
    % Discover initial values.
    log_msg('%s: listing files\n',mfilename)
    cellImageFileNames = list_all_image_filenames(strPathName);
    
    % parse channel and zstack info
    [matChannelNumbers,matZStackNumbers] = discover_channels(cellImageFileNames);

    % see if we could parse all images.
    matBadImageIX = isnan(matChannelNumbers);
    if any(matBadImageIX)
        log_msg('%s: %d of %d images were not recognized\n',mfilename,sum(matBadImageIX),numel(cellImageFileNames))
        cellImageFileNames(matBadImageIX) = [];
        matChannelNumbers(matBadImageIX) = [];
        matZStackNumbers(matBadImageIX) = [];
    end

    % store total number of images
    totalNumOfImages = length(cellImageFileNames);
    
    % get channel numbers
    matUniqueChannelNumbers = lin(unique(matChannelNumbers))';
        
    % check if we have z-stack information at all.
    matUniqueZStackNumbers = lin(unique(matZStackNumbers(~isnan(matZStackNumbers))))';
    if isempty(matUniqueZStackNumbers)
        % there was no z-stack information, so we should set them all to 1.
        matUniqueZStackNumbers = 1;
        matZStackNumbers(:) = 1;
    end
    
    % Init stats and bin filenames per channel number.
    numOfChannels = numel(matUniqueChannelNumbers);
    numOfStacks = numel(matUniqueZStackNumbers);
    cellImageFilePerChannelAndStack = cell(max(matUniqueChannelNumbers), max(matUniqueZStackNumbers));
    stats = cell(max(matUniqueChannelNumbers), max(matUniqueZStackNumbers));
    for zNum = matUniqueZStackNumbers
        for channelNum = matUniqueChannelNumbers
            stats{channelNum,zNum} = RunningStatVec.new();
            cellImageFilePerChannelAndStack{channelNum,zNum} = ...
                cellImageFileNames(matChannelNumbers == channelNum & matZStackNumbers == zNum);
        end
    end
    
    % Round-robin over the prepared lists of files learning one image per 
    % channel list.  
    numOfImagesPerChannel = max(lin(cellfun(@numel, cellImageFilePerChannelAndStack)));
    log_msg(['%s: compute statistics for %d images ',...
        'per %d channels with %d zstacks (i.e. %d images in total).\n'],...
        mfilename, numOfImagesPerChannel, numOfChannels, numOfStacks, totalNumOfImages);
    
    timePoint = tic;
    
    % Loop over each image per channel, up to the maximum defined by
    % numMaxImagesPerChannelProcessed
    iCounter = 0;
    for i = 1:min(numOfImagesPerChannel,numMaxImagesPerChannelProcessed)
        log_msg('%s: parsing image set %d of %d (average %.2f sec)\n',...
            mfilename, i, numOfImagesPerChannel,toc(timePoint)/i);
        for zNum = matUniqueZStackNumbers
            for channelNum = matUniqueChannelNumbers

                if length(cellImageFilePerChannelAndStack{channelNum,zNum}) < i
                    continue
                end

                % Learn statistics
                strImageFilename = cellImageFilePerChannelAndStack{channelNum,zNum}{i};
                boolReadSuccesfull = illunimator.learn_image(stats{channelNum,zNum},strImageFilename);
                
                % If reading failed, try again while checking if the image was
                % png or tif.
                if ~boolReadSuccesfull
                    strImageFilename = lookForFile(strImageFilename);
                    illunimator.learn_image(stats{channelNum,zNum}, strImageFilename);
                end
                
                % update counter
                iCounter = iCounter + 1;
            end
        end
        
        % Check if we should intermittently save the output (PDF and MAT
        % file) per channel 
        if performIntermedSave(iCounter) | i == min(numOfImagesPerChannel,numMaxImagesPerChannelProcessed) %#ok<OR2>
            saveStats(strBatchDir, stats, matUniqueChannelNumbers, matUniqueZStackNumbers);
            saveFigure(strPathName, strFigureDir, stats, matUniqueChannelNumbers, matUniqueZStackNumbers);
            iCounter = 0;
        end
        
    end
    elapsedTime = toc(timePoint);
    log_msg(['%s: learning %d images took %g seconds.\n'],...
        mfilename, totalNumOfImages, elapsedTime);

end

%--------------------------------------------------------------------------
% Perform an intermediate saving of results.
function doSave = performIntermedSave(iCounter)
    LIMIT = 500;
%     doSave = mod(stepNum, min(LIMIT,numOfImagesPerChannel)) == 0;
    doSave = iCounter > LIMIT;
end

%--------------------------------------------------------------------------
% Save learned results into files.  
function saveStats(strBatchDir, stats, matUniqueChannelNumbers, matUniqueZStackNumbers)      
    for zNum = matUniqueZStackNumbers
        for channelNum = matUniqueChannelNumbers
            filename = fullfile(strBatchDir,sprintf('IllCorStat_w%02d_z%02d.mat', channelNum,zNum));
            log_msg(['%s: save learned image statistics of channel %d zstack %d ',...
                'images for illumination correction method into ',...
                'filename: %s.\n'],...
                mfilename, channelNum, zNum, filename);
            illunimator.save_stat(filename, stats{channelNum,zNum});
        end
    end
end

%--------------------------------------------------------------------------
function saveFigure(strPathName, strFigureDir, stats, matUniqueChannelNumbers, matUniqueZStackNumbers)
    for zNum = matUniqueZStackNumbers
        for channelNum = matUniqueChannelNumbers
            h = figure;
            subplot(2,2,1)
            imagesc(stats{channelNum,zNum}.mean)
            title('running mean estimate')
            subplot(2,2,2)
            imagesc(stats{channelNum,zNum}.std)
            title('running std estimate')
            if any(lin(stats{channelNum,zNum}.std==0))
                subplot(2,2,3)
                imagesc(stats{channelNum,zNum}.std==0)
                title('running std estimate equals 0')
            else
                subplot(2,2,3)
                imagesc(stats{channelNum,zNum}.var)
                title('running var estimate')            
            end
            subplot(2,2,4)
            plotquant(lin(stats{channelNum,zNum}.mean),lin(stats{channelNum,zNum}.std))
            axis tight
            xlabel('running mean estimate')
            ylabel('running std estimate')
            suptitle(sprintf('illumination correction for plate ''%s''\nchannel %d zstack %d (%d images processed) (%d dead pixels)',getlastdir(getbasedir(strPathName)),channelNum,zNum, stats{channelNum,zNum}.count,sum(lin(stats{channelNum,zNum}.std==0))),13);

            % store figure
            try
                gcf2pdf(strFigureDir,sprintf('IllCorStat_w%02d_z%02d.pdf', channelNum, zNum),'overwrite');
            catch objError
                log_msg('%s: failed to store PDF file: ''%s''.\n',...
                mfilename,objError.message);
            end
            close(h)
        end
    end
end
%--------------------------------------------------------------------------
% Look for file image .PNG or .TIFF.
function strFoundFilename = lookForFile(strImageFilename)
    if fileattrib(strImageFilename)
        strFoundFilename = strImageFilename;
        return
    end
    [pathstr, name, ext] = fileparts(strImageFilename);
    if strcmpi(ext, '.png')
        strFoundFilename = fullfile(pathstr, sprintf('%s.tif',name));
    else
        strFoundFilename = fullfile(pathstr, sprintf('%s.png',name));
    end
    if fileattrib(strFoundFilename)
        return
    end
    log_msg(['%s: skipping apparently not existing and/or ',...
        'disappeared file: %s.'], mfilename, strImageFilename);
    strFoundFilename = [];
end

%--------------------------------------------------------------------------
% Implement own function for image listing based on channels.
function [matChannelNumbers,matZStackNumbers] = discover_channels(cellImageFileNames)
    % Find all channel numbers using image filenames.
    log_msg('%s: finding all unique channels (and z-stack numbers) from image filenames.\n',...
        mfilename);
    
    [cellChannelNumbers,cellZStackNumbers] = cellfun(@check_image_channel,cellImageFileNames, 'UniformOutput', false);
    matChannelNumbers = cell2mat(cellChannelNumbers);
    matZStackNumbers = cell2mat(cellZStackNumbers);
    
end

%--------------------------------------------------------------------------
function cellImageFileNames = list_all_image_filenames(strPathName)
    if exist('CPdir', 'file')
        lsDir = @CPdir;
    else
        lsDir = @dir;
    end    
    % List directory content as filenames.    
    fileList = lsDir(strPathName)';
    fileList([fileList.isdir]) = [];
    cellImageFileNames = {fileList.name}';
    % Filter for images using regexp from package config.
    strImagesRegexpi = '\.(png|tiff?)$';
    if ~isempty(strImagesRegexpi)
        matMatchedIndexes = ~cellfun(@isempty,... 
            regexpi(cellImageFileNames, strImagesRegexpi));
        cellImageFileNames = cellImageFileNames(matMatchedIndexes);
    end
    
    % Shuffle file names to prevent biased subsampling of images
    cellImageFileNames = cellImageFileNames(randperm(numel(cellImageFileNames)));
    
    % Prepend path as prefix to each filename prefix.
    cellImageFileNames = cellfun(...
        @(name) fullfile(strPathName, name),...
        cellImageFileNames, 'UniformOutput', false);
end

%--------------------------------------------------------------------------
function log_msg(varargin)
    fprintf(varargin{:});
end