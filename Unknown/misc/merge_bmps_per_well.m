% strTiffPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Berend\Philip\Tfn_MZ2\philip_071006_Tfn_MZ_AWaa\COLORCODED_JPGS_ALL_CELLS';
% strOutputPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Berend\Philip\Tfn_MZ2\philip_071006_Tfn_MZ_AWaa\COLORCODED_JPGS_PER_WELL_ALL_CELLS';        

strTiffPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Berend\Philip\Tfn_MZ2\philip_071006_Tfn_MZ_AWaa_ALL_CELLS\COLORCODED_JPGS_ALL_CELLS2';
strOutputPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Berend\Philip\Tfn_MZ2\philip_071006_Tfn_MZ_AWaa_ALL_CELLS\COLORCODED_JPGS_PER_WELL_ALL_CELLS2';


    dircoutput=dir(sprintf('%s%s*_ACTIVITY_hot.bmp',strTiffPath,filesep));
    dircoutput=struct2cell(dircoutput);
    dircoutput=dircoutput';
    item_isdir=cell2mat(dircoutput(:,4));
    cellAllFileNames=dircoutput(~item_isdir,1);

    rowstodo = 2;
    colstodo = [1,4];

%     rowstodo = 1:8;
%     colstodo = 1:12;
    
    matRows = cellstr(regexp(char(65:80),'\w','match'));
    matCols = regexp(sprintf('%.2d',1:24),'\d\d','match');

%     matImageSnake = [0,1,2,2,1,0,0,1,2;2,2,2,1,1,1,0,0,0];
%     matStitchDimensions = [3,3];

    matImageSnake = [0,1,2,3,4,4,3,2,1,0,0,1,2,3,4,4,3,2,1,0,0,1,2,3,4;...
                     4,4,4,4,4,3,3,3,3,3,2,2,2,2,2,1,1,1,1,1,0,0,0,0,0];
    matStitchDimensions = [5,5];
    
    matImageSize = size(imread(fullfile(strTiffPath,cellAllFileNames{1})));
    
    for rowNum = rowstodo
        for colNum = colstodo

            %%% CHECK IF THERE ARE ANY MATCHING IMAGES FOR THIS WELL...
            str2match = strcat('_',matRows(rowNum), matCols(colNum),'_');
            FileNameMatches = strfind(cellAllFileNames, char(str2match));
            matAllFileNameMatchIndices = find(~cellfun('isempty',FileNameMatches));

            strFileSuffix = '';
            
            if not(isempty(matAllFileNameMatchIndices))    
                Overlay = zeros(round(matImageSize(1,1)*matStitchDimensions(1)),round(matImageSize(1,2)*matStitchDimensions(2)),3, 'uint8');                
                intImageCount = 0;


                str2match = strcat('_',matRows(rowNum), matCols(colNum));
                FileNameMatches = strfind(cellAllFileNames, char(str2match));
                matFileNameMatchIndices = find(~cellfun('isempty',FileNameMatches));
                
                for k = matFileNameMatchIndices'
                    
                    strImageName = cellAllFileNames{k};
%                     strImagePosition = regexpi(strImageName,'_\w\d\df(\d)d0_','tokens');
%                     strImagePosition = str2double(strImagePosition{1})+1;
                    strImagePosition = regexpi(strImageName,'_\w\d\d_(\d\d)_w','tokens');
                    strImagePosition = str2double(strImagePosition{1});

                    xPos=(matImageSnake(1,strImagePosition)*matImageSize(1,2))+1:((matImageSnake(1,strImagePosition)+1)*matImageSize(1,2));
                    yPos=(matImageSnake(2,strImagePosition)*matImageSize(1,1))+1:((matImageSnake(2,strImagePosition)+1)*matImageSize(1,1));

                    matImage = uint8(imread(fullfile(strTiffPath,strImageName)));
                    intImageCount = intImageCount + 1;

                    Overlay(yPos,xPos,:) = matImage;
                end
                
                
                strProjectName = strrep(strImageName,'.bmp','');
                strfilename = [strProjectName,char(str2match),'_WELL.jpg'];
                if intImageCount > 0
                    disp(sprintf('  storing %s',strfilename))                
                    imwrite(Overlay,fullfile(strOutputPath,strfilename),'jpg','Quality',95);
%                     imwrite(Overlay,fullfile(strOutputPath,strfilename),'bmp');                            
                else
                    disp(sprintf('  NOT storing %s',strfilename))                
                end
                drawnow
                
            end
        end
    end      
