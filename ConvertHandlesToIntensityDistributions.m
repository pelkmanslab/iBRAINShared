function [cellWellIntensities,wellTotalImages, wellTotalCells, wellOutOfFocus, wellHistogram, wellName] = ConvertHandlesToIntensityDistributions(handles)



    matTotal = []; 
    matInfected = [];
    matWellPresent = [];
    
    str2match = []; 
    TotalInfectedIndex = [];
    cellFileNames = {};

    rowstodo = [1:16];
    colstodo = [1:24];
    
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

    
    %  Object you want to measure
    
    if isfield(handles.Measurements,'Cells')
        strObjectName = 'Cells';
   
    else
        error('there are no objects in your handles file')
        return
    end


    % What do you want to measure and in which channel
    
    if isfield(handles.Measurements.(strObjectName),'Intensity_OrigRed')
        strFieldname = 'Intensity_OrigRed';
      
    
    else
        error('there are no measurements for object in your handles file')
        return
    end    
    
    disp(sprintf('ANALYZING %s FROM %s',strFieldname,strObjectName))
    
    
    %convert ImageNames to something we can index
    for l = 1:length(handles.Measurements.Image.FileNames)
        cellFileNames{l} = char(handles.Measurements.Image.FileNames{l}(1));
    end
    
    wellTotalCells = [];
    wellTotalIntensities = [];
    cellWellIntensities = {};
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
                tmpIntensities = [tmpIntensities;handles.Measurements.(strObjectName).(strFieldname){k}(:,2)];
                
                if isfield(handles.Measurements.Image,'RescaledBlueSpectrum')
                    if max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) < 20
                        tmpOutoffocus = tmpOutoffocus + 1;
                    end
                end
%                 tmpOutoffocusness = [tmpOutoffocusness;handles.Measurements.Image.RescaledBlueSpectrum{k}(1,1)];
            end

%             [n,xout] = hist(tmpIntensities);
%             [wellHistogram{rowNum,colNum,1} wellHistogram{rowNum,colNum,2}] = hist(tmpIntensities);
            [wellHistogram{rowNum,colNum}] = tmpIntensities;
%             clear n xout
            
            wellTotalImages(rowNum,colNum) = length(find(~cellfun('isempty',FileNameMatches)));
            
            wellOutOfFocus(rowNum,colNum) = tmpOutoffocus;            
            cellWellIntensities{rowNum,colNum} = tmpIntensities;
            wellTotalCells(rowNum,colNum) = length(tmpIntensities);            
%             wellMeanIntensities(rowNum,colNum) = mean(handles.Measurements.(strObjectName).(strFieldname){find(~cellfun('isempty',FileNameMatches))}(:,2));                

            wellName{rowNum,colNum} = strcat(matRows(rowNum),matCols(colNum));
            
         end
    end
