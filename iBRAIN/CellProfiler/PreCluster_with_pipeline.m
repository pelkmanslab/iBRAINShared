function PreCluster_with_pipeline(CPOutputFile, InputPath, OutputPath)

%%% Must list all CellProfiler modules here
%#function Align ApplyThreshold Average CalculateMath CalculateRatios CalculateStatistics ClassifyObjects ClassifyObjectsByTwoMeasurements ColorToGray Combine ConvertToImage CorrectIllumination_Apply CorrectIllumination_Calculate CreateBatchFiles CreateWebPage Crop DefineGrid DisplayDataOnImage DisplayGridInfo DisplayHistogram DisplayImageHistogram DisplayMeasurement DistinguishPixelLabels Exclude ExpandOrShrink ExportToDatabase ExportToExcel FilterByObjectMeasurement FindEdges Flip GrayToColor IdentifyObjectsInGrid IdentifyPrimAutomatic IdentifyPrimManual IdentifySecondary IdentifyTertiarySubregion InvertIntensity LoadImages LoadSingleImage LoadText MaskImage MeasureCorrelation MeasureImageAreaOccupied MeasureImageGranularity MeasureImageIntensity MeasureImageSaturationBlur MeasureObjectAreaShape MeasureObjectIntensity MeasureObjectNeighbors MeasureTexture Morph OverlayOutlines PlaceAdjacent Relate RenameOrRenumberFiles RescaleIntensity Resize Restart Rotate SaveImages SendEmail Smooth SpeedUpCellProfiler SplitOrSpliceMovie Subtract SubtractBackground Tile CPaddmeasurements CPaverageimages CPblkproc CPcd CPclearborder CPcompilesubfunction CPcontrolhistogram CPconvertsql CPdilatebinaryobjects CPerrordlg CPfigure CPgetfeature CPhelpdlg CPhistbins CPimagesc CPimagetool CPimread CPinputdlg CPlabel2rgb CPlistdlg CPlogo CPmakegrid CPmsgbox CPnanmean CPnanmedian CPnanstd CPnlintool CPplotmeasurement CPquestdlg CPrelateobjects CPrescale CPresizefigure CPretrieveimage CPretrievemediafilenames CPrgsmartdilate CPselectmodules CPselectoutputfiles CPsigmoid CPsmooth CPtextdisplaybox CPtextpipe CPthresh_tool CPthreshold CPwaitbar CPwarndlg CPwhichmodule CPwritemeasurements VirusScreen_Cluster_01 VirusScreen_Cluster_02 VirusScreen_LocalDensity_01  fit_mix_gaussian

% Add custom project code support.
brainy.libpath.checkAndAppendLibPath(OutputPath);

warning off all

if not(nargin == 3)
%     CPOutputFile = fullfile(getbasedir(which('PreCluster.m')),'PreCluster_pipeline_example.mat')
%     CPOutputFile = fullfile(getbasedir(which('PreCluster.m')),'DefaultHandles.mat')

%     CPOutputFile = '\\Nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\Ad3_KY_NEW\PreCluster_50K_Ad3_KY_NEW.mat';
% %     CPOutputFile = '\\Nas-biol-imsb-1\share-3-$\Data\Users\50K_final\Ad3_KY_NEW\PreCluster_Default_96_PIPELINE_OUT.mat';
%     InputPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\Ad3_KY_NEW\070606_Ad3_50k_Ky_1_1_CP071-1aa\TIFF\'
%     OutputPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\Ad3_KY_NEW\070606_Ad3_50k_Ky_1_1_CP071-1aa\BATCH\'

    CPOutputFile = '\\Nas-biol-imsb-1\share-3-$\Data\Users\50K_final\EV1_MZ\070123_EV1_50K_MZ_P1_1_1_CP071-1aa\BATCH\Batch_data.mat';
