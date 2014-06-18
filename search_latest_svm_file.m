function [strSvmMeasurementName,strSvmStrMatch] = search_latest_svm_file(strRootPath, strSvmStrMatch, varargin)
%%% BS: 080828. load_latest_svm_file load the svm measurement file from
%%% strRootPath into handles, that matches the search string stored in
%%% strSvmStrMatch, and returns the handles, and the measurement name with
%%% which to index handles.Measurements.Nuclei.(strSvmMeasurementName), and
%%% the number of the positive class, i.e. the class that does not start
%%% with 'non' or 'not'.

%%% ADDED OPTIONAL INPUT 'NEWEST' (CASE INSENSITIVE): WHICH PREFERS THE
%%% NEWEST SVM OUTPUT AS OPPOSED TO THE SVM WITH THE HIGHEST NUMBER

strSvmMeasurementName = '';

if nargin == 0;
%     strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\SV40_DG\20080715103908425-668_20080715103052_M1_rescan_SV40_DG_CP069-1dg\BATCH';
    strRootPath = npc('Y:\Data\Users\Prisca\endocytome\090203_MZ_w2Tf_w3EEA1\090203_Mz_Tf_EEA1_CP392-1ad\BATCH');
    strSvmStrMatch = 'BiNuclei';
end

% get list of all SVM files present
cellSvmDataFiles = findfilewithregexpi(strRootPath,sprintf('Measurements_SVM_.*%s.*\.mat',strSvmStrMatch));
% cellSvmDataFiles = SearchTargetFolders(strRootPath,'*SVM_*.mat','rootonly');

% if none found, give warning and return
if isempty(cellSvmDataFiles)
   warning('MATLAB:NoSVMFilesFound','%s: no SVM files found in %s',mfilename,strRootPath) 
   return
end

% break apart in classification name and classification number
cellSvmPartMatches = regexp(getlastdir(cellSvmDataFiles),'SVM_(\w*)_(\d*).mat','Tokens');

if isempty(find(~cellfun(@isempty,cellSvmPartMatches), 1))
    warning('MATLAB:SVMFilesDoNotMatchNomenclature','%s: no SVM files found containing both a classification name and number according to the following regexp "Measurements_SVM_(\\w*)_(\\d*).mat"',mfilename) 
    return
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
    matSvmClassificationNumbers = [matSvmClassificationNumbers;str2double(cellSvmPartMatches{i}{1}{2})]; %#ok<AGROW>
    cellstrSvmClassificationNumbers = [cellstrSvmClassificationNumbers;cellSvmPartMatches{i}{1}{2}]; %#ok<AGROW>
end

% check the svm-number-sorted svm-names, for matches against the search
% string in strSvmStrMatch (case insensitive, both converted to upper)
matSvmNameMatches = ~cellfun(@isempty,strfind(upper(cellSvmClassificationNames),upper(strSvmStrMatch)));

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
    
%     strSvmMeasurementName = strrep(getlastdir(cellSvmDataFiles{numSvmFileIndexLoad}),'.mat','');
    strSvmMeasurementName = sprintf('%s_%s',cellSvmClassificationNames{numSvmFileIndexLoad},cellstrSvmClassificationNumbers{numSvmFileIndexLoad});    
    disp(sprintf('%s: highest svm number for ''%s'' is %s',mfilename,strSvmStrMatch,strSvmMeasurementName))
else
    % get the latest created/modified file
    if ~isempty(cellSvmDataFiles)
        a = cellfun(@dir,cellSvmDataFiles);
        [b,ix]=max(cat(1,a.datenum));
        % set the strSvmMeasurementName output parameter
        numSvmFileIndexLoad = ix(1);    
    end        
    
%     strSvmMeasurementName = strrep(getlastdir(cellSvmDataFiles{numSvmFileIndexLoad}),'.mat','');
    strSvmMeasurementName = sprintf('%s_%s',cellSvmClassificationNames{numSvmFileIndexLoad},cellstrSvmClassificationNumbers{numSvmFileIndexLoad});
    disp(sprintf('%s: latest svm file for ''%s'' is %s',mfilename,strSvmStrMatch,strSvmMeasurementName))
end

