function [intImagePosition,strMicroscopeType] = check_image_position(strImageName)
% help for check_image_position()
% BS, 082015
% usage [intImagePosition,strMicroscopeType] = check_image_position(strImageName)
%
% possible values for strMicroscopeType are 'CW', 'BD', and 'MD'

    if nargin == 0
%         strImageName = '061224_YD_50K_KY_P1_1_1_H07f00d0.png';
    % strImageName = '090313_SV40_FAKKO_GLY_GLYGGPP_GM1_noGM1_A01_01_w460_SegmentedCells.png';
    
%    strImageName = '070314_TDS_VSV_50K_P2_1_B02f0d0_SegmentedCells.png';
        
%         strImageName = '070420_Tf_KY_P2_20x_C10_19_w460.tif'
%         strImageName = 'Dapi - n000000.tif'
%         strImageName = 'DAPI_p53SLS - n000000.png';    
%         strImageName = '040423_frank_si_VSV_B02_25_w460.tif';  
%         strImageName = 'Y:\Data\Users\Jean-Philippe\p53hitvalidation\ko_p53Pro72_plate1_triplicate1\TIFF\Well H12\Dapi_p53SLS - n000000.tif';
%         strImageName = '080611-olivia-1_A10_s1_w12E22EFEB-B167-43E0-A05F-997CCA19728A.tif'
%         strImageName = '080815-Frank-VSV-pH-dyn_B02_s1_w11BBF4034-97B9-4912-9DA5-6FBAF05BA7E4.tif'
%         strImageName = '081008_VV_rescreen_CP078-1aa_K04_8_w530.png';
%         strImageName = '2008-08-14_HPV16_batch1_CP001-1ea_A20_9_w530.tif'
%         strImageName = 'BAC-siRNA-Optimisation_C01_s3CB0B5EFE-CA88-49D1-B8B8-2115D7B91A6F.png'
         strImageName = 'RDUP20120522-CNX_K04_s6_w210E554F9-A2B4-4D39-969A-C1216D5C5893.png';        
    end

    strMicroscopeType = '';
    intImagePosition = 1;
    
    % CW
    strNomenclature1 = regexp(strImageName,'f\d\dd\d.(tif|png)','Match');
    strNomenclature1a = regexp(strImageName,'f\dd\d.(tif|png)','Match'); 
    strNomenclature1b = regexp(strImageName,'f\d\dd\d','Match');
    strNomenclature1c = regexp(strImageName,'f\dd\d','Match');
    strNomenclature2 = regexp(strImageName,'_w\d\d\d.(tif|png)','Match'); 
    strNomenclature3 = regexp(strImageName,' - n\d{2,}.(tif|png)','Match');
    
    % NIKON
    strNomenclaturePre4 = regexp(strImageName,'NIKON.*_t\d{1,}(_z\d{1,}_|_)[A-Z]\d{2,3}_s\d{1,}_w\d{1,}[^\.]*\.(tiff?|png)','Match');
    
    % MD MICROEXPRESS
    strNomenclature4 = regexp(strImageName,'_\w\d\d_s\d{1,}_w\d','Match');    
    % MD with only one channel matches this but not the previous
    strNomenclature4a = regexp(strImageName,'_\w\d\d_s\d{1,}[A-Z0-9\-]{36}','Match');
    strNomenclature4b = regexp(strImageName,'_\w\d\d_\d{1,}_w\d','Match');    
    
    % CV7K
    %%[NB] here is a fix from the first regexp below. It was not compatible
    %%with the iBrainTrackerV1.
    strNomenclature5 = regexp(strImageName, ...
        '_([^_]{3})_(T\d{4})(F\d{3})(L\d{2})(A\d{2})(Z\d{2})(C\d{2})', 'Match');
    %    strNomenclature5 = regexp(strImageName, ...
    %    '_([^_]{3})_(T\d{4})(F\d{3})(L\d{2})(A\d{2})(Z\d{2})(C\d{2})\.(tif|png)$', 'Match');

	% fallback
	strNomenclature6 = regexp(strImageName,'_s\d{1,}_','Match');
    
    if not(isempty(strNomenclature1))
        strMicroscopeType = 'CW';
        strImagePosition = regexp(strImageName,'f\d\dd\d.(tif|png)','Match');
        strImagePosition = strImagePosition{1,1}(1,1:3);
        strImagePosition = strrep(strImagePosition,'f','');
        intImagePosition = str2double(strImagePosition)+1;        
    elseif not(isempty(strNomenclature2))
        strMicroscopeType = 'CW';        
        strImagePosition = regexp(strImageName,'_\d\d_w\d\d\d.(tif|png)','Match');
        if not(isempty(strImagePosition))
            intImagePosition = str2double(strImagePosition{1,1}(1,2:3));
        else
            strImagePosition = regexp(strImageName,'_\d_w\d\d\d.(tif|png)','Match');
            intImagePosition = str2double(strImagePosition{1,1}(1,2));
        end
    elseif not(isempty(strNomenclature1a))
        strMicroscopeType = 'CW';        
        strImagePosition = regexp(strImageName,'f\dd\d.(tif|png)','Match');
        strImagePosition = strImagePosition{1,1}(1,1:2);
        strImagePosition = strrep(strImagePosition,'f','');
        intImagePosition = str2double(strImagePosition)+1;        
    elseif not(isempty(strNomenclature1b))
        strMicroscopeType = 'CW';
        strImagePosition = regexp(strImageName,'f\d\dd\d','Match');
        strImagePosition = strImagePosition{1,1}(1,1:3);
        strImagePosition = strrep(strImagePosition,'f','');
        intImagePosition = str2double(strImagePosition)+1;     
    elseif not(isempty(strNomenclature1c))
        strMicroscopeType = 'CW';
        strImagePosition = regexp(strImageName,'f\dd\d','Match');
        strImagePosition = strImagePosition{1,1}(1,2);
        intImagePosition = str2double(strImagePosition)+1;             
    elseif not(isempty(strNomenclature3))
        strMicroscopeType = 'BD';        
        strImagePosition = regexpi(strImageName,' - n(\d{2,}).(tif|png)','Tokens');
        if ~isempty(strImagePosition)
            intImagePosition = str2double(strImagePosition{1}{1})+1;
        end   
    elseif not(isempty(strNomenclaturePre4))
        strMicroscopeType = 'NIKON';
        strImagePosition = regexpi(strImageName,'NIKON.*_t\d{1,}(_z\d{1,}_|_)[A-Z]\d{2,3}_s(\d{1,})_w(\d{1,})[^\.]*\.(tiff?|png)','Tokens');
        intImagePosition = str2double(char(strImagePosition{1}(2)));
    elseif not(isempty(strNomenclature4))
        strMicroscopeType = 'MD';        
        strImagePosition = regexpi(strImageName,'_\w\d\d_s(\d{1,})_w\d','Tokens');        
        intImagePosition = str2double(strImagePosition{1});
    elseif not(isempty(strNomenclature4a))
        strMicroscopeType = 'MD';
        strImagePosition = regexpi(strImageName,'_\w\d\d_s(\d{1,})[A-Z0-9\-]{36}','Tokens');  
        intImagePosition = str2double(strImagePosition{1});        
    elseif not(isempty(strNomenclature4b))
        strMicroscopeType = 'MD';
        strImagePosition = regexpi(strImageName,'_\w\d\d_(\d{1,})_w\d','Tokens');        
        intImagePosition = str2double(strImagePosition{1});
    elseif not(isempty(strNomenclature5))
        %%% CV7K - we have a match against "Yokogawa" filenaming tail
        strMicroscopeType = 'CV7K';
        %%[NB] I change this to be compatible with tracker as before
        strImagePosition = regexp(strImageName, '_([^_]{3})_(T\d{4})F(\d{3})(L\d{2})(A\d{2})(Z\d{2})C(\d{2})', 'Tokens');
        %strImagePosition = regexp(strImageName, '_([^_]{3})_(T\d{4})F(\d{3})(L\d{2})(A\d{2})(Z\d{2})C(\d{2})\.(tif|png)$', 'Tokens');
        intImagePosition = str2double(strImagePosition{1}(3));
    elseif not(isempty(strNomenclature6)) 
        strMicroscopeType = 'MD';
        strImagePosition = regexpi(strImageName,'_s(\d{1,})_','Tokens');
        intImagePosition = str2double(strImagePosition{1});
 
    else        
        
        error('unknown file name %s',strImageName)
    end
end