%     CPOutputFile = '\\Nas-biol-imsb-1\share-3-$\Data\Users\50K_final\Ad3_KY_NEW\PreCluster_Default_96_PIPELINE_OUT.mat';
    InputPath = '\\Nas-biol-imsb-1\share-3-$\Data\Users\50K_final\EV1_MZ\070123_EV1_50K_MZ_P1_1_1_CP071-1aa\TIFF\'
    OutputPath = '\\Nas-biol-imsb-1\share-3-$\Data\Users\50K_final\EV1_MZ\070123_EV1_50K_MZ_P1_1_1_CP071-1aa\BATCH\'

end

%%% Load the PreCluster file (either an output file or a pipeline only file)
LoadedSettings = load(CPOutputFile);

%%% Error Checking for valid settings file.
if ~(isfield(LoadedSettings, 'Settings') || isfield(LoadedSettings, 'handles'))
    error(['The file ' CPOutputFile ' does not appear to be a valid settings or output file. Settings can be extracted from an output file created when analyzing images with CellProfiler or from a small settings file saved using the "Save Settings" button.  Either way, this file must have the extension ".mat" and contain a variable named "Settings" or "handles".']);
    return
end

%%% check if it is an output file, or a settings file
if isfield(LoadedSettings,'handles')
    disp('PreCluster file contains complete handles structure')
    handles = LoadedSettings.handles;
elseif isfield(LoadedSettings,'Settings')
    disp('PreCluster file contains pipeline only')
    disp('- loading template handles file')
    load(fullfile(getbasedir(which('PreCluster.m')),'DefaultHandles.mat'))
    disp('- loading pipeline')
    handles = LoadPipeline(handles, LoadedSettings.Settings);%#ok Ignore MLint
    disp('- faking figure number for modules')
    for i = 1:size(handles.Settings.VariableValues,1)
        handles.Current.(sprintf('FigureNumberForModule%02d',i))=i;
    end
else
    error('The PreCluster pipeline file does not contain a valid handles structure, or a valid pipeline file')
end
clear LoadedSettings;


% check if the pipeline ends with the CreateBatchFiles module
NumberOfModules = length(handles.Settings.ModuleNames);
if isempty(strmatch(char(handles.Settings.ModuleNames(NumberOfModules)), 'CreateBatchFiles'))
    error('*** ERROR: For iBRAIN to work, your PreCluster pipeline file should have CreateBatchFiles as last module');
    % return
end


