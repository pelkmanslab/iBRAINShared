function strJpgPath = openPlateJpg(strJpgDir,iRow,iCol)
%
% Usage:
%
% strJpgPath = openPlateJpg(strJpgDir,iRow,iCol)
%
% if output is requested it returns the jpg path rather than opening it.
    

% check if jpg dir exists
if ~fileattrib(strJpgDir)
    error('invalid jpg path')
end
    

% find corresponding JPG file
cellstrJpgs = CPdir(strJpgDir);

% filter out directories
cellstrJpgs = {cellstrJpgs(~[cellstrJpgs.isdir]).name};

% format search string according to well indices
strWellName = sprintf('_%s%02d_',char(iRow+64),iCol);

% find corresponding jpg file name
strJpgFile = cellstrJpgs(~cellfun(@isempty,strfind(cellstrJpgs,strWellName)));

if isempty(strJpgFile)
    fprintf('%s: no jpgs found\n',mfilename)
    return
end

% start default system image browser for corresponding jpgs
strJpgPath = fullfile(strJpgDir,strJpgFile{1});
if nargout==0
    go(strJpgPath)
end
