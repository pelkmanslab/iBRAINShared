function [BASICDATA] = fuse_basic_data_v5(strRootPath, BASICDATA)

if nargin == 0
    
    strRootPath = npc('/BIOL/imsb/fs2/bio3/bio3/Data/Users/Katharina/iBrain');
end

if nargin < 2
    % INITIALIZE BASICDATA
    BASICDATA = struct();
end

% LOOK FOR TARGET FOLDERS
fprintf('Looking for target folders in %s\n',strRootPath)
cellstrFolderList = findPlates(strRootPath);

% check number of basicdatas found
intNumOfFolders = size(cellstrFolderList,1);
fprintf('Found %d target folders\n',intNumOfFolders)

for iDir = 1:intNumOfFolders

    strCurrentDir = cellstrFolderList{iDir};
    strCurrentBasicData = findfilewithregexpi(strCurrentDir,'BASICDATA_.*\.mat');
    if isempty(strCurrentBasicData)
        fprintf('Skipping %s (no basicdata file found)\n',cellstrFolderList{iDir})
        continue
    else
        strCurrentBasicData = fullfile(strCurrentDir,strCurrentBasicData);
    end
    
    %%% LOAD BASICDATA
    fprintf('Loading %s\n',strCurrentBasicData)
    PLATE_BASICDATA = load(strCurrentBasicData);
    PLATE_BASICDATA = PLATE_BASICDATA.BASICDATA;

    strPlateDirectory = getbasedir(strCurrentDir);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% CHECK IF THERE IS Measurements_Nuclei_CellType_Overview DATA PER WELL, AND ADD TO PLATE_BASICDATA IF SO
    %%% Measurements_Nuclei_CellType_Overview.mat
    try
        strTargetFile = fullfile(strCurrentDir,'Measurements_Nuclei_CellType_Overview.mat');
        
        if fileattrib(strTargetFile)
            
            PLATE_CellTypeData = load(strTargetFile);

            if sum(PLATE_BASICDATA.WellCol == PLATE_CellTypeData.BASICDATA_CellType.WellCol) ~= 384 || ...
                    sum(PLATE_BASICDATA.WellRow == PLATE_CellTypeData.BASICDATA_CellType.WellRow) ~= 384
                error('Measurements_Nuclei_CellType_Overview plate layouts does not match BASICDATA plate layout!!!')
            end

            %%% automatically add all fieldnames (fieldnames slightly renamed),
            %%% they are all numerical matrices (double)
            cellFieldNames = fieldnames(PLATE_CellTypeData.BASICDATA_CellType);
            for iFieldName = cellFieldNames'
                % Skip WellRow, WellCol fields
                strFieldName = char(iFieldName);
                if ~strcmpi(strFieldName,'wellrow') && ~strcmpi(strFieldName,'wellcol')
                    % remove underscores, capitalize "index" and "number"
                    strNewFieldName = strrep(strFieldName,'_','');
                    strNewFieldName = strrep(strNewFieldName,'index','Index');
                    strNewFieldName = strrep(strNewFieldName,'number','Number');                
                    strNewFieldName = ['CellTypeOverview',strNewFieldName]; %#ok<AGROW>
                    PLATE_BASICDATA.(strNewFieldName) = PLATE_CellTypeData.BASICDATA_CellType.(strFieldName);
                end
            end

        end
    catch caughtError
        caughtError.identifier        
        caughtError.message
       disp(sprintf('error while adding %s from %s','Measurements_Nuclei_CellType_Overview',strPlateDirectory))
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% MERGE ALL FIELDS IN PLATE_BASICDATA TO BASICDATA %%%

    % LIST ALL FIELDNAMES IN PLATE_BASICDATA
    cellstrCurrentFieldNames = fieldnames(PLATE_BASICDATA);

    % LOOP OVER ALL FIELDNAMES, AND MERGE TO BASICDATA
    for sField = cellstrCurrentFieldNames'
        strFieldName = char(sField);

        intNumOfColumns = size(PLATE_BASICDATA.(strFieldName),2);
        intNumOfRows = size(PLATE_BASICDATA.(strFieldName),1);

        % CHECK IF FIELD IS ALREADY PRESENT, IF NOT, INITIALIZE IT
        % ACCORDING TO CLASS IN BASICDATA
        if ~isfield(BASICDATA,strFieldName)

            if isa(PLATE_BASICDATA.(strFieldName), 'char')
                BASICDATA.(strFieldName) = cell(intNumOfFolders,1);
            elseif isa(PLATE_BASICDATA.(strFieldName), 'numeric') && (intNumOfRows == 1)
                BASICDATA.(strFieldName) = NaN(intNumOfFolders,intNumOfColumns);
            elseif isa(PLATE_BASICDATA.(strFieldName), 'numeric') && (intNumOfRows > 1)
                BASICDATA.(strFieldName) = cell(intNumOfFolders,1);
            elseif isa(PLATE_BASICDATA.(strFieldName), 'cell')
                BASICDATA.(strFieldName) = cell(intNumOfFolders,intNumOfColumns);
            elseif isa(PLATE_BASICDATA.(strFieldName), 'struct')
                BASICDATA.(strFieldName) = cell(intNumOfFolders,intNumOfColumns);
            end
        end

        if isa(PLATE_BASICDATA.(strFieldName), 'char')
            BASICDATA.(strFieldName){iDir,:} = PLATE_BASICDATA.(strFieldName);
        elseif isa(PLATE_BASICDATA.(strFieldName), 'numeric') && (intNumOfRows > 1)
            BASICDATA.(strFieldName){iDir,:} = PLATE_BASICDATA.(strFieldName);
        else
            BASICDATA.(strFieldName)(iDir,:) = PLATE_BASICDATA.(strFieldName);
        end
    end
