function RunDataFusion(strRootPath, strFileNameMatch)

warning off all;

if nargin == 0
    strRootPath = '\\nas-biol-imsb-1.d.ethz.ch\share-3-$\Data\Users\Prisca\090309_A431-Chtx-GM130\090309_A431-Chtx-GM130-CP395-1af\BATCH';
%     error('please give an input path')
    strFileNameMatch = 'Measurements_ShCells_Location';
end

if nargin==1
    strFileNameMatch = '';
end

try
    RootPathFolderList = CPdir(strRootPath);
    % remove '.' and '..'
    RootPathFolderList(ismember({RootPathFolderList.name},{'.','..'})) = [];
    RootPathFolderList(~cat(1,RootPathFolderList.isdir)) = [];
catch
    error(['Failed to read folder ', strRootPath]);
end

if size(RootPathFolderList,1) == 0
    %if there are no subfolders on the input folder, try the current folder...
    try
        DataSorterFusion(strRootPath,strFileNameMatch);
    catch lastObjError
            lastObjError.message
            lastObjError.identifier
        disp(['FAILED: ',strRootPath]);
    end
else
    % otherwise try and check all subfolders
    for folderLoop = 1:size(RootPathFolderList,1)
        strSubfolderPath = strcat(strRootPath,RootPathFolderList{folderLoop,1},filesep);
        try
            DataSorterFusion(strSubfolderPath,strFileNameMatch);
        catch lastObjError
            lastObjError.message
            lastObjError.identifier
            disp(['FAILED: ',strRootPath]);
        end
        RunPostClusterDataSorterFusion(strSubfolderPath,strFileNameMatch);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function DataSorterFusion(strOutputFolderPath,strFileNameMatch)

if nargin==1
    strFileNameMatch = '';
end

warning off all

fprintf('%s: checking %s\n\n',mfilename,strOutputFolderPath);

%strOutputFolderPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\50K_final\Ad5_KY\061210_Ad5_50K_Ky_1_1\';
strOutputFolderFileList = CPdir(strOutputFolderPath);
% remove '.' and '..'
strOutputFolderFileList(ismember({strOutputFolderFileList.name},{'.','..'})) = [];
% remove directories from list
strOutputFolderFileList(cat(1,strOutputFolderFileList.isdir)) = [];
strOutputFolderFileList = {strOutputFolderFileList.name}';

matFindMATFilesIndexes = find(~cellfun('isempty',strfind(strOutputFolderFileList, 'mat')));
truncatedFileNames = {};
boolFolderHasBeenFlagged = 0;

for i = 1:length(matFindMATFilesIndexes)
    filename = char(strOutputFolderFileList(matFindMATFilesIndexes(i),1));
    measindex = strfind(filename, 'Measurements');
    if measindex > 1
        % skip files that start with Measurements or that do not have
        % Measurements in its name
        truncatedFileNames{end+1,1} = filename(1,measindex:end);
    end
end

MeasurementList = unique(truncatedFileNames);


% let's make an optional second input parameter a part of a
% measurement file name, such that datafusion only fuses those files that
% have that piece of text in their file name
if ~isempty(strFileNameMatch)
    matOkMeasurementsIX = cellfun(@(x) ~isempty(strfind(x,strFileNameMatch)),MeasurementList);
    MeasurementList(~matOkMeasurementsIX)=[];
    fprintf('%s: only processing %d measurements containing ''%s''\n',mfilename,sum(matOkMeasurementsIX),strFileNameMatch)
end



for i = 1:length(MeasurementList)
    boolOutputIntegrityCheck = 1;
    
    OutputFileName = fullfile(strOutputFolderPath,char(MeasurementList(i)));
    [boolOutputFileAlreadyExists]=fileattrib(OutputFileName);

    if boolOutputFileAlreadyExists
        fprintf('%s: already done %s. checking integrity of file\n',mfilename,OutputFileName);
        try
            boolOutputIntegrityCheck = checkmeasurementsfile2(OutputFileName, fullfile(strOutputFolderPath,'Batch_data.mat'), fullfile(strOutputFolderPath,'Measurements_Image_ObjectCount.mat'));
            if boolOutputIntegrityCheck==0
                fprintf('%s: redoing %s. integrity-check of file failed\n',mfilename,OutputFileName);
            elseif boolOutputIntegrityCheck==1
                fprintf('%s: skipping %s. integrity-check of file passed\n\n',mfilename,OutputFileName);
            end
        catch
            warning('somehow checkmeasurementsfile failed...')
            boolOutputIntegrityCheck = 0;
        end
    end

    if boolOutputFileAlreadyExists==0 || boolOutputIntegrityCheck==0
        if not(boolFolderHasBeenFlagged) && boolOutputIntegrityCheck
            fprintf('%s: found %d unprocessed and unique measurements in %s\n',mfilename,length(MeasurementList),strOutputFolderPath);
            boolFolderHasBeenFlagged = 1;
        end
        fprintf('%s: processing %s\n',mfilename,strrep(strrep(char(MeasurementList(i)),'_','.'),'.mat',''));
        matFindMeasurementFilesIndexes = find(~cellfun('isempty',strfind(strOutputFolderFileList(:,1), char(MeasurementList(i)))));

        handles = struct();
        for ii = 1:length(matFindMeasurementFilesIndexes)
            if not(strcmp(char(strOutputFolderFileList{matFindMeasurementFilesIndexes(ii),1}(1,1:12)),'Measurements')) 
                InputFileName = fullfile(strOutputFolderPath,char(strOutputFolderFileList(matFindMeasurementFilesIndexes(ii),1)));
                fprintf('%s: loading %s\n',mfilename,InputFileName);
                try
                    handles = LoadMeasurements(handles,InputFileName);
                catch
                    fprintf('%s: failed to load %s\n',mfilename,InputFileName)
                end
            end                
        end
        % if handles is bigger than 1GB, store as v7.3, otherwise store as
        % default version.
        matWhoInfo = whos('handles');
        if (matWhoInfo.bytes / (1024^2)) > 1000
            try
                save(OutputFileName,'handles','-v7.3'); % 
            catch objError
                disp(objError)
                delete(OutputFileName)
                save(OutputFileName,'handles','-v7'); % 
            end
        else
            save(OutputFileName,'handles'); % '-v7.3'
        end
        fprintf('%s: stored %s\n\n',mfilename,OutputFileName);
%     else
%         disp(sprintf('already done %s',OutputFileName));
    end
end
