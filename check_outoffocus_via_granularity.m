function [totaldiscarded, matdiscarded ] = check_outoffocus_via_granularity(strRootPath)
    
    if nargin == 0
       strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\50K_final\Ad3_KY\070208_Ad3_50K_Ky_1_1\';
    end

    handles = struct();
%     handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_FileNames.mat'));    
%     handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_ObjectCount.mat'));
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_RescaledBlueSpectrum.mat'));
%     handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_Intensity_RescaledGreen.mat'));

    warning off all
    
    intNumberOfImages = length(handles.Measurements.Image.FileNames);
    matImageIntensities = cell2mat(handles.Measurements.Image.Intensity_RescaledGreen');
    
    % check image intensity outliers...
    [matOutput, matDiscardedValues, matDiscardedImageIndices] = DiscardOutliers(matImageIntensities(:,2), 2.5);
    
    % check which images to score
    cellFileNames = cell(1,intNumberOfImages);
    for l = 1:length(handles.Measurements.Image.FileNames)
        cellFileNames{1,l} = char(handles.Measurements.Image.FileNames{l}(2));
    end
    
    totaldiscarded = 0;
    matdiscarded = zeros(intNumberOfImages,1);
    
    for k = 1:intNumberOfImages
        if max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) < 16
            matdiscarded(k,1) = 1;
            totaldiscarded = totaldiscarded + 1;
        end
    end

matdiscarded
totaldiscarded

%     for k = find(matdiscarded)%ImageIndexes
%         if max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) < 16 %max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) >= 16 && 
% %          if matImageIntensities(k,2) < 0.003
%             figure(1)
%             clf
%             strImagePath = [strrep(strRootPath,'Data\Users\Berend\BATCH_RESULTS\',''), 'TIFF', filesep];
% 
%             InputImageBlue = imread(fullfile(strImagePath, char(handles.Measurements.Image.FileNames{k}(1,1))));
%             InputImageBlue = double(InputImageBlue(:,:))/1200;
% 
%             InputImageBlue(find(InputImageBlue < 0)) = 0;
%             InputImageBlue(find(InputImageBlue > 1)) = 1;
% 
%             subplot(3,2,1)
%             bar(handles.Measurements.Image.RescaledBlueSpectrum{k})
% 
%             subplot(3,2,2)
%             hold on
%             hist(matImageIntensities(:,2),50)
%             vline(matImageIntensities(k,2))
%             hold off
% 
%             subplot(3,2,[3 4 5 6])
%             colormap gray;
%             hold on
%             imagesc(InputImageBlue);
%             hold off
%             drawnow
%             pause(.1)
%             discarded = discarded + 1;
%         end
%     end
