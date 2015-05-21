function updatePath(dontSave)
% Proper way to update MATLAB path to include folders of
% general lab repository.
%
% Just call update_path, that will update pathdef.m
labrep.addPath(labrep.createPath());

if ~dontSave
    savepath();
end

% It could be that MATLAB process does not have the write permissions to
% save pathdef.m.  In that case you would have to save it manually //yy
end