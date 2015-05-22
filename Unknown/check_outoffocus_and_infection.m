function [discarded,meaninfectionindex] = check_outoffocus_and_infection(strRootPath)
    
    discarded = [];
    meaninfectionindex = [];

    handles = struct();
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_FileNames.mat'));    
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_ObjectCount.mat'));
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_RescaledBlueSpectrum.mat'));
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Nuclei_VirusScreen_ClassicalInfection_Overview.mat'));

    warning off all
    
    intNumberOfImages = length(handles.Measurements.Image.FileNames);

    % check which images to score
    cellFileNames = cell(1,intNumberOfImages);
    for l = 1:length(handles.Measurements.Image.FileNames)
        cellFileNames{1,l} = char(handles.Measurements.Image.FileNames{l}(2));
    end
    discarded = 0;
    for k = 1:intNumberOfImages%ImageIndexes
%         disp(['checking: ',char(handles.Measurements.Image.FileNames{k}(1,1))])                    
        if handles.Measurements.Image.ObjectCount{k}(1,1)&& max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) < 16 %max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) >= 16 && 
            discarded = discarded + 1;
        end
        
    end
    
    tempInfectionData = cell2mat(handles.Measurements.Nuclei.VirusScreenInfection_Overview);
    infectionindex = tempInfectionData(:,2) ./ tempInfectionData(:,1);
    meaninfectionindex = mean(infectionindex(find(~isnan(infectionindex))));