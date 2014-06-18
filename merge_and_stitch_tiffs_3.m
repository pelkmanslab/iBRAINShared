function merge_and_stitch_tiffs_3(strBatchPath, strTiffPath, strOutputPath)

    if nargin == 0
       strOutputPath= 'C:\Documents and Settings\imsb\Desktop\temp\';        
       strTiffPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\50K_final\MHV_KY\061102_MHV_KY_GFP_50K_GFP_P1_1\TIFF\';        
       
       strBatchPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\50K_final\MHV_KY\061102_MHV_KY_GFP_50K_GFP_P1_1\';               
%        strOutputPath = 'C:\Documents and Settings\imsb\Desktop\temp\';        
    end

% 
    handles = struct();
    handles = LoadMeasurements(handles, fullfile(strBatchPath, 'Measurements_Image_FileNames.mat'));
%     handles = LoadMeasurements(handles, fullfile(strBatchPath, 'Measurements_Nuclei_VirusScreen_ClassicalInfection_Overview2.mat'));    
%     load(fullfile(strBatchPath,'DefaultOUT__16.mat'))

%     matInfectionData = cell2mat(handles.Measurements.Nuclei.VirusScreenInfection_Overview');
    intNumberOfImages = size(handles.Measurements.Image.FileNames,2);


    strNomenclature1 = regexp(handles.Measurements.Image.FileNames{1}(1,1),'_[A-Z]\d\df\d','Match');
    strNomenclature2 = regexp(handles.Measurements.Image.FileNames{1}(1,1),'_[A-Z]\d\d_\d','Match');    

    if not(isempty(strNomenclature1{1})) % OLDSKOOL FILES, RESCALE MORE
    %    matChannelRescaleFactors = [600,250,750]; % RV CONSTRUCT DATA
    %    matChannelRescaleFactors = [600,150,150]; % MHV CONSTRUCT DATA        
    
        matChannelRescaleFactors = [800,350,150];     % SFV MZ
%         matChannelRescaleFactors = [400,150,150]; % DEFAULT
    elseif not(isempty(strNomenclature2{1})) % NEWSKOOL FILES, RESCALE LESS
        matChannelRescaleFactors = [3000,1200,1000]; % BENJAMIN DATA            
    else not(isempty(strNomenclature1{1})) % NEWSKOOL FILES, RESCALE LESS
        disp('taking a guess at the correct rescale factor')
        matChannelRescaleFactors = [5000,1200,1000]; % BENJAMIN DATA            
    end
    
    matImageSize = size(imread(fullfile(strTiffPath,char(handles.Measurements.Image.FileNames{1}(1,1)))));
    matChannelOrder = [3,2,1]; % BLUE, GREEN, RED --- !!! SHOULD BE DETERMINED FROM FILENAMES DATA !!!
    
    for k = 613%1:9:intNumberOfImages
        Overlay = zeros(round(matImageSize(1,1)*3),round(matImageSize(1,2)*3),3, 'single');        
        for i = 1:size(handles.Measurements.Image.FileNames{1},2) %NUMBER OF CHANNELS
            Patch = zeros(matImageSize(1,1)*3,matImageSize(1,2)*3, 'single');
            Patch(:,:) = ...
                single([imread(fullfile(strTiffPath,char(handles.Measurements.Image.FileNames{k+6}(1,i)))),...
                    imread(fullfile(strTiffPath,char(handles.Measurements.Image.FileNames{k+7}(1,i)))),...
                    imread(fullfile(strTiffPath,char(handles.Measurements.Image.FileNames{k+8}(1,i))));
                    imread(fullfile(strTiffPath,char(handles.Measurements.Image.FileNames{k+5}(1,i)))),...
                    imread(fullfile(strTiffPath,char(handles.Measurements.Image.FileNames{k+4}(1,i)))),...
                    imread(fullfile(strTiffPath,char(handles.Measurements.Image.FileNames{k+3}(1,i))));
                    imread(fullfile(strTiffPath,char(handles.Measurements.Image.FileNames{k}(1,i)))),...
                    imread(fullfile(strTiffPath,char(handles.Measurements.Image.FileNames{k+1}(1,i)))),...
                    imread(fullfile(strTiffPath,char(handles.Measurements.Image.FileNames{k+2}(1,i))))]);
            
%                 Patch = imresize(Patch,.5);
            
            Patch(:,:) = Patch(:,:)/matChannelRescaleFactors(1,i);
            Patch(Patch < 0) = 0;
            Patch(Patch > 1) = 1;  
            Overlay(:,:,matChannelOrder(i)) = Patch;
        end

        strfilename = [char(strrep(handles.Measurements.Image.FileNames{k}(1,1),'.tif','')),'_RGB.bmp'];
        disp(sprintf('storing %s in %s.',strfilename,strOutputPath))
%         imwrite(Overlay,fullfile(strOutputPath,strfilename),'jpg','Quality',50);
        imwrite(Overlay,fullfile(strOutputPath,strfilename),'bmp');
    end
end