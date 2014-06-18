function check_image_filenamelist_integrity_DATAFUSION(strRootPath)

    warning off all;

    if nargin == 0
        tic
        disp('check_image_filenamelist_integrity_DATAFUSION')
        if ispc
%             strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\50K_final\VV_KY\';
            strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\VSV_DG\';
            
        else
            strRootPath = '/Volumes/share-2-$/Data/Users/Berend/BATCH_RESULTS/Data/Users/50K_final/';
        end
    end

    try
        RootPathFolderList = dirc(strRootPath,'de');
    catch
        disp(sprintf('could not get file listing for path: %s',strRootPath))
        return
    end

    handles = struct();
    
    strFileNameToLookFor = 'Measurements_Image_FileNames.mat';
%     strOutputFileToLookFor = 'Measurements_Nuclei_VirusScreen_ClassicalInfection2.mat';

    for folderLoop = 1:size(RootPathFolderList,1)
%         path = strcat(strRootPath,RootPathFolderList{folderLoop,1},filesep);
        path = strcat(strRootPath,RootPathFolderList{folderLoop,1},filesep,'DATAFUSION',filesep);

        InputFileName = fullfile(path,strFileNameToLookFor);
        [boolFileNameListFound]=fileattrib(InputFileName);
        
        if boolFileNameListFound
            
            strImagePath = [strrep(path,'\Data\Users\Berend\BATCH_RESULTS',''),'TIFF',filesep];
            strImagePath = strrep(strImagePath,'\DATAFUSION','');
            
            if not(fileattrib(strImagePath))
				disp(sprintf('%.0fm Checking integrity of %s: ??? images', (toc/60),getlastdir(path)))				
                disp('! ERROR:')
                disp(sprintf('! image folder not found:   %s',strImagePath))
                disp(sprintf('! deduced from data folder: %s',path))                
			else
                handles = LoadMeasurements(handles,InputFileName);
				disp(sprintf('%.0fm Checking integrity of %s: %d images', (toc/60),getlastdir(path),size(handles.Measurements.Image.FileNames,2)))
                filemismatch = 0;
                for i = 1:size(handles.Measurements.Image.FileNames,2)
                    for ii = 1:size(handles.Measurements.Image.FileNames{i},2)                    
                        strImageFile = strcat(strImagePath, handles.Measurements.Image.FileNames{i}(1,ii));
                        if not(fileattrib(char(strImageFile)))
                            filemismatch = filemismatch + 1;
%                         else
%                             disp(sprintf('       : OK %s IN %s',char(strImageFile),getlastdir(path)))                            
                        end
                    end
                end
                if filemismatch > 0
                    disp(sprintf('!!! *********************************'))                    
                    disp(sprintf('!!! WARNING: %d MISMATCHES IN %s',filemismatch,char(strImagePath)))
                    disp(sprintf('!!! *********************************'))                                        
                end                
            end   
        else
            check_image_filenamelist_integrity_DATAFUSION(path);
        end
%         OutputFileName = fullfile(path,strOutputFileToLookFor);
%         [boolOutputFileAlreadyExists]= 0;%fileattrib(OutputFileName);
%         
%         if boolInputFileAlreadyExists && not(boolOutputFileAlreadyExists)
%             PostClusterLocalDensity(path);
%         elseif boolOutputFileAlreadyExists
%             disp(sprintf('%s already present in %s', strOutputFileToLookFor, getlastdir(path)))
%             Run_PostClusterLocalDensity(path)
%         else
%             disp(sprintf('%s not present in %s', strFileNameToLookFor, getlastdir(path)))
%             Run_PostClusterLocalDensity(path)
%         end
    end

end