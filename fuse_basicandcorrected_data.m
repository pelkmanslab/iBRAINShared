function fuse_basicandcorrected_data(strRootPath, BASICCORRECTEDDATA)
% BASICCORRECTED: adds adding together the Probmodel_Tensor files.

  warning off all;

    
    global BASICCORRECTEDDATA
    
    if nargin == 0
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\VV_DG\';
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Raphael\070611_Tfn_kinase_screen\';
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Others\Jean_Philippe\HCT116KS-BDimages\';
%        strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Lilli\adhesome_screen_data\';
 strRootPath = '/Volumes/share-2-$/Data/Users/Lilli/adhesome_screen_data';

%         strRootPath = '\\nas-biol-micro.ethz.ch\share-micro-1-$\_HSM\Salmonella_DG_Screen1\';
        strOutputPath = strRootPath;
    end

    if nargin == 1
        strOutputPath = strRootPath;
    end

    if nargin < 2
        % INITIALIZE BASICCORRECTEDDATA
        BASICCORRECTEDDATA = struct();
        BASICCORRECTEDDATA.TotalCells = [];
        BASICCORRECTEDDATA.InfectedCells = [];
        BASICCORRECTEDDATA.InfectionIndex = [];
        BASICCORRECTEDDATA.RelativeInfectionIndex = [];
        BASICCORRECTEDDATA.Log2RelativeInfectionIndex = [];
        BASICCORRECTEDDATA.Log2RelativeCellNumber = [];    
        BASICCORRECTEDDATA.ZScore = [];
        BASICCORRECTEDDATA.MAD = [];        
        BASICCORRECTEDDATA.Images = [];
        BASICCORRECTEDDATA.OligoNumber = [];
        BASICCORRECTEDDATA.PlateNumber = [];
        BASICCORRECTEDDATA.ReplicaNumber = [];        
        BASICCORRECTEDDATA.BatchNumber = [];                
        BASICCORRECTEDDATA.GeneData = {};
        BASICCORRECTEDDATA.GeneID = {};    
        BASICCORRECTEDDATA.WellRow = [];
        BASICCORRECTEDDATA.WellCol = [];  
        BASICCORRECTEDDATA.Path = {};
        BASICCORRECTEDDATA.RawImages = [];
        BASICCORRECTEDDATA.ImageIndices = {};
        BASICCORRECTEDDATA.CorrectedLog2RII = [];
        BASICCORRECTEDDATA.CorrectedZScoreLog2RII = [];  
        BASICCORRECTEDDATA.PredictedLog2RII = [];
        BASICCORRECTEDDATA.PredictedZScoreLog2RII = [];
        BASICCORRECTEDDATA.Modelparameters = [];
        BASICCORRECTEDDATA.Modelparametersdescription = {};
       
        % INITIALIZE BASICCORRECTEDDATA        
    end
    
    %RootPathFolderList = dirc(strRootPath,'de');
%%
 if ispc
        %%% WINDOWS HACK TO DIR ONLY DIRECTORIES: FASTER
        list=dir(sprintf('%s%s*.',strRootPath,filesep));
    else
        list=dir(sprintf('%s%s*',strRootPath,filesep));        
    end
    list=struct2cell(list);
    
%%    
    list=list';
    item_isdir=logical(cell2mat(list(:,4)));
    RootPathFolderList=list(item_isdir,1);
    if strcmp(RootPathFolderList(1),'.') && ...
        strcmp(RootPathFolderList(2),'..')
        RootPathFolderList(1:2)=[];
    end
    
%%    
    strFileNameToLookFor = 'Measurements_Image_FileNames.mat';
    
    if not(isempty(RootPathFolderList))
        for folderLoop = 1:size(RootPathFolderList,1)
            
            if strcmpi(RootPathFolderList{folderLoop,1},'TIFF')
                break
            end
            
            path = strcat(strRootPath,RootPathFolderList{folderLoop,1},filesep);
            
            strOutputFolderFileList = dirc(path,'f');
            hasMATFilesInOutputFolder = strcmp(strFileNameToLookFor,strOutputFolderFileList(:,1));
            
            if not(isempty(find(hasMATFilesInOutputFolder,1)));

                hasBASICDATAInOutputFolder = strfind(strOutputFolderFileList(:,1),'BASICDATA_');
                intBASICDATAIndex = find(~cellfun('isempty',hasBASICDATAInOutputFolder));

                if not(isempty(intBASICDATAIndex))

                    PLATE_BASICDATA = load(fullfile(path,char(strOutputFolderFileList(intBASICDATAIndex,1))));
                    disp(sprintf('Loading %s from %s',char(strOutputFolderFileList(intBASICDATAIndex,1)), path))


                    if not(isfield(PLATE_BASICDATA.BASICDATA,'GeneID'))
                        error('MISSING GENEID IN %s',path)
                    end

                    if ~exist('BASICDATA')% isempty(BASICDATA.TotalCells)
                        BASICDATA = PLATE_BASICDATA.BASICDATA;
