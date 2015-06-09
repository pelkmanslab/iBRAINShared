function [ repositoryPath ] = getRepositoryPath()
%GETPATH returns an absoulte path to repository folder
repositoryPath = [regexprep(mfilename('fullpath'), ['\' filesep '[\w\.]*$'],'') filesep];
repositoryPath = os.path.dirname(os.path.dirname(repositoryPath));
end

