function SearchAndExecute(strRootPath,strFileNameToLookFor,strFunction)

    if nargin==0
        strRootPath='\\nas-biol-imsb-1\share-2-$\Data\Users\Others\Jean_Philippe\HCT116KS-BDimages\';
        strFileNameToLookFor='CheckImageSet_384.complete';
        strFunction='create_jpgs_manual_rescale_BDPathway';
    end

    RootPathFolderList = dirc(strRootPath,'de');
    for folderLoop = 1:size(RootPathFolderList,1)
        path = strcat(strRootPath,RootPathFolderList{folderLoop,1},filesep);
        [boolFileFound] = fileattrib(fullfile(path,strFileNameToLookFor));
        if boolFileFound
            disp(sprintf('Running %s on %s',strFunction,path))
            feval(strFunction, path);
        else
            SearchAndExecute(path,strFileNameToLookFor,strFunction);
        end
    end
end