function merge_jpgs_per_plate(strJpgPath, strSearchString)

    if nargin == 0
%         strJpgPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Lilli\adhesome_screen_data\080214_Lilli_A431cavgfp_ChT_phal_screen_CP074-1aa\JPG\';
%         strJpgPath = npc('\\nas-biol-imsb-1\share-3-$\Data\Users\Berend\081015_MD_HDMECS_Tfn_pFAK\JPG\');
        strJpgPath = npc('Z:\Data\Users\Berend\50K_FollowUps\SFV-3\2010-11-21\JPG2');
    end
    
    if nargin<=1
        strSearchString = '*.jpg';
    end

    fprintf('%s: processing %s\n',mfilename,strJpgPath)
    fprintf('%s: looking for %s\n',mfilename,strSearchString)
    
    matRows = cellstr(regexp(char(65:80),'\w','match'));
    matCols = regexp(sprintf('%.2d',1:24),'\d\d','match');

    if nargin<=1
        cellJPGs = SearchTargetFolders(strJpgPath,strSearchString);        
    else
        cellJPGs = SearchTargetFolders(strJpgPath,['*',strSearchString,'*']);        
    end

    
    fprintf('%s: found %d matching files\n',mfilename,length(cellJPGs))
    
    if isempty(cellJPGs)
        return
    end
    
    [matRowsPresent, matColumnsPresent] = cellfun(@filterimagenamedata,getlastdir(cellJPGs),'UniformOutput',1);

    if (nanmax(matRowsPresent) <= 8) & (nanmax(matColumnsPresent) <= 12)
        matRowsToProcess = 1:8;
        matColumnsToProcess = 1:12;
        intResizefactor = 0.2;
    else
        [imwidth,imheight] = size(imread(cellJPGs{1}));
        % jpg dependent resizing seems smart...
        if imwidth < 1000
            intResizefactor = 0.4;
        else
           intResizefactor = 0.1; 
        end
        matRowsToProcess = 1:16;
        matColumnsToProcess = 1:24;        
    end    
    
    

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

            % let's add white lines...
            matPlateImage(:,(colNum-1)*matImageSize(2)+1,:) = Inf(size(matPlateImage,1),1,size(matPlateImage,3));
            matPlateImage((rowNum-1)*matImageSize(1)+1,:,:) = Inf(1,size(matPlateImage,2),size(matPlateImage,3));            
        end
    end

    %%% Here we can add text-labels per well, A01, A02... P24
    % do imshow(matPlateImage)
    % place text() for well labels
    % x = getframe and get x.cdata, store that as jpg
    % see also merge_jpgs_per_gene
    
    
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
    
    if nargin < 2
        strfilename = strcat(strCurrentObject,'_PlateOverview.jpg');
    else
        strfilename = strcat(strCurrentObject,sprintf('_PlateOverview_%s.jpg',strSearchString));
%         fileCounter = 0;
%         if fileattrib(fullfile(strJpgPath,strfilename))
%             while fileattrib(fullfile(strJpgPath,strfilename))
%                 fileCounter = fileCounter +1;
%                 strfilename = strcat(strCurrentObject,sprintf('_PlateOverview_%d.jpg',fileCounter));
%             end
%         end
    end
        
    disp(sprintf('storing %s',fullfile(strJpgPath,strfilename)))    
    imwrite(matPlateImage,fullfile(strJpgPath,strfilename),'jpg','Quality',95);

end