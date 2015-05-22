function PreCluster_from_pipeline(CPOutputFile, InputPath, OutputPath, cellstrFileREGEXPs)

%%% Must list all CellProfiler modules here
%#function Align ApplyThreshold Average CalculateMath CalculateRatios CalculateStatistics ClassifyObjects ClassifyObjectsByTwoMeasurements ColorToGray Combine ConvertToImage CorrectIllumination_Apply CorrectIllumination_Calculate CreateBatchFiles CreateWebPage Crop DefineGrid DisplayDataOnImage DisplayGridInfo DisplayHistogram DisplayImageHistogram DisplayMeasurement DistinguishPixelLabels Exclude ExpandOrShrink ExportToDatabase ExportToExcel FilterByObjectMeasurement FindEdges Flip GrayToColor IdentifyObjectsInGrid IdentifyPrimAutomatic IdentifyPrimManual IdentifySecondary IdentifyTertiarySubregion InvertIntensity LoadImages LoadSingleImage LoadText MaskImage MeasureCorrelation MeasureImageAreaOccupied MeasureImageGranularity MeasureImageIntensity MeasureImageSaturationBlur MeasureObjectAreaShape MeasureObjectIntensity MeasureObjectNeighbors MeasureTexture Morph OverlayOutlines PlaceAdjacent Relate RenameOrRenumberFiles RescaleIntensity Resize Restart Rotate SaveImages SendEmail Smooth SpeedUpCellProfiler SplitOrSpliceMovie Subtract SubtractBackground Tile CPaddmeasurements CPaverageimages CPblkproc CPcd CPclearborder CPcompilesubfunction CPcontrolhistogram CPconvertsql CPdilatebinaryobjects CPerrordlg CPfigure CPgetfeature CPhelpdlg CPhistbins CPimagesc CPimagetool CPimread CPinputdlg CPlabel2rgb CPlistdlg CPlogo CPmakegrid CPmsgbox CPnanmean CPnanmedian CPnanstd CPnlintool CPplotmeasurement CPquestdlg CPrelateobjects CPrescale CPresizefigure CPretrieveimage CPretrievemediafilenames CPrgsmartdilate CPselectmodules CPselectoutputfiles CPsigmoid CPsmooth CPtextdisplaybox CPtextpipe CPthresh_tool CPthreshold CPwaitbar CPwarndlg CPwhichmodule CPwritemeasurements VirusScreen_Cluster_01 VirusScreen_Cluster_02 VirusScreen_LocalDensity_01  fit_mix_gaussian

warning off all

if not(nargin == 3 || nargin == 4)
    nargin
    CPOutputFile
    InputPath
    OutputPath
    disp('***')    
    disp('PreCluster usage: PreCluster(CPOutputFile, InputPath, OutputPath, [optional:cellstrFileREGEXPs])')
    disp('***')    
    return
end

load(CPOutputFile)

% check if the pipeline ends with the CreateBatchFiles module
NumberOfModules = length(handles.Settings.ModuleNames);
if isempty(strmatch(char(handles.Settings.ModuleNames(NumberOfModules)), 'CreateBatchFiles'))
    disp('***')    
    disp('Your input file should have CreateBatchFiles as last module');
    disp('***')    
    % return
end

handles.Current.DefaultOutputDirectory = OutputPath;
handles.Current.DefaultImageDirectory = InputPath;

% check if the optional cellstring cellstrFileREGEXPs is entered
% if so, set the loadimages regexps to these values...
% Example: cellstrFileREGEXPs = {'d0.tif','d1.tif'};
if nargin == 4 && iscellstr(cellstrFileREGEXPs)
    index = strcmpi(handles.Settings.ModuleNames,'LoadImages');
    for i = 1:length(cellstrFileREGEXPs)
        if isempty(strmatch(handles.Settings.VariableValues{index, (i*2)}, '/'))
            handles.Settings.VariableValues{index, i*2} = cellstrFileREGEXPs{i};
            disp(sprintf('LoadImages module: changed regexp %s to %s',handles.Settings.VariableValues{index, (i*2)},cellstrFileREGEXPs{1,i}));
        end
    end
