function appendExternalFolders()
%APPEND_EXTERNAL_FOLDERS Recursively append external folders.
%   Append external folders if they are found to exist. Folders are 
%   relative to the location of +labrep namespace folder.
repositoryPath = labrep.getRepositoryPath();
% A list sibling repositories.
externalFolders = struct();
externalFolders(1).path = fullfile(os.path.dirname(repositoryPath), 'cmt');
externalFolders(1).ignoreList = {
    ['cmt' filesep 'Compiled'] ...
    ['cmt' filesep 'cmt'] ...
    ['cmt' filesep 'Patches'] ...
};
externalFolders(2).path = fullfile(os.path.dirname(repositoryPath), 'CellClassifierDev');
externalFolders(2).ignoreList = {
    ['CellClassifierDev' filesep 'classify_gui'] ...
};


morefolders = '';
for iFolder = 1:numel(externalFolders)
    externalFolder = externalFolders(iFolder);
    if ~os.path.exists(externalFolder.path)
        continue
    end
    morefolders = [morefolders ...
        labrep.createPath(externalFolder.path, ...
                          externalFolder.ignoreList) ...
        pathsep];
end
if numel(morefolders) > 1
    labrep.addPath(morefolders(1:end - 1));
end
