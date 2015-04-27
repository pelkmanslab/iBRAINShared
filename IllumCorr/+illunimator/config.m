classdef config
%CONFIG class of illuminator package

    properties (Constant)
        % Use optimized CP functions.
        USE_CP_FUNC = true
        
        % Settings required by LEARN_STAT function to match filenames 
        % for images.
        IMAGES_REGEXPI = '\.(png|tiff?)$';
    end 
    
end