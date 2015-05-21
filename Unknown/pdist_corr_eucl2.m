function matPdist = pdist_corr_eucl(XI, XJ,varargin)
%
% [Berend Snijder]. Pass this function handle as @pdist_corr in rowPDist and columnPDist.
%
% How cool is this! A correlation based distance measure for clustering
% that is NaN robust! Woot!
%
% diggety. 
%
% PS. competes with Pauli's "ownmetric.m", which is similar.

    matPdist = 1 - corr(XI',XJ');

    
    % add in nan-robus normalized euclidean distance?
    matEuclDist = sum((repmat(XI,[size(XJ,1),1]) - XJ).^2,2);
    matEuclDist = (matEuclDist / max(matEuclDist)) * 2;
    % lets average out correlation and norm. euclidean distances?
    matPdist = mean([matPdist;matEuclDist']);

    
end