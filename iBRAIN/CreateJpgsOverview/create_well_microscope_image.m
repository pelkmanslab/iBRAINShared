function create_well_microscope_image(strTiffPath, strOutputPath, strSearchString, ownMIPs, strSettingsFile)

% This function is a customized version of the original create_jpg
% function. In contrast to the create_jpg function it is modular and allows
% several methods for finding the lower and upper bound of the
% intensities,rescaling the intensities, and applying illumination
% correction. Settings can be retreived from an optional settings file
% located in the project folder or located at "strSettingsFile";
%
% Options for the particular methods can be specified using a settings file
% called 'Settings_WellMicroscopeImage.json'. See template below. It contains a structure
% array of strings and can be modified and run in matlab. For use with
% iBrain the settings file should be placed in the main project folder. To
% this end, provide the path to your project folder by assigning it to the
% variable 'strProjectPath'.
%
%
% %% Settings file template:
%
% % Set modules using the according field of the structure array.
% % Default options are already provided, but can be changed to alternative
% % options (% commented).
% % Make sure spelling is correct! Otherwise, there will be an error!
% % Also note that not all combinations are possible!
%
% % The field 'ChannelIntensityEstimator' can be provided as a string or
% % a n-by-2 matrix, where n is the number of channels. Column one should
% % contain the min values and column two the max values for each channel.
% % Tho get values you can use ImageJ > Adjust > Color Balance.
%
%     settings = struct();
%     settings.ImageIntensityEstimator = 'imagej'; % 'classical' % 'none'
%     settings.ChannelIntensityEstimator = 'median'; % 'classical' % [n,2]
%     settings.IlluminationCorrectionToApply = 'NBBSsinglesite'; % 'none'
%     settings.RescalingMethod = 'removeExtrema'; % 'classical'
%     settings.OutputImage.matChannelOrder = [3 2 1]; % Optional, e.g.: [1 0 2] -> channel 1 in R(ed), channel 2 black, channel 3 B(lue)
%
% % Provide path to main project folder
%
%     strProjectPath = '/path/to/project/folder';
%     filename = [strProjectPath filesep 'Settings_WellMicroscopeImage'];
%
% % Save file as .JSON
%
%     string.write([filename '.json'], savejson('', settings));
%
%
% strTiffPath = nnpc('\\nas21nwg01.ethz.ch\biol_uzh_pelkmans_s5\\Data\Users\RNAFish\140417-BAC-PioneerSet-MultiScan\BAC-PioneerSet-GFP-cycle1\TIFF');
% strOutputPath = nnpc('\\nas21nwg01.ethz.ch\biol_uzh_pelkmans_s5\\Data\Users\RNAFish\MANULYSIS\140519-BACcycle1-overview\JPG2'); ensurePresenceOfDirectory(strOutputPath);
% ownMIPs = true;
% strSearchString = '(\.png|\.tif)$';
% strSettingsFile = nnpc('\\nas21nwg01.ethz.ch\biol_uzh_pelkmans_s5\\Data\Users\RNAFish\MANULYSIS\140519-BACcycle1-overview\Settings_WellMicroscopeImage_NoIllCorr.json');
% create_well_microscope_image(strTiffPath, strOutputPath, strSearchString, ownMIPs, strSettingsFile);
%
% {
%     "ImageIntensityEstimator": "none",
%     "ChannelIntensityEstimator": [
%         [100,800],
%         [110,200],
%         [110,400],
%         [120,6000],
%     ],
%     "IlluminationCorrectionToApply": "NBBSsinglesite",
%     "RescalingMethod": "classical",
%     "OutputImage": {
%         "matChannelOrder": [3,2,0,1]
%     },
%     "ShrinkFactor": [3]
% }
%
%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%     PREPERATORY STEPS    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

inputDefaultMIP = true;
if nargin < 4
   ownMIPs=inputDefaultMIP;
