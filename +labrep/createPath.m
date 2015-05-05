function p = createPath(d, ignorePaths)
%CREATEPATH build a list of PATH folders to be add to the Matlab path. 
% This includes all directories below it's current point in the directory 
% structure, except directories coming from SVN, CSV or private 
% directories, or ones containing 'old', 'obsolete' or 'backup'
% in the name (case insensitive). See code for more exclusions.


if nargin==0
    d = labrep.getRepositoryPath();
end
if nargin < 2
    ignorePaths = {
        ['General' filesep 'dip'], ...
    };
end



p = [d,';'];

% Generate path based on given root directory
files = dir(d);
if isempty(files)
    return
end

% set logical vector for subdirectory entries in d
isdir = logical(cat(1,files.isdir));

% Recursively descend through directories which are neither
% private nor "class" directories.
dirs = files(isdir); % select only directory entries from the current listing

for i=1:length(dirs)
    dirname = dirs(i).name;
    % ignore cetain paths
    dirpath = [d filesep dirname];
    ignore_dir = 0;
    for ix = 1:length(ignorePaths)
        if strendswith(dirpath, ignorePaths{ix})
            ignore_dir = 1;
            break
        end
    end
    loweDirName = lower(dirname);
    if ~ignore_dir && ...
            ~strcmp(dirname, '.')       && ...
            ~strcmp(dirname, '..')      && ...
            ~strcmp(dirname, '.svn')    && ...
            ~strcmp(dirname, '.git')    && ...
            ~strcmp(dirname, 'conf')    && ...
            ~strcmp(dirname, 'hooks')   && ...
            ~strcmp(dirname,' db')      && ...
            ~strcmp(dirname,' locks')   && ...
            ~strncmp(dirname, '@',1)    && ... % ignore matlab classes
            ~strncmp(dirname, '+',1)    && ... % ignore matlab packages
            ~strcmp(dirname, 'private') && ...            
            ~strcmp(dirname, 'CVS')     && ...            
            ~strcmp(loweDirName(1:min(3,end)), 'old') && ... % ignore everything that starts with those words (case-insesitive)
            ~strcmp(loweDirName(1:min(8,end)), 'obsolete') && ...
            ~strcmp(loweDirName(1:min(6,end)), 'backup')
        p = [p labrep.createPath(fullfile(d,dirname), ignorePaths)]; % recursive calling of this function.
    end
end
end

%%
function b = strendswith(s, pat)
%STRENDSWITH Determines whether a string ends with a specified pattern
%
%   b = strstartswith(s, pat);
%       returns whether the string s ends with a sub-string pat.
%
sl = length(s);
pl = length(pat);

b = (sl >= pl && strcmp(s(sl-pl+1:sl), pat)) || isempty(pat);
end