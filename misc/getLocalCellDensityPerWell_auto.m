function getLocalCellDensityPerWell_auto(strRootPath)

if nargin==0
    strRootPath = npc('/Volumes/biol_uzh_pelkmans_s4/Data/Users/Vicky/iBrain/RV/130702HapDipDS1/BATCH/');
    figure()
end

%   If  project folder contains learn_LocalCellDensity_FromSpots.mat file,
%   function will learn population context measurements from spot, or other object, locations, rather than nuclei locations. This is useful if nuclei are secondary objects derived from another object eg spot expansion). MAT-file should
%   contain a structure like this:
% 
%   strProjectPath = '/Volumes/biol_uzh_pelkmans_s6/Data/Users/Vicky/Tests/testHCT_checker/';
%   LCD_config = struct(...
%       'strObject', {'Spots'},'intFilterSigma',25); % can therefore
%       include a sigma value.
%   save(fullfile(strProjectPath, 'learn_LocalCellDensity_FromObject.mat'),...
%       'LCD_config');

%


%%% PARAMETERS:

% how many pixels should the images be made to overlap, in order to
% overcome the absence of cells due to discarding of objects that touch the
% border of images?
%
% 15 works well for SV40_DG
% intImageBorderOverlap = 15;

% What is the gaussian blur size? (i.e. fillter of size hsize with standard
% deviation sigma)
% intFilterSize = 150;
% intFilterSigma = 25;

% We can have a schrink-factor, to speed the whole thing up! (4 works nice)
%
% note that all other factors will be shrunken automatically. do not adjust
% the other parameters according to the shrink-factor.
%
% note that if you want LCD measurements to be comparible (within 1
% experiment) keep the shrink factor equal for all calculations!!
% intShrinkFactor = 4;

% % SV40_DG
% intImageBorderOverlap = 15;
% intFilterSize = 150;
% intFilterSigma = 25;
% intShrinkFactor = 4;

% % MCF10A, 20X
% intImageBorderOverlap = 75;
% intFilterSize = 1250;
% intFilterSigma = intFilterSize*(25/150);
% intShrinkFactor = 40;

% 50K
% intFilterSize = 200;
% intFilterSigma = intFilterSize*(25/150);
% could this be typical nucleus size?
% intFilterSigma = 4;
% intShrinkFactor = 10;
% 
% % Prisca screens
% % intFilterSigma = 60;
% % intShrinkFactor = 40;

% % Vicky screens with HCT116 cells, CV7K 10X
% intImageBorderOverlap = -6;
% intFilterSize = 150;
% intFilterSigma = 25;
% intShrinkFactor = 6;

% 
% % these can probably be set automatically...
% intFilterSize = intFilterSigma*6;
% intImageBorderOverlap = intFilterSigma;

%%% end of parameters list.



strRootPath = npc(strRootPath);

% note, we only need the tiff path to get the image size... perhaps we can
% get this from the BATCH dir directly?
strTiffPath = strrep(strRootPath,'BATCH','TIFF');

fprintf('%s: analyzing %s\n',mfilename,strRootPath)


% if fileattrib(fullfile(strRootPath,'Measurements_Nuclei_DistanceToEdge.mat'))
%     fprintf('%s: Output already found, quitting...\n',mfilename)    
%     return
% end

% init!
handles = struct();
% load basic measurements
if ~fileattrib(fullfile(strRootPath, 'Measurements_Image_FileNames.mat'))
    fprintf('%s: no iBRAIN data found\n',mfilename)
    return
end

fprintf('%s: loading file names, object counts, nuclei locations\n',mfilename)
handles = LoadMeasurements(handles,fullfile(strRootPath, 'Measurements_Image_FileNames.mat'));
handles = LoadMeasurements(handles,fullfile(strRootPath, 'Measurements_Image_ObjectCount.mat'));

% look for settings file to indicate object whose locations to work with
% (optional). Default is nuclei.
if fileattrib(fullfile(getbasedir(strRootPath),'learn_LocalCellDensity_FromObject.mat'))
    flag_pathname = fullfile(getbasedir(strRootPath), 'learn_LocalCellDensity_FromObject.mat');
    data = load(flag_pathname);
    LCD_config = data.LCD_config;
    strObject = getfield(LCD_config,'strObject');
else
    strObject = ('Nuclei');
end
strLocationFile = ['Measurements_' (strObject) '_Location.mat'];
handles = LoadMeasurements(handles,fullfile(strRootPath,strLocationFile));
    
% handles = LoadMeasurements(handles,fullfile(strRootPath, 'Measurements_Nuclei_Location.mat'));

% image object counts
matImageObjectCount = cat(1,handles.Measurements.Image.ObjectCount{:});

