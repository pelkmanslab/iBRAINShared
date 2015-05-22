function mergepngmovieV1(strTrackingPath)
% perhaps we do not need the output path
% we should add the time information for the movies


%Check inputs.
if nargin == 0
    strTrackingPath = 'Z:\Data\Users\Berend\Prisca\081202_H2B_GPI_movies_F07\081202_H2B_GPI_movies_F07\TRACKING\Nuclei09';
end

strTrackingPath = npc(strTrackingPath);

% get the DUMPSITES path
strDumpSitesPath = fullfile(strTrackingPath,'DUMPSITES');
%check if it exists, if not output error
if ~fileattrib(strDumpSitesPath)
    error('%s:  DUMPSITES directory not found in %s',mfilename,strTrackingPath);
end




% get list of files in tiff directory
cellFileList = CPdir(strDumpSitesPath);
cellFileList = {cellFileList(~[cellFileList.isdir]).name};

% only look at .png or .tif
matNonImageIX = cellfun(@isempty,regexpi(cellFileList,'.*(\.png|\.tif)$','once'));
cellFileList(matNonImageIX) = [];
fprintf('%s:  found %d images\n',mfilename,length(cellFileList));

% parse channel number and position number
fprintf('%s:  parsing channel & position information\n',mfilename);
matChannelNumber = cellfun(@check_image_channel,cellFileList);
matPositionNumber = cellfun(@check_image_position,cellFileList);


% find unparsable images and remove them from list
matBadImageIX = find(matChannelNumber==0 | isnan(matChannelNumber) | matPositionNumber==0 | isnan(matPositionNumber));
if any(matBadImageIX)
    fprintf('%s:  removing %d unrecognized image formats\n',mfilename,sum(matBadImageIX));
    cellFileList(matBadImageIX) = [];
    matChannelNumber(matBadImageIX) = [];
    matPositionNumber(matBadImageIX) = [];
end

% get image well row and column numbers
[matImageRowNumber,matImageColumnNumber, strWells, matTimePoints]=cellfun(@filterimagenamedata,cellFileList,'UniformOutput',false);
matImageRowNumber = cell2mat(matImageRowNumber);
matImageColumnNumber = cell2mat(matImageColumnNumber);
matTimePoints = cell2mat(matTimePoints);

% boolean to see if there is time resolved data
boolTimeData = false;
if length(unique(matTimePoints))>1
    boolTimeData = true;
end

% get microscope type
[foo,strMicroscopeType] = check_image_position(cellFileList{1});
clear foo;

% get image snake. special case if images come from Safia (thaminys).
if ~isempty(strfind(strDumpSitesPath,'thaminys'))
    [matImageSnake,matStitchDimensions] = get_image_snake_safia(max(matPositionNumber), strMicroscopeType);
else
    [matImageSnake,matStitchDimensions] = get_image_snake(max(matPositionNumber), strMicroscopeType);
end

fprintf('%s:  microscope type "%s"\n',mfilename,strMicroscopeType);
fprintf('%s:  %d images per well\n',mfilename,max(matPositionNumber));
    
% Calculate the size of the images
tempImage = imread(fullfile(strDumpSitesPath,cellFileList{1}));
matImageSize = round(size(tempImage));

%Need to change this to save output / well, Also would be nice to imput
%time Info at some point 
%fprintf('%s: start saving JPG''s in %s\n',mfilename,strOutputPath);


% Asign unique ID to sites in the whole plate 
[structUniqueSiteID.matUniqueValues foo structUniqueSiteID.matJ]=  unique([matImageRowNumber',matImageColumnNumber', matTimePoints'],'rows');
clear foo 



for iPos = 1:size(structUniqueSiteID.matUniqueValues,1)%unique([matImageRowNumber',matImageColumnNumber', matTimePoints'],'rows')'
    
    % lookup which images belong to current well
    matCurrentWellIX = ismember([matImageRowNumber',matImageColumnNumber',matTimePoints'],...
        structUniqueSiteID.matUniqueValues(iPos,:),'rows');
    
    cellChannelPatch = cell(1,4);
    
    % init matPatch
    matPatch = zeros(round(matImageSize(1,1)*matStitchDimensions(1)),round(matImageSize(1,2)*matStitchDimensions(2)),matImageSize(1,3),'uint8');
    
    for k = find(structUniqueSiteID.matJ == iPos)'
        
        % get current image name
        strImageName = cellFileList{k};
        
        % get current image subindices in whole well matPatch
        xPos=(matImageSnake(1,matPositionNumber(k))*matImageSize(1,2))+1:((matImageSnake(1,matPositionNumber(k))+1)*matImageSize(1,2));
        yPos=(matImageSnake(2,matPositionNumber(k))*matImageSize(1,1))+1:((matImageSnake(2,matPositionNumber(k))+1)*matImageSize(1,1));
        
        try
            matImage = imread(fullfile(strDumpSitesPath,strImageName));
        catch caughtError
            caughtError.identifier
            caughtError.message
            warning('matlab:bsBla','%s: failed to load image ''%s''',mfilename,fullfile(strDumpSitesPath,strImageName));
            matImage = zeros(matImageSize,'single');
        end
        % do image rescaling
        %matPatch(yPos,xPos) = (matImage - matChannelIntensities(intChannel,1)) * (2^16/(matChannelIntensities(intChannel,2)-matChannelIntensities(intChannel,1)));
        matPatch(yPos,xPos,:) = (matImage);%./max(matImage(:));
    end
 
    matPatch(matPatch<0) = 0;
    

    %Draw dividing white lines (same than berends code)
    [matSize1,matSize2,matSize3]=size(matPatch);
    matStepSize1 = matSize1 / matStitchDimensions(1);% should come from get_image_snake!!
    matStepSize2 = matSize2 / matStitchDimensions(2);% should come from get_image_snake!!
    matYSteps = 0:matStepSize1:matSize1;matYSteps(1)=1;
    matXSteps = 0:matStepSize2:matSize2;matXSteps(1)=1;
    matPatch(matYSteps,:,:) = 190;%max(matPatch(:))/2;%I hope this works!
    matPatch(:,matXSteps,:) = 190;%max(matPatch(:))/2;
    
    
    %Get the name of the Frame accordind to the timepoint and create the
    %well directory 
    numIndexWellTime = find(structUniqueSiteID.matJ == iPos); 
    numIndexWellTime = numIndexWellTime(1);
    
    %currentwell
    strCurrentwell =  char(strWells(numIndexWellTime));
    
    %current time point
    numCurrentTimePoint = matTimePoints(numIndexWellTime);
    
    
    %create the well directory if it does not exist
    strTempOutputFile = fullfile(strTrackingPath,strcat('Well_',strCurrentwell));
    if ~fileattrib(strTempOutputFile)
        disp(sprintf('%s:  creating %s',mfilename,strTempOutputFile));
        mkdir(strTempOutputFile)
    end
    
    % Save Image with timepoint name
    strFileName = fullfile(strTempOutputFile,sprintf('%04d.jpg',numCurrentTimePoint));
    
    fprintf('%s: Saving image %s of well %s\n',mfilename,sprintf('%04d.jpg',numCurrentTimePoint),strCurrentwell);
    
    matPatch = imresize(matPatch, 0.5);
    imwrite(matPatch,strFileName,'jpg','Quality',100);
 
end 
