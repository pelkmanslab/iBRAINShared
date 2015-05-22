function CropBDImages(strRootPath)

if nargin == 0
%     strRootPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\HPV16_DG\2008-08-21_HPV16_batch3_CP070-1eb\';
    strRootPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\HPV16_DG\2008-10-16_HPV16_batch2_CP030-1eb\';
end

strOutputPath = fullfile(strRootPath,'TIFF');

if ~fileattrib(strOutputPath) && fileattrib(getbasedir(strRootPath))
    disp(sprintf('Creating TIFF directory in %s',strRootPath))
    mkdir(strOutputPath)
    if ~fileattrib(strOutputPath)
        error('Failed to create TIFF directory!')
    end
end

strPlateBase = getlastdir(strRootPath);

cellTargetFolderList = SearchTargetFolders(strRootPath,'Dapi* - n000000.tif');
cellTargetFolderList = getbasedir(cellTargetFolderList);
intNumOfFolders = size(cellTargetFolderList,1);

intNumOfRows=3;
intNumOfCols=3;

matCellWorxImageNumbers = [7,8,9,6,5,4,1,2,3];

for i = 1:intNumOfFolders
    
    strTargetDirectory = cellTargetFolderList{i};    
    cellTargetImages = SearchTargetFolders(strTargetDirectory,'* - n000000.tif');
    
    intNumOfImages = size(cellTargetImages,1);
    for ii = 1:intNumOfImages
        strTargetImage = cellTargetImages{ii};
        disp(sprintf('PROCESSING %s',strTargetImage))
        matOrigImage = imread(strTargetImage);
        [intHeight,intWidth]=size(matOrigImage);
        intColStep = intWidth/intNumOfCols;
        intRowStep = intHeight/intNumOfRows;        
        intSubImageIndex=0;
        for iRow = 0:intNumOfRows-1
            for iCol = 0:intNumOfCols-1
                intSubImageIndex = intSubImageIndex + 1;

                [intRow, intColumn, strWellName] = filterimagenamedata(strTargetImage);
                intChannelNumber = check_image_channel(strTargetImage);
                intPositionNumber = check_image_position(strTargetImage);
                strImageNumber = sprintf('_%d',matCellWorxImageNumbers(intSubImageIndex));

                strChannelNumber = '';
                if ~isempty(findstr(upper(strTargetImage),'DAPI'))
                    strChannelNumber = '_w460';
                elseif ~isempty(findstr(upper(strTargetImage),'GFP'))
                    strChannelNumber = '_w530';                    
                elseif ~isempty(findstr(upper(strTargetImage),'FITC'))
                    strChannelNumber = '_w530';
                end

                %%% example 20071203_FLU3V_DG_batch1_CP0163-1aa_A01_2_w530.tif
                strOutputFileName = fullfile(strOutputPath,[strPlateBase,'_',strWellName,strImageNumber,strChannelNumber,'.png']);
                if ~fileattrib(strOutputFileName)
                    disp(sprintf('  STORING %s (%s)',strOutputFileName,class(matOrigImage)))
                    matRowIndices = 1+(intRowStep * iRow):(intRowStep * (iRow+1));
        %                 disp(sprintf('    rows from %d to %d (length = %d)',min(matRowIndices),max(matRowIndices),length(matRowIndices)))
                    matColIndices = 1+(intColStep * iCol):(intColStep * (iCol+1));
        %                 disp(sprintf('    cols from %d to %d (length = %d)',min(matColIndices),max(matColIndices),length(matColIndices)))                

                    imwrite(matOrigImage(matRowIndices,matColIndices),strOutputFileName,'png');
                else
                    disp(sprintf('  SKIPPING %s (%s), ALREADY PRESENT',strOutputFileName,class(matOrigImage)))                    
                     
                end
            end
        end
    end
end