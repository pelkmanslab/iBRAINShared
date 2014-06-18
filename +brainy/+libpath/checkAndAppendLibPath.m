function checkAndAppendLibPath( batchPath )
%CHECKANDAPPENDLIBPATH Check and append libpath if found.
%   Supplied is the path to a batch folder.
import brainy.libpath.*;

platePath = os.path.dirname(batchPath);
libDir = getLibDir(platePath);
% Check if the plate (or project folder contains LIB/MATLAB
if os.path.exists(libDir)
    disp(['Custom project code support is enabled by temporary expanding ' ...
          'of MATLAB path by including all the subfolders under: ' libDir]);
    projectMatlabPath = labrep.createPath(libDir, {});
    labrep.addPath(projectMatlabPath);
else
    disp(['Ignoring custom project code support. Path does not exist: ' libDir]);
end

