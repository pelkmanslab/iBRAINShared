function strUNC = replaceDRIVEwithUNC(strPath)

% [BS] get's on windows machines the UNC for any mapped drive letter. drive
% letters must be formatted as 'z:' including the colon at the end.
%
% usage:
%
% strUNC = getUNCfromDRIVE(strDrive)
warning off 'MATLAB:UIW_DOSUNC'

if nargin==0
    strPath = 'X:\Data\Users\mRNAmes\Enes';
end

if iscell(strPath)
    strPath = strPath{1};
end

% init output to be equal to input, in case we have to exit.
strUNC = strPath;

if ~ispc
    return
end

if ~regexpi(strPath,'^[a-z]:.*')
    return
end

try
    [status result] = system(sprintf('net use %s:',lower(strPath(1))));
    foo = regexpi(result,'Remote.*name\s{1,}(.*)','tokens','dotexceptnewline');
    strUNC = fullfile(foo{1}{1},strPath(3:end));
catch objFoo
    strUNC = 'non existent directory...';
end
end