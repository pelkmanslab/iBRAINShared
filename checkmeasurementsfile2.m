function boolDataIsOK = checkmeasurementsfile2(strMeasurementsFile, strBatchDataFile, strImageObjectCountFile)

    boolDataIsOK = 1;
    boolDataIncomplete = 0;

    if nargin==0
        strMeasurementsFile = '\\nas-biol-imsb-1.d.ethz.ch\share-3-$\Data\Users\Prisca\090203_Mz_Tf_EEA1\090203_Mz_Tf_EEA1_CP394-1aa\BATCH\Measurements_Cells_Texture_3_OrigGreen.mat'
        strBatchDataFile = '\\nas-biol-imsb-1.d.ethz.ch\share-3-$\Data\Users\Prisca\090203_Mz_Tf_EEA1\090203_Mz_Tf_EEA1_CP394-1aa\BATCH\Batch_data.mat'
    end
    
    fprintf('%s: checking %s\n',mfilename,strMeasurementsFile);

    if ~fileattrib(strMeasurementsFile)
        fprintf('%s: %s is not an existing measurement file\n',mfilename,strMeasurementsFile);
        return
    end
    
    strRootPath = npc(getbasedir(strMeasurementsFile));
    
    % let's get a Measurement_*.mat file listing
    cellstrFile = CPdir(strRootPath);
    cellstrFile([cellstrFile.isdir]) = [];
    cellstrFile = {cellstrFile.name};    
    
    % get a list of all Batch_x_to_y.mat files, to get the image-set-block
    % sizes (or should we load Batch_data.mat and read out the setting?)
    cellstrBatchFiles = cellstrFile;
    cellstrBatchFiles(cellfun(@isempty,regexp(cellstrBatchFiles,'^Batch_\d{1,}_to_\d{1,}\.mat'))) = [];
    % process numbers of batch block sizes
    matBatchIndicesFromFiles = regexp(cellstrBatchFiles,'^Batch_(\d{1,})_to_(\d{1,})\.mat','tokens');
    matBatchIndicesFromFiles = cell2mat(cellfun(@str2double,cat(1,matBatchIndicesFromFiles{:}),'UniformOutput',false));
    [foo,sortIx]=sort(matBatchIndicesFromFiles(:,1));
    matBatchIndicesFromFiles = matBatchIndicesFromFiles(sortIx,:);

    fprintf('%s: found %d Batch_x_to_y.mat files\n',mfilename,length(cellstrBatchFiles));

    % also load in the Batch_data.mat file, calculate batch indices from
    % settings, and compare with the results from matBatchIndicesFromFiles
    fprintf('%s: loading %s\n',mfilename,strBatchDataFile);
    batchHandle = load(strBatchDataFile);
    intBatchSize = str2double(batchHandle.handles.Settings.VariableValues{end,2});
    intImageCount = batchHandle.handles.Current.NumberOfImageSets;
    matBatchIndicesFromBatchData = [];
    for i = 1:ceil((intImageCount-1)/intBatchSize)
        matBatchIndicesFromBatchData = [matBatchIndicesFromBatchData; ...
            ((i-1)*intBatchSize)+2, ((i)*intBatchSize)+1];
    end
    matBatchIndicesFromBatchData(end,end) = intImageCount;
    fprintf('%s: batch size = %d, image cycle count = %d, theoratical batch count = %d\n',mfilename,intBatchSize,intImageCount,size(matBatchIndicesFromBatchData,1));


    % now let's compare the two matrices, and give warning if they're not
    % equal.
    if ~isequal(matBatchIndicesFromFiles,matBatchIndicesFromBatchData)
        warning('BS:Bla','%s: error, batch indices from Batch_x_to_y.mat files is not the same as should be based on the settings in Batch_data.mat! Assuming theoretical batch indices from Batch_data.mat is correct. This may already indicate problems in the data.')
    end
    
    % load measurement
    fprintf('%s: loading file %s\n',mfilename,strMeasurementsFile)

    try
        handles = LoadMeasurements(struct(),strMeasurementsFile);
    catch objError
        fprintf('%s: ---- file %s is corrupt! (%s)\n',mfilename,strMeasurementsFile,objError.message)
        boolDataIncomplete = 1;
        boolDataIsOK = 0;
        return
    end
    % get measurement data, object name and measurement name from file
    % name (this should really work, if not iBRAIN wouldn't work

    try
        % assuming the object name never contains an underscore this
        % should work
        strUnderscoreIx = strfind(strMeasurementsFile,'_');
        strObjectName = strMeasurementsFile(strUnderscoreIx(1)+1:strUnderscoreIx(2)-1);
        strFieldName = strMeasurementsFile(strUnderscoreIx(2)+1:end-4);
        cellData = handles.Measurements.(strObjectName).(strFieldName);
    catch objError    
        % get most likely cell with measurement data and corresponding
        % objectname and fieldname 
        fprintf('%s: -- failed to parse data via filename, trying different approach\n',mfilename)
        [cellData, strObjectName, strFieldName]=getMostLikelyMeasurementFieldFromHandles(handles,intImageCount);
    end

    if isempty(cellData)
        fprintf('%s: -- file %s is incomplete/non-standard, but consider it ok!\n',mfilename,strMeasurementsFile)
        return
    elseif ~iscell(cellData)
        fprintf('%s: -- skipping object %s measurement %s, it it not a cell, consider it ok!\n',mfilename,strObjectName,strFieldName)
    else
        fprintf('%s: -- processing object ''%s'' measurement ''%s''\n',mfilename,strObjectName,strFieldName)



        for iBlock = 1:size(matBatchIndicesFromBatchData,1)
            % skip blocks with small sizes (smaller than 15)
            if (matBatchIndicesFromBatchData(iBlock,2) - matBatchIndicesFromBatchData(iBlock,1)) < 15
                continue
            end
            if all(cellfun(@isempty, cellData(matBatchIndicesFromBatchData(iBlock,1):matBatchIndicesFromBatchData(iBlock,2))))
                fprintf('%s: -- file %s, field %s is missing image data block %d to %d\n',mfilename,strMeasurementsFile,strFieldName,matBatchIndicesFromBatchData(iBlock,1),matBatchIndicesFromBatchData(iBlock,2))
                
                % we could check if the batch_x_to_y_measurement file is
                % empty, if so, reparsing does not make sense, and probably
                % the measurement was absent for all images (at least the
                % problem can not be fixed by re-fusing data).
                strBatchMeasurementFile = fullfile(strRootPath,sprintf('Batch_%d_to_%d_Measurements_%s_%s.mat',matBatchIndicesFromBatchData(iBlock,1),matBatchIndicesFromBatchData(iBlock,2),strObjectName,strFieldName));
                
                fprintf('%s: ---- checking %s\n',mfilename,strBatchMeasurementFile)

                % if file is missing, let's ignore it for now, throw the
                % error but consider the bigger boolDataIncomplete file as complete
                if ~fileattrib(strBatchMeasurementFile)
                    fprintf('%s: ---- batch file %s is MISSING, ignoring data gap\n',mfilename,getlastdir(strBatchMeasurementFile))
                    continue
                end

                try
                    batchMeasurementHandles = load(strBatchMeasurementFile);
                catch objError
                    fprintf('%s: ---- batch file %s is CORRUPT (''%s''), ignoring data gap\n',mfilename,getlastdir(strBatchMeasurementFile),objError.message)
                    continue
                end

                try
                    batchMeasurementHandles = LoadMeasurements(struct(),strBatchMeasurementFile);
                catch objError
                    fprintf('%s: ---- batch file %s is NOT a VALID batch file (%s), ignoring data gap\n',mfilename,getlastdir(strBatchMeasurementFile),objError.message)
                    continue
                end

                % see if all measurements in
                % Batch_x_to_y_Measurement...mat are empty, if so
                % ignore data gap
                if all(cellfun(@isempty,batchMeasurementHandles.handles.Measurements.(strObjectName).(strFieldName)(matBatchIndicesFromBatchData(iBlock,1):matBatchIndicesFromBatchData(iBlock,2))))
                     fprintf('%s: ---- batch file %s contains EMPTY measurements for image-cycle block, ignoring data gap\n',mfilename,getlastdir(strBatchMeasurementFile),objError.message)
                    continue
                end

                % if the batch file is not missing, not corrupt and not
                % empty, let's call it a true 'data fusion' problem!
                boolDataIncomplete = 1;
            end
        end
        
        % report final finding
        if ~boolDataIncomplete
            fprintf('%s: -- file %s is complete\n',mfilename,strMeasurementsFile)
            boolDataIsOK = 1;
        else
            fprintf('%s: -- file %s is NOT complete!\n',mfilename,strMeasurementsFile)
            boolDataIsOK = 0;
        end        
    
    end
    
end% function
    

    
function [cellData, strObjectName, strFieldName]=getMostLikelyMeasurementFieldFromHandles(handles,intImageCount);
    
    % most likely object name to be used is the first one... (bit iffy)
    strObjectName = fieldnames(handles.Measurements);
    strObjectName = strObjectName{1};
    
    % get largest field from data, process that
    cellData = handles;
    
    try
        cellData = structfun(@struct2cell,cellData);
        cellDataFieldNames = fieldnames(cellData{:});
        cellData = cellfun(@struct2cell,cellData,'UniformOutput',false);
        cellData = cellData{:};
    
        % look for the field with the same size as the number of images, if not
        % present, we know data is missing! 
        matFieldSizes = cellfun(@numel,cellData);
        intFieldIx = find(matFieldSizes == intImageCount);
    catch
        intFieldIx = [];
    end
    
    if isempty(intFieldIx)
        cellData = {};
        strFieldName = '';
    else
        cellData = cellData{intFieldIx};
        strFieldName = cellDataFieldNames{intFieldIx};
    end
end    