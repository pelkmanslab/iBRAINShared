function SeparateMeasurementsFromHandles(handles,cluster)

warning off all

% check if handles.Measurements exists
if not(isfield(handles, 'Measurements'))
   error('SeparateMeasurementsFromHandles: Handles does not contain any Measurements') 
   return
end

% we want to work with either a cluster file, when called from CPCluster,
% or without one, in which case we assume BathFilePrefix to be 'Batch_'.
if nargin == 2 && isfield(cluster, 'BatchFilePrefix')
    BatchFilePrefix = cluster.BatchFilePrefix;
    StartImage = cluster.StartImage;
    EndImage = cluster.EndImage;
else
    BatchFilePrefix = 'Batch_';
    try
        StartImage = handles.Current.BatchInfo.Start;
        EndImage = handles.Current.BatchInfo.End;
    catch
        StartImage = 1;
        EndImage = length(handles.Measurements.Image.FileNames);        
    end
end

strDataSorterOutputFolderPath = handles.Current.DefaultOutputDirectory;
% virus infection fields
cellstrFieldsWithNoDescription = {'VirusScreenGaussians','VirusScreenThresholds','GridNucleiCount','GridNucleiEdges'};
% benjamin misselwitz fields
cellstrFieldsWithNoDescription = [cellstrFieldsWithNoDescription, {'ImageFileName','NumberNuclei','NumberSpots','ThresholdNuclei','ThresholdSpots','NumberInfectedCells','uninfected','count_spot_1','count_spot_2','count_spot_3','count_spot_4','count_spot_5','count_spot_6','count_spot_7','count_spot_8','count_spot_9','count_spot_10','spot_over_10','spot_related','spot_unrelated','SpotHistogramm','SpotDistance','MaxSpotSpotDistance','SpotIntensity','NucleiIntensity','PercentInfectedCells','LargeSizeExclNuclei','LargeSizeExclSpots','SmallSizeExclNuclei','SmallSizeExclSpots','BorderExclNuclei','BorderExclSpots','totalNuclei','Percent_LaSize','PreBlebSpots','PreBlebAreaSpots','MaxImageGranularity','WarningFocus','WarningFocus2','WarningBlobs','WarningBlebs','Included'}];

%%%%%%%%%%%%%%%%%%%%%%%
%%%  STORING  DATA  %%%
%%%%%%%%%%%%%%%%%%%%%%%

ListOfObjects = fieldnames(handles.Measurements); 
for ix = 1:length(ListOfObjects)
    ListOfMeasurements = fieldnames(handles.Measurements.(char(ListOfObjects(ix))));
    for iix = 1:length(ListOfMeasurements)
        if ((length(ListOfMeasurements{iix}) > 7 && ~(strcmp(ListOfMeasurements{iix}(1,end-7:end),'Features')))  ...
            || (length(ListOfMeasurements{iix}) > 3 && ~(strcmp(ListOfMeasurements{iix}(1,end-3:end),'Text')))) ...
            && (length(ListOfMeasurements{iix}) > 5 && ~(strcmp(ListOfMeasurements{iix}(1,1:6),'illcor')))
            % we are not dealing with a ...Features or ...Text list

            OutPutFile = fullfile(strDataSorterOutputFolderPath, sprintf('%s%d_to_%d_Measurements_%s_%s',BatchFilePrefix,StartImage,EndImage,char(ListOfObjects(ix)), char(ListOfMeasurements(iix))));
            matPossibleFeaturesIndex = strcmp(ListOfMeasurements, strcat(char(ListOfMeasurements(iix)),'Features'));
            matPossibleTextIndex = strcmp(ListOfMeasurements, strcat(char(ListOfMeasurements(iix)),'Text'));
            intFieldDescriptionIndex = [find(matPossibleFeaturesIndex), find(matPossibleTextIndex)];

            % init the output variable Measurements
            Measurements = struct();            

            % save MeasurementFields that do not have a DescriptionField as
            % listed in cellstrFieldsWithNoDescription
            if not(isempty(find(strcmp(cellstrFieldsWithNoDescription, char(ListOfMeasurements(iix))))))
                disp(sprintf('saving %s%d_to_%d_Measurements.%s.%s',BatchFilePrefix,StartImage,EndImage,char(ListOfObjects(ix)), char(ListOfMeasurements(iix))))
                Measurements.(char(ListOfObjects(ix))).(char(ListOfMeasurements(iix))) = handles.Measurements.(char(ListOfObjects(ix))).(char(ListOfMeasurements(iix)));
                save(OutPutFile, 'Measurements','-v7.3');%
            % also save all fieldnames that have descriptionfields
            elseif not(isempty(intFieldDescriptionIndex))
                %%% REGULAR CODE
                disp(sprintf('saving %s%d_to_%d_Measurements.%s.%s and %s',BatchFilePrefix,StartImage,EndImage,char(ListOfObjects(ix)), char(ListOfMeasurements(intFieldDescriptionIndex)), char(ListOfMeasurements(iix))))
                Measurements.(char(ListOfObjects(ix))).(char(ListOfMeasurements(intFieldDescriptionIndex))) = handles.Measurements.(char(ListOfObjects(ix))).(char(ListOfMeasurements(intFieldDescriptionIndex)));
                Measurements.(char(ListOfObjects(ix))).(char(ListOfMeasurements(iix))) = handles.Measurements.(char(ListOfObjects(ix))).(char(ListOfMeasurements(iix)));
                save(OutPutFile, 'Measurements','-v7.3');%
            end
            clear Measurements;
        else
            disp(sprintf('SKIPPED %s', char(ListOfMeasurements{iix})))
        end
    end
end


end % end function
