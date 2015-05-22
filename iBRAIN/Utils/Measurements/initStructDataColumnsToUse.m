function [structDataColumnsToUse, structMiscSettings] = initStructDataColumnsToUse(strSettingsFile) %#ok<STOUT>

%%% determines the tensor input settings, either from reading in the
%%% settings from a file, or from this function directly
if nargin==0
%     strSettingsFile = '/Volumes/share-2-$/Data/Users/Herbert/iBRAIN_ii/ProbModel_Settings.txt';
%     strSettingsFile = npc('\\nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\ProbModel_Settings_test.txt');
    
    strSettingsFile = npc('Y:\Data\Users\Prisca\endocytome\090203_MZ_w2Tf_w3EEA1\getRawProbModData2_NEW_INPUT.txt');
end

% a struct to keep count of how often each field name is added
structFieldCounter = struct();
structExclusionFieldCounter = struct();

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

% loop over each line
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
            (strncmpi(tline, 'structDataColumnsToUse',21) || ...
            strncmpi(tline, 'structMiscSettings',17))

        % idea, if users adds the same 'parent' fieldname
        % multiple times, let's make the struct
        % incremental, and loop over all the similar parent
        % fieldnames in downstreamprocessing...   
        if strncmpi(tline, 'structDataColumnsToUse.',23)
            
            % we shold be able to switch between the old and the new format
            strFieldName = regexpi(tline,'^structDataColumnsToUse.(\w{1,}).','Tokens');
            strFieldName = char(strFieldName{:});

            % check if new format or old
            if ismember(strFieldName,{'Column','FileName','DiscardNaNs','ObjectName','MeasurementName','Label','Log10Transform'})
                % new format detected. append 'MeasurementBlock' to
                % beginning of line, to keep in style with old
                % formatting...
                strFieldName = sprintf('MeasurementBlock_%d',intBlockCounter);
                tline = strrep(tline,'structDataColumnsToUse.',sprintf('structDataColumnsToUse.MeasurementBlock_%d.',intBlockCounter));
                
                % new format, note that we just processed a line...
                boolJustPorcessedBlock = true;
                structFieldCounter.(strFieldName) = 1;
                
            else
                % old format depends on this line to find a new block.
                if ~isempty(strfind(tline,'.Include = true'))
                    if isfield(structFieldCounter,strFieldName)
                        structFieldCounter.(strFieldName) = structFieldCounter.(strFieldName) + 1;
                    else 
                        structFieldCounter.(strFieldName) = 1;
                    end
                end
                
            end
                
            

            strToReplace = sprintf('structDataColumnsToUse.%s.',strFieldName);
            strToReplaceWith = sprintf('structDataColumnsToUse.%s(%d).',strFieldName,structFieldCounter.(strFieldName));
            tline = strrep(tline,strToReplace,strToReplaceWith);
        end

        % also allow multiple object & image exclusion
        % blocks. Assume first field = 'Column' for
        % exclusion blocks...
        if strncmpi(tline, 'structMiscSettings.',19) 
            strFieldName = regexpi(tline,'^structMiscSettings.(\w{1,}).','Tokens');
            strFieldName = char(strFieldName{:});

            if ~isempty(strfind(tline,'.Column'))
                if isfield(structExclusionFieldCounter,strFieldName)
                    structExclusionFieldCounter.(strFieldName) = structExclusionFieldCounter.(strFieldName) + 1;
                else 
                    structExclusionFieldCounter.(strFieldName) = 1;
                end
            end

            if isfield(structExclusionFieldCounter,strFieldName)
                strToReplace = sprintf('structMiscSettings.%s.',strFieldName);
                strToReplaceWith = sprintf('structMiscSettings.%s(%d).',strFieldName,structExclusionFieldCounter.(strFieldName));
                tline = strrep(tline,strToReplace,strToReplaceWith);
            end
        end                        

        % here we go...
        eval(tline)

    end
end
fclose(fid);

% sanity checks
if ~exist('structDataColumnsToUse','var') && ~exist('structMiscSettings','var')
    fprintf('%s: %s did not produce desired output, using standard settings\n',mfilename,strSettingsFile)
else
    fprintf('%s: extracted settings from %s\n',mfilename,strSettingsFile)
    return
end            



end