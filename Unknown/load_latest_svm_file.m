function [handles, strSvmMeasurementName, numPositiveClassNumber] = load_latest_svm_file(handles, strRootPath, strSvmStrMatch,varargin)
%%% BS: 080828. load_latest_svm_file load the svm measurement file from
%%% strRootPath into handles, that matches the search string stored in
%%% strSvmStrMatch, and returns the handles, and the measurement name with
%%% which to index handles.Measurements.Nuclei.(strSvmMeasurementName), and
%%% the number of the positive class, i.e. the class that does not start
%%% with 'non' or 'not'.

%%% ADDED OPTIONAL INPUT 'NEWEST' (CASE INSENSITIVE): WHICH PREFERS THE
%%% NEWEST SVM OUTPUT AS OPPOSED TO THE SVM WITH THE HIGHEST NUMBER

strSvmMeasurementName = '';
numPositiveClassNumber = NaN;
boolNumberInfoMissing = 0;

if nargin == 0;
    handles = struct();
%     strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\SV40_DG\20080715103908425-668_20080715103052_M1_rescan_SV40_DG_CP069-1dg\BATCH';
    strRootPath = npc('/BIOL/imsb/fs3/bio3/bio3/Data/Users/50K_final_reanalysis/IV_MZ/061004_IV_MZ_P3_1_3_CP073-1ac/BATCH/')
    strSvmStrMatch = 'blob'
    varargin={'newest'}
end

% get list of all SVM files present
cellSvmDataFiles = SearchTargetFolders(strRootPath,'Measurements_SVM_*.mat');


% if none found, give warning and return
if isempty(cellSvmDataFiles)
   warning('MATLAB:NoSVMFilesFound','%s: no SVM files found in %s',mfilename,strRootPath) 
   return
end

% break apart in classification name and classification number
cellSvmPartMatches = regexp(getlastdir(cellSvmDataFiles),'Measurements_SVM_(\w*)_(\d*).mat','Tokens');

cellSvmPartMatches2 = regexp(getlastdir(cellSvmDataFiles),'Measurements_SVM_(\w*).mat','Tokens');
if isempty(find(~cellfun(@isempty,cellSvmPartMatches), 1))
    warning('MATLAB:SVMFilesDoNotMatchNomenclature','%s: no SVM files found containing both a classification name and number according to the following regexp "Measurements_SVM_(\\w*)_(\\d*).mat"',mfilename) 
    
    % check if there are lesser strict matches...
    if ~isempty(find(~cellfun(@isempty,cellSvmPartMatches2), 1))
        disp(sprintf('%s: found less strict SVM measurement name matches. Using those.',mfilename))
        cellSvmPartMatches = cellSvmPartMatches2;
        boolNumberInfoMissing = 1;
    else
        return
    end
end

% removing non-officially names SVM classes
matIncorrectlyNamedIndices = cellfun(@isempty,cellSvmPartMatches);
if sum(matIncorrectlyNamedIndices) > 0
    warning('MATLAB:IncorrectSVMFilesFound','%s: removing %d incorrectly names SVM file(s)',mfilename,sum(matIncorrectlyNamedIndices)) 
    cellSvmPartMatches(matIncorrectlyNamedIndices) = [];
    cellSvmDataFiles(matIncorrectlyNamedIndices) = [];    
end

% extract to user friendly cell (containing svm names) and matrix (containing svm numbers)
matSvmClassificationNumbers=[];
cellstrSvmClassificationNumbers={};
cellSvmClassificationNames={};
for i = 1:length(cellSvmPartMatches)
    cellSvmClassificationNames = [cellSvmClassificationNames;cellSvmPartMatches{i}{1}(1)]; %#ok<AGROW>
    
    % if we're working with less strict matches, set number to 0.
    if boolNumberInfoMissing
        matSvmClassificationNumbers = [matSvmClassificationNumbers;1];
        cellstrSvmClassificationNumbers = [cellstrSvmClassificationNumbers;{'1'}]; %#ok<AGROW>
    else
        matSvmClassificationNumbers = [matSvmClassificationNumbers;str2double(cellSvmPartMatches{i}{1}{2})]; %#ok<AGROW>
        cellstrSvmClassificationNumbers = [cellstrSvmClassificationNumbers;cellSvmPartMatches{i}{1}{2}]; %#ok<AGROW>
    end
    
end

% check the svm-number-sorted svm-names, for matches against the search
% string in strSvmStrMatch (case insensitive, both converted to upper)
% matSvmNameMatches = ~cellfun(@isempty,strfind(upper(cellSvmClassificationNames),upper(strSvmStrMatch)));

% let's use regular expressions, but keep in mind backward compatibility!
matSvmNameMatches = ~cellfun(@isempty,regexpi(cellSvmClassificationNames,strSvmStrMatch));

% remove those svm classifications that do not match the requested
% strSvmStrMatch
cellSvmPartMatches(~matSvmNameMatches) = [];
cellSvmDataFiles(~matSvmNameMatches) = [];    
cellSvmClassificationNames(~matSvmNameMatches) = [];    
matSvmClassificationNumbers(~matSvmNameMatches) = [];    
cellstrSvmClassificationNumbers(~matSvmNameMatches) = [];    

if isempty(find(matSvmNameMatches, 1))
   warning('MATLAB:NoSVMMatches','%s: no SVM files found matching your search string "%s"',mfilename,strSvmStrMatch)
   return
end

if isempty(find(strcmpi(varargin,'newest')))
    % get the indexes (ix) of the ordered svm numbers
    [a,ix]=max(matSvmClassificationNumbers);
    % get the index of the lates file to load
    numSvmFileIndexLoad = ix(1);
%     disp('highest number')
else
    % get the latest created/modified file
    if ~isempty(cellSvmDataFiles)
        a = cellfun(@dir,cellSvmDataFiles);
        [b,ix]=max(cat(1,a.datenum));
        % set the strSvmMeasurementName output parameter
        numSvmFileIndexLoad = ix(1);    
    end        
%     disp('latest file')    
end


% load the measurement file
try
    disp(sprintf('%s: loading %s',mfilename,getlastdir(cellSvmDataFiles{numSvmFileIndexLoad})))
    handles = LoadMeasurements(handles,cellSvmDataFiles{numSvmFileIndexLoad});
catch 
   warning('MATLAB:FailedToLoadFile','%s: failed to load "%s"',mfilename,cellSvmDataFiles{numSvmFileIndexLoad})
   disp(lasterr.message)
   return
end

% set the strSvmMeasurementName output parameter
if boolNumberInfoMissing
    strSvmMeasurementName = sprintf('%s',cellSvmClassificationNames{numSvmFileIndexLoad});
else
    strSvmMeasurementName = sprintf('%s_%s',cellSvmClassificationNames{numSvmFileIndexLoad},cellstrSvmClassificationNumbers{numSvmFileIndexLoad});
end

% get the _Features value stored by the classify_gui svm tool in the
% measurement file
cellSvmFeatureValues = handles.Measurements.SVM.([strSvmMeasurementName,'_Features']);

% match which of these start with the word non or not, followed by a dash,
% underscore or whitespace...
matNonMatches = ~cellfun(@isempty,regexpi(cellSvmFeatureValues,'^no[nt][_-\w]','start'));

if isempty(find(matNonMatches))
   warning('MATLAB:StrangeSVMFeatures','%s: no class name started with ''non'' or ''not'' in "%s", setting the first class as the positive class number',mfilename,strSvmMeasurementName)
end

numPositiveClassNumber = find(~matNonMatches,1,'first');