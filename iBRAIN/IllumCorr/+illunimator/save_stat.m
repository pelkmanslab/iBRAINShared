function save_stat(filename, stat)
%SAVE_STAT write learned statistical values.
% 
% SAVE_STAT FILENAME STAT
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
  
    stat_values = struct(...
        'mean', stat.mean,...
        'var', stat.var,...
        'std', stat.std,...
        'count', stat.count,...
        'min', stat.min,...
        'max', stat.max...
    );
    save(filename, 'stat_values');
end
