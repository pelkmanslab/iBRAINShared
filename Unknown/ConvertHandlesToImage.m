function [cellTotal, cellInfected, cellWellPresent] = ConvertHandlesToImage(handles)

% 2007-02-13 Berend Snijder & Pauli Rämö
% ConvertHandlesToPlate takes a CellProfiler output file and returns the
% total objects (assuming either Cells or Nuclei), and total infected cells
% if the VirusInfection data is present, per well for maximally a 384 well
% plate.

    cellTotal = {};
    cellInfected = {};
    cellWellPresent = {};
    
    str2match = []; 
    TotalInfectedIndex = [];
    cellFileNames = {};

    rowstodo = 1:16;
    colstodo = 1:24;
    
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

    if isfield(handles.Measurements.(strObjectName),'VirusInfection')
       boolVirusData = 1;
       TotalInfectedIndex = strfind(handles.Measurements.(strObjectName).VirusInfectionFeatures, 'TotalInfected');
       TotalInfectedIndex = find(~cellfun('isempty',TotalInfectedIndex));
    else
        boolVirusData = 0;
    end    


    %convert ImageNames to something we can index
    for l = 1:length(handles.Measurements.Image.FileNames)
        cellFileNames{l} = char(handles.Measurements.Image.FileNames{l}(1));
    end


    for rowNum = rowstodo %2:7

        for colNum = colstodo %2:11

            %'_' 'A' '01' should match well A01 depending on the
            %nomenclature of the microscope & images.
            
            str2match = strcat('_',matRows(rowNum), matCols(colNum));
            FileNameMatches = strfind(cellFileNames, char(str2match));
            imagecounter = 0;
          
            for k = find(~cellfun('isempty',FileNameMatches))
                imagecounter = imagecounter + 1;
                cellTotal{imagecounter}(rowNum,colNum) = handles.Measurements.Image.ObjectCount{k}(:,1);
                if boolVirusData
                    cellInfected{imagecounter}(rowNum,colNum) = handles.Measurements.(strObjectName).VirusInfection{k}(:,TotalInfectedIndex);
                end

                cellWellPresent{imagecounter}(rowNum,colNum) = ~isempty(k);
            end
            
            
            
        end
    end
end