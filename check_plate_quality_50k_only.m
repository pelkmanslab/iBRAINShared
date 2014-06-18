function [discarded,meaninfectionindex,mediancellnumber,medianinfectionindex] = check_plate_quality_50k_only(strRootPath)
    
    discarded = [];
    meaninfectionindex = [];
    medianinfectionindex = [];
    
    handles = struct();
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_FileNames.mat'));    
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_ObjectCount.mat'));
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_RescaledBlueSpectrum.mat'));
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Nuclei_VirusScreen_ClassicalInfection_Overview2.mat'));
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_OutOfFocus.mat'));    

    warning off all
    
    intNumberOfImages = length(handles.Measurements.Image.FileNames);

    % check which images to score
    cellFileNamesAll = cell(1,intNumberOfImages);
    for l = 1:length(handles.Measurements.Image.FileNames)
        cellFileNamesAll{1,l} = char(handles.Measurements.Image.FileNames{l}(2));
    end
    discarded = 0;
    
    %%% check which filename system has been used
    cellFileNamesAll;
    
    FileNameMatches50K = regexp(cellFileNamesAll, '_[C-G]\d\d');
    ImageIndexes50K = find(~cellfun('isempty', FileNameMatches50K));
    
    tempInfectionData = [];
    infectionindex = [];
    
    for k = ImageIndexes50K % 1:intNumberOfImages%
%         disp(['checking: ',char(handles.Measurements.Image.FileNames{k}(1,1))])                    
%         if handles.Measurements.Image.ObjectCount{k}(1,1)&& max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) < 16 %max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) >= 16 && 
%             discarded = discarded + 1;
%         end

        if handles.Measurements.Image.OutOfFocus(1,k) == 1
            discarded = discarded + 1;
        else
            % only score good images...
            tempInfectionData(end+1,:) = handles.Measurements.Nuclei.VirusScreenInfection_Overview{k};
            infectionindex(end+1,:) = tempInfectionData(end,2) ./ tempInfectionData(end,1);        
        end
    end

%     try
        mediancellnumber = nanmedian(tempInfectionData(:,1));    
        meaninfectionindex = nanmean(infectionindex);
        medianinfectionindex = nanmedian(infectionindex);
%     catch
%         mediancellnumber = NaN;    
%         meaninfectionindex = NaN;
%         medianinfectionindex = NaN;        
%     end
    
    % determine oligo and triplicate number
%     foldername = strrep(folderlist{end},filesep,'')
    