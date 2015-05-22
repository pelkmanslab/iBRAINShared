function [wellTotalIntensities,wellTotalImages, wellTotalCells, wellOutOfFocus] = ConvertHandlesToMeanIntensitiesArray(handles)

    matTotal = []; 
    matInfected = [];
    matWellPresent = [];
    
    str2match = []; 
    TotalInfectedIndex = [];
    cellFileNames = {};

    rowstodo = [2:8];
    colstodo = [2:11];
    
    matRows = {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P'};
    matCols = {'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24'};

    if ~exist('handles')
        warndlg('a valid cellprofiler handles variable is required')
        return
    end

    if ~isfield(handles,'Measurements')
        warndlg('there are no measurements in your handles file')
        return
    end

    if isfield(handles.Measurements,'Cells')
        strObjectName = 'Cells';
    elseif isfield(handles.Measurements,'Nuclei')
        strObjectName = 'Nuclei';
    else
        warndlg('there are no Cells or Nuclei objects in your handles file')
        return
    end

    %convert ImageNames to something we can index
    for l = 1:length(handles.Measurements.Image.FileNames)
        cellFileNames{l} = char(handles.Measurements.Image.FileNames{l}(1));
    end
    
    wellTotalCells = [];
    wellTotalIntensities = [];
    wellMeanIntensities = [];
    wellTotalImages = [];
    wellcounter = 0;
    wellName = {};
    
    for rowNum = rowstodo %2:7

        for colNum = colstodo %2:11

            %'_' 'A' '01' should match well A01 depending on the
            %nomenclature of the microscope & images.
            
            wellcounter = wellcounter + 1;
            
            str2match = strcat('_',matRows(rowNum), matCols(colNum));
            FileNameMatches = strfind(cellFileNames, char(str2match));

            
            tmpIntensities = [];
            tmpOutoffocus = 0;
            
            for k = find(~cellfun('isempty',FileNameMatches))
                tmpIntensities = [tmpIntensities;handles.Measurements.(strObjectName).Intensity_RescaledRed{k}(:,2)];
                if isfield(handles.Measurements.Image,'RescaledBlueSpectrum')
                    if max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) < 20
                        tmpOutoffocus = tmpOutoffocus + 1;
                    end
                end
%                 tmpOutoffocusness = [tmpOutoffocusness;handles.Measurements.Image.RescaledBlueSpectrum{k}(1,1)];
            end

%             [n,xout] = hist(tmpIntensities);
            [wellHistogram{rowNum,colNum,1} wellHistogram{rowNum,colNum,2}] = hist(tmpIntensities);
%             clear n xout
            
            wellTotalImages(wellcounter,1) = length(find(~cellfun('isempty',FileNameMatches)));
            
            wellOutOfFocus(wellcounter,1) = tmpOutoffocus;            
            wellTotalIntensities(wellcounter,1) = mean(tmpIntensities);
            wellTotalCells(wellcounter,1) = length(tmpIntensities);            
%             wellMeanIntensities(rowNum,colNum) = mean(handles.Measurements.(strObjectName).Intensity_RescaledRed{find(~cellfun('isempty',FileNameMatches))}(:,2));                

            wellName(wellcounter,1) = strcat(matRows(rowNum),matCols(colNum));
            
         end
    end

return
    
figure;
clf;    

subplot(2,2,1)

imagesc(wellTotalIntensities);
% scatter(wellTotalIntensities(5,:),1:6);
title('Mean Mean Cell Intensity')
colorbar;

subplot(2,2,2)
imagesc(wellTotalImages);
title('Total Images per Well')
colorbar;

subplot(2,2,3)
imagesc(wellTotalCells);
title('Total Cell Number')
colorbar;

subplot(2,2,4)
imagesc(wellOutOfFocus);
title('OutOfFocus Images per Well ')
colorbar;
% 
% figure(2);
% clf;    
% 
% plotcounter = 0;
% for rowNum = 1:8
%     for colNum = 1:6
%         plotcounter = plotcounter + 1;
%         subplot(6,8,plotcounter)
%         bar([wellHistogram{rowNum,colNum,2}],[wellHistogram{rowNum,colNum,1}])
%     end
% end


% end