elseif isempty(ownMIPs)
   ownMIPs = inputDefaultMIP;
elseif isequal(ownMIPs,'false')
   ownMIPs = false;
elseif isequal(ownMIPs,'true')
   ownMIPs = true;
end

if nargin < 5
   strSettingsFile = [];
else
   strSettingsFile = npc(strSettingsFile);
end


if nargin == 0

   strTiffPath = '/share/nas/ethz-share4/Data/Users/Yauhen/iBrainProjects/zstack/TIFF/';
   strOutputPath = '/share/nas/ethz-share4/Data/Users/Yauhen/iBrainProjects/zstack/JPG2/';

elseif nargin == 1 || isempty(strOutputPath)
   strOutputPath = strrep(strTiffPath,'TIFF','Overview');
end

% change paths
strTiffPath = npc(strTiffPath);
strOutputPath = npc(strOutputPath);


%%%%%%%%%%%%%%%%
%%% Settings %%%

%%% general settings
% how much the images shold be shrunk for overviewimages
% intShrinkFactor = 1;

% what are the target dimensions of the final overviewimages
matTargetImageSize = [2000 3000];

% maximum number of images to sample for rescale settings
intMaxNumImagesPerChannel = 500;

% quantile values for rescale lower and upper rescale settings
matImageExtremaettings = [0.01, 0.99];

% fraction of images to sample for rescaling
intImageSampleFractionPerChannel = 1;

% % jpg quality (scale of 1 to 100)
% intJpgQuality = 95;

% filemask (via strSearchString regexp)
if nargin<3
   useDefaultFilePattern = true;
elseif isempty(strSearchString)
   useDefaultFilePattern = true;
else
   useDefaultFilePattern = false;
end

if useDefaultFilePattern
   if checkIfTiffDirHasZStacks(strTiffPath)
       if ~ownMIPs
           % A regexp using "Negative lookahead assertion" will ignore
           % filenames with "_z00*" parts.
           fprintf('%s: ignoring z-stacks (if any), using only MIPs\n',mfilename);
           strSearchString = '^(?!(.*\_z\d+)).*(\.png|\.tif)$';
       else
           % A regexp to generate overviewimages based after grouping and generating own
           % MIPs with matlab code. Take only filenames with "_z00*" parts.
           fprintf('%s: ignoring MIPs, using only z-stacks\n',mfilename);
           strSearchString = '^(?:(.*\_z\d+)).*(\.png|\.tif)$';
       end
   else
       % A regexp to generate overviewimages for all images (rather blind).
       fprintf('%s: using all images found\n',mfilename);
       strSearchString = '.*(\.png|\.tif)$';
   end
end

%%% module settings
% check whether settings file exists
strProjectPath = strrep(strTiffPath,'TIFF','');

% Find settings File
if ~exist(strSettingsFile,'file') == 2
   strSettingsFile = fullfile(strProjectPath,'Settings_WellMicroscopeImage.json');
   if ~exist(strSettingsFile,'file') == 2
       strSettingsFile = fullfile(strProjectPath,'Settings_WellMicroscopeImage.json');
   end
end

if exist(strSettingsFile,'file') == 2
   % load settings file
   jsonSettingsFile = strSettingsFile;
   fprintf('%s: loading settings file from %s\n',mfilename,strProjectPath)
   if ~exist('loadjson')
       % Please install JSONlab package from
       % http://www.mathworks.com/matlabcentral/fileexchange/33381
       error('unable to load settings file, ''loadjson'' not on path')
   end
   settings = loadjson(jsonSettingsFile);
   % check whether settings file is provided in the right format
   check_settingsfile(settings);
   % load settings
   if isnumeric(settings.ChannelIntensityEstimator) && size(settings.ChannelIntensityEstimator,2)==2
       matPreloaded = settings.ChannelIntensityEstimator;
       settings.ChannelIntensityEstimator = 'preloaded';
   end
   ImageIntensityEstimator = settings.ImageIntensityEstimator;
   ChannelIntensityEstimator = settings.ChannelIntensityEstimator;
   IlluminationCorrectionToApply = settings.IlluminationCorrectionToApply;
   RescalingMethod = settings.RescalingMethod;