end


try
    disp(sprintf('\n%d plates gathered',size(BASICDATA.TotalCells,1)))
    disp(sprintf('Saving %s',fullfile(strRootPath,'BASICDATA.mat')))
    save(fullfile(strRootPath,'BASICDATA.mat'),'BASICDATA');
catch
    err1 = lasterror
    msg = err1.message;
    disp(sprintf('   !!! Saving BASICDATA failed on %s. \n\n%s',strRootPath, msg))
end


try
    disp('**** CREATING ADVANCEDDATA')
    ADVANCEDDATA = convert_basic_to_advanced_data(BASICDATA);
    disp('**** SAVING ADVANCEDDATA')
    save(fullfile(strRootPath,'ADVANCEDDATA.mat'),'ADVANCEDDATA');
catch
    err1 = lasterror
    msg = err1.message;
    disp(sprintf('*** creating and saving ADVANCEDDATA failed on %s. \n\n%s',strRootPath, msg))
end

try
    disp('**** CREATING ADVANCEDDATA2')
    Create_ADVANCEDDATA2_iBRAIN(strRootPath);
catch
    err1 = lasterror
    msg = err1.message;
    disp(sprintf('*** creating and saving ADVANCEDDATA2 failed on %s. \n\n%s',strRootPath, msg))
end

try
    disp('**** CREATING BASICDATA.csv')
    Convert_BASICDATA_to_csv(strRootPath)
catch
    err1 = lasterror
    msg = err1.message;
    disp(sprintf('*** creating and saving BASICDATA.csv failed on %s. \n\n%s',strRootPath, msg))
end


try
    disp('**** CREATING ADVANCEDDATA_html.csv')
%     Convert_ADVANCEDDATA_to_csv(strRootPath)
    Convert_ADVANCEDDATA_to_csv_HTML(strRootPath)
catch
    err1 = lasterror
    msg = err1.message;
    disp(sprintf('*** creating and saving ADVANCEDDATA_html.csv failed on %s. \n\n%s',strRootPath, msg))
end

try
    disp('**** CREATING ADVANCEDDATA2.csv')
    Convert_ADVANCEDDATA2_to_full_csv_iBRAIN(strRootPath)
catch
    err1 = lasterror
    msg = err1.message;
    disp(sprintf('*** creating and saving ADVANCEDDATA.csv failed on %s. \n\n%s',strRootPath, msg))
end

end%end of function