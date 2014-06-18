function [handles, cellFileNames, matChannelNumber, matImagePositionNumber, cellstrMicroscopeType, matImageWellRow, matImageWellColumn, cellstrImageWellName, matObjectCountPerImage] = LoadStandardData(strRootPath)
% HELP FOR LoadStandardData
%
% Loads image file names and image object count from data, and process both
% 
%
% Usage: 
%
% [handles, cellFileNames, matChannelNumber, matImagePositionNumber, cellstrMicroscopeType, matImageWellRow, matImageWellColumn, cellstrImageWellName, matObjectCountPerImage] = LoadStandardData(strRootPath)


    if nargin==0
        strRootPath = 'Z:\Data\Users\Berend\090216_Mz_Tfn_CB\090216_Mz_Tfn_CB\BATCH';
    end
    strRootPath = npc(strRootPath);

    fprintf('%s: loading data from %s\n',mfilename,strRootPath)
    % init handles
    handles = struct();
    handles = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_Image_FileNames'));
    handles = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_Image_ObjectCount'));

    % put image file names in cell-array
    cellFileNames = cat(1,handles.Measurements.Image.FileNames{:});

    % object count per image
    matObjectCountPerImage = cat(1,handles.Measurements.Image.ObjectCount{:});

    % Image channel number
    fprintf('%s: parsing image name data: channel\n',mfilename)
    matChannelNumber = cellfun(@check_image_channel,cellFileNames);

    % Image position number, and microscope type
    fprintf('%s: parsing image name data: position & microscope\n',mfilename)
    [matImagePositionNumber,cellstrMicroscopeType] = cellfun(@check_image_position,cellFileNames,'UniformOutput',false);
    matImagePositionNumber = cell2mat(matImagePositionNumber);

    % Image well row, column and name
    fprintf('%s: parsing image name data: well row, column and name\n',mfilename)
    [matImageWellRow, matImageWellColumn, cellstrImageWellName] = cellfun(@filterimagenamedata,cellFileNames,'UniformOutput',false);
    matImageWellRow = cell2mat(matImageWellRow);
    matImageWellColumn = cell2mat(matImageWellColumn);

end