else
   % use default settings when no settings file is provided
   fprintf('%s: no settings file found in %s; using default settings',mfilename,strProjectPath)
   ImageIntensityEstimator = 'imagej';
   ChannelIntensityEstimator = 'median';
   IlluminationCorrectionToApply = 'NBBSsinglesite';
   RescalingMethod = 'removeExtrema';
end

%%% Settings %%%
%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% OBTAIN IMAGE CHARACTERISTICS %%%

if nargin~=3
   fprintf('%s: analyzing %s\n',mfilename,strTiffPath);
else
   fprintf('%s: analyzing %s, searching for ''%s''\n',mfilename,strTiffPath,strSearchString);
end

% create output directory if it doesn't exist.
if ~fileattrib(strOutputPath)
   fprintf('%s:  creating %s',mfilename,strOutputPath);
   mkdir(strOutputPath)
end

% get list of files in tiff directory
cellFileList = CPdir(strTiffPath);
cellFileList = {cellFileList(~[cellFileList.isdir]).name};

% only look at .png or .tif
matNonImageIX = cellfun(@isempty,regexpi(cellFileList,strSearchString,'once'));
cellFileList(matNonImageIX) = [];
fprintf('%s: found %d images\n',mfilename,length(cellFileList));

% parse channel number and position number
fprintf('%s: parsing channel & position information\n',mfilename);
matChannelNumber = cellfun(@check_image_channel,cellFileList);
matPositionNumber = cellfun(@check_image_position,cellFileList);

if all(matChannelNumber==0) || all(isnan(matChannelNumber))
   disp('all channels were 0 or NaN, setting all to 1')
   matChannelNumber=ones(size(matChannelNumber));
end
if all(matPositionNumber==0) || all(isnan(matPositionNumber))
   disp('all positions were 0 or NaN, setting all to 1')
   matPositionNumber=ones(size(matPositionNumber));
end

% find unparsable images and remove them from list
matBadImageIX = matChannelNumber==0 | isnan(matChannelNumber) | matPositionNumber==0 | isnan(matPositionNumber);
if any(matBadImageIX) && not(all(matBadImageIX))
   fprintf('%s: removing %d unrecognized image formats\n',mfilename,sum(matBadImageIX));
   cellFileList(matBadImageIX) = [];
   matChannelNumber(matBadImageIX) = [];
   matPositionNumber(matBadImageIX) = [];
end

% if there is only one unique position, ignore position information and
% make overviewimages with only one site
if numel(unique(matPositionNumber))==1
   fprintf('%s: only onse site (%d) per well present, treating all images as coming from site 1\n',mfilename,matPositionNumber(1));
   matPositionNumber(:) = 1;
end

% get image well row and column numbers
[matImageRowNumber,matImageColumnNumber, ~, matTimePoints]=cellfun(@filterimagenamedata,cellFileList,'UniformOutput',false);
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
strBatchDir = fullfile(os.path.dirname(strTiffPath),'BATCH');

if isempty(cellFileList)
   return
end

% get microscope type
[~,strMicroscopeType] = check_image_position(cellFileList{1});

% get image snake. special case if images come from Safia (thaminys).
if ~isempty(strfind(strTiffPath,'thaminys'))
   [matImageSnake,matStitchDimensions] = get_image_snake_safia(max(matPositionNumber), strMicroscopeType);
else
   [matImageSnake,matStitchDimensions] = get_image_snake(max(matPositionNumber), strMicroscopeType);
end

fprintf('%s: microscope type "%s"\n',mfilename,strMicroscopeType);
fprintf('%s: %d images per well\n',mfilename,max(matPositionNumber));
fprintf('\t \t \t \t channel %d present\n',matChannelsPresent);

