function lastdir=getlastdir(strRootPath)
% getlastdir retreives the last directory name from a path string

    if nargin==0
        strRootPath = {'Z:\Data\Users\YF_DG\20080309165648_M1_080309_YF_DG_batch1_CP004-1de\BATCH\Measurements_Image_FileNames.mat'};
    end

    if ischar(strRootPath)
        basedir = doit(strRootPath);
    elseif iscell(strRootPath)
        basedir = cellfun(@doit,strRootPath,'UniformOutput',0);
    else
        error('unknown input type for getbasedir')
    end


end

function strOutput = doit(strInput)
    strRootPath = strrep(strRootPath,strcat(filesep,filesep),'');
    strOutput = '';
    matFilesepIndices = strfind(strRootPath, filesep);
    
    if isempty(matFilesepIndices) && strcmp(filesep,'\')
        matFilesepIndices = strfind(strRootPath, '/');        
    elseif isempty(matFilesepIndices) && strcmp(filesep,'/')
        matFilesepIndices = strfind(strRootPath, '\');
    end
        
    intPathLength = length(strRootPath);
    if matFilesepIndices(end) == intPathLength
        strOutput = strRootPath(matFilesepIndices(end-1)+1:end-1);
    else
        strOutput = strRootPath(matFilesepIndices(end)+1:end);  
    end
end