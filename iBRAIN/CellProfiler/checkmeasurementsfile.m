function output = checkmeasurementsfile(strMeasurementsFile, strBatchDataFile, strImageObjectCountFile)
    warning off all
    output = 0;
    emptyindices = [];

    if nargin==0
       strMeasurementsFile = npc('\\nas-biol-imsb-1.d.ethz.ch\share-3-$\Data\Users\Prisca\090203_Mz_Tf_EEA1\090203_Mz_Tf_EEA1_CP394-1aa\BATCH\Measurements_Cells_ExtractCell_OrigGreen.mat')
       strBatchDataFile = npc('\\nas-biol-imsb-1.d.ethz.ch\share-3-$\Data\Users\Prisca\090203_Mz_Tf_EEA1\090203_Mz_Tf_EEA1_CP394-1aa\BATCH\Batch_data.mat')
    end
    
    % load Batch_data.mat to see how many imagesets are expected
    try
        load(strBatchDataFile)
    catch
        error('%s: failed to load Batch data file %s',mfilename,strBatchDataFile)
    end
    intNumberOfImages = handles.Current.NumberOfImageSets;
    intNumberOfImageSetsPerBatch = handles.Settings.VariableValues{end,2};
    
    % if passed, load objectcount to compensate for empty measurements due to no objects on the imageset
    if nargin == 3 && fileattrib(strImageObjectCountFile)
        try
            load(strImageObjectCountFile)
        catch
            warning('%s: failed to load object count file %s',mfilename,strImageObjectCountFile)
        end
        
        % select the correct object count column 
        % now 3 predefined objects: Nuclei, Cells, Spots... (for Ben)
        if not(isempty(strfind(strMeasurementsFile, 'Nuclei_')))
            intObjectColumn = find(strcmp(handles.Measurements.Image.ObjectCountFeatures,'Nuclei'));
        elseif not(isempty(strfind(strMeasurementsFile, 'Cells_')))
            intObjectColumn = find(strcmp(handles.Measurements.Image.ObjectCountFeatures,'Cells'));            
        elseif not(isempty(strfind(strMeasurementsFile, 'Spots_')))
            intObjectColumn = find(strcmp(handles.Measurements.Image.ObjectCountFeatures,'Spots'));            
        else
            intObjectColumn = find(strcmp(handles.Measurements.Image.ObjectCountFeatures,'Nuclei'));            
        end
        
        matObjectCount = cell2mat(handles.Measurements.Image.ObjectCount');        
        if not(isempty(intObjectColumn))
            matObjectCount = matObjectCount(:,intObjectColumn)';% TAKE THE CORRECT OBJECT COLUMN!
        else
            matObjectCount = matObjectCount(:,1)';% TAKE A GUESS            
        end
    else
        matObjectCount = ones(1,intNumberOfImages);        
    end    

    
    handles = struct();
    try
        handles = LoadMeasurements(handles,strMeasurementsFile);
    catch
        error('%s: failed to load Measurements file %s',mfilename,strMeasurementsFile)
    end

    
    parents = fieldnames(handles.Measurements);
    for i = 1:size(parents,1)
        ListOfMeasurements = fieldnames(handles.Measurements.(parents{i}));
        
        for ii = 1:size(ListOfMeasurements,1)        
            if length(ListOfMeasurements{ii}) > 6 && ... 
               (not(strcmp(ListOfMeasurements{ii}(1,end-7:end),'Features')) && not(strcmp(ListOfMeasurements{ii}(1,end-3:end),'Text')))
           
                intMissingDataCounter = 0;
                counter = 0;
    
                if size(handles.Measurements.(parents{i}).(ListOfMeasurements{ii}),2) < intNumberOfImages
                	intMissingDataCounter = intNumberOfImages - size(handles.Measurements.(parents{i}).(ListOfMeasurements{ii}),2);
                elseif size(handles.Measurements.(parents{i}).(ListOfMeasurements{ii}),2) > intNumberOfImages
                    error('%s: handles.Measurements.%s has more image results (%d) then expected from the Batch_data.mat file (%d)',mfilename,ListOfMeasurements{ii},size(handles.Measurements.(parents{i}).(ListOfMeasurements{ii}),2), intNumberOfImages)
                end
                
                if iscell(handles.Measurements.(parents{i}).(ListOfMeasurements{ii}))
%                     disp(sprintf('checkmeasurementsfile: handles.Measurements.%s.%s is a cell array', parents{i}, ListOfMeasurements{ii}))
%                     emptyindices = find(cellfun('isempty',handles.Measurements.(parents{i}).(ListOfMeasurements{ii})));
                    for iii = 1:size(handles.Measurements.(parents{i}).(ListOfMeasurements{ii}),2)
                        if isempty(handles.Measurements.(parents{i}).(ListOfMeasurements{ii}){iii}) && (matObjectCount(1,iii) >= 1) && ...
                                not(strcmp(char(ListOfMeasurements{ii}),'GridNucleiCount')) && ...
                                not(strcmp(char(ListOfMeasurements{ii}),'GridNucleiEdges')) && ...
                                not(strcmp(char(ListOfMeasurements{ii}),'VirusScreenThresholds'))
                            counter = counter + 1;
                            emptyindices(1,counter) = iii;
                            
                            % these measurements produce empty output if
                            % only 1 nucleus is present
                        elseif isempty(handles.Measurements.(parents{i}).(ListOfMeasurements{ii}){iii}) && (matObjectCount(1,iii) >= 2) && ...
                                ( strcmp(char(ListOfMeasurements{ii}),'GridNucleiCount') || ...
                                   strcmp(char(ListOfMeasurements{ii}),'GridNucleiEdges') || ...
                                   strcmp(char(ListOfMeasurements{ii}),'VirusScreenThresholds') )
                            counter = counter + 1;
                            emptyindices(1,counter) = iii;
                        end
                    end
                elseif isnumeric(handles.Measurements.(parents{i}).(ListOfMeasurements{ii}))
%                     disp(sprintf('checkmeasurementsfile: handles.Measurements.%s.%s is a numeric array', parents{i}, ListOfMeasurements{ii}))
                    for iii = 1:size(handles.Measurements.(parents{i}).(ListOfMeasurements{ii}),2)
                        if isempty(handles.Measurements.(parents{i}).(ListOfMeasurements{ii})(iii)) && (matObjectCount(1,iii) >= 1)
                            counter = counter + 1;
                            emptyindices(1,counter) = iii;
                        end
                    end
                else
                    error('%s: handles.Measurements.%s is of unrecognized type ''%s''',mfilename,ListOfMeasurements{ii},class(handles.Measurements.(parents{i}).(ListOfMeasurements{ii})))
                end

                intMissingDataCounter = intMissingDataCounter + length(emptyindices);

                %%% BEN RESULTS HACK!                
                %%% ORIGINAL LINE:
                %%% if (isempty(emptyindices) && intMissingDataCounter == 0)
                %%%
                
                if (isempty(emptyindices) && intMissingDataCounter == 0) ... 
                        || strcmp(char(parents{i}),'Bacterial_results') ...
                        || not(isempty(strfind(char(ListOfMeasurements{ii}),'Excl'))) ...
                        || not(isempty(strfind(char(ListOfMeasurements{ii}),'Bleb')))

                    disp(sprintf('%s: handles.Measurements.%s is complete',mfilename,ListOfMeasurements{ii}))
                    output = 1;
                    
                %%% ADDED THE FOLLOWING LINE, IF THERE ARE FEWER DATAPOINTS
                %%% MISSING THAN THERE WOULD BE IN A SINGLE BATCH SET,
                %%% CONSIDER THE DATA TO BE COMPLETE AS WELL...
                %%% [BS, 2009-02-10].
                elseif intMissingDataCounter < intNumberOfImageSetsPerBatch

                    fprintf('%s: handles.Measurements.%s is complete\n',mfilename,ListOfMeasurements{ii})
                    output = 1;

                else
                    fprintf('%s: handles.Measurements.%s is NOT complete. There are %d missing values\n',mfilename,ListOfMeasurements{ii},intMissingDataCounter)                        
                end                
                
            end
        end
    end
end