function merge_bmps_per_plate(strJpgPath)

    if nargin == 0
%         strJpgPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Lilli\adhesome_screen_data\080214_Lilli_A431cavgfp_ChT_phal_screen_CP074-1aa\JPG\';
        if ispc
            strJpgPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Berend\Philip\Tfn_MZ\philip_071006_Tfn_MZ_AWaa\JPG2\';
        elseif ismac
            strJpgPath = '/Volumes/share-2-$/Data/Users/Berend/Philip/Tfn_MZ/philip_071006_Tfn_MZ_AWaa/JPG2/';        
        end
    end

    matRows = cellstr(regexp(char(65:80),'\w','match'));
    matCols = regexp(sprintf('%.2d',1:24),'\d\d','match');

    cellJPGs = SearchTargetFolders(strJpgPath,'*.bmp');

    [matRowsPresent, matColumnsPresent] = cellfun(@filterimagenamedata,getlastdir(cellJPGs),'UniformOutput',1);

    if (max(matRowsPresent) <= 8) && (max(matColumnsPresent) <= 12)
        matRowsToProcess = 1:8;
        matColumnsToProcess = 1:12;
    else
        matRowsToProcess = 1:16;
        matColumnsToProcess = 1:24;        
    end
    
    
    
    intResizefactor = 0.2;

    matWellImage = imread(cellJPGs{1});
    matWellImage = imresize(matWellImage,intResizefactor);
    matImageSize = size(matWellImage);

    matPlateImage = zeros(matImageSize(1)*max(matRowsToProcess),matImageSize(2)*max(matColumnsToProcess),3,'uint8');

    for rowNum = matRowsToProcess
        for colNum = matColumnsToProcess
            str2match = strcat('_',matRows{rowNum}, matCols{colNum});        
            FileNameMatches = strfind(cellJPGs, char(str2match));
            matFileNameMatchIndices = find(~cellfun('isempty',FileNameMatches));

            if ~isempty(matFileNameMatchIndices)
                disp(sprintf('processing %s',cellJPGs{matFileNameMatchIndices(1)}))                
                matWellImage = imread(cellJPGs{matFileNameMatchIndices(1)});
                matWellImage = imresize(matWellImage,intResizefactor);
                matImageSize = size(matWellImage);
                matPlateImage((rowNum-1)*matImageSize(1)+1:(rowNum)*matImageSize(1), (colNum-1)*matImageSize(2)+1:(colNum)*matImageSize(2),:) = matWellImage;
            end
            
        end
    end

    try
        strLeftOver = strJpgPath;
        while 1
            strCurrentObject = getlastdir(strLeftOver);        
            if isempty(strfind(strCurrentObject,'JPG')) && ... 
                    isempty(strfind(strCurrentObject,'BATCH')) && ... 
                    isempty(strfind(strCurrentObject,'POSTANALYSIS')) && ...                     
                    isempty(strfind(strCurrentObject,'TIFF'))
                break
            end
            strLeftOver = getbasedir(strLeftOver);        
        end        
    catch
        strLeftOver = strJpgPath;
        strLeftOver = strrep(strLeftOver,[filesep,'JPG'],'');
        strCurrentObject = getlastdir(strLeftOver);
    end

    strfilename = strcat(strCurrentObject,'_PlateOverview.bmp');
    disp(sprintf('storing %s',fullfile(strJpgPath,strfilename)))    
    imwrite(matPlateImage,fullfile(strJpgPath,strfilename),'bmp');
end