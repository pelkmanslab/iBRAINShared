function folderfun(varargin)

warning off all;

if nargin == 0
    disp('RunPreCluster: 50K MODE')
    if ispc
        strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\50K_final\';
    else ismac
        strRootPath = '/Volumes/share-2-$/Data/Users/50K_final/';        
    end
    strFunction = 'PreCluster';
else
    strRootPath = varargin{1}
    strFunction = varargin{2}
end

strOutputFolder = 'BATCH';
strInputFolder = 'TIFF';

RootPathFolderList = dirc(strRootPath,'de');
%disp(sprintf('%s; %g subfolders found', strRootPath, size(RootPathFolderList,1)));

for folderLoop = 1:size(RootPathFolderList,1)
    % do not search for tiff folders inside Input- and Output-Folders
    if ~strcmpi(RootPathFolderList{folderLoop,1}, strOutputFolder) && ...
            ~strcmpi(RootPathFolderList{folderLoop,1}, strInputFolder)
        strSubfolderPath = strcat(strRootPath,RootPathFolderList{folderLoop,1},filesep);
        folderfun(strSubfolderPath, strFunction, varargin{2:nargin})
        
    elseif strcmpi(RootPathFolderList{folderLoop,1}, strInputFolder)
        strSubfolderPath = strcat(strRootPath,RootPathFolderList{folderLoop,1},filesep);
        disp(strSubfolderPath)

        nargin
        if nargin > 2
            strFunctionCall = sprintf('%s(',strFunction);
            for i = 3:nargin
                if i == nargin
                    strFunctionCall = sprintf('%s%s',strFunctionCall,char(varargin(i)));
                else
                    strFunctionCall = sprintf('%s%s,',strFunctionCall,char(varargin(i)));                   
                end
            end
            strFunctionCall = sprintf('%s)',strFunctionCall) ;
        else
            strFunctionCall = strFunction;
        end
        disp(strFunctionCall)
        eval(strFunctionCall)
    end
end
