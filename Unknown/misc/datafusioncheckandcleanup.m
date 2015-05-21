function datafusioncheckandcleanup(strRootPath,strMeasurementTargetName)

% Help for datafusioncheckandcleanup(strRootPath)
%
% should be run on a batch directory. function is written (090823) because
% the old system sucked monkey teets, this guy basically let's anything
% pass as OK unless it is truely a problem that re-running datafusion can
% fix.
%
% Plus, it's more stringent in detecting fusion problems, (i.e. less false
% positives :)
%
% Diggety. BS.


    if nargin==0
        % strRootPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\Prisca\090217_A431_Tf_EEA1\090217_A431_Tf_EEA1_CP395-1ae\BATCH\';
        % strRootPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\HPV16_DG\2008-12-15_HPV16_batch3_CP063-1ec_rescreen\BATCH\';
        % strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Manuel\iBRAIN_Various\090813_EGFR_CSC2\BATCH\';
        strRootPath = npc('/BIOL/imsb/fs2/bio3/bio3/Data/Users/Katharina/iBrain/230212-katha-alpha2-20x-z-stack2_postMIP/BATCH/')
    end

    strRootPath = npc(strRootPath);
    
    fprintf('%s: checking %s\n',mfilename,strRootPath);

    % let's get a Measurement_*.mat file listing
    cellstrFile = CPdir(strRootPath);
    cellstrFile([cellstrFile.isdir]) = [];
    cellstrFile = {cellstrFile.name};

    if isempty(cellstrFile)
        if ~fileattrib(strRootPath)
            fprintf('%s: %s is not a valid path\n',mfilename,strRootPath);
            return
        else
            fprintf('%s: no files found in %s\n',mfilename,strRootPath);
            return
        end
    end
    
    % get a list of all Batch_x_to_y.mat files, to get the image-set-block
    % sizes (or should we load Batch_data.mat and read out the setting?)
    cellstrBatchFiles = cellstrFile;
    cellstrBatchFiles(cellfun(@isempty,regexp(cellstrBatchFiles,'^Batch_\d{1,}_to_\d{1,}\.mat'))) = [];
    
    if isempty(cellstrBatchFiles)
        % double check if there are any Batch_X_to_Y...mat files
        fprintf('%s: no Batch_X_to_Y.mat files found in %s. Double checking for bad files...\n',mfilename,strRootPath);
        cellstrBatchFiles2 = cellstrFile;
        cellstrBatchFiles2(cellfun(@isempty,regexp(cellstrBatchFiles2,'^Batch_\d{1,}_to_\d{1,}_Measurements_.*\.mat'))) = [];
        if ~isempty(cellstrBatchFiles2)
            fprintf('%s: Found %d bad files. Deleting...\n',mfilename,numel(cellstrBatchFiles2));
            cellfun(@delete,cellfun(@(x) fullfile(strRootPath,x),cellstrBatchFiles2,'UniformOutput',false))
        end
        return
    end
    % process numbers of batch block sizes
    matBatchIndicesFromFiles = regexp(cellstrBatchFiles,'^Batch_(\d{1,})_to_(\d{1,})\.mat','tokens');
    matBatchIndicesFromFiles = cell2mat(cellfun(@str2double,cat(1,matBatchIndicesFromFiles{:}),'UniformOutput',false));
    [foo,sortIx]=sort(matBatchIndicesFromFiles(:,1));
    matBatchIndicesFromFiles = matBatchIndicesFromFiles(sortIx,:);

    fprintf('%s: found %d Batch_x_to_y.mat files\n',mfilename,length(cellstrBatchFiles));

    % also load in the Batch_data.mat file, calculate batch indices from
    % settings, and compare with the results from matBatchIndicesFromFiles
    fprintf('%s: loading Batch_data.mat file\n',mfilename);
    batchHandle = load(fullfile(strRootPath,'Batch_data.mat'));
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

    
    if nargin<=1
        % get list of all Measurement_*.mat files.
        cellstrMeasurementFiles = cellstrFile;
        cellstrMeasurementFiles(cellfun(@isempty,regexp(cellstrMeasurementFiles,'^Measurements_(?!batch_illcor).*\.mat'))) = [];
        fprintf('%s: found %d measurement files\n',mfilename,length(cellstrMeasurementFiles))
    else
        % if we passed a particular measurement_*.mat file, only process
        % this!
        cellstrMeasurementFiles = {strMeasurementTargetName};
    end
    
    % loop over all measurements, and look for exact entire batch-blocks that
    % are tmpty (and have reasonably large block size)
    for iMeas = 1:length(cellstrMeasurementFiles)
        % set this bool to 1 for the various checks if any data is missing
        boolDataIncomplete = 0;

        % load measurement
        fprintf('\n%s: processing file %d of %d: %s\n',mfilename,iMeas,length(cellstrMeasurementFiles),cellstrMeasurementFiles{iMeas})
        
        try
            handles = LoadMeasurements(struct(),fullfile(strRootPath,cellstrMeasurementFiles{iMeas}));
        catch objError
            fprintf('%s: ---- file %s is corrupt! (%s)\n',mfilename,cellstrMeasurementFiles{iMeas},objError.message)
            boolDataIncomplete = 1; 
            continue
        end
        % get measurement data, object name and measurement name from file
        % name (this should really work, if not iBRAIN wouldn't work
        
        try
            % assuming the object name never contains an underscore this
            % should work
            strUnderscoreIx = strfind(cellstrMeasurementFiles{iMeas},'_');
            strObjectName = cellstrMeasurementFiles{iMeas}(strUnderscoreIx(1)+1:strUnderscoreIx(2)-1);
            strFieldName = cellstrMeasurementFiles{iMeas}(strUnderscoreIx(2)+1:end-4);
            cellData = handles.Measurements.(strObjectName).(strFieldName);
        catch objError    
            % get most likely cell with measurement data and corresponding
            % objectname and fieldname 
            fprintf('%s: -- failed to parse data via filename, trying different approach\n',mfilename)
            [cellData, strObjectName, strFieldName]=getMostLikelyMeasurementFieldFromHandles(handles,intImageCount);
        end
        
        if isempty(cellData)
            fprintf('%s: -- file %s is incomplete/non-standard, but consider it ok!\n',mfilename,cellstrMeasurementFiles{iMeas})
            continue
        elseif max(matBatchIndicesFromBatchData(:))-length(cellData) > median(lin(diff(matBatchIndicesFromBatchData)))
            fprintf('%s: -- object %s measurement %s is missing more measurements at the end than the batch size, this is NOT ok!!!\n',mfilename,strObjectName,strFieldName)
            boolDataIncomplete = 1;
        elseif ~iscell(cellData)
            fprintf('%s: -- skipping object %s measurement %s, it it not a cell, consider it ok!\n',mfilename,strObjectName,strFieldName)
        else
            fprintf('%s: -- processing object %s measurement %s\n',mfilename,strObjectName,strFieldName)



            for iBlock = 1:size(matBatchIndicesFromBatchData,1)
                % skip blocks with small sizes (smaller than 15)
                if (matBatchIndicesFromBatchData(iBlock,2) - matBatchIndicesFromBatchData(iBlock,1)) < 15
                    continue
                end
                if all(cellfun(@isempty, cellData(matBatchIndicesFromBatchData(iBlock,1):min(matBatchIndicesFromBatchData(iBlock,2),length(cellData)))))
                    fprintf('%s: -- file %s, field %s is missing image data block %d to %d\n',mfilename,cellstrMeasurementFiles{iMeas},strFieldName,matBatchIndicesFromBatchData(iBlock,1),matBatchIndicesFromBatchData(iBlock,2))

                    % we could check if the batch_x_to_y_measurement file is
                    % empty, if so, reparsing does not make sense, and probably
                    % the measurement was absent for all images (at least the
                    % problem can not be fixed by re-fusing data).
                    strBatchMeasurementFile = fullfile(strRootPath,sprintf('Batch_%d_to_%d_%s',matBatchIndicesFromBatchData(iBlock,1),matBatchIndicesFromBatchData(iBlock,2),cellstrMeasurementFiles{iMeas}));

                    % if file is missing, let's ignore it for now, throw the
                    % error but consider the bigger output file as complete
                    if ~fileattrib(strBatchMeasurementFile)
                        fprintf('%s: ---- batch file %s is missing, ignoring data gap\n',mfilename,getlastdir(strBatchMeasurementFile))
                        continue
                    end

                    try
                        batchMeasurementHandles = load(strBatchMeasurementFile);
                    catch objError
                        fprintf('%s: ---- batch file %s is corrupt (%s), ignoring data gap\n',mfilename,getlastdir(strBatchMeasurementFile),objError.message)
                        continue
                    end

                    try
                        batchMeasurementHandles = LoadMeasurements(struct(),strBatchMeasurementFile);
                    catch objError
                        fprintf('%s: ---- batch file %s is not a valid batch file (%s), ignoring data gap\n',mfilename,getlastdir(strBatchMeasurementFile),objError.message)
                        continue
                    end
                    
                    % if handles is missing, create it here.
                    if ~isfield(batchMeasurementHandles,'handles')
                        batchMeasurementHandles.handles = batchMeasurementHandles;
                    end
                    
                    % see if all measurements in
                    % Batch_x_to_y_Measurement...mat are empty, if so
                    % ignore data gap
                    if all(cellfun(@isempty,batchMeasurementHandles.handles.Measurements.(strObjectName).(strFieldName)(matBatchIndicesFromBatchData(iBlock,1):matBatchIndicesFromBatchData(iBlock,2))))
                         fprintf('%s: ---- batch file %s contains empty measurements for image-cycle block, ignoring data gap\n',mfilename,getlastdir(strBatchMeasurementFile),objError.message)
                        continue
                    end
                    
                    % if the batch file is not missing, not corrupt and not
                    % empty, let's call it a true 'data fusion' problem!
                    boolDataIncomplete = 1;
                end
            end

        end

        % check if the file is complete, if so, clean up all corresponding
        % batch files, if not, set iBRAIN compatible flag file and leave batch
        % files present... (ugly to do this in matlab?) 
        strFlagFile = fullfile(strRootPath,strrep(cellstrMeasurementFiles{iMeas},'.mat','.datacheck-incomplete'));

        if ~boolDataIncomplete
            fprintf('%s: -- file %s is complete\n',mfilename,cellstrMeasurementFiles{iMeas})

            % get list of corresponding Batch_x_to_y_Measurements_z.mat files
            cellstrBatchMeasurementFiles = cellstrFile;
            cellstrBatchMeasurementFiles(cellfun(@isempty,regexp(cellstrBatchMeasurementFiles,['^Batch_\d{1,}_to_\d{1,}_',cellstrMeasurementFiles{iMeas}]))) = [];

            % use a cellfun(@delete to get rid of all corresponding batch
            % files...
            if ~isempty(cellstrBatchMeasurementFiles)
                fprintf('%s: -- cleaning up %d corresponding batch files\n',mfilename,length(cellstrBatchMeasurementFiles))
                if ~isunix
                    cellfun(@delete,strcat(strRootPath,cellstrBatchMeasurementFiles))
                else
                    % [BS] if we're on a unix environment, like the cluser,
                    % let's make a RM command... datafusioncheckandcleanup
                    % is timing out too often, and this is by far the
                    % slowest step!
                    strSystemCall = sprintf('rm -f %s',fullfile(strRootPath,sprintf('Batch_*_to_*_%s',cellstrMeasurementFiles{iMeas})));
                    fprintf('%s: -- linux detected, running system call: ''%s''\n',mfilename,strSystemCall)
                    system(strSystemCall);
                end
            end

            % if flag file is present while data is complete, remove it
            if fileattrib(strFlagFile)
                fprintf('%s: -- cleaning up old flag file %s\n',mfilename,strFlagFile)
                delete(strFlagFile)
            end

        else

            fprintf('%s: -- file %s is NOT complete, setting flag file!\n',mfilename,cellstrMeasurementFiles{iMeas})

            fid = fopen(strFlagFile, 'w');
            fclose(fid);
            fprintf('%s: -- created %s\n',mfilename,getlastdir(strFlagFile))
        end

        % clear handles for next run.
        clear handles

    end

end

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