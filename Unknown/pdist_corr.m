function matPdist = pdist_corr(XI, XJ,varargin)
%
% [Berend Snijder]. Pass this function handle as @pdist_corr in rowPDist and columnPDist.
%
% How cool is this! A correlation based distance measure for clustering
% that is NaN robust! Woot!
%
% diggety. 
%
% PS. competes with Pauli's "ownmetric.m", which is similar.

    matPdist = 1 - corr(XI',XJ','rows','pairwise');

    % should we default NaNs to something? (maximum distance = 2, since 
    % 1 - -1 = 1 + 1 = 2
    matPdist(isnan(matPdist)) = 2;
end