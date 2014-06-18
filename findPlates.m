function cellstrPaths = findPlates(strPath,cellstrPaths)

if nargin==0
%     strPath = npc('Y:\Data\Users\Prisca\endocytome');
    strPath = '\\nas-unizh-imsb1.ethz.ch\share-3-$\Data\Users\Prisca\endocytome';
%     strPath = npc('y:\Data\Users\Prisca\endocytome');
end

% bloody find the plate directories fast!
if nargin<2
    fprintf('%s: looking for plates in %s\n',mfilename,strPath)
    strCacheFile = fullfile(strPath,'findPlates_cellstrPaths.mat');
    if fileattrib(strCacheFile)        
        load(strCacheFile)
        % Ensure that path leads to plate directory. (Different computers
        % with different mounts of the same directory will have distinct 
        % absolute paths in cached file).
        if fileattrib(cellstrPaths{1})    
            fprintf('%s: loaded plate paths from cache %s\n',mfilename,strCacheFile)
            return
        end       
    end
    cellstrPaths = {};    
end

% if the directory is a plate already, we're done.
if strcmp(getlastdir(strPath),'BATCH')
    cellstrPaths = {strPath};
    return
end

% if we find a BATCH directory, append current directory and move on to
% next
if fileattrib(fullfile(strPath,'BATCH'))
    
    % BATCH dir found, append and do not process further
    cellstrPaths = [cellstrPaths;fullfile(strPath,'BATCH')];
    
else
    % if we do not find a BATCH directory, recursively process that directory
    
    % find subdirectories
    cellFiles = CPdir(strPath);
    cellFiles = {cellFiles([cellFiles.isdir]).name};
    cellFiles(ismember(cellFiles,{'.','..'})) = [];

    % process each recursively
    for i = 1:length(cellFiles)

        cellstrPaths = findPlates(fullfile(strPath,cellFiles{i}),cellstrPaths);

    end
    
end    

if nargin<2
    fprintf('%s: storing plates in cache %s\n',mfilename,strCacheFile)
    save(strCacheFile,'cellstrPaths')
end
