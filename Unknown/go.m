function go(strRootPath,varargin)
%
% go(path) starts the explorer on that path. does npc & iterative path
% truncation if the paths is invalid.
%
% Berend Snijder

    if nargin==0
        strRootPath = '/BIOL/imsb/fs3/bio3/bio3/Data/Users/Prisca/Safia/iBRAIN/40exp/40exp-R3/TIFF/ aerg ';
    end

    if nargin>1
        strRootPath = sprintf('%s %s',strRootPath,sprintf('%s ',varargin{:}));
        strRootPath(end) = [];
    end
    
    strRootPath = npc(strRootPath);

    while ~fileattrib(strRootPath) && ~isempty(strRootPath)
        fprintf('%s: ''%s'' is not a valid path, trying parent directory.\n', mfilename,strRootPath)
        strRootPath = getbasedir(strRootPath);
    end

    if isempty(strRootPath) || ~fileattrib(strRootPath)
        fprintf('%s: ''%s'' is not a valid path.\n', mfilename,strRootPath)
    else
        fprintf('%s: starting explorer on ''%s''.\n', mfilename,strRootPath)
        system(sprintf('explorer %s',strRootPath));
    end

end