end


% remove all references to the original CPOutputFile

handles.Pipeline = struct();
handles.Measurements = struct();

% set it to empty...
handles.timertexthandle = '';

% apparently only used by the GUI
if isfield(handles.Current,'FilenamesInImageDir')
    handles.Current = rmfield(handles.Current,'FilenamesInImageDir');
end

% so that the load images module does not error if the amount of detected
% imaged differs from the amount of images present in the input folder

handles.Current.NumberOfImageSets = 1;
handles.Current.StartingImageSet = 1;

%%% Note, this should only be set in the batch process itself!
% handles.Current.BatchInfo.Start = 1;
% handles.Current.BatchInfo.End = 1;

tic;

for BatchSetBeingAnalyzed = 1
    handles.Current.SetBeingAnalyzed = BatchSetBeingAnalyzed;
    for SlotNumber = 1:NumberOfModules,
        ModuleNumberAsString = sprintf('%02d', SlotNumber);
        ModuleName = char(handles.Settings.ModuleNames(SlotNumber));
        handles.Current.CurrentModuleNumber = ModuleNumberAsString;
        disp(sprintf('PreCluster module %02d: %s (t=%gs)',SlotNumber, ModuleName, (round(toc*10)/10)))
       try
            handles = feval(ModuleName,handles);
        catch
            handles.BatchError = [ModuleName ' ' lasterr];
            disp(['Batch Error: ' ModuleName ' ' lasterr]);
            rethrow(lasterror);
            quit;
        end
    end
end





% general idea for strategy to make PreCluster also accept pipeline files
% only: (1) load in an existing and valid 'handles' structure. (2) call
% LoadPipeline with the pipeline file to be loaded

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LOAD PIPELINE BUTTON %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = LoadPipeline(handles, CPOutputFile) %#ok We want to ignore MLint error checking for this line.

if isempty(eventdata)
    errFlg = 0;
    [SettingsFileName, SettingsPathname] = ...
	CPuigetfile('*.mat', 'Choose a pipeline file', ...
		    handles.Current.DefaultOutputDirectory); 
    pause(.1);
    figure(handles.figure1);
else
    SettingsFileName = eventdata.SettingsFileName;
    SettingsPathname = eventdata.SettingsPathname;
end

%%% If the user presses "Cancel", the SettingsFileName.m will = 0 and
%%% nothing will happen.
if SettingsFileName == 0
    return
end

drawnow
%%% Loads the Settings file.
try
    LoadedSettings = load(fullfile(SettingsPathname,SettingsFileName));
catch
    error(['CellProfiler was unable to load ',fullfile(SettingsPathname,SettingsFileName),'. The file may be corrupt.']);
end
%%% Error Checking for valid settings file.
if ~(isfield(LoadedSettings, 'Settings') || isfield(LoadedSettings, 'handles'))
    CPerrordlg(['The file ' SettingsPathname SettingsFileName ' does not appear to be a valid settings or output file. Settings can be extracted from an output file created when analyzing images with CellProfiler or from a small settings file saved using the "Save Settings" button.  Either way, this file must have the extension ".mat" and contain a variable named "Settings" or "handles".']);
    errFlg = 1;
    return
end
%%% Figures out whether we loaded a Settings or Output file, and puts
%%% the correct values into Settings. Splices the subset of variables
%%% from the "settings" structure into the handles structure.
if (isfield(LoadedSettings, 'Settings')),
    Settings = LoadedSettings.Settings;
else
    try Settings = LoadedSettings.handles.Settings;
        Settings.NumbersOfVariables = LoadedSettings.handles.Settings.NumbersOfVariables;
    end
end

try
    [NumberOfModules, MaxNumberVariables] = size(Settings.VariableValues); %#ok Ignore MLint
    if (size(Settings.ModuleNames,2) ~= NumberOfModules)||(size(Settings.NumbersOfVariables,2) ~= NumberOfModules);
        CPerrordlg(['The file ' SettingsPathname SettingsFileName ' is not a valid settings or output file. Settings can be extracted from an output file created when analyzing images with CellProfiler or from a small settings file saved using the "Save Settings" button.']);
        errFlg = 1;
        return
    end
