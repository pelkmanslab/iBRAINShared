function [handles] = initTrackingSettings(strSettingsFile) %#ok<STOUT>

%%% This function parses the SetTracking_ file, if no settings are
%%% specified then in returs default settings. I also initializes the
%%% handles structure which shall contains the results of the tracker.
%%% settings from a file, or from this function directly. Note it was
%%% modified from Berend's code
% strSettingsFile = ('SetTracking_Nuclei01.txt');

if nargin==0
    error('No setting File specified in ParseSetTrackingFile.');
end


% check if file exists
if ~fileattrib(strSettingsFile)
    error('%s: settingsfile %s does not exist',mfilename,strSettingsFile)
end

% open file for reading
fid = fopen(strSettingsFile,'r');
% check if opening worked
if ~(fid>0)
    error('%s: failed to open %s',mfilename,strSettingsFile)
end

% variables required for counting measurement blocks in the new format
intBlockCounter = 1;
boolJustPorcessedBlock = false;



% Initialize the structure structTrackingSettings with default values
structTrackingSettings = struct();
structTrackingSettings.TrackingMethod = 'Distance';
structTrackingSettings.ObjectName = 'Nuclei';
structTrackingSettings.PixelRadius = 10;
structTrackingSettings.CollectStatistics = 'Yes';
structTrackingSettings.OverlapFactorC = 0.3;
structTrackingSettings.OverlapFactorP = 0.3;

% loop over each line
fprintf('%s: Parsing setting file %s.\n',mfilename,strSettingsFile);
while 1
    tline = fgetl(fid);
    if ~ischar(tline),   break,   end
    
    %%% hehe, this is higly insecure! ALMOST arbitrary code
    %%% execution, woot! :D
    tline = strtrim(tline);
    
    
    if isempty(tline) && boolJustPorcessedBlock
        % if we encounter an empty line, and we just had non-empty lines,
        % increment measurement block counter +1.
        intBlockCounter = intBlockCounter + 1;
        boolJustPorcessedBlock = false;
    end
    
    if ~strncmpi(tline, 'function ',9) && ...
            ~strncmpi(tline, 'end',3) && ...
            strncmpi(tline, 'structTrackingSettings.',23)
        
        % A setting was found. The default values will be changed
        strFieldName = regexpi(tline,'^structTrackingSettings.(\w{1,})','Tokens');
        strFieldName = char(strFieldName{:});
        
        if strncmp(strFieldName, 'TrackingMethod',14)...
                || strncmp(strFieldName, 'ObjectName',10)...
                || strncmp(strFieldName, 'PixelRadius',11)...
                || strncmp(strFieldName, 'CollectStatistics',17)...
                || strncmp(strFieldName, 'OverlapFactorC',14)...
                || strncmp(strFieldName, 'OverlapFactorP',14)...
                
            strFieldName = sprintf('MeasurementBlock_%d',intBlockCounter);
            boolJustPorcessedBlock = true;
            
            fprintf('%s: Setting %s\n',mfilename,tline);
            
            eval(tline)
            
        else
            error('%s: Typing error at %s',mfilename,tline)
        end
    end
end
fclose(fid);

% intialize handles structue

handles.Current = struct();
handles.Measurements.(structTrackingSettings.ObjectName) = struct();
handles.Current = struct();
handles.Pipeline = struct();
handles.TrackingSettings = structTrackingSettings;

% sanity checks
if ~exist('structTrackingSettings','var')
    fprintf('%s: %s did not produce desired output, using standard settings\n',mfilename,strSettingsFile)
else
    fprintf('%s: extracted settings from %s\n',mfilename,strSettingsFile)
    return
end            

end