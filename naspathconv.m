function strConvPath = naspathconv(strRootPath)
%
%
% Input can either be a share-2-$ or share-3-$ path, in any format
% (mac/pc/unix (Brutus)), and has to be converted to the format that is
% usable on the machine which calls this function (mac/pc/unix (Brutus))

 if nargin==0

% the formats we want to be able to convert
%      strRootPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\Berend';
%      strRootPath = 'X:\Data\Users\Berend';
%      strRootPath = '/Volumes/share-3-$/Data/Users/Pauli/';     
     strRootPath = '/BIOL/imsb/fs2/bio3/bio3/Data/Users/Berend';

 end

% by default, the output is the same as the input, only if the input could
% be succesfully converted do we set the conversion result as output
strConvPath = strRootPath;

% detect format of input path, and store value in intPathFormat, possible
% values are: 
% intPathFormat = 1 --> PC (mapped), 
% intPathFormat = 2 --> PC, 
% intPathFormat = 3 --> Mac
% intPathFormat = 4 --> UNIX/Brutus

intPathFormat = 0;

% see what type of input we're dealing with
% mapped PC path references (case insensitive)
if ~isempty(regexpi(strRootPath,'^[E-Z]:\\'))
    intPathFormat = 1; % PC format mapped
    strShareRegexp = '^[E-Z]:\\'; % --> this helps to catch the PathBase, but not the share number...
%     disp('input path is mapped PC')

% typical PC path    
elseif ~isempty(regexpi(strRootPath,'^\\\\nas-biol-imsb-1'))
    intPathFormat = 2; % PC format 
    strShareRegexp = '^\\\\nas-biol-imsb-1\\share-(\d)-\$\\';    
%     disp('input path is PC')
    
% typical Mac path references
elseif ~isempty(regexp(strRootPath,'^/Volumes'))
    intPathFormat = 3; % Mac format
    strShareRegexp = '^/Volumes/share-(\d)-\$/';
%     disp('input path is Mac')
    
% typical Brutus cluster path references
elseif ~isempty(regexp(strRootPath,'^/BIOL/imsb'))
    intPathFormat = 4; % Brutus format
    strShareRegexp = '^/BIOL/imsb/fs(\d)/bio3/bio3/';
%     disp('input path is UNIX/Brutus')    
end

% if no format is recognized on the input, throw warning and return (output
% is equal to input).
if ~intPathFormat
   warning('naspathconv:unknownPathFormat','%s: ''%s'' is not recognized as a NAS path',mfilename,strRootPath)
   return
end

% determine available NAS paths on this machine for both share-2-$ and
% share-3-$
if ispc
    strLocalBaseShare2 = '\\nas-biol-imsb-1\share-2-$\';
    strLocalBaseShare3 = '\\nas-biol-imsb-1\share-3-$\';
elseif ismac
    strLocalBaseShare2 = '/Volumes/share-2-$/';
    strLocalBaseShare3 = '/Volumes/share-3-$/';
elseif isunix
    strLocalBaseShare2 = '/BIOL/imsb/fs2/bio3/bio3/';
    strLocalBaseShare3 = '/BIOL/imsb/fs3/bio3/bio3/';
end

% check if they are both present, otherwise notify user (may get annoying)
if ~fileattrib(strLocalBaseShare2)
    warning('naspathconv:unableToReachNasShare','%s: unable to reach share-2-$ on ''%s'', please map this path',mfilename,strLocalBaseShare2)
end
if ~fileattrib(strLocalBaseShare3)
    warning('naspathconv:unableToReachNasShare','%s: unable to reach share-3-$ on ''%s'', please map this path',mfilename,strLocalBaseShare3)
end


% determine the Nas Share number we want to get (0 is unknown/default)
intNasShare = 0;
strPathBase = char(regexpi(strRootPath,strShareRegexp,'Match'));
strNasShare = regexpi(strRootPath,strShareRegexp,'Tokens');
try
    intNasShare = str2double(strNasShare{1});
    if isempty(intNasShare)
        intNasShare = 0; % if not determinable, set to 0
    end
end
% if we weren't able to determine the share number, we might want to
% error-out (or alternatively try to determine the share number via
% trying...)
if (intNasShare == 0 | ~isnumeric(intNasShare)) & (intPathFormat > 1)
    error('%s: unable to determine share number from input path ''%s''',mfilename,strRootPath)
end



% do the conversion, by trying different nas shares
strNewPath = '';
if intNasShare == 0
    
    % create tentative path for share 2
    strNewPath = strrep(strRootPath,strPathBase,strLocalBaseShare2);
    strNewPath = strrep(strNewPath,'/',filesep);
    strNewPath2 = strrep(strNewPath,'\',filesep);

    % create tentative path for share 3    
    strNewPath = strrep(strRootPath,strPathBase,strLocalBaseShare3);
    strNewPath = strrep(strNewPath,'/',filesep);
    strNewPath3 = strrep(strNewPath,'\',filesep);

    % if share 3 path exists, use this, otherwise use share-2-$ (fulles
    % share...)
    if fileattrib(strNewPath2)
        strNewPath = strNewPath2;       
    elseif fileattrib(strNewPath3)
        strNewPath = strNewPath3;
    else
        % if we weren't able to determine the nas share, try if the current new
        % path exist (for share-3-$), if not, see if the path exists for share-2-$
        warning('naspathconv:unableToDetermineNasShareNumber','%s: unable to determine the share-number from ''%s'', and neither corresponding share-2-$ nor share-3-$ paths are found. Assuming share-2-$, but expext a crash..',mfilename,strPathBase)
        strNewPath = strNewPath2;
    end
    
% do the conversion for share-2-$
elseif intNasShare == 2
    strNewPath = strrep(strRootPath,strPathBase,strLocalBaseShare2);
% do the conversion for share-3-$    
elseif intNasShare == 3    
    strNewPath = strrep(strRootPath,strPathBase,strLocalBaseShare3);
end
strNewPath = strrep(strNewPath,'/',filesep);
strNewPath = strrep(strNewPath,'\',filesep);

strConvPath = strNewPath;
    


end % function pathconv