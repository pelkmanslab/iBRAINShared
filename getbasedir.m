function basedir=getbasedir(strRootPath)
% getlastdir retreives the base path excluding the last filename or
% directory of a path

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

    if strncmp(strInput,'\\',2)
        boolStartWithSlashSlash = 1;
        strInput = strInput(3:end);
    else
        boolStartWithSlashSlash = 0;
    end

    strInput = strrep(strInput,strcat(filesep,filesep),filesep);
    
    strOutput = '';
    matFilesepIndices = strfind(strInput, filesep);

    if isempty(matFilesepIndices) && strcmp(filesep,'\')
        matFilesepIndices = strfind(strInput, '/');        
    elseif isempty(matFilesepIndices) && strcmp(filesep,'/')
        matFilesepIndices = strfind(strInput, '\');
    end

    intPathLength = size(strInput,2);
    if matFilesepIndices(end) == intPathLength
        basedir = strInput(1:matFilesepIndices(end-1));
    else
        basedir = strInput(1:matFilesepIndices(end)); 
    end

    if boolStartWithSlashSlash
        strOutput = ['\\',basedir];
    else
        strOutput = basedir;
    end
end