%%% OBTAIN IMAGE CHARACTERISTICS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% OBTAIN PARAMETERS FOR IMAGE RESCALING %%%

% containing the rescaling settings
matChannelIntensities = NaN(max(matChannelsPresent),2);

for iChannel = matChannelsPresent
   % initialize illumination correction
   switch IlluminationCorrectionToApply

       case 'NBBSsinglesite'
           fprintf('%s: loading illumination correction files\n',mfilename);
           [IlluminationStat.matMeanImage, IlluminationStat.matStdImage, IlluminationStat.CorrectForIllumination] = ...
getIlluminationReferenceWithCaching(strBatchDir,iChannel);

       case 'none'
           IlluminationStat = [];

       otherwise
           error('"IlluminationCorrectionToApply" module not set correctly')

   end

   % initialize output for rescaling intensities
   intCurrentChannelIX = find(matChannelNumber==iChannel);

   intNumberofimages = length(intCurrentChannelIX);

   intNumOfSamplesPerChannel = min(ceil(intNumberofimages*intImageSampleFractionPerChannel),intMaxNumImagesPerChannel);

   fprintf('%s: sampling %d random images from channel %d...',mfilename,intNumOfSamplesPerChannel,iChannel);

   % get randomized indices for all images coming from current
   % channel.
   matRandomIndices = randperm(intNumberofimages);
   matRandomIndices = intCurrentChannelIX(matRandomIndices);

   % contains lower and upper quantile intensity per image
   matImageExtrema= NaN(intNumOfSamplesPerChannel,2);

   % estiminating intensity
   if ~isequal(ChannelIntensityEstimator, 'preloaded') % only estimate intensity, if no custom intensities are provided

       switch ImageIntensityEstimator

           case 'classical'
               fprintf('%s: applying the following setting for module "ImageIntensityEstimator": "%s"\n',mfilename,ImageIntensityEstimator);
               for i = 1:intNumOfSamplesPerChannel;
                   strImageName = cellFileList{matRandomIndices(i)};
                   tempImage = loadImage(strTiffPath,strImageName,IlluminationCorrectionToApply,IlluminationStat);

                   % get average lower and upper 5% quantiles per sampled image
                   matImageExtrema(i,:) = quantile(single(tempImage(:)),matImageExtremaettings)';
               end

           case 'imagej'
               fprintf('%s: applying the following setting for module "ImageIntensityEstimator": "%s"\n',mfilename,ImageIntensityEstimator);
               maximalSampledImages = 50;

               matMean = NaN(intNumOfSamplesPerChannel,1);
               for i = 1:intNumOfSamplesPerChannel;
                   strImageName = cellFileList{matRandomIndices(i)};
                   tempImage = loadImage(strTiffPath,strImageName,IlluminationCorrectionToApply,IlluminationStat);
                   matMean(i,1) = mean(tempImage(:));
               end

               [~,index] = sort(matMean,'descend');
               matImageExtrema = NaN(min([intNumOfSamplesPerChannel,maximalSampledImages]),2);
               for j = 1:min([intNumOfSamplesPerChannel,maximalSampledImages])
                   strImageName = cellFileList{matRandomIndices(index(j))};
                   tempImage = loadImage(strTiffPath,strImageName,IlluminationCorrectionToApply,IlluminationStat);
                   [minAdjust,maxAdjust] = getMinMax4Adjust(tempImage);
                   matImageExtrema(j,1) = minAdjust;
                   matImageExtrema(j,2) = maxAdjust;
               end

           case 'none'
               fprintf('%s: applying the following setting for module "ImageIntensityEstimator": "%s"\n',mfilename,ImageIntensityEstimator);

           otherwise
               error('"ImageIntensityEstimator" module not set correctly')

       end
   end
   % get upper and lower intensity values per channel
   switch ChannelIntensityEstimator

       case 'classical'
           fprintf('%s: applying the following setting for module "ChannelIntensityEstimator": "%s"\n',mfilename,ChannelIntensityEstimator);
           % make medians of those quantiles the new lower and upper bounds
           matChannelIntensities(iChannel,:) = [nanmin(matImageExtrema(:,1)),nanmax(matImageExtrema(:,2))];

       case 'median'
           fprintf('%s: applying the following setting for module "ChannelIntensityEstimator": "%s"\n',mfilename,ChannelIntensityEstimator);
           % take median of individual min and max values
           matChannelIntensities(iChannel,1) = nanmedian(matImageExtrema(:,1));
           matChannelIntensities(iChannel,2) = nanmedian(matImageExtrema(:,2));

       case 'preloaded'
           fprintf('%s: applying the following setting for module "ChannelIntensityEstimator": matrix of min and max values\n',mfilename);
           % use provided matrix
           matChannelIntensities = matPreloaded;

       otherwise
           error('"ChannelIntensityEstimator" module not set correctly')

   end
   fprintf('done\n')

