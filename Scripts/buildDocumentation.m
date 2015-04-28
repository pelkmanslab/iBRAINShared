%
% Script to build matlab documentation with m2html
%
% Expects to be run from the Scripts/ directory
%
% This particular script is GPL as it references m2html

% PARAMETERS START

% TAP file to output
docDirRelToTopLevel = 'docHTML/';

% PARAMETERS END

% Check that we are in right directory
[upperPath, deepestFolder, ignoreThisStr] = fileparts(pwd());
if (strcmp(deepestFolder,'Scripts')==0)
   error('Not in Scripts/ directory');
end

addpath('Scripts/lib/m2html')

% Gets the top-level folder name
[upperPath, deepestFolderTopLevel, ignoreThisStr] = fileparts(upperPath);

cd('../..');

% This needs to be run from one-folder higher up than the current directory
%  e.g.  "." in top-level  does not work
%       but "iBRAINShared" in top-level/.. does
m2html('mfiles',deepestFolderTopLevel,'recursive','on','htmlDir', fullfile(deepestFolderTopLevel,docDirRelToTopLevel))