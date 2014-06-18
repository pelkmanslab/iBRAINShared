function [matWeights, matDirectionality, matPartialVariances] = GGM_bs(X)
% Graphical Gaussian Models, implemented by Berend Snijder as described in:
%   "From correlation to causation networks: a simple approximate learning
%   algorithm and its application to high-dimensional plant gene expression
%   data."
%   Rainer Opgen-Rhein and Korbinian Strimmer
%
% usage:
% [matWeights, matDirectionality, matPartialVariances] = GGM(X)
%
%   (Note that matWeights equals the partial correlation.)

p = size(X,2);
matCovariance = cov(X);
matConcentration = inv(matCovariance);
matVariances = var(X);

% the inverse of the diagonal of 'the inverse of the covariance matrix'. Note
% that 'the inverse of the covariance matrix' is the concentration matrix.
matPartialVariances = NaN(1,p);
for k = 1:p
    matPartialVariances(k) = matConcentration(k,k) ^ -1;
end

% matCorrelations = corr(X);

A = NaN(p,p);
B = NaN(p,p);
for k = 1:p
    for l = 1:p
        % note, A = partial correlation
        A(k,l) = -matConcentration(k,l) * (matConcentration(k,k) * matConcentration(l,l)) ^ -(1/2);
        % note, log(B) = directionality
        B(k,l) = sqrt((matPartialVariances(k)^2 / matVariances(k) ^ 2) / (matPartialVariances(l)^2 / matVariances(l) ^ 2));
    end
end

matWeights = A;
matDirectionality = log(B);
end