catch
    CPerrordlg(['The file ' SettingsPathname SettingsFileName ' is not a valid settings or output file. Settings can be extracted from an output file created when analyzing images with CellProfiler or from a small settings file saved using the "Save Settings" button.']);
    errFlg = 1;
    return
end

%%% Hide stuff in the background, but keep old values in case of errors.
OldValue = get(handles.ModulePipelineListBox,'Value');
OldString = get(handles.ModulePipelineListBox,'String');
set(handles.ModulePipelineListBox,'Value',1);
set(handles.ModulePipelineListBox,'String','Loading...');
set(get(handles.variablepanel,'children'),'visible','off');
set(handles.slider1,'visible','off');

%%% Check to make sure that the module files can be found and get paths
ModuleNames = Settings.ModuleNames;
Skipped = 0;
for k = 1:NumberOfModules
    if ~isdeployed
        CurrentModuleNamedotm = [char(ModuleNames{k}) '.m'];
        
        %% Smooth.m was changed to SmoothOrEnhance.m since Tophat Filter
        %% was added to the Smooth Module
        if strcmp(CurrentModuleNamedotm,'Smooth.m')
            CurrentModuleNamedotm  = 'SmoothOrEnhance.m'; %% 
            Filename = 'SmoothOrEnhance';
            Pathname = handles.Preferences.DefaultModuleDirectory;
            pause(.1);
            figure(handles.figure1);
            Pathnames{k-Skipped} = Pathname;
            Settings.ModuleNames{k-Skipped} = Filename;
            CPwarndlg('Note: The module ''Smooth'' has been replaced with ''SmoothOrEnhance''.  The settings have been transferred for your convenience')
        end
        
        if exist(CurrentModuleNamedotm,'file')
            Pathnames{k-Skipped} = fileparts(which(CurrentModuleNamedotm)); %#ok Ignore MLint
        else
            %%% If the module.m file is not on the path, it won't be
            %%% found, so ask the user where the modules are.
            Choice = CPquestdlg(['The module ', CurrentModuleNamedotm, ' cannot be found. Either its name has changed or it was moved or deleted. What do you want to do? Note: You can also choose another module to replace ' CurrentModuleNamedotm ' if you select Search Module. It will be loaded with its default settings and you will also be able to see the saved settings of ' CurrentModuleNamedotm '.'],'Module not found','Skip Module','Search Module','Abort','Skip Module');
            switch Choice
                case 'Skip Module'
                    %%% Check if this was the only module in the pipeline or if
                    %%% all previous modules have been skipped too
                    if Skipped+1 == NumberOfModules
                        CPerrordlg('All modules in this pipeline were skipped. Loading will be canceled.','Loading Pipeline Error')
                        Abort = 1;
                    else
                        %%% Remove module info from the settings
                        View = CPquestdlg(['The pipeline will be loaded without ' CurrentModuleNamedotm ', but keep in mind that it might not work properly. Would you like to see the saved settings ' CurrentModuleNamedotm ' had?'], 'Module Skipped', 'Yes', 'No', 'Yes');
                        if strcmp(View,'Yes')
                            FailedModule(handles,Settings.VariableValues(k-Skipped,:),'Sorry, variable descriptions could not be retrieved from this file',CurrentModuleNamedotm,k-Skipped);
                        end
                        %%% Notice that if the skipped module is the one that
                        %%% had the most variables, then the VariableValues
                        %%% will have some empty columns at the end. I guess it
                        %%% doesn't matter, but it could be fixed if necessary.
                        Settings.VariableValues(k-Skipped,:) = [];
                        Settings.VariableInfoTypes(k-Skipped,:) = [];
                        Settings.ModuleNames(k-Skipped) = [];
                        Settings.NumbersOfVariables(k-Skipped) = [];
                        Settings.VariableRevisionNumbers(k-Skipped) = [];
                        Settings.ModuleRevisionNumbers(k-Skipped) = [];
                        Skipped = Skipped+1;
                        Abort = 0;
                    end
                case 'Search Module'
                    %% Why is this 'if' needed?  An outer 'if' has already
                    %% checked for this.  David 2008.02.08
                    if ~isdeployed
                        filter = '*.m';
                    else
                        filter = '*.txt';
                    end
                    [Filename Pathname] = CPuigetfile(filter, ['Find ' CurrentModuleNamedotm ' or Choose Another Module'], handles.Preferences.DefaultModuleDirectory);
                    pause(.1);
                    figure(handles.figure1);
                    if Filename == 0
                        Abort = 1;
                    else
                        Pathnames{k-Skipped} = Pathname;
                        %% Why is this 'if' needed?  An outer 'if' has already
                        %% checked for this.  David 2008.02.08
                        if ~isdeployed
                            Settings.ModuleNames{k-Skipped} = Filename(1:end-2);
                        else
                            Settings.ModuleNames{k-Skipped} = Filename(1:end-4);
                        end
                        Abort = 0;
                    end
                otherwise
                    Abort = 1;
            end
            if Abort
                %%% Restore whatever the user had before attempting to load
                set(handles.ModulePipelineListBox,'String',OldString);
                set(handles.ModulePipelineListBox,'Value',OldValue);
                ModulePipelineListBox_Callback(hObject,[],handles);
                errFlg = 1;
                return
            end
        end
    else
        Pathnames{k-Skipped} = handles.Preferences.DefaultModuleDirectory;
    end
