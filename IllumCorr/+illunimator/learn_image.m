function boolReadSuccesfull = learn_image(stat, filename)
%LEARN_IMAGE try to read image as a matrix of double values and learn 
% statistics.
% 
% LEARN_IMAGE STAT FILENAME
%
% Method is a part of "illunimator" package - an implementation of 
% illumination correction algorithm by B. Snijder and N. Battich.
%
% Illunimator is distributed under the GNU General Public License.
% See the accompanying file LICENSE for details.
%
% Authors: 
%   Yauhen Yakimovich <yauhen.yakimovich@uzh.ch>
%

%   Copyright 2012 Pelkmans group.
    boolReadSuccesfull = false;
    try
        image = double(imread(filename));
        boolReadSuccesfull = true;
    catch exception
        warning('illuminator:learn_image',...
            'Failed to read image: %s. Error: %s',... 
            filename, exception. message);
        % Ignoring failure and skipping the read for this image.
        return
    end
    
    % Log10 transform 
    image = log10(image);
    image(isinf(image)) = 0;

    % Smooth [BS-14-06-2012] Disabled smoothing as it creates too many
    % artifacts at the border of images. Discuss with me if you disagree...
    % :) 
    % H = fspecial('gaussian',[150 150],50);
    % image = imfilter(image,H,'replicate');
    
    
    % Update stat
    stat.update(image);
end
