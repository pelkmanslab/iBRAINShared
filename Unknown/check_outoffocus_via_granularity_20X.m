function [totaldiscarded, matdiscarded ] = check_outoffocus_via_granularity_20X(strRootPath)
   
global handles

    %if nargin == 0
%        strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\50K_final\MHV_TDS\070131_MHV_50K_rt_Srec_TDS_P3_3\';
%        strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\50K_final\SFV_KY\070124_SFV_KY_50K_P3_1_2_rescan\';
%        strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\50K_final\VSV_KY\060621_VSV_Kyoto_50k_p2_1\';
%        strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\50K_final\HRV2_KY\070302_HRV2_KY_50K_rt_P1_2\';
%        strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\50K_final\MHV_KY\061102_MHV_KY_GFP_50K_GFP_P2_2\';       


%        strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\VSV_DG\070309_VSV_DG_batch1_CP004-1ab\';       
%        strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\VSV_DG\070407_VSV_DG_batch4_CP0063-1c\DATAFUSION\';              
        strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\VSV_DG\070407_VSV_DG_batch4_CP0064-1c\DATAFUSION\';       
       

    %end

    if nargin == 0
        if ispc
            strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\50K_final\Ad3_KY\070208_Ad3_50K_Ky_1_1\';
        else
            strRootPath = '/Volumes/share-2-$/Data/Users/Raphael/070611_Tfn_kinase_screen/070610_Tfn_MZ_kinasescreen_CP045-1cd/BATCH/';
        end
    end
    
    
    
    
    %%% [070518 BS] ADDED _TDS SPECIFIC IMAGE GRANULARITY THRESHOLD
    if strfind(strRootPath, '_TDS')
        intMinimalGranularity = 20;        
    else
%        intMinimalGranularity = 18;
        intMinimalGranularity = 15 % 20X non-binned images
    end
    
    if isempty(handles)
        handles = struct();
        handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_OrigBlueSpectrum.mat'));
        handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_ObjectCount.mat'));    
    end
    
    matImageObjectCount = cell2mat(handles.Measurements.Image.ObjectCount');
    matImageObjectCount = matImageObjectCount(:,1);
    
    warning off all
    intNumberOfImages = length(handles.Measurements.Image.OrigBlueSpectrum);
    
    totaldiscarded = 0;
    matdiscarded = zeros(1,intNumberOfImages);

% OLDSCHOOL     
%     for k = 1:intNumberOfImages
%             if (max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) < intMinimalGranularity) & (matImageObjectCount(k,1) < 1700) | ...
%                (max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) < intMinimalGranularity-2) & (matImageObjectCount(k,1) >= 1700)
%             matdiscarded(1,k) = 1;
%             totaldiscarded = totaldiscarded + 1;
%         end
%     end
    

    imagespectra = cell2mat(handles.Measurements.Image.OrigBlueSpectrum');
    maximagespectrum = max(imagespectra,[],2);
    outoffocusindices = find((maximagespectrum < intMinimalGranularity & matImageObjectCount < 1700) | (maximagespectrum < intMinimalGranularity-2 & matImageObjectCount >= 1700));
    matdiscarded(1,outoffocusindices) = 1;
    totaldiscarded = length(outoffocusindices);
    
    
    strOutPutFile = fullfile(strRootPath, 'Measurements_Image_OutOfFocus.mat');
    Measurements = struct();
    Measurements.Image.OutOfFocus = matdiscarded;
    if nargin ~= 0
        save(strOutPutFile,'Measurements', '-v7.3')
        disp(['Saved ',strOutPutFile])
    end
    
    if nargin == 0
        % IF THIS IS A TEST RUN, MAKE DISPLAY
        handles = LoadMeasurements(handles, fullfile(strRootPath,'Measurements_Image_FileNames.mat'));    
%         matImageIntensities = cell2mat(handles.Measurements.Image.Intensity_RescaledGreen');
        matImageObjectCount = cell2mat(handles.Measurements.Image.ObjectCount');     
        matImageGrans = cell2mat(handles.Measurements.Image.OrigBlueSpectrum');
        for k = find(matdiscarded)%ImageIndexes
%             if (max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) < intMinimalGranularity) & (matImageObjectCount(k,1) < 1700) | ...
%                     (max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) < intMinimalGranularity-2) & (matImageObjectCount(k,1) >= 1700)
                %max(handles.Measurements.Image.RescaledBlueSpectrum{k}(:)) >= 16 && 
    %          if matImageIntensities(k,2) < 0.003
                figure(1)
                clf
%                strImagePath = [strrep(strRootPath,'Data\Users\Berend\BATCH_RESULTS\',''), 'TIFF', filesep];
                strImagePath = [strrep(strRootPath,'BATCH',''), 'TIFF', filesep];
%                strImagePath = strrep(strImagePath,'DATAFUSION\','');                

                InputImageBlue = imread(fullfile(strImagePath, char(handles.Measurements.Image.FileNames{k}(1,2))));
                InputImageBlue = double(InputImageBlue(:,:))/1800;

                InputImageBlue(find(InputImageBlue < 0)) = 0;
                InputImageBlue(find(InputImageBlue > 1)) = 1;

                subplot(3,3,1)
                bar(handles.Measurements.Image.OrigBlueSpectrum{k})

%                 subplot(3,3,2)
%                 hold on
%                 hist(matImageObjectCount(:,2),50)
%                 vline(matImageObjectCount(k,2))
%                 hold off

                subplot(3,3,3)
                hold on
                scatter(matImageObjectCount(:,1),max(matImageGrans'),5)
                vline([matImageObjectCount(k,2), 1700], {'r', 'b'});
                hline([max(matImageGrans(k,:)'), intMinimalGranularity, intMinimalGranularity-2], {'r', 'b', 'b'});
                xlabel('total number of cells')
                ylabel('max granularity')                
                hold off                
                
                
                subplot(3,3,[4 5 6 7 8 9])
                colormap gray;
                hold on
                imagesc(InputImageBlue);
                hold off
                
                uicontrol('style','text','units','normalized','fontsize',36,'HorizontalAlignment','center','FontWeight','bold','String',num2str(round(max(handles.Measurements.Image.OrigBlueSpectrum{k}(:)))),'position',[.48 .85 .06 .05], 'BackgroundColor', 'w');
                
                
                drawnow
                pause(.001)
%             end
        end
    end