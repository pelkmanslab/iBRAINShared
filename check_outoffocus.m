function check_outoffocus(strRootPath)

    if nargin == 0
        strRootPath = 'Y:\Data\Users\Prisca\090203_Mz_Tf_EEA1\090203_Mz_Tf_EEA1_CP394-1ac\BATCH\';
        strRootPath = sp('ethz_share4', 'Data/Users/Vicky/iBrain/RV/130625_DS1_HCT_batch1a/BATCH');
        %strRootPath = npc(strRootPath);
    end
    
    disp(sprintf('%s: analyzing "%s"',mfilename,strRootPath));    

    
    handles = struct();
    try
        handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_OrigBlueSpectrum.mat'));
        BlueSpectrum = 'OrigBlueSpectrum';
    catch
        handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_RescaledBlueSpectrum.mat'));        
        BlueSpectrum = 'RescaledBlueSpectrum';        
    end
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_ObjectCount.mat'));       
    handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_FileNames.mat'));
    
    %%% MAKE THRESHOLD DEPEND ON THE TYPE OF MICROSCOPE FROM WHICH THE
    %%% IMAGES CAME
    %%% [070518 BS] ADDED _TDS SPECIFIC IMAGE GRANULARITY THRESHOLD
    
    [foo,strMicroscopeType] = check_image_position(handles.Measurements.Image.FileNames{1}{1});
    clear foo;
    disp(sprintf('%s: microscope type "%s"',mfilename,strMicroscopeType));

    if strfind(strRootPath, '_TDS')
        intMinimalGranularity = 20;        
    elseif strfind(strRootPath, '_RVHCT116') 
        % Vicky's endocytome screen on CV7K
        intMinimalGranularity = 1;
    elseif strcmpi(strMicroscopeType,'md')
       intMinimalGranularity = 8;
    elseif strcmpi(strMicroscopeType,'CV7K')
       intMinimalGranularity = 6;
    else 
       intMinimalGranularity = 18;       
    end    
    disp(sprintf('%s: minimial image granularity threshold: %d',mfilename,intMinimalGranularity));    
    
    
    
    % DETERMINE WHICH OBJECT_COUNT TO USE.
    cellstrObjectName = {'Nuclei', 'Cells', 'OrigNuclei'};
    for i = 1:length(handles.Measurements.Image.ObjectCountFeatures)
        intObjectCountColumn = find(strcmp(handles.Measurements.Image.ObjectCountFeatures,cellstrObjectName{i}));                    
        if not(isempty(intObjectCountColumn))
            disp(sprintf('%s: using %s for total object count',mfilename,handles.Measurements.Image.ObjectCountFeatures{1,intObjectCountColumn}))
            break
        end
    end
    if isempty(intObjectCountColumn)
        intObjectCountColumn = 1;
        disp(sprintf('WARNING: Could not find Nuclei or Cells object in your data, using %s',handles.Measurements.Image.ObjectCountFeatures{1,intObjectCountColumn}))
    end

    
    matImageObjectCount = cell2mat(handles.Measurements.Image.ObjectCount');
    matImageObjectCount = matImageObjectCount(:,intObjectCountColumn);
    
    warning off all
    intNumberOfImages = length(handles.Measurements.Image.(BlueSpectrum ));
    
    totaldiscarded = 0;
    matdiscarded = zeros(1,intNumberOfImages);

    imagespectra = cell2mat(handles.Measurements.Image.(BlueSpectrum )');
    maximagespectrum = max(imagespectra,[],2);
    outoffocusindices = find((maximagespectrum < intMinimalGranularity & matImageObjectCount < 1700) | (maximagespectrum < intMinimalGranularity-2 & matImageObjectCount >= 1700 & matImageObjectCount < 2500) | (maximagespectrum < intMinimalGranularity-3 & matImageObjectCount >= 2500));
    matdiscarded(1,outoffocusindices) = 1;
    totaldiscarded = length(outoffocusindices);
    
    
    strOutPutFile = fullfile(strRootPath, 'Measurements_Image_OutOfFocus.mat');
    Measurements = struct();
    Measurements.Image.OutOfFocus = matdiscarded;
    disp(sprintf('%s: discarded %d images (%.0f%%)as out of focs',mfilename,sum(matdiscarded),100*(sum(matdiscarded)/length(matdiscarded))))
    if nargin ~= 0
        save(strOutPutFile,'Measurements', '-v7.3')
        disp(sprintf('%s: stored %s',mfilename,strOutPutFile))
    end