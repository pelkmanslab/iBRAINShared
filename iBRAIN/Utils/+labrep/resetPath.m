function resetPath(dontSave)
%RESET_PATH The *only* proper way to reset MATLAB path while using Pelkmans
% lab repository.
%
% This function will:
%
%  - Change current directory to point to the repository root.
%
%  - Reset MATLAB path to include only native Mathworks toolboxes.
%
%  - Extend path with custom pathnames from Pelkmans lab repository,
%    excluding optional pathnames or exceptions.
%
% See also UPDATE_PATH
%
import labrep.*;

labrepPath = os.path.dirname(os.path.dirname(which(mfilename)));
restoredefaultpath();
path([
    labrepPath pathsep ...
    fullfile(labrepPath, 'Upsilon')], path);
appendExternalFolders();
updatePath(dontSave);

end