end

%%% Save old settings in case of error
OldValue = get(handles.ModulePipelineListBox,'Value');
OldString = get(handles.ModulePipelineListBox,'String');
OldSettings = handles.Settings;
try
    OldVariableBox = handles.VariableBox;
    OldVariableDescription = handles.VariableDescription;
catch
    OldVariableBox = {};
    OldVariableDescription = {};
end

%%% Update handles structure
handles.Settings.ModuleNames = Settings.ModuleNames;
handles.Settings.VariableValues = {};
handles.Settings.VariableInfoTypes = {};
handles.Settings.VariableRevisionNumbers = [];
handles.Settings.ModuleRevisionNumbers = [];
handles.Settings.NumbersOfVariables = [];
handles.VariableBox = {};
handles.VariableDescription = {};

%%% For each module, extract its settings and check if they seem alright
revisionConfirm = 0;
Skipped = 0;
for ModuleNum=1:length(handles.Settings.ModuleNames)
    CurrentModuleName = handles.Settings.ModuleNames{ModuleNum-Skipped};
    %%% Replace names of modules whose name changed
    if strcmp('CreateBatchScripts',CurrentModuleName) || strcmp('CreateClusterFiles',CurrentModuleName)
        handles.Settings.ModuleNames(ModuleNum-Skipped) = {'CreateBatchFiles'};
    elseif strcmp('WriteSQLFiles',CurrentModuleName)
        handles.Settings.ModuleNames(ModuleNum-Skipped) = {'ExportToDatabase'};
    end
    
    %%% Load the module's settings

    try
        %%% First load the module with its default settings
        [defVariableValues defVariableInfoTypes defDescriptions handles.Settings.NumbersOfVariables(ModuleNum-Skipped) DefVarRevNum ModuleRevNum] = LoadSettings_Helper(Pathnames{ModuleNum-Skipped}, CurrentModuleName);
        %%% If no VariableRevisionNumber was extracted, default it to 0
        if isfield(Settings,'VariableRevisionNumbers')
            SavedVarRevNum = Settings.VariableRevisionNumbers(ModuleNum-Skipped);
        else
            SavedVarRevNum = 0;
        end
        
        %%% Adjust old 'LoadImages' variables to new ones. This is applied to 
        %%% the pipelines saved with the LoadImages variable revision number less than 2
        %%% VariableValues is a cell structure, please use {} rather than ().
        if strcmp('LoadImages',CurrentModuleName) && (SavedVarRevNum < 2)
            ImageOrMovie = Settings.VariableValues{ModuleNum-Skipped,11};
            if strcmp(ImageOrMovie,'Image')
                new_variablevalue = 'individual images';
            else
                if strcmp(Settings.VariableValues{ModuleNum-Skipped,12},'avi')
                    new_variablevalue = 'avi movies';
                elseif strcmp(Settings.VariableValues{ModuleNum-Skipped,12},'stk')
                    new_variablevalue = 'stk movies';
                end
            end
            Settings.VariableValues{ModuleNum-Skipped,11} = new_variablevalue;
            Settings.VariableValues{ModuleNum-Skipped,12} = Settings.VariableValues{ModuleNum-Skipped,13};
            Settings.VariableValues{ModuleNum-Skipped,13} = Settings.VariableValues{ModuleNum-Skipped,14};   
            SavedVarRevNum = 2;
        end

        %%% Using the VariableRevisionNumber and the number of variables,
        %%% check if the loaded module and the module the user is trying to
        %%% load is the same
        if SavedVarRevNum == DefVarRevNum && handles.Settings.NumbersOfVariables(ModuleNum-Skipped) == Settings.NumbersOfVariables(ModuleNum-Skipped)
            %%% If so, replace the default settings with the saved ones            
            handles.Settings.VariableValues(ModuleNum-Skipped,1:Settings.NumbersOfVariables(ModuleNum-Skipped)) = Settings.VariableValues(ModuleNum-Skipped,1:Settings.NumbersOfVariables(ModuleNum-Skipped));
            %%% save module revision number
            handles.Settings.ModuleRevisionNumbers(ModuleNum-Skipped) = ModuleRevNum;
        else
            %%% If not, show the saved settings. Note: This will always
            %%% appear if user selects another module when they search for
            %%% the missing module, but the user is appropriately warned
            savedVariableValues = Settings.VariableValues(ModuleNum-Skipped,1:Settings.NumbersOfVariables(ModuleNum-Skipped));
            FailedModule(handles, savedVariableValues, defDescriptions, char(handles.Settings.ModuleNames(ModuleNum-Skipped)),ModuleNum-Skipped);
            %%% Go over each variable
            for k = 1:handles.Settings.NumbersOfVariables(ModuleNum-Skipped)
                if strcmp(defVariableValues(k),'Pipeline Value')
                    %%% Create FixList, which will later be used to replace
                    %%% pipeline-dependent variable values in the loaded modules
                    handles.Settings.VariableValues(ModuleNum-Skipped,k) = {''};
                    if exist('FixList','var')
                        FixList(end+1,1) = ModuleNum-Skipped;
                        FixList(end,2) = k;
                    else
                        FixList(1,1) = ModuleNum-Skipped;
                        FixList(1,2) = k;
                    end
                else
                    %%% If no need to change, save the default loaded variables
                    handles.Settings.VariableValues(ModuleNum-Skipped,k) = defVariableValues(k);
                end
            end
            %%% Save the infotypes and VariableRevisionNumber
             handles.Settings.VariableInfoTypes(ModuleNum-Skipped,1:numel(defVariableInfoTypes)) = defVariableInfoTypes;
             handles.Settings.VariableRevisionNumbers(ModuleNum-Skipped) = DefVarRevNum;
             handles.Settings.ModuleNames{ModuleNum-Skipped} = CurrentModuleName;
             handles.Settings.ModuleRevisionNumbers(ModuleNum-Skipped) = ModuleRevNum;
            revisionConfirm = 1;
        end
        clear defVariableInfoTypes;
    catch
        %%% It is very unlikely to get here, because this means the
        %%% pathname was incorrect, but we had checked this before
        Choice = CPquestdlg(['The ' CurrentModuleName ' module could not be found in the directory specified or an error occured while extracting its variable settings. This error is not common; the module might be corrupt or, if running on the non-developers version of CellProfiler, your preferences may not be set properly. To check your preferences, click on File >> Set Preferences.  The module will be skipped and the rest of the pipeline will be loaded. Would you like to see the module''s saved settings? (' lasterr ')'],'Error','Yes','No','Abort','Yes');
        switch Choice
            case 'Yes'
                FailedModule(handles,Settings.VariableValues(ModuleNum-Skipped,:),'Sorry, variable descriptions could not be retrieved from this file',CurrentModuleName,ModuleNum-Skipped);
                Abort = 0;
            case 'No'
                Abort = 0;
            otherwise
                Abort = 1;
        end
        if Skipped+1 == length(handles.Settings.ModuleNames)
            CPerrordlg('All modules in this pipeline were skipped. Loading will be canceled.  Your preferences may not be set correctly.  Click File >> Set Preferences to be sure that the module path is correct.','Loading Pipeline Error')
            Abort = 1;
        else
            %%% Remove module info from the settings and handles
            handles.Settings.ModuleNames(ModuleNum-Skipped) = [];
            Pathnames(ModuleNum-Skipped) = [];
            Settings.VariableValues(ModuleNum-Skipped,:) = [];
            Settings.VariableInfoTypes(ModuleNum-Skipped,:) = [];
            Settings.ModuleNames(ModuleNum-Skipped) = [];
            Settings.NumbersOfVariables(ModuleNum-Skipped) = [];
            try Settings.VariableRevisionNumbers(ModuleNum-Skipped) = []; end
            try Settings.ModuleRevisionNumbers(ModuleNum-Skipped) = []; end
            Skipped = Skipped+1;
        end
        if Abort
            %%% Reset initial handles settings
            handles.Settings = OldSettings;
            handles.VariableBox = OldVariableBox;
            handles.VariableDescription = OldVariableDescription;
            set(handles.ModulePipelineListBox,'String',OldString);
            set(handles.ModulePipelineListBox,'Value',OldValue);
            guidata(hObject,handles);
            ModulePipelineListBox_Callback(hObject,[],handles);
            errFlg = 1;
            return
        end
    end