%                     elseif isempty(BASICDATA.TotalCells)
%                         BASICDATA = PLATE_BASICDATA.BASICDATA;
                    else
                        cellstrFieldnames = fieldnames(BASICDATA);
                        for field = 1:length(cellstrFieldnames)
                            try
                                BASICDATA.(char(cellstrFieldnames(field))) = [BASICDATA.(char(cellstrFieldnames(field))); PLATE_BASICDATA.BASICDATA.(char(cellstrFieldnames(field)))];
                            catch
                                disp(sprintf('   (! Failed to add field %s to BASICDATA)', char(cellstrFieldnames(field))))

                                % FILL BASICDATA WITH PLACEHOLDER DATA FOR
                                % MISSING FIELDS
                                intNumOfColumns = size(BASICDATA.(char(cellstrFieldnames(field))),2);
                                if intNumOfColumns == 0
                                    intNumOfColumns = 1;
                                end
                                if iscell(BASICDATA.(char(cellstrFieldnames(field))))
                                    PlaceHolderData = repmat({'-'},1,intNumOfColumns);                                
                                else 
                                    PlaceHolderData = repmat(NaN,1,intNumOfColumns);
                                end
                                BASICDATA.(char(cellstrFieldnames(field))) = [BASICDATA.(char(cellstrFieldnames(field))); PlaceHolderData];
                            end
                        end                            
                    end                        

%                     disp(sprintf('processed %s',path))                        
                end                                        
            else
%                 disp(sprintf('continuing with %s',path))
                fuse_basic_data(path, BASICDATA);
            end
        end
        
        if size(BASICDATA.GeneID,1) ~= size(BASICDATA.GeneData,1)
            error('MISSING GENEID IN %s',path)            
        end
        
        if size(BASICDATA.GeneID,2) ~= size(BASICDATA.GeneData,2)
            error('MISSING GENEID IN %s',path)            
        end
        
        if exist('strOutputPath') && not(isempty(BASICDATA.TotalCells))        
            %%% SAVING BASIC DATA            
            try
                disp('**** SAVING BASICDATA')
                disp(sprintf('**** %d PLATES GATHERED',size(BASICDATA.TotalCells,1)))
                save(fullfile(strOutputPath,'BASICDATA.mat'),'BASICDATA');
            catch
                err = lasterror;
                msg = err.message;
                disp(sprintf('*** saving BASICDATA failed on %s. \n\n%s',strRootPath, msg))                                
            end                    

            %%% SAVING ADVANCED DATA        
            try
                disp('**** CREATING ADVANCEDDATA')                
                ADVANCEDDATA = convert_basic_to_advanced_data(BASICDATA);
                disp('**** SAVING ADVANCEDDATA')                
                save(fullfile(strOutputPath,'ADVANCEDDATA.mat'),'ADVANCEDDATA');
            catch
                err = lasterror;
                msg = err.message;
                disp(sprintf('*** creating and saving ADVANCEDDATA failed on %s. \n\n%s',strRootPath, msg))                                
            end    
            
            try
                disp('**** CREATING BASICDATA.csv')                
                Convert_BASICDATA_to_csv(strOutputPath)            
            catch
                err = lasterror;
                msg = err.message;
                disp(sprintf('*** creating and saving BASICDATA.csv failed on %s. \n\n%s',strRootPath, msg))                                                                
            end

           
            try
                disp('**** CREATING ADVANCEDDATA.csv')                
                Convert_ADVANCEDDATA_to_csv(strOutputPath)            
            catch
                err = lasterror;
                msg = err.message;
                disp(sprintf('*** creating and saving ADVANCEDDATA.csv failed on %s. \n\n%s',strRootPath, msg))                                                
            end            
        end        
        
        
    end

