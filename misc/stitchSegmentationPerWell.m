function stitchSegmentationPerWell(strRootPath)

    % ok, let's redo the basis for: 
    %
    % 1) stitching segmentation images back to whole wells, 
    % 2) having unique identifiers for each object, stored as measurement
    % 3) and be able to color code the objects by any measurement value
    %
    % on top of this, we want to also:
    %
    % 4) redo edge & density detection on whole wells
    % 5) visualize safia/scratch analysis (including scratch outline)
    % 
    %%%%%%%%%

    if nargin==0 %|| ~exist('strRootPath','var')

        strRootPath = npc('\\nas-biol-ibt-1.d.ethz.ch\share-images-1-$\thaminys\exp38-44\74exp-R2\BATCH\');

    end

    strRootPath = npc(strRootPath);

    strSegmentationPath = strrep(strRootPath,'BATCH','SEGMENTATION');

    strOutputPath = strrep(strRootPath,'BATCH','SEGMENTATION_WELL');

    % shrink factor of 1 means no resizing...
    intSchrinkFactor = 1;

    %%%%%%%%%

    % if no SEGMENTATION directory exist, stop and say you're done.
    if ~fileattrib(strSegmentationPath)
        fprintf('%s: segmentation directory ''%s'' does not exists. My job is done here :)\n',mfilename,strSegmentationPath)
        return
    end
    
    % if output directory does not exist, create it
    if ~fileattrib(strOutputPath)
        mkdir(strOutputPath)
    end

    fprintf('%s: looking for segmentation files in %s\n',mfilename,strSegmentationPath)
    % list segmentation files
    strucSegmentationFileList = CPdir(strSegmentationPath);
    strucSegmentationFileList(cat(1,strucSegmentationFileList.isdir)) = [];
    cellCompleteSegmentationFileList = {strucSegmentationFileList.name};
    clear strucSegmentationFileList

    % get rid of non "_Segmented" files
    matOKSegIX = cellfun(@(x) ~isempty(findstr(x,'_Segmented')), cellCompleteSegmentationFileList);
    cellCompleteSegmentationFileList(~matOKSegIX) = [];

    
    % we could do stitching for all segmentations stored...
    cellObjectNames = regexpi(cellCompleteSegmentationFileList,'.*_Segmented(.*)\.png','tokens');
    cellObjectNames = cellfun(@(x) x{1}, cellObjectNames);
    
    cellUniqueObjectNames = unique(cellObjectNames);
    
    fprintf('%s: the following %d object segmentations were found\n',mfilename,length(cellUniqueObjectNames))
    for i = 1:length(cellUniqueObjectNames)
        fprintf('%s: \t %s\n',mfilename,cellUniqueObjectNames{i})
    end
    

    % get image size
    objImInfo = imfinfo(fullfile(strSegmentationPath,cellCompleteSegmentationFileList{1}));
    matImageSize = [objImInfo.Height,objImInfo.Width] / intSchrinkFactor;

    % load original object count to ensure that new measurement has exact same
    % dimensions...
    handlesOrig = LoadMeasurements(struct(),fullfile(strRootPath,'Measurements_Image_ObjectCount.mat'));
    handlesOrig = LoadMeasurements(handlesOrig,fullfile(strRootPath,'Measurements_Image_FileNames.mat'));
    
    % do the following for each object for which segmentation is present
    for iObj = 1:length(cellUniqueObjectNames)
        
        % set object name to current processab;e object... (do all objects
        % have an object count?!?!)
        strObjectName = char(cellUniqueObjectNames{iObj});
    
        % get rid of non ["_Segmented",strObjectCount,".png"] files, i.e.
        % make a segmentation list for only the current object.
        cellSegmentationFileList = cellCompleteSegmentationFileList;
        matOKSegIX = cellfun(@(x) ~isempty(findstr(x,['_Segmented',strObjectName,'.png'])), cellCompleteSegmentationFileList);
        cellSegmentationFileList(~matOKSegIX) = [];
    

        fprintf('%s: parsing segmentation files for ''%s''\n',mfilename,strObjectName)
        % parse segmentation image metadata (position, etc)
        [matRowIX, matColumnIX] = cellfun(@filterimagenamedata,  cellSegmentationFileList);
        matWellPositionData = [matRowIX', matColumnIX'];
        matImagePosition = cellfun(@check_image_position,  cellSegmentationFileList);
        [foo,strMicroscopeType]=check_image_position(cellSegmentationFileList{1});
        clear foo
        
        % unfortunately, safia does a non-standard 5x6 setup... competing
        % with prisca's 5x6 setup. sucks. perhaps there's a way to find out
        % which is which?
        if ~isempty(strfind(strRootPath,'thaminys'))
            [matImageSnake,matStitchDimensions] = get_image_snake_safia(max(matImagePosition),strMicroscopeType);
        else
            [matImageSnake,matStitchDimensions] = get_image_snake(max(matImagePosition),strMicroscopeType);
        end

        % get all unique well positions
        matUniqueWellPositionData = unique(matWellPositionData,'rows')';
        
        matObjectCountIX = strcmp(handlesOrig.Measurements.Image.ObjectCountFeatures,strObjectName);
        matObjectCount = cat(1,handlesOrig.Measurements.Image.ObjectCount{:});
        matObjectCount = matObjectCount(:,matObjectCountIX);

        % we need a mapping between original file names order in measurements, and
        % the segmentation file name
        cellOriginalFileNames = cat(1,handlesOrig.Measurements.Image.FileNames{:});
        cellOriginalFileNames = cellOriginalFileNames(:,1);
        [foo,matOrigImageIX]=ismember(strrep(cellSegmentationFileList,['_Segmented',strObjectName,'.png'],'')',strrep(strrep(cellOriginalFileNames,'.tif',''),'.png',''));
        clear foo

        % init new measurement as NaNs with exactly right dimensions
        handles = struct();
        handles.Measurements.(strObjectName).StitchedWellObjectIds = cellfun(@(x) NaN(x(1,matObjectCountIX),1),handlesOrig.Measurements.Image.ObjectCount,'UniformOutput',false);

        fprintf('%s: starting stitching of well segmentation for %d wells\n',mfilename,size(matUniqueWellPositionData,2))
        % loop over each well present, merge segmentation images into well view,
        % recalculate new well-unique object identifiers
        for iPos = matUniqueWellPositionData

            rowNum = iPos(1,1);
            colNum = iPos(2,1);

            matAllFileNameMatchIndices = ismember(matWellPositionData,iPos','rows');

            fprintf('%s: \t stitching %d images for row %d column %d\n',mfilename,sum(matAllFileNameMatchIndices),iPos(1),iPos(2))

            matStitchedSegmentationImage = zeros(round(matImageSize(1,1)*matStitchDimensions(1)),round(matImageSize(1,2)*matStitchDimensions(2)),1, 'uint16');

            for iImage = find(matAllFileNameMatchIndices)';

                % get image coordinates in stitched image
                xPos=(matImageSnake(1,matImagePosition(iImage))*matImageSize(1,2))+1:((matImageSnake(1,matImagePosition(iImage))+1)*matImageSize(1,2));
                yPos=(matImageSnake(2,matImagePosition(iImage))*matImageSize(1,1))+1:((matImageSnake(2,matImagePosition(iImage))+1)*matImageSize(1,1));

                % read in original image
                matCurrentImage = imread(fullfile(strSegmentationPath,cellSegmentationFileList{iImage}));

                % resize original image
                if intSchrinkFactor~=1
                    matCurrentImage = imresize(matCurrentImage,(1/intSchrinkFactor),'nearest');
                end

                % relabel original image (incremental, starting with maximum
                % object-id of previous combined images) 

                intObjectIDOffset = max(matStitchedSegmentationImage(:));

                % mapping of current segmentation image to original cellprofiler
                % image name
                iOrigImage = matOrigImageIX(iImage);        

                % store new object identifiers as measurement
                matOriginalObjectIDs = unique(matCurrentImage(matCurrentImage>0));
                handles.Measurements.(strObjectName).StitchedWellObjectIds{iOrigImage}(matOriginalObjectIDs) = matOriginalObjectIDs + intObjectIDOffset;

                % relabel image to new object identifiers
                matCurrentImage(matCurrentImage>0) = matCurrentImage(matCurrentImage>0) + intObjectIDOffset;

                % put original image in stitch
                matStitchedSegmentationImage(yPos,xPos) = matCurrentImage;
            end

            % store stitched image segmentation
            strFileName = sprintf('Well_%s%02d_Segmented%s.png',char(64+iPos(1)),iPos(2),strObjectName);
            fprintf('%s: \t storing %s\n',mfilename,strFileName)
            imwrite(matStitchedSegmentationImage,fullfile(strOutputPath,strFileName),'png');

        end

        % store stitched image segmentation object identifiers
        fprintf('%s: storing %s\n',mfilename,['Measurements_',strObjectName,'_StitchedWellObjectIds.mat'])
        save(fullfile(strRootPath,['Measurements_',strObjectName,'_StitchedWellObjectIds.mat']),'handles');
    
    end % loop over found object names

end