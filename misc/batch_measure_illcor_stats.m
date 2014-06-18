function batch_measure_illcor_stats(strPathName, strBatchFile)
cmt.loadPackages();
%BATCH_MEASURE_ILLCOR_STATS learn statistics used for the illumination correction
% method.
%
%   BATCH_MEASURE_ILLCOR_STATS STRPATHNAME STRBATCHFILE
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

%   Copyright 2012-2013 Pelkmans group.

    if nargin==0
        % Default input directory for debugging purposes. Change at will.
        % strPathName  = npc('\\nas-unizh-imsb1.ethz.ch\share-2-$\Data\Users\SV40_DG\20080419033214_M1_080418_SV40_DG_batch2_CP001-1dh\TIFF');
        % strBatchFile = npc('\\nas-unizh-imsb1.ethz.ch\share-2-$\Data\Users\SV40_DG\20080419033214_M1_080418_SV40_DG_batch2_CP001-1dh\BATCH\batch_illcor_channel001_zstack001.mat');
        
        % strPathName  = npc('\\nas-unizh-imsb1.ethz.ch\share-2-$\Data\Users\Gabriele\120308-A431-Checkerboard\120308-A431-checkerboard-B-pGSK-Tf\TIFF');
        % strBatchFile = npc('\\nas-unizh-imsb1.ethz.ch\share-2-$\Data\Users\Gabriele\120308-A431-Checkerboard\120308-A431-checkerboard-B-pGSK-Tf\BATCH\batch_illcor_channel004_zstack000.mat');

        strPathName  = npc('http://www.ibrain.ethz.ch/share-2/Data/Users/mRNAmes/iBrainIndividual/120514-LR-PlateEffects/TIFF');
        strBatchFile  = npc('http://www.ibrain.ethz.ch/share-2/Data/Users/mRNAmes/iBrainIndividual/120514-LR-PlateEffects/BATCH/batch_illcor_channel001_zstack000.mat');
        
    end

    % If output directory is not passed, and data is iBRAIN format, store
    % output in BATCH directory, otherwise store output in intput
    % directory.    
    if strcmp(getlastdir(strPathName),'TIFF')
        strBatchDir = fullfile(getbasedir(strPathName),'BATCH');
        strFigureDir = fullfile(getbasedir(strPathName),'POSTANALYSIS');
    else
        strBatchDir = strPathName;
        strFigureDir = strPathName;
    end

    % Maximum number of images per channel that will be processed.
    numMaxImagesPerChannelProcessed = 10000;
    
    % Log input and output directories.
    fprintf('%s: learning stats of images for:\n         input = ''%s''\n         batch = ''%s''\n figure output = ''%s''\n    batch file = ''%s''\n',mfilename,strPathName,strBatchDir,strFigureDir,strBatchFile)
    
    % parse channel number and z-stack value to parse from batch file
    cellRegexpMatch = regexpi(strBatchFile,'(batch_illcor_.*)(\d{3})_zstack(\d{3})','tokens');
    strBatchPrefix = cellRegexpMatch{1}{1}; % for measurements filename
    intTargetChannelNumber = str2double(cellRegexpMatch{1}{2});
    intTargetZStackNumber = str2double(cellRegexpMatch{1}{3});
    foo = load(strBatchFile);
    cellImageFileNames = foo.cellBatchFileNames;
    % randomize file name order
    cellImageFileNames = cellImageFileNames(randperm(numel(cellImageFileNames)));

    % store total number of images
    numOfImages = length(cellImageFileNames);
    
    % Add averaging over up to 5 separate instances. Each instance is a bin
    % for bootrapping. So the bootstrapping is don not only by selecting
    % not more than numMaxImagesPerChannelProcessed, but also into a
    % a number of subpopulations = numOfStatInstances. Also see 
    % aggregate_stats() below, we subpopulations are pooled together.
    if numOfImages<100
        numOfStatInstances = 1;
    elseif numOfImages<300
        numOfStatInstances = 3;
    else
        numOfStatInstances = 5;
    end
    
    log_msg('%s: parsing %d images of channel %d with zstack %d, distributed over %d stat instances.\n',mfilename, numOfImages, intTargetChannelNumber,intTargetZStackNumber,numOfStatInstances)

    % init statistics and keep track of which image should go to which
    % instance
    matInstanceIX = repmat((1:numOfStatInstances)',[ceil(numOfImages/numOfStatInstances)+1,1]);
    stats = cell(numOfStatInstances,1);
    for i = 1:numOfStatInstances
        stats{i} = RunningStatVec.new();
    end
    
    timePoint = tic;

    % Loop over each image per channel, up to the maximum defined by
    % numMaxImagesPerChannelProcessed
    iCounter = 0;
    for i = 1:min(numOfImages,numMaxImagesPerChannelProcessed)
        iCounter = iCounter + 1;
        
        log_msg('%s: parsing image set %d of %d (in stat #%d) (average %.2f sec)\n',            mfilename, i, numOfImages,matInstanceIX(i),toc(timePoint)/i);

        if numOfImages < i
            continue
        end

        % Learn statistics
        if ~isunix
            % for using iBRAIN setting files on your local machine, apply
            % NPC, otherwise its overkill..
            strImageFilename = npc(cellImageFileNames{i});
        else
            strImageFilename = cellImageFileNames{i};
        end
        boolReadSuccesfull = illunimator.learn_image(stats{matInstanceIX(i)},strImageFilename);

        % If reading failed, try again while checking if the image was
        % png or tif.
        if ~boolReadSuccesfull
            strImageFilename = lookForFile(strImageFilename);
            illunimator.learn_image(stats{matInstanceIX(i)}, strImageFilename);
        end
        
        % Check if we should intermittently save the output (PDF and MAT
        % file) per channel: either every 500 steps or at last step
%
% [YY] This iterative behavoir is disabled in favour of one single saving attempt, when everything is learned.
%
%%%         if mod(iCounter, 500) == 0 | i == min(numOfImages,numMaxImagesPerChannelProcessed) %#ok<OR2>
%%%             saveStats(strBatchDir, stats, intTargetChannelNumber, intTargetZStackNumber, strBatchPrefix);
%%%             saveFigure(strPathName, strFigureDir, stats, intTargetChannelNumber, intTargetZStackNumber, strBatchPrefix);
%%% 	    log_msg('%s: saved measured statistics for %d  out of %d images.. ',mfilename, iCounter, numOfImages);
%%%        end
        
    end
    saveStats(strBatchDir, stats, intTargetChannelNumber, intTargetZStackNumber, strBatchPrefix);
    saveFigure(strPathName, strFigureDir, stats, intTargetChannelNumber, intTargetZStackNumber, strBatchPrefix);
    elapsedTime = toc(timePoint);
    log_msg('%s: learning %d images took %g seconds.\n',mfilename, numOfImages, elapsedTime);
    log_msg('%s: statistics for all images was successfully learned. We are done.\n',mfilename);

end


%--------------------------------------------------------------------------
% Save learned results into files.  
function saveStats(strBatchDir, stats, channelNum, zNum, strBatchPrefix)
cmt.loadPackages();
% assemble filename so that the naming pattern is include.
    filename = fullfile(strBatchDir,sprintf(        'Measurements_%s%03d_zstack%03d.mat',... 
        strBatchPrefix, channelNum,zNum));
    log_msg('%s: stored stats of channel %d zstack %d: %s.\n',        mfilename, channelNum, zNum, filename);
    %illunimator.save_stat(filename, stats);
    % smart aggregate distributed statistics
    stat_values = struct(        'mean', aggregate_stats(stats,'mean'),...        
        'std', aggregate_stats(stats,'std')        ); %#ok<NASGU>
        % If nesessary consider adding more statistics
        %'var', aggregate_stats(stats,'var'),        %'count', aggregate_stats(stats,'count'),        %'min', aggregate_stats(stats,'min'),        %'max', aggregate_stats(stats,'max')...    
    save(filename, 'stat_values');
end

%--------------------------------------------------------------------------
function saveFigure(strPathName, strFigureDir, stats, channelNum, zNum, strBatchPrefix)
cmt.loadPackages();
% smart aggregate distributed statistics
    stat_values = struct(        'mean', aggregate_stats(stats,'mean'),        'var', aggregate_stats(stats,'var'),        'std', aggregate_stats(stats,'std'),        'count', aggregate_stats(stats,'count'),        'min', aggregate_stats(stats,'min'),        'max', aggregate_stats(stats,'max')    );

    h = figure;
    subplot(2,2,1)
    imagesc(stat_values.mean,[quantile(stat_values.mean(:),0.001),quantile(stat_values.mean(:),1-0.001)])
    title('running mean estimate')
    subplot(2,2,2)
    % force somewhat robust color range
    imagesc(stat_values.std,[quantile(stat_values.std(:),0.001),quantile(stat_values.std(:),1-0.001)])
    title('running std estimate')
    if any(lin(stat_values.std==0))
        subplot(2,2,3)
        imagesc(stat_values.std==0)
        title('running std estimate equals 0')
    else
        subplot(2,2,3)
        imagesc(stat_values.var,[quantile(stat_values.var(:),0.001),quantile(stat_values.std(:),1-0.001)])
        title('running var estimate')            
    end
    subplot(2,2,4)
    if numel(lin(stat_values.mean)) > 1
        plotquant(lin(stat_values.mean),lin(stat_values.std));
    end
    axis tight
    xlabel('running mean estimate')
    ylabel('running std estimate')
    suptitle(sprintf('illumination correction for plate ''%s''\nchannel %d zstack %d (%d images processed over %d stat instances) (%d dead pixels)',getlastdir(getbasedir(strPathName)),channelNum,zNum, stat_values.count,numel(stats),sum(lin(stat_values.std==0))));
    drawnow
    
    % store figure
    try
        gcf2pdf(strFigureDir,sprintf('Measurements_%s%03d_zstack%03d.pdf', strBatchPrefix, channelNum, zNum), 'overwrite');
    catch objError
        log_msg('%s: failed to store PDF file: ''%s''.\n',        mfilename,objError.message);
    end
    close(h)
end
%--------------------------------------------------------------------------
% Look for file image .PNG or .TIFF.
function strFoundFilename = lookForFile(strImageFilename)
cmt.loadPackages();
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
    log_msg(['%s: skipping apparently not existing and/or ',        'disappeared file: %s.'], mfilename, strImageFilename);
    strFoundFilename = [];
end

%--------------------------------------------------------------------------
function log_msg(varargin)
cmt.loadPackages();
fprintf(varargin{:});
end

%--------------------------------------------------------------------------
function matAggregate = aggregate_stats(stats, strFuncHandle)
cmt.loadPackages();
switch lower(strFuncHandle)
        case 'mean'
            cellfield = cellfun(@(x) x.mean, stats,'UniformOutput',false);
            matAggregate = median(cat(3,cellfield{:}),3);
        case 'var'
            cellfield = cellfun(@(x) x.var, stats,'UniformOutput',false);
            matAggregate = median(cat(3,cellfield{:}),3);
        case 'std'
            cellfield = cellfun(@(x) x.std, stats,'UniformOutput',false);
            matAggregate = median(cat(3,cellfield{:}),3);
        case 'count'
            cellfield = cellfun(@(x) x.count, stats,'UniformOutput',false);
            matAggregate = sum(cat(3,cellfield{:}),3);
        case 'min'
            cellfield = cellfun(@(x) x.min, stats,'UniformOutput',false);
            matAggregate = min(cat(3,cellfield{:}),[],3);
        case 'max'
            cellfield = cellfun(@(x) x.max, stats,'UniformOutput',false);
            matAggregate = max(cat(3,cellfield{:}),[],3);
        otherwise
            error('unknown method requested...')
    end
    % Compress the size of the resulting measurement files.
    matAggregate = single(matAggregate);
    
end
