function [matLog10PValues,matOverlap] = calculateHygePDFAnnotationEnrichment(matGenesIX,matClassesIX,intMinSize)
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
elseif iscell(matGenesIX)
    if any(lin(cellfun(@(x) size(x,2),matGenesIX)) ~= size(matClassesIX,2))
        error('first input is a cell array, so each cell should have the same number of columns as the second input (corresponding to gene identities)')
    end
    intNumOfGeneSets = numel(matGenesIX);
    matGeneSetSize = cellfun(@sum,matGenesIX);
else
    error('%s: first input must either be a matrix or a cell array\n',mfilename)
end
intNumOfClasses = size(matClassesIX,1);

fprintf('%s: calculating hygepdf enrichments for %d genes, %d gene lists and %d annotations, with a minimal presence of %d genes\n',mfilename,size(matClassesIX,2),intNumOfGeneSets,intNumOfClasses,intMinSize)


if islogical(matGenesIX)
    matLog10PValues = ones(intNumOfGeneSets,intNumOfClasses);
    matOverlap = zeros(intNumOfGeneSets,intNumOfClasses);
elseif iscell(matGenesIX)
    matLog10PValues = ones([size(matGenesIX),intNumOfClasses]);
    matOverlap = zeros([size(matGenesIX),intNumOfClasses]);
end

for iAnnotation = 1:intNumOfClasses
    
    % init tmp result placeholders per annotations
    if islogical(matGenesIX)
        matTmpAnnotationResults = ones(intNumOfGeneSets,1);
        matTmpOverlap = zeros(intNumOfGeneSets,1);
    elseif iscell(matGenesIX)
        matTmpAnnotationResults = ones(size(matGenesIX));
        matTmpOverlap = zeros(size(matGenesIX));
    end    
    
    for iGeneSet = 1:intNumOfGeneSets
        if matGeneSetSize(iGeneSet)<intMinSize;continue;end
        
        if islogical(matGenesIX)
            intListOverlap = sum(matGenesIX(iGeneSet,:) & matClassesIX(iAnnotation,:));
        else
            intListOverlap = sum(matGenesIX{iGeneSet} & matClassesIX(iAnnotation,:));
        end
        
        if intListOverlap<intMinSize;continue;end

        matTmpOverlap = intListOverlap;
        
        X = intListOverlap;
        M = intPopulationSize;
        K = matAnnotationSize(iAnnotation);
        N = matGeneSetSize(iGeneSet);

        intDownP = log10(hygepdf(X,M,K,N));
        
        
        % only score enrichment
        if ((X/N) > (K/M)) && (-intDownP)>1 && X>=intMinSize
            % enrichment
            %matLog10PValues(iGeneSet,iAnnotation) = intDownP;
            matTmpAnnotationResults(iGeneSet) = intDownP;
        end
    end
    
    if islogical(matGenesIX)
        matLog10PValues(:,iAnnotation) = matTmpAnnotationResults;
        matOverlap(:,iAnnotation) = matTmpOverlap;
    elseif iscell(matGenesIX)
        matLog10PValues(:,:,iAnnotation) = matTmpAnnotationResults;
        matOverlap(:,:,iAnnotation) = matTmpOverlap;
    end
end