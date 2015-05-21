function cellstrFileList = SearchTargetFiles(strRootPath,strFileNameToLookFor,cellstrFolderList)

    if nargin == 0
        strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\VV_DG\20071022102932_M2_071020_VV_DG_batch1_CP002-1dc\'
        strFileNameToLookFor = 'BASICDATA_*.mat'
        cellstrFileList = {};
        cellstrFolderList = {};
    end


    if nargin == 2
        cellstrFileList = {};
    end

%     RootPathFolderList = dirc(strRootPath,'de');

    if ispc
        %%% WINDOWS HACK TO DIR ONLY DIRECTORIES: FASTER
        list=dir(sprintf('%s%s*.',strRootPath,filesep));
    else
        list=dir(sprintf('%s%s*',strRootPath,filesep));        
    end
    list=struct2cell(list);
    list=list';
    item_isdir=cell2mat(list(:,4));
    RootPathFolderList=list(item_isdir,1);
    if strcmp(RootPathFolderList(1),'.') && ...
        strcmp(RootPathFolderList(2),'..')
        RootPathFolderList(1:2)=[];
    end
    
    if size(RootPathFolderList,1) > 0 && not(isempty(RootPathFolderList))
        for folderLoop = 1:size(RootPathFolderList,1)
            path = strcat(strRootPath,RootPathFolderList{folderLoop,1},filesep);
            [boolFileFound] = fileattrib(fullfile(path,strFileNameToLookFor));
            if boolFileFound
                cellstrFileList = [cellstrFileList;{fullfile(path,strFileNameToLookFor)}];
            else
                cellstrCurrentFolderList = SearchTargetFiles(path,strFileNameToLookFor,cellstrFolderList);
                cellstrFileList = unique([cellstrFileList;cellstrCurrentFolderList]);
            end
        end
    else
        path = strcat(strRootPath,filesep);
        [boolFileFound,structFileData] = fileattrib(fullfile(path,strFileNameToLookFor));
        if boolFileFound
%             cellstrFileList = [cellstrFileList;{fullfile(path,strFileNameToLookFor)}];
            cellstrFileList = [cellstrFileList;{structFileData.Name}];
        end
    end
end