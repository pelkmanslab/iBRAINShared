function [handles,ListOfObjects,ListOfMeasurements] = LoadMeasurements(handles, strFileName)
%
% Usage:
%
% [handles,ListOfObjects,ListOfMeasurements] = LoadMeasurements(handles, strFileName)
 

%     if nargin==0
%         handles=struct();
%         strFileName = npc('Z:\Data\Users\Berend\081008-berend\BATCH\Measurements_Cells_Texture_3_RescaledBlue.mat')
%         profile on
%     end

    ListOfObjects = {};
    ListOfMeasurements = {};

    % remove double fileseparators from file name if present, and if not at
    % the first index
    matDoubleFileSepIX = strfind(strFileName,[filesep,filesep]);
    if length(matDoubleFileSepIX) > 1
        if matDoubleFileSepIX(1)==1
            boolStartsWithDoubleFilesep = 1;
        end
        % remove all double fileseparators
        strFileName = strrep(strFileName,[filesep filesep],filesep);
        % if it started with one put the starting file separator back in
        % the string
        if boolStartsWithDoubleFilesep
            strFileName = [filesep,strFileName];
        end
    end


    if not(isstruct(handles))
        error('LoadMeasurements: Handles should be a valid structure variable.')
    end
    
    try
        tempHandles = load(strFileName);
    catch ME
        fprintf('%s: error loading %s\n',mfilename,strFileName)
        fprintf('%s: error message %s\n',mfilename,ME.message)
        fprintf('%s: error message %s\n',mfilename,ME.identifier)
        error(['LoadMeasurements: Unable to load ', strFileName]);
    end
    
    if isfield(tempHandles, 'handles') && isfield(tempHandles.handles, 'Measurements') 
        tempHandles.Measurements = tempHandles.handles.Measurements;
        tempHandles = rmfield(tempHandles,'handles');
%         disp('removed handles from loaded file...')
    elseif not(isfield(tempHandles, 'Measurements'))
        error('LoadMeasurements: Input file does not contain a Measurements field');
    end
    
    newHandles = handles;
%     disp(['LoadMeasurements: loaded ', strFileName]);        
        
    if not(isfield(newHandles, 'Measurements'))
        % if the struct didnt have any Measurements field, dump everything in as
        % is, we will not overwrite anything.
        newHandles.Measurements = tempHandles.Measurements;
%         disp('copying handles.Measurements')
    else
        ListOfObjects = fieldnames(tempHandles.Measurements);
        for i = 1:length(ListOfObjects)
            ListOfCurrentMeasurements = fieldnames(tempHandles.Measurements.(char(ListOfObjects(i))));
            ListOfMeasurements = [ListOfMeasurements;ListOfCurrentMeasurements]; %#ok<AGROW>
            if not(isfield(newHandles.Measurements, ListOfObjects(i)))
                % if the first field wasn't already present we can add it as is
                newHandles.Measurements.(char(ListOfObjects(i))) = tempHandles.Measurements.(char(ListOfObjects(i)));
%                 disp(sprintf('copying handles.Measurements.%s',(char(ListOfObjects(i)))))
            else
                % else we need to look for fields inside the
                % Measurements.ObjectField which weren't already present
                for ii = 1:length(ListOfCurrentMeasurements)
                    % check if measurement was already present, if so, only
                    % fill in the measurements that are present in this
                    % particular measurement file (COMPATIBILITY WITH PARTIAL CLUSTER RESULT FILES)
  
                    if not(isfield(newHandles.Measurements.(char(ListOfObjects(i))), ListOfCurrentMeasurements(ii) ))
%                         disp(sprintf('copying handles.Measurements.%s.%s',(char(ListOfObjects(i))),char(ListOfCurrentMeasurements(ii))))
                        newHandles.Measurements.(char(ListOfObjects(i))).(char(ListOfCurrentMeasurements(ii))) = tempHandles.Measurements.(char(ListOfObjects(i))).(char(ListOfCurrentMeasurements(ii)));
                    else

                        % find measurements indices that are present, and
                        % only fill in those..
                        if iscell(tempHandles.Measurements.(char(ListOfObjects(i))).(char(ListOfCurrentMeasurements(ii))))
                            % for cells
                            matMeasurementIndexes = find(~cellfun('isempty',tempHandles.Measurements.(char(ListOfObjects(i))).(char(ListOfCurrentMeasurements(ii)))));
                            for iii = 1:length(matMeasurementIndexes)
                                newHandles.Measurements.(char(ListOfObjects(i))).(char(ListOfCurrentMeasurements(ii))){matMeasurementIndexes(iii)} = tempHandles.Measurements.(char(ListOfObjects(i))).(char(ListOfCurrentMeasurements(ii))){matMeasurementIndexes(iii)};
                            end
    %                         disp(sprintf('filled %s with %d new measurements',char(ListOfCurrentMeasurements(ii)),length(matMeasurementIndexes)))                                                 
                        else
                            % for matrices (OutOfFocus exception... perhaps not smart?)
                            matMeasurementIndexes = find(tempHandles.Measurements.(char(ListOfObjects(i))).(char(ListOfCurrentMeasurements(ii))));
                            newHandles.Measurements.(char(ListOfObjects(i))).(char(ListOfCurrentMeasurements(ii)))(matMeasurementIndexes) = tempHandles.Measurements.(char(ListOfObjects(i))).(char(ListOfCurrentMeasurements(ii)))(matMeasurementIndexes);
                        end
                    end

                end
            end
        end
    end
    handles = newHandles;
    
%     if nargin==0
%         profile report
%     end
           
end