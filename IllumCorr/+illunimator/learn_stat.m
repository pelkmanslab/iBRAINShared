function stat = learn_stat(varargin)
%LEARN_STAT learn statistics for a bundle of supplied images
% 
% LEARN_STAT PATH
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
% TODO: 
%   - Consider varargin{1} as cell array of filenames.

%   Copyright 2012 Pelkmans group.
    
    % Parse and check input parameters.
    if ~iscellstr(varargin)
        error(makeErrID('NotString'), 'The input must be a string.');
    end
    if (nargin == 0)
        error(makeErrID('NoArgs'),...
            'Expected input is a string or a function handle.');
    end
    if ischar(varargin{1})
        % Check if path is an existing folder.
        if ~fileattrib(varargin{1})
            error(makeErrID('NotValidPath'),...
                'Supplied argument is not a valid path: %s.', varargin{1});
        end
        % Use default implementation for listing of images.        
        get_image_filenames = @()list_folder(varargin{1});
    else
        % Use user supplied implementation for listing of images.
        get_image_filenames = varargin{1};
    end
    if ~isa(get_image_filenames, 'function_handle')
        error(makeErrID('NotFuncHandle'),...
            'Expected input is a string or a function handle.');
    end
    if length(varargin) >= 2 && isobject(varargin{2})
        % Expect already existing stat instance to continue the learning
        % process.
        stat = varargin{2};
    else
        % Define new instance to capture running statistics.
        stat = new_stat_instance();
    end

    % For each image filename (which is expected to be a full path to the 
    % image file) do:
    %  * read image as a matrix of doubles
    %  * update statistics in a running ("on-line") manner
    cellfun(@(image_file) illuminator.learn_image(stat, image_file),...
        get_image_filenames(), 'uniformoutput',false);
end

%--------------------------------------------------------------------------
% Default image listing method if path is supplied.
function filenames = list_folder(images_pathname)
    if exist('CPdir', 'file') && illunimator.config.USE_CP_FUNC
        ls_dir = @CPdir;
    else
        ls_dir = @dir;
    end    
    % List directory content as filenames.    
    file_list = ls_dir(images_pathname)';
    file_list([file_list.isdir]) = [];
    filenames = {file_list.name}';
    % Filter for images using regexp from package config.
    images_regexpi = illunimator.config.IMAGES_REGEXPI;
    if ~isempty(images_regexpi)
        matched_indexes = ~cellfun(@isempty,... 
            regexpi(filenames, images_regexpi));
        filenames = filenames(matched_indexes);
    end
    % Prepend path as prefix to each filename prefix.
    filenames = cellfun(@(name) fullfile(images_pathname, name),...
        filenames, 'UniformOutput', false);
end

%--------------------------------------------------------------------------
% Define instance to capture running statistics.
function stat = new_stat_instance()
    % Use 'running_stat' package.
    stat = RunningStatVec.new();
end

%--------------------------------------------------------------------------
% Helper method for error messageID display.
function realErrID = makeErrID(errIDin)
    realErrID = ['illuminator:'  errIDin];
end