if size(unique(matImageObjectCount','rows'),1)==1
    % this means that all object count columns are equal, so it doesn't
    % matter which one we take
    matImageObjectCount = matImageObjectCount(:,1);
else
    %  otherwise, look for "Nuclei" containing object names, take that
    %  column
    matIX = find(~cellfun(@isempty,strfind(handles.Measurements.Image.ObjectCountFeatures,'Nuclei')),1,'first');
    matImageObjectCount = matImageObjectCount(:,matIX);
    clear matIX
end


% image file names
cellFileNames = cat(1,handles.Measurements.Image.FileNames{:});
cellFileNames = cellFileNames(:,1);
cellFileNames = strrep(cellFileNames,'.tif','.png');

% lookup image well/plate position
[matRows, matColumns, ~, matTimepoints] = cellfun(@filterimagenamedata,cellFileNames,'UniformOutput',false);
matRows = cell2mat(matRows);
matColumns = cell2mat(matColumns);
matTimepoints = cell2mat(matTimepoints);
% lookup image positions
[intImagePosition,strMicroscopeType] = cellfun(@check_image_position,cellFileNames,'UniformOutput',false);
intImagePosition = cell2mat(intImagePosition);
strMicroscopeType = unique(strMicroscopeType);
% get image snake
[matImageSnake,matStitchDimensions] = get_image_snake(max(intImagePosition),strMicroscopeType);


% matImageSnake(1,:) = max(matImageSnake(1,:)) - matImageSnake(1,:)
% matImageSnake(2,:) = max(matImageSnake(2,:)) - matImageSnake(2,:)

% get image size
try
    strucImageInfo = imfinfo(fullfile(strTiffPath,cellFileNames{1}));
    matImageSize = [strucImageInfo.Height, strucImageInfo.Width];% [height, width]
catch exception
    warning(exception);
    matImageSize = [1040 1392];    
end


% keep meta data track, i.e. image-index and object-index
cellNucleiMetaData = cell(size(handles.Measurements.(strObject).Location));
% add offsets to nuclei positions
for i = 1:length(handles.Measurements.(strObject).Location)
    if ~isempty(handles.Measurements.(strObject).Location{i})
        % meta data: image-index & object-index
        cellNucleiMetaData{i} = NaN(size(handles.Measurements.(strObject).Location{i}));
        cellNucleiMetaData{i}(:,1) = i;
        cellNucleiMetaData{i}(:,2) = 1:size(handles.Measurements.(strObject).Location{i},1);
    end
end


% Here we could make a small loop to optimize overlap!
iScoreCount = 0;
matOverlapScore = [];
boolOptimumFound = 0;
numOfHigherValues = 200;

if ~all(matImageSnake(:)==0)
   matOverlapValues = -90:2:1250;    
%      matOverlapValues = -10:10;   % narrow range can cause problems in finding optimum! 
else
    matOverlapValues = 0:1:10;
    fprintf('%s: only one site per well imaged\n',mfilename)
end

fprintf('%s: starting optimal overlap search\n',mfilename)
for iOverlap = matOverlapValues
    
    if boolOptimumFound==0
        intImageBorderOverlap = iOverlap;
    elseif boolOptimumFound==1
        % if the optimal overlap value is found, recalculate values using
        % this setting, then break out of loop.
        [foo,minIX]=nanmin(matOverlapScore); %#ok<ASGLU>
        intImageBorderOverlap = matOverlapValues(minIX);
    end

    % calculate new origins for each image, use these as offsets.
    matNucleusOffsetX = matImageSnake(1,intImagePosition) * matImageSize(1,2);% width
    matNucleusOffsetY = matImageSnake(2,intImagePosition) * matImageSize(1,1);% height

    matNucleusOffsetX = matNucleusOffsetX - (matImageSnake(1,intImagePosition) * intImageBorderOverlap);
    matNucleusOffsetY = matNucleusOffsetY - (matImageSnake(2,intImagePosition) * intImageBorderOverlap);

    % get max well dimensions, for 2D binning later
    intMaxWelPosX = (max(matImageSnake(1,:))+1) * matImageSize(1,2) - max(matImageSnake(1,:) * intImageBorderOverlap);% max well width
    intMaxWelPosY = (max(matImageSnake(2,:))+1) * matImageSize(1,1) - max(matImageSnake(2,:) * intImageBorderOverlap);% max well height

    % get nuclei positions
    cellNucleiPositions = handles.Measurements.(strObject).Location;
    % add offsets to nuclei positions
    for i = 1:length(cellNucleiPositions)
        if ~isempty(cellNucleiPositions{i})
            cellNucleiPositions{i}(:,1) = round(cellNucleiPositions{i}(:,1) + matNucleusOffsetX(i));
            cellNucleiPositions{i}(:,2) = round(cellNucleiPositions{i}(:,2) + matNucleusOffsetY(i));
        end
    end

    % plot total LCD map of all wells combined 
    matAllWellPositions = cat(1,cellNucleiPositions{:});
    % get 2D heatmap of cell count
    matDescriptor = [0, intMaxWelPosY, round(intMaxWelPosY / 50);
                     0, intMaxWelPosX, round(intMaxWelPosX / 50)];
    [matComplete2DBinCount]=histogram2(matAllWellPositions(:,2)',matAllWellPositions(:,1)',matDescriptor);

    matSumY = sum(matComplete2DBinCount,1);
    matSumX = sum(matComplete2DBinCount,2);
    
    matSmoothSumY = smooth(matSumY);
    matSmoothSumX = smooth(matSumX);
    
    
    
%     x = (0: 0.1: 5)';
%     y = erf(x);
%     f = polyval(p,x);
%     plot(x,y,'o',x,f,'-')
    
    if nargin==0 || boolOptimumFound==1
        subplot(2,2,1)
        imagesc(matComplete2DBinCount)
        subplot(2,2,2)
        cla
        hold on
        plot(matSumY,'*b')
        plot(matSmoothSumY,':r')
        hold off
        subplot(2,2,3)
%         bar(matSumX)
        cla
        hold on
        plot(matSumX,'*b')
        plot(matSmoothSumX,':r')
        hold off
        subplot(2,2,4)
        plot(matOverlapValues(~isnan(matOverlapScore)),matOverlapScore(~isnan(matOverlapScore)))
        if boolOptimumFound==1
            vline(matOverlapValues(minIX),':r',sprintf('minimum=%d',intImageBorderOverlap))
        elseif ~isempty(matOverlapScore)
            [~,minIX] = min(matOverlapScore);
            vline(matOverlapValues(minIX),':r',sprintf('temp_minimum=%d',matOverlapValues(minIX)))
        end
        
        suptitle(sprintf('%s: intImageBorderOverlap = %d',strRootPath,intImageBorderOverlap))
        drawnow

        if boolOptimumFound==1
            try %#ok<TRYNC>
                gcf2pdf(strrep(strRootPath,'BATCH','POSTANALYSIS'),mfilename,'overwrite')
            end
            close all
            figure();            
        end        
    end    
    
    if boolOptimumFound==1
        fprintf('%s: found optimal overlap value of %d in %d iterations\n',mfilename,intImageBorderOverlap,iScoreCount)
        break
    end

    % add current score to score overview
    iScoreCount = iScoreCount + 1;
%     matOverlapScore(iScoreCount) = ...
%         std(matSumY) + ...
%         std(matSumX); %#ok<AGROW>

    matOverlapScore(iScoreCount) = ...
        sum(abs(matSmoothSumY(:)-matSumY(:))) + ...
        sum(abs(matSmoothSumX(:)-matSumX(:))); %#ok<AGROW>

    % minimum found if last X overlap-scores measurements are bigger
    % the -Xth.
    
    if length(matOverlapScore)>numOfHigherValues
        if all(matOverlapScore(end-(numOfHigherValues-1):end)>matOverlapScore(end-numOfHigherValues))
            boolOptimumFound = 1;
        end
    end

end % end optimization loop

% % in case of extremely spread out cells, such as MCF10A, increase sigma as
% % 2 * intImageBorderOverlap, otherwise: intFilterSigma = intImageBorderOverlap
% if ~isempty(strfind(strRootPath,'50K_'))
%     fprintf('%s: optimal overlap value of %d overwritten by 50K setting of 25!\n',mfilename,intImageBorderOverlap)
%     intImageBorderOverlap = 25;
% elseif ~isempty(strfind(strRootPath,'101013_10-62_siRNAsize'))
%     fprintf('%s: optimal overlap value of %d overwritten by FRANK setting of 130!\n',mfilename,intImageBorderOverlap)
%     intImageBorderOverlap = 120;
% elseif ~isempty(strfind(strRootPath,['_DG',filesep]))
%     fprintf('%s: optimal overlap value of %d overwritten by "_DG" setting of 16!\n',mfilename,intImageBorderOverlap)
%     intImageBorderOverlap = 16;    
% elseif ~isempty(strfind(strRootPath,'120521MatGFPFAK'))
%     fprintf('%s: optimal overlap value of %d overwritten by "120521MatGFPFAK" setting of 500!\n',mfilename,intImageBorderOverlap)
%     intImageBorderOverlap = 500;
% elseif ~isempty(strfind(strRootPath,'20130125_Hela_CCandTf_SPLIT'))
%     fprintf('%s: optimal overlap value of %d overwritten by "20130125_Hela_CCandTf_SPLIT" setting of 10!\n',mfilename,intImageBorderOverlap)
%     intImageBorderOverlap = 10;
% end
% 
% see if we detected a situation in which nuclei were not discarded. if so,
% switch to inferring filter size from minimal neighbor distance
if intImageBorderOverlap < 5% totalleh arbitrareh :)
    matNearestNeighborDistances = nanmedian(cellfun(@(x) median(findClosestDistanceToNeighbors(x)), cellNucleiPositions));    
    fprintf('%s: objects at edge of images were not discarded (border overlap < 5px). switching to median minimal nearest neighbor (%dpx) to figure out cell diameter...',mfilename,round(matNearestNeighborDistances))
    intFilterSigma = ceil(matNearestNeighborDistances*1.2);    
    intFilterSize = intFilterSigma*6;    
else
    % set filter sigma equal to image border overlap
    if ~isempty(strfind(strRootPath,'Cameron'))
        fprintf('%s: optimal filter sigma set to 60 for CAMERON!\n',mfilename,intImageBorderOverlap)
        intFilterSigma = 60;
    else
        intFilterSigma = intImageBorderOverlap;
    end
    intFilterSize = intFilterSigma*6;
end
% set sigma for Vicky's screens with HCT116, CV7K 10X, from settings file
if ~isempty(strfind(strRootPath,'_RVHCT116_'))
    intFilterSigma = getfield(LCD_config,'intFilterSigma');
    fprintf('%s: optimal filter sigma set to %d for RVHCT116!\n',mfilename,intFilterSigma)
    intFilterSize = intFilterSigma*6;
end


% intFilterSigma = intImageBorderOverlap;
if ~all(matImageSnake(:)==0)
    intShrinkFactor = ceil(max(intMaxWelPosY,intMaxWelPosX)/1000);
else
    intShrinkFactor = 4;
    fprintf('%s: only one site per well imaged, using shrink factor of 4\n',mfilename)
end



%%% end of parameters list.



strRootPath = npc(strRootPath);

% note, we only need the tiff path to get the image size... perhaps we can
% get this from the BATCH dir directly?
strTiffPath = strrep(strRootPath,'BATCH','TIFF');

fprintf('%s: analyzing %s\n',mfilename,strRootPath)
fprintf('%s: \t image border scrunching: %d pixels\n',mfilename,intImageBorderOverlap)
fprintf('%s: \t gaussian filter size: %d pixels\n',mfilename,intFilterSize)
fprintf('%s: \t gaussian filter sigma: %d pixels\n',mfilename,intFilterSigma)
fprintf('%s: \t shrink factor: %d\n',mfilename,intShrinkFactor)

% return

% find which object count column to use for initializing the measurements
matObjectCountIX = find(~cellfun(@isempty,strfind(lower(handles.Measurements.Image.ObjectCountFeatures),'nuclei')),1,'first');
matObjectCount = cat(1,handles.Measurements.Image.ObjectCount{:});
if all(~matObjectCountIX)
    matObjectCountIX = find(~cellfun(@isempty,strfind(lower(handles.Measurements.Image.ObjectCountFeatures),'cells')),1,'first');
end
if all(~matObjectCountIX)
    % if column one and two are identical, assume their nuclei/cells.
    if isequal(matObjectCount(:,1),matObjectCount(:,2))
        matObjectCountIX = 1;
    else
        error('argh, don''t know which object count column to use?!?!')
    end
end
matObjectCount = matObjectCount(:,matObjectCountIX);

%%% RECALCULATE LCD & EDGE PER WELL
% loop over each well, & recalculate LCD & EDGE measurements
matWellPositionsPerImage = [matRows, matColumns, matTimepoints];
% init LCD output measurement
cellMeasurement_Nuclei_LocalCellDensity = arrayfun(@(x) NaN(x,1),matObjectCount,'UniformOutput',false)';
cellMeasurement_Nuclei_Edge = arrayfun(@(x) NaN(x,1),matObjectCount,'UniformOutput',false)';
cellMeasurement_Nuclei_DistanceToEdge = arrayfun(@(x) NaN(x,1),matObjectCount,'UniformOutput',false)';
cellMeasurement_Nuclei_Single = arrayfun(@(x) NaN(x,1),matObjectCount,'UniformOutput',false)';

% calculate the point spread function (PSF) for image dilution
PSF = fspecial('gaussian',intFilterSize,intFilterSigma);

%%%%%%
% THE MEANING OF PSF: Number of cells 


% is equal to
% PSF = fspecial('gaussian',intFilterSize/intShrinkFactor,intFilterSigma/intShrinkFactor);



% %% CALCULATE SET OF REFERENCE LCD VALUES
% It would be nice if we could have a reference for approximately how much
% the LCD measurement corresponds to ~number of cells per area...
% 
% let's make a fake data set with equally spaced cells. stepwise increase
% crowding, measure LCD, report LCD of center-most cell.

% % % intMaxTestSize = round(intFilterSigma*3);
% % % matLCDs = NaN(1,intMaxTestSize);
% % % matCellCountPerArea = NaN(1,intMaxTestSize);
% % % matDistances = 1:intMaxTestSize;
% % % 
% % % h = figure();
% % % 
% % % for iDistance = matDistances
% % %     
% % %     matTestMap = zeros(intMaxTestSize*3,intMaxTestSize*3);
% % %     matSteps = 1:iDistance:(intMaxTestSize*3) + floor(iDistance/2);
% % %     
% % %     matTestMap(matSteps,matSteps) = 1;
% % %     
% % %     matSmoothedTestMap = imfilter(matTestMap,PSF,0,'conv');
% % %     
% % %     intRefIX = matSteps(floor(length(matSteps)/2));
% % %     if matTestMap(intRefIX,intRefIX) ==0; error('!!!'); end
% % %     
% % %     matLCDs(iDistance) = matSmoothedTestMap(intRefIX,intRefIX);
% % %     
% % %     % count the number of test cells that are present in (3*sigma)^2 area
% % %     matCellCountPerArea(iDistance) = (length(1:iDistance:intMaxTestSize)^2) / ((intMaxTestSize^2) / sum(PSF(:)));
% % % 
% % %     figure(h)
% % %     
% % %     subplot(2,2,1)
% % %     imagesc(matTestMap)
% % %     subplot(2,2,2)
% % %     imagesc(matSmoothedTestMap)
% % % %     colorbar
% % %     subplot(2,2,3)
% % %     AX = plotyy(matDistances(~isnan(matLCDs)),matLCDs(~isnan(matLCDs)),...
% % %         matDistances(~isnan(matLCDs)),matCellCountPerArea(~isnan(matLCDs)));
% % %     set(get(AX(1),'Ylabel'),'String','local cell density') 
% % %     set(get(AX(2),'Ylabel'),'String',sprintf('cells per (3*sigma)^2 (%d pixels)',intMaxTestSize^2))
% % %     xlabel('pixel distance petween cells')
% % % %     set(AX(1),'YLim',[0 sum(PSF(:))])
% % % %     set(AX(2),'YLim',[0 sum(PSF(:))])
% % %     subplot(2,2,4)
% % %     plot(log10(matLCDs(~isnan(matLCDs))),log10(matCellCountPerArea(~isnan(matLCDs))),'--r');
% % %     xlabel('log_1_0 local cell density')
% % %     ylabel(sprintf('log_1_0 cells per (3*sigma)^2 (%d pixels)',intMaxTestSize^2))
% % % 
% % % end
% % % 
% % % try %#ok<TRYNC>
% % %     gcf2pdf(strrep(strRootPath,'BATCH','POSTANALYSIS'),[mfilename,'_value'],'overwrite')
% % % end
% % % close all


% do resizing of PSF, after calculating the reference LCD values at full
% resolution. I've tested and shrunk LCDs and corresponding cell counts per
% pixel are equal to their full resolution versions.
PSF = imresize(PSF,1/intShrinkFactor);
PSF = PSF - min(PSF(:));
PSF = PSF / max(PSF(:));
intMaxPSFValue = max(PSF(:));
intSingleCellFactor = 1.1;

boolPlotExample = 0;

matRescaledImageSize = ceil((matImageSize - (intImageBorderOverlap/2)) / intShrinkFactor);

for iPos = unique(matWellPositionsPerImage,'rows')'

    fprintf('%s: processing well: row %d, col %d (t=%d)\n',mfilename,iPos(1),iPos(2),iPos(3))
    
    % look up images corresponding to current well
    matImageIX = ismember(matWellPositionsPerImage,iPos','rows');
    
    % old data issue, if last image(s) were empty, they're not added...
    if max(find(matImageIX)) > length(cellNucleiPositions)
        matImageIX(length(cellNucleiPositions)+1:end)=0;
    end        
        
    % get all nuclei positions and meta data for current well
    matNucleiPositions = cat(1,cellNucleiPositions{matImageIX});
    matNucleiMetaData = cat(1,cellNucleiMetaData{matImageIX});
    
    if size(matNucleiPositions,1)==0
        fprintf('%s: skipping well: no cells\n',mfilename)
        continue
    end
    
    % shrink nuclei positions if necessary
    if intShrinkFactor~= 1
        matNucleiPositions = ceil(matNucleiPositions / intShrinkFactor);
    end
    % fix weird bug with nuclei positions of 0
    matNucleiPositions(matNucleiPositions==0)=1;
        
    % create map with dots for each cell
    % perhaps work with dots, gaussian blurred...
    matImageMapWithDots = zeros(ceil(intMaxWelPosY / intShrinkFactor),ceil(intMaxWelPosX / intShrinkFactor));
    for iCell = 1:size(matNucleiPositions,1)
        matImageMapWithDots(matNucleiPositions(iCell,2),matNucleiPositions(iCell,1)) = 1;
    end
   
%     % we might cut off the borders from the image, in case of DG screen
%     % images. This will only work if there's enough cells in the well,
%     % let's say > 8000
%     % cropping vector: [xmin ymin width height]
%     if size(matNucleiPositions,1) > 8000
%         matCropVector = [min(matNucleiPositions,[],1), max(matNucleiPositions,[],1)-min(matNucleiPositions,[],1)];
%         matImageMapWithDots = imcrop(matImageMapWithDots,matCropVector);
% 
%         % we should adjust the matNucleiPositions coordinates after cropping
%         matNucleiPositions(:,1) = matNucleiPositions(:,1) - (min(matNucleiPositions(:,1))-1);
%         matNucleiPositions(:,2) = matNucleiPositions(:,2) - (min(matNucleiPositions(:,2))-1);
%     end
    
%     % check: after cropping each adjusted nuclei position should still be 1
%     for iCell = 1:size(matNucleiPositions,1)
%         if matImageMap(matNucleiPositions(iCell,2),matNucleiPositions(iCell,1))==0
%             disp('NOT GOOD!')
%         end
%     end
    
    % gaussian blur mask. note: mask size determines radius for LCD & EDGE
    % measurement, which is crucial! 150,25 seems to be good for 10x binned
    % HeLa-TDS (in SV40_DG)
    matImageMap = matImageMapWithDots;
    matImageMap = imfilter(matImageMap,PSF,'symmetric','conv');

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EDGE DETECTION %%%%%%%%%%%
    %%% Calculate edges: make binary map, expand dots with sigma from mask,
    %%% look for empty areas (excluding too small empty areas), mark those
    %%% cells bordering empty areas as edge cells.

    % look for empty space
    
    % strategy 1: expand dots, look for edges.
    matImageMapWithEmptySpace = matImageMapWithDots;
    matImageMapWithEmptySpace = bwmorph(matImageMapWithEmptySpace,'thicken',ceil(intFilterSigma/intShrinkFactor));
    matImageMapWithEmptySpace = bwmorph(matImageMapWithEmptySpace,'close');
    matImageMapWithEmptySpace = bwmorph(matImageMapWithEmptySpace,'fill');
    matImageMapWithEmptySpace(:,1) = 1;
    matImageMapWithEmptySpace(:,end) = 1;
    matImageMapWithEmptySpace(1,:) = 1;
    matImageMapWithEmptySpace(end,:) = 1;
    
    
%     % Here we could add the outline of missing images to prevent objects at
%     % the interface of images and missing images to be scored as
%     % edge-object.
%     
%     matImageSitesPresent = unique(intImagePosition(matImageIX,:));
%     if numel(matImageSitesPresent) < max(intImagePosition)
%         % we have missing images...
%         warning('bs:Bla','correcting edge-detection for missing images in well...')
%         matImageSitesMissing = setxor(1:max(intImagePosition),matImageSitesPresent);
%         for iMissing = 1:numel(matImageSitesMissing)
%             matMissingImageIX = matImageSnake(:,matImageSitesMissing(iMissing));
%             matRescaledImageSize * max(matImageSnake(1,:))
%             matRescaledImageSize * max(matImageSnake(2,:))
%             matMissingImageIX
%             matImageMapWithEmptySpace
%         end
% 
%     end
    
    
    
    
    
    matImageMapWithEmptySpace = ~matImageMapWithEmptySpace;
    % alternative: threshold gaussian blur...
%     matImageMapWithEmptySpace = matImageMap < 1; % empty = 1/true
    
    
    %%% remove too small empty space regions
    % first, label all objects
    matEmptySpaceLabelMatrix = bwlabel(matImageMapWithEmptySpace);
    % get area counts per object
    props = regionprops(matEmptySpaceLabelMatrix,'Area');
    matEmptySpaceRegionSize = cat(1,props.Area);
    
    % find too small empty areas, and exclude these (size somehow in
    % relation to mask-size used in image blur)
    matTooSmallEmptyAreasObjectID = find(matEmptySpaceRegionSize < ceil(intFilterSize/intShrinkFactor) );
    % remove too small empty-space-objects
    if ~isempty(matTooSmallEmptyAreasObjectID)
        fprintf('%s: discarding %d too small empty areas\n',mfilename,length(matTooSmallEmptyAreasObjectID))
        matImageMapWithEmptySpace(ismember(matEmptySpaceLabelMatrix,matTooSmallEmptyAreasObjectID)) = 0;
    end
    %%%

%     matImageMapWithEmptySpace = edge_bs(uint8(matImageMapWithEmptySpace),'sobel');
    matImageMapWithEmptySpace = edge_bs(uint8(matImageMapWithEmptySpace));
    
    % find edges of scratch-mask
    [matEmptySpaceEdgeX,matEmptySpaceEdgeY] = find(matImageMapWithEmptySpace);
    
    % create euclidean distance to closest sratch for each cell position
    % (note that for a distance ranking, the sqrt() can be ommitted)
    matIDOfClosestCellPerEdgePixel = NaN(size(matEmptySpaceEdgeX,1),1);
    for iPixel = 1:size(matEmptySpaceEdgeX,1)
        [foo, matIDOfClosestCellPerEdgePixel(iPixel)] = min( sqrt( ...
                (matNucleiPositions(:,1) - matEmptySpaceEdgeY(iPixel)) .^2 + ...
                (matNucleiPositions(:,2) - matEmptySpaceEdgeX(iPixel)) .^2 ...
            ) ); %#ok<ASGLU>
    end
    matEdgePerCell = zeros(size(matNucleiPositions,1),1);
    matEdgePerCell(unique(matIDOfClosestCellPerEdgePixel)) = 1;
    
    
    % calculate the closest distance between each cell and an edge pixel
    matClosestDistanceToEdgePerCell = NaN(size(matNucleiPositions,1),1);
    if ~isempty(matEmptySpaceEdgeY)
        for iCell = 1:size(matNucleiPositions,1)
            matClosestDistanceToEdgePerCell(iCell) = min( sqrt( ...
                    (matEmptySpaceEdgeY - matNucleiPositions(iCell,1)) .^2 + ...
                    (matEmptySpaceEdgeX - matNucleiPositions(iCell,2)) .^2 ...
                ) );
        end    
    else
        % there are no edges in current image, set to max distance
        % possible. (i.e. diagonal on entire image)
        matClosestDistanceToEdgePerCell(:,1) = round(sqrt(intMaxWelPosX^2 + intMaxWelPosY^2));
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate if cells are all alone, if so they are 'single' cells
    % (should we set single cells to not-edge?)
    matLCDsForCurrentCells = arrayfun(@(x,y) matImageMap(x,y),matNucleiPositions(:,2),matNucleiPositions(:,1));    
    matSingleForCurrentCells = matLCDsForCurrentCells<=(intMaxPSFValue*intSingleCellFactor);
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    
    % draw stuff
    if boolPlotExample==0
        
        figure(gcf)
        subplot(2,3,1)
        imagesc(flipud(matImageMap))
        title(sprintf('well: row %d, col %d. shrink = %d',iPos(1),iPos(2),intShrinkFactor));
        subplot(2,3,2)
%         matImageMapWithEdgeCells = uint8(matImageMapWithDots);
%         for iCell = unique(matIDOfClosestCellPerEdgePixel)'
%             matImageMapWithEdgeCells(matNucleiPositions(iCell,2),matNucleiPositions(iCell,1)) = 2;
%         end            
%         imagesc(matImageMapWithEdgeCells)
        scatter(matNucleiPositions(:,1),matNucleiPositions(:,2),15,matEdgePerCell,'Marker','*')
        axis tight
        title(sprintf('Edge Cells (%d%%)',round(mean(matEdgePerCell)*100)))

        subplot(2,3,3)
%         matImageMapWithEdgeCells = uint8(matImageMapWithDots);
%         for iCell = 1:size(matNucleiPositions,1)
%             matImageMapWithEdgeCells(matNucleiPositions(iCell,2),matNucleiPositions(iCell,1)) = matClosestDistanceToEdgePerCell(iCell);
%         end
%         imagesc(matImageMapWithEdgeCells)
        scatter(matNucleiPositions(:,1),matNucleiPositions(:,2),15,matClosestDistanceToEdgePerCell,'Marker','*')
        axis tight
        title('Minimal distance to edge')

        subplot(2,3,4)
        scatter(matNucleiPositions(:,1),matNucleiPositions(:,2),15,matSingleForCurrentCells,'Marker','*')
        axis tight
        title('Single/lonely cells')
        
        subplot(2,3,5)
        hist(matLCDsForCurrentCells)
        title('LCD histogram')    

        
        subplot(2,3,6)
        imagesc(flipud(matComplete2DBinCount))
        title('plate total')
        
        %subplot(2,3,6)
        %imagesc(PSF,[0 1])
        %title('PSF')
        %drawnow
        
     
        if boolPlotExample==0
            try %#ok<TRYNC>
                gcf2pdf(strrep(strRootPath,'BATCH','POSTANALYSIS'),[mfilename,'_example'],'overwrite')
            end
            close all
            figure();            
        end        
        
        boolPlotExample=1;
        
        drawnow
    end          
        
        
    % now store the calculated LCD, EDGE, Distance2Edge values, per
    % original image-index and object-index.
    for iImage = unique(matNucleiMetaData(:,1))'
        matImageIX = ismember(matNucleiMetaData(:,1),iImage);
        matObjectIX = matNucleiMetaData(matImageIX,2);
        % store LCD per object, from image
        cellMeasurement_Nuclei_LocalCellDensity{iImage}(matObjectIX) = ...
            arrayfun(@(x,y) matImageMap(x,y),matNucleiPositions(matImageIX,2),matNucleiPositions(matImageIX,1));
        
        % store if a cell is all alone
        cellMeasurement_Nuclei_Single{iImage}(matObjectIX) = cellMeasurement_Nuclei_LocalCellDensity{iImage}(matObjectIX)<=(intMaxPSFValue*intSingleCellFactor);
        
        % store EDGE per object 
        cellMeasurement_Nuclei_Edge{iImage}(matObjectIX) = matEdgePerCell(matImageIX);
        cellMeasurement_Nuclei_DistanceToEdge{iImage}(matObjectIX) = matClosestDistanceToEdgePerCell(matImageIX);
    end
    
end

if nargin~=0

    % store LCD output
    strMeasurementFile = fullfile(strRootPath,'Measurements_Nuclei_LocalCellDensity.mat');
    Measurements = struct();
    Measurements.Nuclei.LocalCellDensity = cellMeasurement_Nuclei_LocalCellDensity;
    Measurements.Nuclei.LocalCellDensityFeatures = {sprintf('LCD_Border%d_Size%d_Sigma%d_Shrink%d_TotPSF%d',intImageBorderOverlap,intFilterSize,intFilterSigma,intShrinkFactor,round(sum(PSF(:))))};

    save(strMeasurementFile, 'Measurements')
    fprintf('%s: stored LCD measurement in %s\n',mfilename,strMeasurementFile)

    % store EDGE output
    strMeasurementFile = fullfile(strRootPath,'Measurements_Nuclei_Edge.mat');
    Measurements = struct();
    Measurements.Nuclei.Edge = cellMeasurement_Nuclei_Edge;
    Measurements.Nuclei.EdgeFeatures = {sprintf('LCD_Border%d_Size%d_Sigma%d_Shrink%d_TotPSF%d',intImageBorderOverlap,intFilterSize,intFilterSigma,intShrinkFactor,round(sum(PSF(:))))};

    save(strMeasurementFile, 'Measurements')
    fprintf('%s: stored EDGE measurement in %s\n',mfilename,strMeasurementFile)

    % store DISTANCE-2-EDGE output
    strMeasurementFile = fullfile(strRootPath,'Measurements_Nuclei_DistanceToEdge.mat');
    Measurements = struct();
    Measurements.Nuclei.DistanceToEdge = cellMeasurement_Nuclei_DistanceToEdge;
    Measurements.Nuclei.DistanceToEdgeFeatures = {sprintf('LCD_Border%d_Size%d_Sigma%d_Shrink%d_TotPSF%d',intImageBorderOverlap,intFilterSize,intFilterSigma,intShrinkFactor,round(sum(PSF(:))))};

    save(strMeasurementFile, 'Measurements')
    fprintf('%s: stored Distance2Edge measurement in %s\n',mfilename,strMeasurementFile)

    
    % store SINGLE CELL output
    strMeasurementFile = fullfile(strRootPath,'Measurements_Nuclei_SingleCell.mat');
    Measurements = struct();
    Measurements.Nuclei.SingleCell = cellMeasurement_Nuclei_Single;
    Measurements.Nuclei.SingleCellFeatures = {sprintf('LCD_Border%d_Size%d_Sigma%d_Shrink%d_TotPSF%d',intImageBorderOverlap,intFilterSize,intFilterSigma,intShrinkFactor,round(sum(PSF(:))))};

    save(strMeasurementFile, 'Measurements')
    fprintf('%s: stored SingleCell measurement in %s\n',mfilename,strMeasurementFile)    
    
end

close all

end