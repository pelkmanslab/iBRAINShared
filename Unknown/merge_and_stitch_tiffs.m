function merge_and_stitch_tiffs(strBatchPath, strTiffPath, strOutputPath)

    if nargin == 0
%         strBatchPath = '\\nas-biol-micro\share-micro-1-$\DG_screen_Salmonella\070814_Sal_DG_KY_batch1_CP001-1ag\BATCH\';
%         strTiffPath = '\\nas-biol-micro\share-micro-1-$\DG_screen_Salmonella\070814_Sal_DG_KY_batch1_CP001-1ag\TIFF\';        
        
%         strBatchPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\VSV_DG\070309_VSV_DG_batch1_CP004-1ab\BATCH\';        
%         strTiffPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\VSV_DG\070309_VSV_DG_batch1_CP004-1ab\TIFF\';        

%         strBatchPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\50K_checkers\060518_HSV1_Ky_checker\BATCH\';        
%         strTiffPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\50K_checkers\060518_HSV1_Ky_checker\TIFF\';        
% 
%         strBatchPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\50K_final\YF_MZ\061213_YF_MZ_P1_1_1\';        
%         strTiffPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\50K_final\YF_MZ\061213_YF_MZ_P1_1_1\TIFF\';        


        strBatchPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Berend\BATCH_RESULTS\Data\Users\50K_final\MHV_KY\061102_MHV_KY_GFP_50K_GFP_P1_1\';        
        strTiffPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\50K_final\MHV_KY\061102_MHV_KY_GFP_50K_GFP_P1_1\TIFF\';        
        
        
        strOutputPath = 'C:\Documents and Settings\imsb\Desktop\benjamin_testcase\';        
    end


    handles = struct();
    handles = LoadMeasurements(handles, fullfile(strBatchPath, 'Measurements_Image_FileNames.mat'));
    handles = LoadMeasurements(handles, fullfile(strBatchPath, 'Measurements_Nuclei_VirusScreen_ClassicalInfection_Overview2.mat'));    
    
    matInfectionData = cell2mat(handles.Measurements.Nuclei.VirusScreenInfection_Overview');
    intNumberOfImages = size(handles.Measurements.Image.FileNames,2);


    strNomenclature1 = regexp(handles.Measurements.Image.FileNames{1}(1,1),'_[A-Z]\d\df\d','Match');
    strNomenclature2 = regexp(handles.Measurements.Image.FileNames{1}(1,1),'_[A-Z]\d\d_\d','Match');    

    if not(isempty(strNomenclature1{1})) % OLDSKOOL FILES, RESCALE MORE
    %    matChannelRescaleFactors = [600,250,750]; % RV CONSTRUCT DATA
    %    matChannelRescaleFactors = [600,150,150]; % MHV CONSTRUCT DATA        
        matChannelRescaleFactors = [400,150,150]; 
    elseif not(isempty(strNomenclature2{1})) % NEWSKOOL FILES, RESCALE LESS
        matChannelRescaleFactors = [3000,1200,1000]; % BENJAMIN DATA            
    else not(isempty(strNomenclature1{1})) % NEWSKOOL FILES, RESCALE LESS
        disp('taking a guess at the correct rescale factor')
        matChannelRescaleFactors = [3000,1200,1000]; % BENJAMIN DATA            
    end
    
    matImageSize = size(imread(fullfile(strTiffPath,char(handles.Measurements.Image.FileNames{1}(1,1)))));
    matChannelOrder = [3,2,1]; % BLUE, GREEN, RED --- !!! SHOULD BE DETERMINED FROM FILENAMES DATA !!!
    
    for k = 1:9:intNumberOfImages
        Overlay = zeros(round(matImageSize(1,1)*1.5),round(matImageSize(1,2)*1.5),3, 'single');        
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
%                 
%             if max(Patch(:)) <= 4096
%                 max(Patch(:))
%                 disp('compensating for cellworx image error!!!')
%                 Patch = Patch * 255;
%             end
            
%             Patch = imresize(Patch, .5);
            Patch(:,:) = Patch(:,:)/matChannelRescaleFactors(1,i);
            Patch(Patch < 0) = 0;
            Patch(Patch > 1) = 1;  
            Overlay(:,:,matChannelOrder(i)) = Patch;
        end
% % %         
% % % %         im = uint8(255*Overlay);
% % %         im = Overlay;        
% % %         % Create the text mask 
% % %         % Make an image the same size and put text in it 
% % %         hf = figure('color','white','units','normalized','position',[.1 .1 .8 .8]); 
% % %         image(ones(size(im))); 
% % %         set(gca,'units','pixels','position',[5 5 size(im,2)-1 size(im,1)-1],'visible','off')
% % % 
% % %         cellstrText = {};            
% % %         strPlateData = regexp(handles.Measurements.Image.FileNames{k}(1,1),'_CP\d\d\d','Match');
% % %         if not(isempty(strPlateData{1}))
% % %             strPlateData = char(strPlateData{1});
% % %             intPlateNumber = str2double(strPlateData(1,4:6));
% % %             strWellData = regexp(handles.Measurements.Image.FileNames{k}(1,1),'_[A-P]\d\d_','Match');
% % %             strWellData = char(strWellData{1});
% % %             intWellRow = double(strWellData(1,2)) - 64;
% % %             intWellColumn = str2double(strWellData(1,3:4));
% % %             [GeneSymbol, OligoNumber, GeneID] = lookupwellcontent(intPlateNumber, intWellRow, intWellColumn);
% % %         else
% % %             GeneSymbol = '';
% % %             OligoNumber = '';
% % %             GeneID = '';
% % %             strPlateData = '';
% % %             strWellData = '';            
% % %         end
% % % 
% % %         cellstrText{1,1} = sprintf('%s - %s',strrep(strPlateData,'_',''),strrep(strWellData,'_',''));            
% % %         cellstrText{2,1} = sprintf('%d cells',sum(matInfectionData(k:k+8,1)));
% % %         cellstrText{3,1} = sprintf('%.1f%% inf.',100*(sum(matInfectionData(k:k+8,2)) / sum(matInfectionData(k:k+8,1))));            
% % %         if isnumeric(GeneID)
% % %             cellstrText{4,1} = sprintf('%s (%d) (%d)',GeneSymbol, GeneID, OligoNumber);
% % %         else
% % %             cellstrText{4,1} = sprintf('%s',GeneSymbol);    
% % %         end
% % % 
% % %         cellstrText = cellstr(cellstrText);
% % %         text('units','pixels','position',[10 100],'fontsize',16,'FontWeight','bold','FontName','Arial','string',cellstrText)  % size(im,1)-10 size(im,2)-10
% % %         drawnow
% % %         pause(.1)
% % % %         text('units','pixels','position',[100 100],'fontsize',16,'FontWeight','bold','FontName','Arial','string',cellstrText)  % size(im,1)-10 size(im,2)-10
% % %         tim = getframe(gca);
% % %         tim2 = tim.cdata;
% % %         close(hf)        
% % %         
% % %         tmask = tim2==0;
% % %         im(tmask) = uint16(255);
% % % %         
% % % %         h2 = figure();
% % % %         imshow(im)
% % % %         drawnow
% % % %         pause(.1)
% % % %         close(h2)

        strfilename = [char(strrep(handles.Measurements.Image.FileNames{k}(1,1),'.tif','')),'_RGB.jpg'];
        disp(sprintf('storing %s in %s.',strfilename,strOutputPath))
%         imwrite(Overlay,fullfile(strOutputPath,strfilename),'jpg','Quality',50);        
        imwrite(Overlay,fullfile(strOutputPath,strfilename),'jpg','Quality',70);
    end
end