function libDir = getLibDir( projectPath )
%GETLIBDIR Appends LIB/DIR to projectPath.

libDir = os.path.join({projectPath, 'LIB', 'MATLAB'});

end