end

delete(get(handles.variablepanel,'children'));
try
    handles.Settings.PixelSize = Settings.PixelSize;
    handles.Preferences.PixelSize = Settings.PixelSize;
    set(handles.PixelSizeEditBox,'String',handles.Preferences.PixelSize)
end
handles.Current.NumberOfModules = 0;
contents = handles.Settings.ModuleNames;
guidata(hObject,handles);

WaitBarHandle = CPwaitbar(0,'Loading Pipeline...');
for i=1:length(handles.Settings.ModuleNames)
    if isdeployed
        PutModuleInListBox([contents{i} '.txt'], Pathnames{i}, handles, 1);
    else
        PutModuleInListBox([contents{i} '.m'], Pathnames{i}, handles, 1);
    end
    handles=guidata(handles.figure1);
    handles.Current.NumberOfModules = i;
    CPwaitbar(i/length(handles.Settings.ModuleNames),WaitBarHandle,'Loading Pipeline...');
end

if exist('FixList','var')
    for k = 1:size(FixList,1)
        PipeList = get(handles.VariableBox{FixList(k,1)}(FixList(k,2)),'string');
        FirstValue = PipeList(1);
        handles.Settings.VariableValues(FixList(k,1),FixList(k,2)) = FirstValue;
    end
end

guidata(hObject,handles);
set(handles.ModulePipelineListBox,'String',contents);
set(handles.ModulePipelineListBox,'Value',1);
ModulePipelineListBox_Callback(hObject, eventdata, handles);
close(WaitBarHandle);

%%% If the user loaded settings from an output file, prompt them to
%%% save it as a separate Settings file for future use.
if isfield(LoadedSettings, 'handles'),
    Answer = CPquestdlg('The settings have been extracted from the output file you selected.  Would you also like to save these settings in a separate, smaller, settings-only file?','','Yes','No','Yes');
    if strcmp(Answer, 'Yes') == 1
        tempSettings = handles.Settings;
        if(revisionConfirm == 1)
            VersionAnswer = CPquestdlg('How should the settings file be saved?', 'Save Settings File', 'Exactly as found in output', 'As Loaded into CellProfiler window', 'Exactly as found in output');
            if strcmp(VersionAnswer, 'Exactly as found in output')
                handles.Settings = Settings;
            end
        end
        SavePipeline_Callback(hObject, eventdata, handles);
        handles.Settings = tempSettings;
    end
end