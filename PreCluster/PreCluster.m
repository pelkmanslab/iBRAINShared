function PreCluster(CPOutputFile, InputPath, OutputPath, cellstrFileREGEXPs)

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

% Add custom project code support.
brainy.libpath.checkAndAppendLibPath(OutputPath);

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
            warning of all
            handles = feval(ModuleName,handles);
        catch
            handles.BatchError = [ModuleName ' ' lasterr];
            disp(['Batch Error: ' ModuleName ' ' lasterr]);
            rethrow(lasterror);
            quit;
        end
    end
end
