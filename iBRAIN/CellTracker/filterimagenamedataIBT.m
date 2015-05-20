function [intRow, intColumn, intTimepoint, intSite] = filterimagenamedata(strImageName)

    intRow = NaN;
    intColumn = NaN;
    strWellName = NaN;
    intTimepoint  = 1;
    intSite = 1;
    
    if nargin == 0
%         strImageName = '070420_Tf_KY_P2_20x_E01_19_w460.tif'
%         strImageName = '070610_Tfn_MZ_kinasescreen_CP022-1cd_A01f0d0.tif'
%         strImageName = 'Y:\Data\Users\Jean-Philippe\p53hitvalidation\ko_p53Pro72_plate1_triplicate1\TIFF\Well A24'
%         strImageName = '080611-olivia-1_A10_s1_w12E22EFEB-B167-43E0-A05F-997CCA19728A.tif'
%         strImageName = '080815-Frank-VSV-pH-dyn_F02_s1_w1E073FDA7-1105-4532-B633-E9D89C3F23FB.tif'
%         strImageName = '\\nas-biol-imsb-1\share-3-$\Data\Users\HPV16_DG\2008-08-16_HPV16_batch1_CP003-1ec\Well A001\Dapi - n000000.tif'
%         strImageName = 'BAC-siRNA-Optimisation_C01_s3CB0B5EFE-CA88-49D1-B8B8-2115D7B91A6F.png'
%         strImageName = '110420GpiGfpHoechstFakInhib_t_0021_C03_s6_w231366D01-7DCF-4473-A4A4-7A78094ADD3E.png';
%         strImageName = '080815-Frank-VSV-pH-dyn_B02_s1_w11BBF4034-97B9-4912-9DA5-6FBAF05BA7E4.tif'        
%         strImageName = '110519_NB_E37_AAVRS1DOX_VS1_H12_12_w460.png';
%       strImageName = 'SettingB_E05_w167678E42-9203-4F07-9F36-EE22FDBE1B90.png';
         strImageName = '111106-InSitu-MovieTest01_G10_T0123F012L01A01Z01C01.png';
    end

    strWellName = char(strrep(regexp(strImageName,'_[A-Z]\d\d_','Match'),'_',''));
    strWellName2 = char(strrep(regexp(strImageName,'_[A-Z]\d\df','Match'),'_',''));
    strWellName3 = char(strrep(regexp(strImageName,'Well [A-Z]\d{2,}','Match'),'_',''));
    
    % MD MICROEXPRESS
    strNomenclature4 = regexp(strImageName,'_\w\d\d_s\d{1,}_w\d','Match');    
        
    
    % In case of time-points, perhaps override the well position and assign
    % different time points artificial well positions? (temp hack really)
    % match timepoint
    cellstrTimepoint = regexp(strImageName,'_[tT]_?(\d{1,})_?','Tokens');  
    if not(isempty(cellstrTimepoint))
        intTimepoint = str2double(cellstrTimepoint{1});
    else
        intTimepoint = 1;
    end
    
    cellstrSite = regexp(strImageName,'_[sS]_?(\d{1,})_?','Tokens');
    cellstrSite2 = regexp(strImageName,'[fF]_?(\d{1,})_?','Tokens');
    if not(isempty(cellstrSite))
        intSite = str2double(cellstrSite{1});
        
    elseif not(isempty(cellstrSite2))
        intSite = str2double(cellstrSite2{1});
    else
        intSite = 1;
    end
    % This was a timepoint hack, but disabled, was giving problems...
%     if not(isempty(strWellNameTime))
%         matFakeRows = lin(repmat(1:12,24,1));
%         matFakeColumns = lin(repmat([1:24],12,1)');
%         int_time = str2double(char(strWellNameTime{1}));
%         intRow = matFakeRows(int_time);
%         intColumn = matFakeColumns(int_time);
%         strWellName = sprintf('%s%02d',char(intRow+64),intColumn);
%         fprintf('%s: time point detected, faking 384 well position (row=%02d, col=%02d = %s) data based on time point t=%03d\n',mfilename,intRow,intColumn,strWellName,int_time)
%     end

% Note that we shold always take the last match... as user might input
% something before that would/could look like a well.

    
    if not(isempty(strWellName))
        intRow=double(strWellName(end,1))-64;
        intColumn=str2double(strWellName(end,2:3));
        strWellName=strWellName(end,1:end);

    elseif not(isempty(strWellName2))
        intRow=double(strWellName2(end,1))-64;
        intColumn=str2double(strWellName2(end,2:3));

        strWellName=strWellName2(end,1:end-1);

    elseif not(isempty(strWellName3))
        strImageData = regexp(strImageName,'Well ([A-Z])(\d{2,})','Tokens');
        intRow=double(strImageData{1}{1})-64;
        intColumn=str2double(strImageData{1}{2});
        strWellName=sprintf('%s%.02d',strImageData{1}{1},intColumn);

    elseif not(isempty(strNomenclature4))
        %%% MD
        strImageData = regexpi(strImageName,'_(\w)(\d\d)_s','Tokens');
        intRow=double(strImageData{1})-64;
        intColumn=str2double(strImageData{2});
        strWellName=[strImageData{1},strImageData{2}];
    else
        intRow = NaN;
        intColumn = NaN;
        strWellName = NaN;

        warning('filterimagenamedata: unable to get well data from image name %s',strImageName)
    end

	
end