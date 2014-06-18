function CPCluster(batchfile,clusterfile)

    %%% Must list all CellProfiler modules here
    %#function Align ApplyThreshold Average CalculateMath CalculateRatios CalculateStatistics ClassifyObjects ClassifyObjectsByTwoMeasurements ColorToGray Combine ConvertToImage CorrectIllumination_Apply CorrectIllumination_Calculate CreateBatchFiles CreateWebPage Crop DefineGrid DisplayDataOnImage DisplayGridInfo DisplayHistogram DisplayImageHistogram DisplayMeasurement DistinguishPixelLabels Exclude ExpandOrShrink ExportToDatabase ExportToExcel FilterByObjectMeasurement FindEdges Flip GrayToColor IdentifyObjectsInGrid IdentifyPrimAutomatic IdentifyPrimAutomaticMod3 IdentifyPrimManual IdentifySecondary IdentifyTertiarySubregion InvertIntensity LoadImages LoadSingleImage LoadText MaskImage MeasureCorrelation MeasureImageAreaOccupied MeasureImageGranularity MeasureImageIntensity MeasureImageSaturationBlur MeasureObjectAreaShape MeasureObjectIntensity MeasureObjectNeighbors MeasureTexture Morph OverlayOutlines PlaceAdjacent Relate RenameOrRenumberFiles RescaleIntensity Resize Restart Results Rotate SaveImages SendEmail Smooth SpeedUpCellProfiler SplitOrSpliceMovie Subtract SubtractBackground Tile CPaddmeasurements CPaverageimages CPblkproc CPcd CPclearborder CPcompilesubfunction CPcontrolhistogram CPconvertsql CPdilatebinaryobjects CPerrordlg CPfigure CPgetfeature CPhelpdlg CPhistbins CPimagesc CPimagetool CPimread CPinputdlg CPlabel2rgb CPlistdlg CPlogo CPmakegrid CPmsgbox CPnanmean CPnanmedian CPnanstd CPnlintool CPplotmeasurement CPquestdlg CPrelateobjects CPrescale CPresizefigure CPretrieveimage CPretrievemediafilenames CPrgsmartdilate CPselectmodules CPselectoutputfiles CPsigmoid CPsmooth CPtextdisplaybox CPtextpipe CPthresh_tool CPthreshold CPwaitbar CPwarndlg CPwhichmodule CPwritemeasurements VirusScreen_Cluster_01 VirusScreen_Cluster_02 VirusScreen_LocalDensity_01 fit_mix_gaussian
    
    fprintf('%s: Starting CPCluster\n',mfilename2)
    fprintf('%s: \tbatchfile = %s\n',mfilename2,batchfile)
    fprintf('%s: \tclusterfile = %s\n',mfilename2,clusterfile)

    batchfile = npc(batchfile);
    clusterfile = npc(clusterfile);
    
    % Add custom project code support.
    brainy.libpath.checkAndAppendLibPath(os.path.dirname(batchfile));
        
    warning off all

    load(batchfile);
    load(clusterfile);
%     tic
    handles.Current.BatchInfo.Start = cluster.StartImage;
    handles.Current.BatchInfo.End = cluster.EndImage;
    
    strPipelineFieldNames = fieldnames(handles.Pipeline);
    strFirstFileListIndex = (find(strncmpi(strPipelineFieldNames,'FileList',8),1,'first'));
    
    for BatchSetBeingAnalyzed = cluster.StartImage:cluster.EndImage,
%        disp(sprintf('Analyzing set %d\n', BatchSetBeingAnalyzed));
%         toc;
        handles.Current.SetBeingAnalyzed = BatchSetBeingAnalyzed;
        fprintf('%s: Analying image set %d (max threads = %d)\n',mfilename2,BatchSetBeingAnalyzed,maxNumCompThreads)
        for SlotNumber = 1:handles.Current.NumberOfModules,
            ModuleNumberAsString = sprintf('%02d', SlotNumber);
            ModuleName = char(handles.Settings.ModuleNames(SlotNumber));
            handles.Current.CurrentModuleNumber = ModuleNumberAsString;
            try
                fprintf('%s:   %02d: %s \n',mfilename2,SlotNumber,ModuleName)
                warning off all %problem is that several modules & subfunctions in CP do a "%warning on all"
                handles = feval(ModuleName,handles);
                warning off all
                if strcmpi(ModuleName,'LoadImages')
                    try
                        fprintf('%s:     Image set %02d = %s\n',mfilename2,BatchSetBeingAnalyzed,handles.Measurements.Image.FileNames{BatchSetBeingAnalyzed}{1,1})
                    end
                end
            catch
                handles.BatchError = [ModuleName ' ' lasterr];
                disp(['Batch Error: ' ModuleName ' ' lasterr]);
                rethrow(lasterror);
                quit;
            end
        end
    end
    % cd(cluster.OutputFolder);
    handles.Pipeline = [];

    %[NB HACK] the OUT.mat file should be saved after the measurement
    %files are saved, else it can lead to iBRAIN joining bad measurement files!!!
%     temp = [];
%     save(sprintf('%s%d_to_%d_OUT',cluster.BatchFilePrefix,cluster.StartImage,cluster.EndImage),'temp','-v7.3');
%     SeparateMeasurementsFromHandles(handles,cluster)
    
    %save measurements
    SeparateMeasurementsFromHandles(handles,cluster)

    %generate OUT.mat file    
    temp = [];
    save(fullfile(cluster.OutputFolder,sprintf('%s%d_to_%d_OUT.mat',cluster.BatchFilePrefix,cluster.StartImage,cluster.EndImage)),'temp','-v7.3');
    disp('finished CPCluster')
%    toc

end

function strTxt = mfilename2()
    strTxt = sprintf('%s - %s',mfilename, datestr(now,13));
end
