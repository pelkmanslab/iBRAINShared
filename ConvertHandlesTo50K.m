function [matTotal, matInfected, matImagesPerWell] = ConvertHandlesTo50K(handles)

% 2007-02-13 Berend Snijder
% ConvertHandlesTo50K takes a CellProfiler output file and returns the
% total objects (assuming either Cells or Nuclei), and total infected cells
% if the VirusInfection data is present, per well for maximally a 384 well
% plate.
%
% Usage:
% [matTotalObjects, matInfectedObjects, matImagesPerWell] = ConvertHandlesToPlate(handles)
%
% UPDATE: Now includes out of focus discarding optionally via
% Image.OutOfFocus

    matTotal = []; 
    matInfected = [];
    matImagesPerWell = [];
    
    str2match = []; 
    TotalInfectedIndex = [];
    OutOfFocusImage = [];
    cellFileNames = {};

    
    rowstodo = [2:8];
    colstodo = [2:11];
    
    matRows = {'A','B','C','D','E','F','G','H'};
    matCols = {'01','02','03','04','05','06','07','08','09','10','11','12'};
    
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

    if isfield(handles.Measurements.(strObjectName),'VirusInfection')
       boolVirusData = 1;
       VirusInfectionFieldName = 'VirusInfection';
       TotalInfectedIndex = strfind(handles.Measurements.(strObjectName).VirusInfectionFeatures, 'TotalInfected');
       TotalInfectedIndex = find(~cellfun('isempty',TotalInfectedIndex));
    elseif isfield(handles.Measurements.(strObjectName),'VirusScreenInfection_Overview')
       boolVirusData = 1;
       VirusInfectionFieldName = 'VirusScreenInfection_Overview';   
       TotalInfectedIndex = strfind(handles.Measurements.(strObjectName).VirusScreenInfection_OverviewFeatures, 'TotalInfected');
       TotalInfectedIndex = find(~cellfun('isempty',TotalInfectedIndex));
    else
        boolVirusData = 0;
    end    

    boolSelectedImageData = 0;
    if isfield(handles.Measurements,'Well')
        if isfield(handles.Measurements.Well,'Selected_images')
%            disp('ConvertHandlesTo50K: using Selected_images data')
           boolSelectedImageData = 1;
           SelectedImages = handles.Measurements.Well.Selected_images;
        end
    end        
    
    if isfield(handles.Measurements.Image,'OutOfFocus')
       boolOutOfFocusData = 1;
       OutOfFocusImage = handles.Measurements.Image.OutOfFocus;
    else
        boolOutOfFocusData = 0;
    end

%
%     if isfield(handles.Measurements.(strObjectName),'CellClassification')
%        boolNucleiClassificationData = 1;
%        NucleiClasses = handles.Measurements.(strObjectName).CellClassification;
%     else
%         boolNucleiClassificationData = 0;
%     end            
    
    %convert ImageNames to something we can index
    for l = 1:length(handles.Measurements.Image.FileNames)
        cellFileNames{l} = char(handles.Measurements.Image.FileNames{l}(1));
    end
    
    well = 0;

    for rowNum = rowstodo %2:7

        for colNum = colstodo %2:11
            
            well = well + 1;

            %'_' 'A' '01' should match well A01 depending on the
            %nomenclature of the microscope & images.
            
            str2match = strcat('_',matRows(rowNum), matCols(colNum));
            FileNameMatches = strfind(cellFileNames, char(str2match));
            
            intImgTotal = 0;
            intImgTotalInfected = 0;
            intImgPerWell = 0;

            
            if boolSelectedImageData
                imageindices = cell2mat(SelectedImages{rowNum}(colNum));
            else
                imageindices = find(~cellfun('isempty',FileNameMatches));
            end
            
            % set imageindices to empty if it only contains NaNs
            if size(find(isnan(imageindices))) == size(imageindices); imageindices = []; end
            
            for k = imageindices

                % if image is not out of focus, or if the out of focus data
                % is not present
                if not(OutOfFocusImage(1,k)) || not(boolOutOfFocusData)
                    intImgPerWell = intImgPerWell + 1;
                    intImgTotal = intImgTotal + handles.Measurements.Image.ObjectCount{k}(:,1);

                    % if infection data is present
                    if boolVirusData
                        intImgTotalInfected = intImgTotalInfected + handles.Measurements.(strObjectName).(VirusInfectionFieldName){k}(:,TotalInfectedIndex);                            
                    end
%                 else
%                     disp(['image discarded...', char(cellFileNames{k})])
                end

            end
            
            
            matImagesPerWell(1,well) = intImgPerWell;
            
            matTotal(1,well) = intImgTotal; 
            if boolVirusData
                matInfected(1,well) = intImgTotalInfected;
            end
        end
    end
end