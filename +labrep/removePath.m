function removePath( token )
%REMOVEPATH Remove path that matches the pattern

% remove each path entry containing the token
lines = split_str(path, pathsep);
newPath = '';
for iLine = 1:numel(lines)
    line = deblank(lines{iLine});
    if strfind(line, token)
        % omit line
        continue
    end
    newPath = [newPath line pathsep];
end
if numel(newPath) == 0
    warning('labrep:removePath', 'New path is empty. removePath() has failed.');
    return
end

path(newPath);

end

function lines = split_str(text, sep)
lines = textscan(text, '%s', 'delimiter', sep,'multipleDelimsAsOne',1);
lines = lines{1};
end