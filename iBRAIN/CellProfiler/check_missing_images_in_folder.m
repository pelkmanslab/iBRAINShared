function check_missing_images_in_folder(strRootPath)

    if nargin == 0
%         strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Karin\HSV1\20080826195329_M2_080826_384_CB_CNX_HSV1_rescan\TIFF';
%         strRootPath = '/BIOL/imsb/fs3/bio3/bio3/Data/Users/HSV1_DG/DG_384_HSV1_100216_CP037_1ef/TIFF';
        strRootPath = 'http://www.ibrain.ethz.ch/share-2/Data/Users/mRNAmes/iBrain/111128-KIM2-Mov02-30min/TIFF';
        
        strRootPath = npc(strRootPath);
    end

    fprintf('%s: checking %s\n',mfilename,strRootPath);
    % list all files in TIFF directory
    cellFileNames = CPdir(strRootPath);
    % remove directories and make cellarray
    cellFileNames = {cellFileNames(~[cellFileNames.isdir]).name};
    
    % let's see if there are previously renamed files in here, and rename
    % them back, just incase the names have changed.
    matPreviouslyRenamedFileIX = find(~cellfun(@isempty,regexpi(cellFileNames,'^.*(\._png|\._tif)$')));
    if ~isempty(matPreviouslyRenamedFileIX)
        fprintf('%s: found %d previously renamed files, renaming them back\n',mfilename,length(matPreviouslyRenamedFileIX));
        for jX = matPreviouslyRenamedFileIX
            strOldFileName = cellFileNames{jX};
            strNewFileName = strrep(strOldFileName,'._png','.png');
            strNewFileName = strrep(strNewFileName,'._tif','.tif');
            fprintf('%s: \t renaming ''%s'' to ''%s''\n!',mfilename,strOldFileName,strNewFileName);
            cellFileNames{jX} = strNewFileName;
            movefile(fullfile(strRootPath,strOldFileName),fullfile(strRootPath,strNewFileName))
        end            
    end
        
    
    % remove non-tif/png files
    cellFileNames(cellfun(@isempty,regexpi(cellFileNames,'^.*(\.png|\.tif)$'))) = [];
    
    % parse file names
    [matRow, matColumn, ~, matTimePoints] = cellfun(@filterimagenamedata,cellFileNames,'UniformOutput',false);
    matRow = cell2mat(matRow);
    matColumn = cell2mat(matColumn);
    matTimePoints = cell2mat(matTimePoints);
    [matImageChannel] = cellfun(@check_image_channel,cellFileNames,'UniformOutput',true);
    [matImagePosition] = cellfun(@check_image_position,cellFileNames,'UniformOutput',true);
    
    % get number of images per well
    matWellData = [matRow;matColumn;matTimePoints];
    [iPos,m,n] = unique(matWellData','rows');
    matPlateImagesPerWell = zeros(16,24,max(matTimePoints));
    matPlateImagesPerWell(sub2ind([16,24,max(matTimePoints)],iPos(:,1),iPos(:,2),iPos(:,3))) = countNumberOfValues(n);
    fprintf('%s: number of images per well (and timepoint) is as follows:\n\n',mfilename);
    disp(matPlateImagesPerWell)
    fprintf('\n');
    
    
    % get number of images per image set (i.e. with the same well-row,
    % well-col, image-position, time point) 
    matWellAndPositionData = [matRow;matColumn;matImagePosition;matTimePoints];
    [iPos,m,n] = unique(matWellAndPositionData','rows');
    
    matNumberOfImagesPerWellPosition = countNumberOfValues(n);
    if length(unique(matNumberOfImagesPerWellPosition))>1

        fprintf('%s: found differences in number of images per image set!\n',mfilename);
        
        % everything is not ok!
        intExpectedNumberOfImage = max(matNumberOfImagesPerWellPosition);
        fprintf('%s: expecting %d images (channels) per image set\n',mfilename,intExpectedNumberOfImage);

        % find image-sets with abberant number of images
        iX = find(matNumberOfImagesPerWellPosition ~= intExpectedNumberOfImage);

        % find the image sets (well row, column and position) that are
        % corrupt
        fprintf('%s: found %d image-sets that do not have the expected %d images!\n',mfilename,length(iX),intExpectedNumberOfImage);

        % if there are not too many incomplete image sets (less than 2.5%
        % of all image sets, and less that 20 in total)
        if (length(iX) / length(cellFileNames) < 0.05) && (length(iX) < 40)
            fprintf('%s: renaming incomplete image-sets\n',mfilename);
            for iXX = iX'
                matSetIX = ismember(matWellAndPositionData',iPos(iXX,:),'rows');
                if ~any(matSetIX)
                    fprintf('%s: \t strange, no match found for well row=%d, col=%d, site=%d, timepoint=%d!\n',mfilename,iPos(iXX,1),iPos(iXX,2),iPos(iXX,3),iPos(iXX,4));
                end
                for jX = find(matSetIX)
                    strOldFileName = cellFileNames{jX};
                    strNewFileName = strrep(strOldFileName,'.png','._png');
                    strNewFileName = strrep(strNewFileName,'.tif','._tif');
                    fprintf('%s: \t renaming ''%s'' to ''%s''\n!',mfilename,strOldFileName,strNewFileName);
                    try
                        movefile(fullfile(strRootPath,strOldFileName),fullfile(strRootPath,strNewFileName))
                    catch objFoo
                        fprintf('%s: \t\t renaming FAILED: ''%s''\n!',mfilename,objFoo.message);
                    end
                end
            end
        else
            fprintf('%s: too many abberant image-sets found! not doing anything, let CellProfiler crash :)\n',mfilename);
        end
    else
        
        % everything is ok, all image sets have equal number of images per
        % set
        fprintf('%s: dataset looks complete\n',mfilename);
        return
    end
    
    
    %%% If we get here, we want to do a double check, see if everything is
    %%% cool now
    % list all files in TIFF directory
    cellFileNames = CPdir(strRootPath);
    % remove directories and make cellarray
    cellFileNames = {cellFileNames(~[cellFileNames.isdir]).name};
    % remove non-tif/png files
    cellFileNames(cellfun(@isempty,regexpi(cellFileNames,'^.*(\.png|\.tif)$'))) = [];
    
    % parse file names
    [matRow, matColumn, ~, matTimePoints] = cellfun(@filterimagenamedata,cellFileNames,'UniformOutput',false);
    matRow = cell2mat(matRow);
    matColumn = cell2mat(matColumn);
    matTimePoints = cell2mat(matTimePoints);    
    [matImageChannel] = cellfun(@check_image_channel,cellFileNames,'UniformOutput',true);
    [matImagePosition] = cellfun(@check_image_position,cellFileNames,'UniformOutput',true);

    % get number of images per well
    matWellData = [matRow;matColumn;matTimePoints];
    [iPos,m,n] = unique(matWellData','rows');
    matPlateImagesPerWell = zeros(16,24,max(matTimePoints));
    matPlateImagesPerWell(sub2ind([16,24,max(matTimePoints)],iPos(:,1),iPos(:,2),iPos(:,3))) = countNumberOfValues(n);
    fprintf('%s: number of images per well (and timepoint) is as follows:\n\n',mfilename);
    disp(matPlateImagesPerWell)
    fprintf('\n');   
    
%     matUniqueImageNumbers = unique(matPlateImagesPerWell);
% 
%     
%     boolAlert = 0;
%     for i = matUniqueImageNumbers'
%         if (i > 0) && (i < max(matPlateImagesPerWell(:)))
%             [row,col] = find(matPlateImagesPerWell == i);
%             for ii = 1:length(row)
%                 boolAlert = 1;
%                 disp(sprintf('%s: WARNING well %s%s has only %d images',mfilename,char(matRowLetters(row(ii))),char(matColLetters(col(ii))),i))
%             end
%         end
%     end
% 
%     if boolAlert
%         disp(sprintf('\n%s: Number of images per well is as follows. Expecting %d images per well',mfilename,max(matPlateImagesPerWell(:))))
%         matPlateImagesPerWell
%     else
%         disp(sprintf('%s: Dataset looks OK: %d images',mfilename,length(cellFileNames)))        
%     end


end