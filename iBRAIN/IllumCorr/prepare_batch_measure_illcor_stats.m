function prepare_batch_measure_illcor_stats(strPathName)
%prepare_batch_measure_illcor_stats prepare batch files to learn statistics
%   used for the illumination correction method.
%
%   STRPATHNAME - in most cases is a path to the project's TIFF folder
%   (Optional) If  project folder contains learn_illcor_per_site.mat file
%   function will also learn image statistics per site. MAT-file should
%   contain a structure like this:
%
%       strProjectRoot = '/share/nas/ethz-share4/Data/Users/Yauhen/iBrainProjects/site_stacks';
%       site_config = struct(...
%           'num_of_sites', 4,...
%           'site_regexp', '.*F%03d.*'...
%       );
%       save(fullfile(strProjectRoot, 'learn_illcor_per_site.mat'),...
%           'site_config');
%
%   Requires: 
%       @check_image_channel
%
%   Authors: 
%       Yauhen Yakimovich <yauhen.yakimovich@uzh.ch>
%       Berend Snijder <berend.snijder@imls.uzh.ch>
%
%   See also check_image_channel, illunimator, RunningStatVec.

%   Copyright 2012-2013 Pelkmans group.

    if nargin==0
        % Default input directory for debugging purposes. Change at will.
        strPathName = '/share/nas/ethz-share4/Data/Users/Vicky/Stat3TIRF/RFPStat3MarkerTests/120222_RFPStat3_cyclinA/TIFF';
    end
    
    % If this is iBRAIN data, store output in BATCH directory, otherwise
    % store output in intput directory.    
    if strcmp(getlastdir(strPathName),'TIFF')
        strBatchDir = fullfile(getbasedir(strPathName),'BATCH');
    else
        strBatchDir = strPathName;
    end
    
    % Log input and output directories.
    log_msg('%s: learning stats of images for:\n         input = ''%s''\n        output = ''%s''\n',mfilename,strPathName,strBatchDir)
    
    
    strBatchPrefix = 'batch_illcor_channel';
    strImagesRegexpi = '\.(png|tiff?)$';
    group_images_into_batches(strPathName, strBatchDir, strBatchPrefix, strImagesRegexpi)
    
    site_config = learn_illcor_per_site(strBatchDir);
    if ~isstruct(site_config)
        return
    end

    log_msg(['%s: additionally, learn image statistics per site\n'...
        '         num_of_sites = %d\n          site_regexp = %s\n'],...
        mfilename, site_config.num_of_sites, site_config.site_regexp);
    for site_index = 1:site_config.num_of_sites
        strBatchPrefix = sprintf('batch_illcor_site%d_channel', site_index);
        strImagesRegexpi =  [sprintf(site_config.site_regexp, site_index) '\.(png|tiff?)$'];
        group_images_into_batches(strPathName, strBatchDir, strBatchPrefix, strImagesRegexpi)
    end

end

%--------------------------------------------------------------------------
function group_images_into_batches(strPathName, strBatchDir, strBatchPrefix, strImagesRegexpi) 

    % Discover initial values.
    log_msg('%s: listing files\n',mfilename)
    cellImageFileNames = list_all_image_filenames(strPathName, strImagesRegexpi);
    
    % parse channel and zstack info
    [matChannelNumbers,matZStackNumbers] = discover_channels(cellImageFileNames);

    % see if we could parse all images.
    matBadImageIX = isnan(matChannelNumbers);
    if any(matBadImageIX)
        log_msg('%s: %d of %d images were not recognized\n',mfilename,sum(matBadImageIX),numel(cellImageFileNames))
        matChannelNumbers(matBadImageIX) = [];
        matZStackNumbers(matBadImageIX) = [];
    end
        
    % if we do not have z-stack info, treat as stack 1.
    matZStackNumbers(isnan(matZStackNumbers)) = 1;
    
    % clean up old batch filenames (?)
    try
        cellstrFileName = findfilewithregexpi(strBatchDir,[strBatchPrefix '.*_zstack.*.mat']);
        if ~isempty(cellstrFileName)
            log_msg('%s: cleaning up %d previous batch settings files\n',mfilename,numel(cellstrFileName))
            cellfun(@(x) delete(fullfile(strBatchDir,x)),cellstrFileName)
        end
    catch objFoo
        log_msg('%s: failed to clean up previous batch settings file\n',mfilename)
        objFoo
    end
    
    % store a settings file per channel and z-stack
    matChannelZStackSettings = unique([matChannelNumbers,matZStackNumbers],'rows');
    for i = 1:size(matChannelZStackSettings,1)
        strFileName = fullfile(strBatchDir,sprintf([strBatchPrefix '%03d_zstack%03d.mat'],matChannelZStackSettings(i,1),matChannelZStackSettings(i,2)));
        % store current batch file names
        cellBatchFileNames = cellImageFileNames(matChannelNumbers==matChannelZStackSettings(i,1) & matZStackNumbers==matChannelZStackSettings(i,2)); %#ok<NASGU>
        try
            save(strFileName,'cellBatchFileNames');
            log_msg('%s: stored batch file %s\n',mfilename,strFileName)            
        catch objFoo
            log_msg('%s: failed to store batch file %s\n',mfilename,strFileName)
            objFoo
        end
    end
    
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
    
    % overwriting z-stack information with 0s so we effectively ignore
    % z-stack information.
    fprintf('%s: [BS] Disabling z-stack parsing...\n',mfilename)
    matZStackNumbers = zeros(size(matChannelNumbers));
    
end

%--------------------------------------------------------------------------
function cellImageFileNames = list_all_image_filenames(strPathName,...
    strImagesRegexpi)
    if nargin == 1
        % Filter for images using regexp from package config.
        strImagesRegexpi = '\.(png|tiff?)$';
    end

    if exist('CPdir', 'file')
        lsDir = @CPdir;
    else
        lsDir = @dir;
    end
    % List directory content as filenames.    
    fileList = lsDir(strPathName)';
    fileList([fileList.isdir]) = [];
    cellImageFileNames = {fileList.name}';    
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
function site_config = learn_illcor_per_site(strBatchDir)
% strPathName - project path
    flag_pathname = fullfile(getbasedir(strBatchDir), 'learn_illcor_per_site.mat');
    if ~fileattrib(flag_pathname)
        site_config = 0;
        return
    end
    data = load(flag_pathname);
    site_config = data.site_config;
end

%--------------------------------------------------------------------------
function log_msg(varargin)
    fprintf(varargin{:});
end