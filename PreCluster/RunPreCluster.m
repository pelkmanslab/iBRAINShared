function RunPreCluster()

warning off all;

strCPOutputFile = 'C:\Documents and Settings\imsb\Desktop\PreCluster\PreCluster_FULL_ANALYSIS_50K_PIPEOUT.mat';
strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\50K_final\MHV_TDS\';
strOutputFolder = 'BATCH';
strInputFolder = 'TIFF';

RootPathFolderList = dirc(strRootPath,'de');

disp(sprintf('starting RunPreCluster on %s; %g subfolders found', strRootPath, length(RootPathFolderList)))

for folderLoop = 1:length(RootPathFolderList)
    strSubfolderPath = strcat(strRootPath,RootPathFolderList{folderLoop,1},'\');
    disp(sprintf('%s', strSubfolderPath))
    
    cellSubDirlist  = dirc(strcat(strSubfolderPath),'de');

    % check if there is a input folder present
    hasInputFolder = strcmpi(cellSubDirlist(:,1),strInputFolder);
    if find(hasInputFolder) 
        
        strInputFolderPath = strcat(strSubfolderPath,strInputFolder,'\');        
        disp(sprintf(' + %s', strInputFolder))

        % check if the output folder exists, if not, create it
        hasOutputFolder = strcmpi(cellSubDirlist(:,1),strOutputFolder);
        strOutputFolderPath = strcat(strSubfolderPath,strOutputFolder,'\');
        
        resultCreateOutputFolder = 1;        
        
        if not(isempty(find(hasOutputFolder)))
            disp(sprintf(' + %s', strOutputFolder));
        else
            disp(sprintf(' - %s', strOutputFolderPath));
            
            resultCreateOutputFolder = mkdir(strSubfolderPath,strOutputFolder);
            if resultCreateOutputFolder
                disp(sprintf(' - succesfully created %s folder', strOutputFolder));
            else
                disp(sprintf(' - failed to create %s folder', strOutputFolder));
                disp(sprintf(' - continuing to next project folder'));
                return
            end
        end

        if not(isempty(find(hasOutputFolder))) || resultCreateOutputFolder
            
            strOutputFolderFileList = dirc(strOutputFolderPath,'f');
            hasMATFilesInOutputFolder = strcmpi('MAT',strOutputFolderFileList(:,3));

            if not(isempty(find(hasMATFilesInOutputFolder)))
                disp(sprintf(' + %s already has .mat files', strOutputFolderPath))
            else
                disp(sprintf(' - %s has no .mat files', strOutputFolderPath))
                disp(sprintf(' - STARTING PreCluster %s %s %s {''_w460.tif'',''_w530.tif''}', strCPOutputFile, strInputFolderPath, strOutputFolderPath))                
                PreCluster(strCPOutputFile, strInputFolderPath, strOutputFolderPath, {'d0.tif','d1.tif'})
            end
            
        end
        
        
        
    end

end