function [matLog10PValues,X,M,K,N] = calculateHygePDFAnnotationEnrichment2(matGenesIX,matClassesIX,intMinSize)
% Help for calculateHygePDFAnnotationEnrichment
%
% calculates enrichment values for logical matrices of equal columns. 
%
% Usage:
%
%    matLog10PValues = calculateHygePDFAnnotationEnrichment(matGenesIX,matClassesIX)
% 
% two logical matrices of the same size would be the most logical input:
% 0) simplest case, both have 1 row and (same) column size. However, row
% sizes can vary. Output is rows = genesets, and columns are annotations.
%
% 1) logical matrix with which genes are selected
% 2) one logical matrix with which genes are in the annotation
%
% But the first input can also be a cell array with one logical vector of
% size number of genes...
%
%  matLog10PValues = log10(p-value) for the enriched cases (i.e. more than probable)

if nargin<3
    intMinSize = 1;
end

if nargin==0
    matGenesIX = zeros(1,1000);
%     matGenesIX(getcolumn(randperm(1000),1:5)) = 1;
    matGenesIX(1:5) = 1;
    matClassesIX = zeros(1,1000);
%     matClassesIX(getcolumn(randperm(1000),1:30)) = 1;
    matClassesIX(1:30) = 1;
end

% we might also do a hygepdf test, although what top-X number of
% genes do we take? varying?
matAnnotationSize = sum(matClassesIX,2);
intPopulationSize = size(matClassesIX,2);

% see how many genes we have in our list
if isnumeric(matGenesIX) || islogical(matGenesIX)
    if isnumeric(matGenesIX); matGenesIX = logical(matGenesIX); end
    if size(matGenesIX,2) ~= size(matClassesIX,2)
        error('first input is a matrix, so both inputs should have the same number of columns (corresponding to gene identities)')
    end
    intNumOfGeneSets = size(matGenesIX,1);
    matGeneSetSize = sum(matGenesIX,2);
    matGeneSetDimensions = intNumOfGeneSets;
elseif iscell(matGenesIX)
    if any(lin(cellfun(@(x) size(x,2),matGenesIX)) ~= size(matClassesIX,2))
        error('first input is a cell array, so each cell should have the same number of columns as the second input (corresponding to gene identities)')
    end
    intNumOfGeneSets = numel(matGenesIX);
    matGeneSetSize = cellfun(@sum,matGenesIX);
    matGeneSetDimensions = size(matGenesIX);
    matGeneSetDimensions(matGeneSetDimensions==1) = [];
else
    error('%s: first input must either be a matrix or a cell array\n',mfilename)
end
intNumOfClasses = size(matClassesIX,1);

fprintf('%s: calculating hygepdf enrichments for %d genes, %d gene lists and %d annotations, with a minimal presence of %d genes\n',mfilename,size(matClassesIX,2),intNumOfGeneSets,intNumOfClasses,intMinSize)

matOutputDimensions = [matGeneSetDimensions,intNumOfClasses];
X = NaN(matOutputDimensions);
M = intPopulationSize;
K = NaN(matOutputDimensions);
N = NaN(matOutputDimensions);
intIX = 0;
for iAnnotation = 1:intNumOfClasses

    for iGeneSet = 1:intNumOfGeneSets

        if islogical(matGenesIX)
            intListOverlap = sum(matGenesIX(iGeneSet,:) & matClassesIX(iAnnotation,:));
        else
            intListOverlap = sum(matGenesIX{iGeneSet} & matClassesIX(iAnnotation,:));
        end
        
        % linear indexing will sort out the variably sized out
        intIX = intIX + 1;
        X(intIX) = intListOverlap;
        K(intIX) = matAnnotationSize(iAnnotation);
        N(intIX) = matGeneSetSize(iGeneSet);

    end

end

matLog10PValues = log10(hygepdf(X,M,K,N));
% only score enrichment, i.e. when the overlap / sample size is bigger than
% class size / population size... and when the overlap is big enough...
matBadIX = ((X./N) <= (K./M)) | X<intMinSize;
matLog10PValues(matBadIX) = 0;