% some pipelines have a fixed reference to the image input / output paths
% in the last - CreateBeatchFiles - module, fix these by setting them to
% '.' --> default input output paths such that iBRAIN can overwrite them.
%
% settings 1 - 3 are important, and the last settings should be 'n/a'...
for iSetting = 4:handles.Settings.NumbersOfVariables(end)
    if ~(strcmp(handles.Settings.VariableValues(end,iSetting),'.') || strcmp(handles.Settings.VariableValues(end,iSetting),'n/a'));
        disp(sprintf('%s: fixing references to paths from the CreateBatchFile module: changing ''%s'' to ''.''',mfilename,handles.Settings.VariableValues{end,iSetting}))

        % this should be a path, either PC, MAC or UNIX, if not, perhaps
        % throw an additional warning!
        if isempty(strfind(handles.Settings.VariableValues{end,iSetting},'/')) && isempty(strfind(handles.Settings.VariableValues{end,iSetting},'\'))
            warning('BEREND:PossibleBadFix','%s: the fixed setting ''%s'' did not appear to be a path, and may therefore erouneously have been ''fixed''',mfilename,handles.Settings.VariableValues{end,iSetting})
        end
        handles.Settings.VariableValues(end,iSetting) = {'.'};
    end
end


% some pipelines have a fixed reference '.tif', if we support '.png', we
% might want to change this, depending on the content of the input path

% check the image type of the input directory (go for the version that has
% most images, .png or .tif)
disp(sprintf('%s: searching for .png or .tif images',mfilename))
dirlisting=dir(sprintf('%s%s*.*',InputPath,filesep));
dirlisting=struct2cell(dirlisting);
dirlisting=dirlisting';
item_isdir=cell2mat(dirlisting(:,4));
dirlisting=dirlisting(~item_isdir,1);

% if there are more png in this directory than tifs, check for hardcoded
% '.tif' references and replace them with '.png'
if sum(~cellfun(@isempty,strfind(dirlisting,'.png'))) >= sum(~cellfun(@isempty,strfind(dirlisting,'.tif')))
    %see function replacetifwithpng at end of script...
    disp(sprintf('%s: %d .png images detected, checking handles.Settings.VariableValues',mfilename,sum(~cellfun(@isempty,strfind(dirlisting,'.png')))))
    handles.Settings.VariableValues = cellfun(@replacetifwithpng,handles.Settings.VariableValues,'UniformOutput', false);
else
    disp(sprintf('%s: %d .tif images detected',mfilename,sum(~cellfun(@isempty,strfind(dirlisting,'.tif')))))
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Starting precluster analysis %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp(sprintf('\nStarting PreCluster analysis'))

handles.Current.DefaultOutputDirectory = OutputPath;
handles.Current.DefaultImageDirectory = InputPath;
handles.Pipeline = struct();
handles.Measurements = struct();
handles.timertexthandle = '';

% apparently only used by the GUI
if isfield(handles.Current,'FilenamesInImageDir')
    handles.Current = rmfield(handles.Current,'FilenamesInImageDir');
end

% so that the load images module does not error if the amount of detected
% imaged differs from the amount of images present in the input folder
handles.Current.NumberOfImageSets = 1;
handles.Current.StartingImageSet = 1;

tic;
for BatchSetBeingAnalyzed = 1
    handles.Current.SetBeingAnalyzed = BatchSetBeingAnalyzed;
    for SlotNumber = 1:NumberOfModules,
        ModuleNumberAsString = sprintf('%02d', SlotNumber);
        ModuleName = char(handles.Settings.ModuleNames(SlotNumber));
        handles.Current.CurrentModuleNumber = ModuleNumberAsString;
        disp(sprintf('- Running  module %02d: %s (t=%gs)',SlotNumber, ModuleName, (round(toc*10)/10)))
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LOAD PIPELINE BUTTON %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = LoadPipeline(handles, Settings)

try
    [NumberOfModules, MaxNumberVariables] = size(Settings.VariableValues); %#ok Ignore MLint
    if (size(Settings.ModuleNames,2) ~= NumberOfModules)||(size(Settings.NumbersOfVariables,2) ~= NumberOfModules);
        % old CP's sometimes have excess & empty rows in VariableValues....
        % remove these from VariableValues!
        disp('  - removing empty VariableValues rows')
        Settings.VariableValues(all(cellfun(@isempty,Settings.VariableValues),2),:) = [];
    end

    [NumberOfModules, MaxNumberVariables] = size(Settings.VariableValues); %#ok Ignore MLint
    if (size(Settings.ModuleNames,2) ~= NumberOfModules)||(size(Settings.NumbersOfVariables,2) ~= NumberOfModules);
        disp('*** CRITICAL ERROR: DEBUG DADTA FOLLOWS BELOW')

        NumberOfModules
        MaxNumberVariables
        Settings.ModuleNames
        Settings.NumbersOfVariables
        Settings.VariableValues

        error(['The PreCluster file is not a valid settings or output file. Settings can be extracted from an output file created when analyzing images with CellProfiler or from a small settings file saved using the "Save Settings" button.']);
        return
    end
catch
    error(['The file is not a valid settings or output file. Settings can be extracted from an output file created when analyzing images with CellProfiler or from a small settings file saved using the "Save Settings" button.']);
    return
end

%%% Check to make sure that the module files can be found and get paths
ModuleNames = Settings.ModuleNames;
Skipped = 0;
for k = 1:NumberOfModules
    if ~isdeployed
        CurrentModuleNamedotm = [char(ModuleNames{k}) '.m'];

%         % Smooth.m was changed to SmoothOrEnhance.m since Tophat Filter
%         % was added to the Smooth Module
%         if strcmp(CurrentModuleNamedotm,'Smooth.m')
%             CurrentModuleNamedotm  = 'SmoothOrEnhance.m'; %%
%             Filename = 'SmoothOrEnhance';
%             Pathname = handles.Preferences.DefaultModuleDirectory;
%             pause(.1);
%             figure(handles.figure1);
%             Pathnames{k-Skipped} = Pathname;
%             Settings.ModuleNames{k-Skipped} = Filename;
%             CPwarndlg('Note: The module ''Smooth'' has been replaced with ''SmoothOrEnhance''.  The settings have been transferred for your convenience')
%         end

        if exist(CurrentModuleNamedotm,'file')
            Pathnames{k-Skipped} = fileparts(which(CurrentModuleNamedotm)); %#ok Ignore MLint
        else
            error('Could not find file %s',CurrentModuleNamedotm)
        end
    else
        Pathnames{k-Skipped} = handles.Preferences.DefaultModuleDirectory;
    end
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
% % % revisionConfirm = 0;
Skipped = 0;
for ModuleNum=1:length(handles.Settings.ModuleNames)
    CurrentModuleName = handles.Settings.ModuleNames{ModuleNum-Skipped};
    disp(sprintf('  - Loading setting for module %d: %s',ModuleNum,CurrentModuleName))
    %%% Replace names of modules whose name changed
    if strcmp('CreateBatchScripts',CurrentModuleName) || strcmp('CreateClusterFiles',CurrentModuleName)
        handles.Settings.ModuleNames(ModuleNum-Skipped) = {'CreateBatchFiles'};
    elseif strcmp('WriteSQLFiles',CurrentModuleName)
        handles.Settings.ModuleNames(ModuleNum-Skipped) = {'ExportToDatabase'};
    end

    %%% Load the module's settings

    %%% First load the module with its default settings
    [defVariableValues defVariableInfoTypes defDescriptions handles.Settings.NumbersOfVariables(ModuleNum-Skipped) DefVarRevNum ModuleRevNum] = LoadSettings_Helper(Pathnames{ModuleNum-Skipped}, CurrentModuleName);
    %%% If no VariableRevisionNumber was extracted, default it to 0
    if isfield(Settings,'VariableRevisionNumbers')
        SavedVarRevNum = Settings.VariableRevisionNumbers(ModuleNum-Skipped);
    else
        SavedVarRevNum = 0;
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

        %%% BS HACK, NEVER MIND ASKING THE USER, JUST GIVE IT A SHOT
        disp(sprintf('    ***WARNING: MODULE %s (NUMMER %d) DOES NOT HAVE THE CORRECT VERSION NUMBER! \n    USING OLD SETTINGS, BUT EXPECT THIS MODULE TO FAIL',CurrentModuleName,ModuleNum))
        disp(sprintf('    Variable Revision Number: %d (old) = %d (new)',SavedVarRevNum,DefVarRevNum))
        disp(sprintf('    Number Of Variables:      %d (old) = %d (new)',handles.Settings.NumbersOfVariables(ModuleNum-Skipped),Settings.NumbersOfVariables(ModuleNum-Skipped)))

        %%% If so, replace the default settings with the saved ones
        handles.Settings.VariableValues(ModuleNum-Skipped,1:Settings.NumbersOfVariables(ModuleNum-Skipped)) = Settings.VariableValues(ModuleNum-Skipped,1:Settings.NumbersOfVariables(ModuleNum-Skipped));
        %%% save module revision number
        handles.Settings.ModuleRevisionNumbers(ModuleNum-Skipped) = ModuleRevNum;
    end
    clear defVariableInfoTypes;
end

try
    handles.Settings.PixelSize = Settings.PixelSize;
    handles.Preferences.PixelSize = Settings.PixelSize;
end
handles.Current.NumberOfModules = 0;
% % % contents = handles.Settings.ModuleNames;
handles.Current.NumberOfModules = length(handles.Settings.ModuleNames);

if exist('FixList','var')
    for k = 1:size(FixList,1)
        PipeList = get(handles.VariableBox{FixList(k,1)}(FixList(k,2)),'string');
        FirstValue = PipeList(1);
        handles.Settings.VariableValues(FixList(k,1),FixList(k,2)) = FirstValue;
    end
end

%%% SUBFUNCTION %%%
function [VariableValues VariableInfoTypes VariableDescriptions NumbersOfVariables VarRevNum ModuleRevNum] = LoadSettings_Helper(Pathname, ModuleName)

VariableValues = {[]};
VariableInfoTypes = {[]};
VariableDescriptions = {[]};
VarRevNum = 0;
ModuleRevNum = 0;
NumbersOfVariables = 0;
if isdeployed
    ModuleNamedotm = [ModuleName '.txt'];
else
    ModuleNamedotm = [ModuleName '.m'];
end
fid=fopen(fullfile(Pathname,ModuleNamedotm));
while 1
    output = fgetl(fid);
    if ~ischar(output)
        break
    end
    if strncmp(output,'%defaultVAR',11)
        displayval = output(17:end);
        istr = output(12:13);
        i = str2double(istr);
        VariableValues(i) = {displayval};
    elseif strncmp(output,'%choiceVAR',10)
        if ~iscellstr(VariableValues(i))
            displayval = output(16:end);
            istr = output(11:12);
            i = str2double(istr);
            VariableValues(i) = {displayval};
        end
    elseif strncmp(output,'%textVAR',8)
        displayval = output(13:end);
        istr = output(9:10);
        i = str2double(istr);
        VariableDescriptions(i) = {displayval};
        VariableValues(i) = {[]};
        NumbersOfVariables = i;
    elseif strncmp(output,'%pathnametextVAR',16)
        displayval = output(21:end);
        istr = output(17:18);
        i = str2double(istr);
        VariableDescriptions(i) = {displayval};
        VariableValues(i) = {[]};
        NumbersOfVariables = i;
    elseif strncmp(output,'%filenametextVAR',16)
        displayval = output(21:end);
        istr = output(17:18);
        i = str2double(istr);
        VariableDescriptions(i) = {displayval};
        VariableValues(i) = {[]};
        NumbersOfVariables = i;
    elseif strncmp(output,'%infotypeVAR',12)
        displayval = output(18:end);
        istr = output(13:14);
        i = str2double(istr);
        VariableInfoTypes(i) = {displayval};
        if ~strcmp(output((length(output)-4):end),'indep') && isempty(VariableValues{i})
            VariableValues(i) = {'Pipeline Value'};
        end
    elseif strncmp(output,'%%%VariableRevisionNumber',25)
        try
            VarRevNum = str2double(output(29:30));
        catch
            VarRevNum = str2double(output(29:29));
        end
    elseif strncmp(output,'% $Revision:', 12)
        try
            ModuleRevNum = str2double(output(14:17));
        catch
            tokens = regexp(output, '% \$Revision:\s*(\d+).*','tokens');
            try
                ModuleRevNum = str2double(tokens{1});
            catch err
                warning(err);
                error(['Failed to parse revision field in module ' ModuleName]);
            end
        end
    end
end
fclose(fid);

%%% SUBFUNCTION %%%
function FailedModule(handles, savedVariables, defaultDescriptions, ModuleName, ModuleNum)
    disp(sprintf('*** FAILED TO LOAD MODULE %s (NUMBER %d)',ModuleName,ModuleNum))

function strOutput=replacetifwithpng(strInput)
    if (iscellstr(strInput) || ischar(strInput)) && ~isempty(strfind(strInput,'.tif'))
        strOutput = strrep(strInput,'.tif','.png');
        disp(sprintf('%s: replacing reference to tif ''%s'' with ''%s''',mfilename,strInput,strOutput))
    else
        strOutput = strInput;
    end