end

%%% OBTAIN PARAMETERS FOR IMAGE RESCALING %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%     MERGE IMAGES    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% START MERGE AND STITCH AND COMPRESSION    %%%


strImageName = cellFileList{1};     % left outside of condition, since reused later (remnant part of original code)
tempImage = loadImage(strTiffPath,strImageName,'none',[]);
% calculate shrink factor dynamically to approach target overviewimage dimensions
if isfield(settings,'ShrinkFactor')
   intShrinkFactor = settings.ShrinkFactor;
else

   intShrinkFactor = floor(max((size(tempImage).*matStitchDimensions) ./ matTargetImageSize));
   if intShrinkFactor < 2;
       intShrinkFactor = 2;
   end
   fprintf('%s: dynamically determined shrinkfactor to be %d.\n',mfilename,intShrinkFactor);
end



matImageSize = size(imresize(tempImage,1/intShrinkFactor));

% Get Channel Order;
matChannelOrder = getChannelOrder(matChannelsPresent,settings);

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

fprintf('%s: start saving overviewimage''s in %s\n',mfilename,strOutputPath);
for iPos = matPosToProcess

   % lookup which images belong to current well
   matCurrentWellIX = ismember(matAllPos,iPos','rows');

   cellChannelPatch = cell(1,4);

   % init matPatch
   matPatch = zeros(round(matImageSize(1,1)*matStitchDimensions(1)),round(matImageSize(1,2)*matStitchDimensions(2)), 'double');

   for iChannel = matChannelsPresent

       % initialize illumination correction
       switch IlluminationCorrectionToApply

           case 'NBBSsinglesite';
               [IlluminationStat.matMeanImage, IlluminationStat.matStdImage, IlluminationStat.CorrectForIllumination] = ...
getIlluminationReferenceWithCaching(strBatchDir,iChannel);

           case 'none'
               IlluminationStat = [];

       end

       % initialize current channel image
       matPatch = zeros(round(matImageSize(1,1)*matStitchDimensions(1)),round(matImageSize(1,2)*matStitchDimensions(2)), 'double');

       % look for current well and current channel information
       matCurrentWellAndChannelIX = (matCurrentWellIX & matChannelNumber'==iChannel);

       % load images
       for k = find(matCurrentWellAndChannelIX)'

           % get current image name
           strImageName = cellFileList{k};

           % get current image subindices in whole well matPatch
xPos=(matImageSnake(1,matPositionNumber(k))*matImageSize(1,2))+1:((matImageSnake(1,matPositionNumber(k))+1)*matImageSize(1,2));
yPos=(matImageSnake(2,matPositionNumber(k))*matImageSize(1,1))+1:((matImageSnake(2,matPositionNumber(k))+1)*matImageSize(1,1));

           matImage = loadImage(strTiffPath,strImageName,IlluminationCorrectionToApply,IlluminationStat,intShrinkFactor);

           matPatch(yPos,xPos) = matImage;
       end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %%%%%%     DO  RESCALING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

       switch RescalingMethod

           case 'classical'
               fprintf('%s: applying the following setting for module "RescalingMethod": "%s"\n',mfilename,RescalingMethod);
               matPatch = (matPatch - matChannelIntensities(iChannel,1)) * (2^16/(matChannelIntensities(iChannel,2)-matChannelIntensities(iChannel,1)));
               matPatch(matPatch<0) = 0;
               matPatch(matPatch>2^16) = 2^16;
               matPatch = matPatch/2^16;

           case 'removeExtrema'
               fprintf('%s: applying the following setting for module "RescalingMethod": "%s"\n',mfilename,RescalingMethod);
               matChannelIntensities(:,1) = min(matChannelIntensities(:,1));   % force all channels to have same minimal intensity (dark background)
matPatch(matPatch<matChannelIntensities(iChannel,1)) = matChannelIntensities(iChannel,1);
matPatch(matPatch>matChannelIntensities(iChannel,2)) = matChannelIntensities(iChannel,2);

           otherwise
               error('"RescalingMethod" module not set correctly')

       end

       % ensure that image only has numerical values
       matPatch(isnan(matPatch)) = 0;
       matPatch(isinf(matPatch)) = 0;

       % prepare output for channel
       cellChannelPatch{iChannel} = matPatch;
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%     CREATE OUTPUT IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   for iChannelCombination = 1:size(matChannelOrder,1)
       % make sure different channel combinations do not overwrite
       % eachother
       if ~boolTimeData
           if size(matChannelOrder,1)>1
               strFileName = sprintf('%s_%s%02d_RGB%d.png',strProjectName,char(iPos(1)+64),iPos(2),iChannelCombination);
           else
               strFileName = sprintf('%s_%s%02d_RGB.png',strProjectName,char(iPos(1)+64),iPos(2));
           end
       else
           if size(matChannelOrder,1)>1
               strFileName = sprintf('%s_%s%02d_t%04d_RGB%d.png',strProjectName,char(iPos(1)+64),iPos(2),iPos(3),iChannelCombination);
           else
               strFileName = sprintf('%s_%s%02d_t%04d_RGB.png',strProjectName,char(iPos(1)+64),iPos(2),iPos(3));
           end
       end

       strFileName = fullfile(strOutputPath,strFileName);

       % create final RGB image
       Overlay = zeros(size(matPatch,1),size(matPatch,2),3, 'double');
       for iChannel = matChannelsPresent
           % skip empty channels or channels that are not in the
           % current RRGB set.
           if ~matChannelOrder(iChannelCombination,iChannel), continue, end
           % put ChannelPatch in Overlay in the right position
Overlay(:,:,matChannelOrder(iChannelCombination,iChannel)) = cellChannelPatch{iChannel} ./ max(cellChannelPatch{iChannel}(:));
       end

       % write final RGB image
       % imwrite(Overlay,strFileName,'jpg','Quality',intJpgQuality);
       imwrite(Overlay,strFileName,'png','bitdepth',8);

       fprintf('%s: storing %s\n',mfilename,strFileName)
       drawnow

   end % iChannelCombination

end % iPos

%%%%%%%%% Clean up Memory  %%%%%%%%%%%%
clear getIlluminationReferenceWithCaching;  % has persistent variable



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


function loadedImage = loadImage(strTiffPath,strImageName,IlluminationCorrectionToApply,IlluminationStat, intShrinkFactor)
% Loading function with illumination correction (and shrinking, which will
% speed up illuminatio correction);

% default shrinking
if nargin < 5
   intShrinkFactor = 1;
elseif isempty(intShrinkFactor)
   intShrinkFactor = 1;
end



% read image from file
if exist(fullfile(strTiffPath,strImageName),'file')==2
   loadedImage = imread(fullfile(strTiffPath,strImageName));
else
   [~, name] = fileparts(strImageName);
   strImageName = [name '.png'];
   if exist(fullfile(strTiffPath,strImageName),'file')==2
       loadedImage = imread(fullfile(strTiffPath,strImageName));
   else
       [~, name] = fileparts(strImageName);
       strImageName = [name '.tiff'];
       if exist(fullfile(strTiffPath,strImageName),'file')==2
           loadedImage = imread(fullfile(strTiffPath,strImageName));
       else
           error('Could not find file');
       end
   end
end

% force double
loadedImage = double(loadedImage);

% resize (note: added to this subfunction to speed up illumination
% correction);
loadedImage = imresize(loadedImage,(1/intShrinkFactor),'nearest');

% perform illumination correction
switch IlluminationCorrectionToApply
   case 'NBBSsinglesite'
       if IlluminationStat.CorrectForIllumination == true
           matMeanImage = imresize(IlluminationStat.matMeanImage,(1/intShrinkFactor),'nearest');
           matStdImage = imresize(IlluminationStat.matStdImage,(1/intShrinkFactor),'nearest');
           loadedImage = IllumCorrect(loadedImage,matMeanImage,matStdImage,true);
       end
end

end



function settings = check_settingsfile(settings)

% make sure variable is structure array and not empty
if ~isempty(settings)
   cellModules = {'ImageIntensityEstimator','ChannelIntensityEstimator','IlluminationCorrectionToApply','RescalingMethod'};
   if any(isfield(settings,cellModules))
       if isfield(settings,cellModules{1})
           if ~(strcmp(settings.ImageIntensityEstimator,'imagej') || strcmp(settings.ImageIntensityEstimator,'classical') || strcmp(settings.ImageIntensityEstimator,'none'))
               error('module "%s" not set correcly',cellModules{1})
           end
       else
           error('module "%s" missing or spelled incorrectly',cellModules{1})
       end
       if isfield(settings,cellModules{2})
           if ~(strcmp(settings.ChannelIntensityEstimator,'median') || strcmp(settings.ChannelIntensityEstimator,'classical') || (isnumeric(settings.ChannelIntensityEstimator) && size(settings.ChannelIntensityEstimator,2)==2))
               error('module "%s" not set correcly',cellModules{2})
           end
       else
           error('module "%s" missing or spelled incorrectly',cellModules{2})
       end
       if isfield(settings,cellModules{3})
           if ~(strcmp(settings.IlluminationCorrectionToApply,'NBBSsinglesite') || strcmp(settings.IlluminationCorrectionToApply,'none'))
               error('module "%s" not set correcly',cellModules{3})
           end
       else
           error('module "%s" missing or spelled incorrectly',cellModules{3})
       end
       if isfield(settings,cellModules{4})
           if  ~(strcmp(settings.RescalingMethod,'removeExtrema') || strcmp(settings.RescalingMethod,'classical'))
               error('module "%s" not set correcly',cellModules{4})
           end
       else
           error('module "%s" missing or spelled incorrectly',cellModules{4})
       end





   else
       error('modules missing or spelled incorrectly')
   end


   % use default settings if structure 'settings' is empty or fields have not
   % been defined correctly
else isempty(settings)
   error('settings file not set correctly')
end

end



function [hmin,hmax] = getMinMax4Adjust(imInput)

% GETMINMAX4ADJUST calculates min and max values for adjustment of
% brightness and contrast of an image. Code is based on an ImageJ macro.
% Calling the function is similar to pressing the "Auto" button in ImageJ >
% Adjust > Brightness&Contrast.
%
% [Markus Herrmann, July 2013]


% convert image to class double (necessary for hist.m function)
imInput = double(imInput);

% set threshold
autoThreshold = 5000;

% get the number of total pixel number (pixelCount)
pixelCount = numel(imInput);

% set the limit of pixel number
limit = pixelCount/10;

% set the threshold value
threshold = pixelCount/autoThreshold;

% get an array of pixel intensity histogram of the current image
nBins = 256; % 16bit: 65536
[n,xout] = hist(imInput(:),nBins);

% find lower value: loop starts from 0 and increments
i = 0;
found = false;
count = 0;
while true;
   i = i+1;
   count = n(i);
   if count > limit % if count exceeds ?limit?, then count becomes 0
       count = 0;
   end
   found = count > threshold; % if count is larger than ?threshold?, then that value is the minimum
   if or(found,i>=nBins);
       break;
   end

end
hmin = xout(i);

% find upper value: loop starts from highest count and decrements
i = nBins;
while true
   i = i-1;
   count = n(i);
   if count > limit % if count exceeds ?limit?, then count becomes 0
       count = 0;
   end
   found = count > threshold; % if count is larger than ?threshold?, then that value is the maximum
   if or(found,i==1)
       break;
   end
end
hmax = xout(i);

end


function matChannelOrder = getChannelOrder(matChannelsPresent,settings)

placedChannelOrder = false;

% Load Channnel Order from settings file
if isfield(settings,'OutputImage')
   if isfield(settings.OutputImage,'matChannelOrder')
       putativeChannelOrder = settings.OutputImage.matChannelOrder;
       if size(putativeChannelOrder,2) <= max(matChannelsPresent)
           matChannelOrder = putativeChannelOrder;
           placedChannelOrder = true;
           fprintf('%s: Using matChannelOrder from Settingsfile.\n',mfilename);
       else
           error('The user provided matChannelOrder has to be [nrOption x NumberOfChannels]');
       end
   end
end

% Default routine for obtaining Channel order ('classical method of
% original create_jpg')
if placedChannelOrder==false
   if length(matChannelsPresent) == 4
       matChannelOrder =   [3,2,1,0; ... % BLUE, GREEN, RED, nothing
           3,2,0,1]; % BLUE, GREEN, nothing, RED
       fprintf('%s: four channels found, producing two different overviews\n',mfilename);
   else
       matChannelOrder = [3,2,1,1]; % BLUE, GREEN, RED, RED (this usually works)
       if length(matChannelsPresent)>4
           matChannelOrder = [matChannelOrder,zeros(1,length(matChannelsPresent)-4)];
       end
   end
end

% capture missing channels problem (e.g. if images from 2nd channel absent,
% but 3rd channel present)
if size(matChannelOrder,2) < max(matChannelsPresent)
   error('Please provide matChannelOrder for absent channels. Note this is not dealt with by default, if more than 4 channels are present');
end


end

function [matMeanImage matStdImage CorrectForIllumination] = getIlluminationReferenceWithCaching(strBatchDir,iChannel)

persistent IlluminationReferenceCache;

if isempty(IlluminationReferenceCache)
   IlluminationReferenceCache = struct();
end

if length(IlluminationReferenceCache) < iChannel
   doLoadFromDisk = true;
elseif length(IlluminationReferenceCache) == iChannel
   if isfield(IlluminationReferenceCache(iChannel),'matMeanImage')
       doLoadFromDisk = false;
   else
       doLoadFromDisk = true;
   end
else
   doLoadFromDisk = false;
end

if doLoadFromDisk == true
   [matMeanImage matStdImage CorrectForIllumination] = getIlluminationReference(strBatchDir,iChannel);
   IlluminationReferenceCache(iChannel).matMeanImage = matMeanImage;
   IlluminationReferenceCache(iChannel).matStdImage = matStdImage;
   IlluminationReferenceCache(iChannel).CorrectForIllumination = CorrectForIllumination;
end

matMeanImage = IlluminationReferenceCache(iChannel).matMeanImage;
matStdImage = IlluminationReferenceCache(iChannel).matStdImage;
CorrectForIllumination = IlluminationReferenceCache(iChannel).CorrectForIllumination;

end
