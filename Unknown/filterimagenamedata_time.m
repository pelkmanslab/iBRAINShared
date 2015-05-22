function [int_time, strWellName] = filterimagenamedata_time(strImageName)

    % default output
    int_time = NaN;
    strWellName = NaN;

    if nargin == 0
        strImageName = 'Z:\Data\Users\Prisca\081126_H2B_GPI_movies\081123\Movie\E04\Movie-2_t141_E04_s20_w1073C4B00-115C-4B32-9C3C-01BE1EAF8C1F.tif'
    end

    % match timepoint
    strWellName = regexp(strImageName,'_t(\d{1,})_','Tokens');

    
    try
        int_time = str2double(char(strWellName{1}));
    catch caughtError
        warning('%s: failed to get timepoint from file %s',mfilename,strImageName)
    end
    
end