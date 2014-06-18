function [intRow, intCol] = check_image_well_position(strImageName)
    intRow = 0;
    intCol = 0;
    
    strImageName = char(strImageName);
    
    strWellMatch = regexp(strImageName,'_[A-Z]\d\d','Match');
    strWellMatch = strWellMatch(end);

    if size(strWellMatch) == [1 1]
        strWellMatch = strrep(char(strWellMatch{1,1}),'_','');
        intCol = str2double(strWellMatch(1,2:3));
        intRow = double(strWellMatch(1,1))-64;
    else
        error('unknown file name %s',strImageName)        
    end
end
