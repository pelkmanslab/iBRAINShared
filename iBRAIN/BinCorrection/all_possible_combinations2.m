function matAllPossibleCombinations = all_possible_combinations2(matBinSizes)

    matAllPossibleCombinations = [];

    intBinProduct = prod(matBinSizes);
    cumbins = 1;
    leftoverBins = intBinProduct;
    allotherbins = 1;
    matRow = [];

    for bin = 1:length(matBinSizes)
        matRow = [];
        bins = matBinSizes(bin);
        cumbins = cumbins * bins;
        leftoverBins = leftoverBins/bins;
        allotherbins = intBinProduct / bins;
        for i = 1:bins
            matRow = [matRow;repmat(i,intBinProduct/bins,1)];
        end
        matAllPossibleCombinations = [matAllPossibleCombinations,reshape(reshape(matRow,leftoverBins,cumbins)',intBinProduct,1)];
    end

    if not(size(matAllPossibleCombinations) == size(unique(matAllPossibleCombinations,'rows')))
        error('buggy berend code: not all rows in the output are unique!!!')
    end
end

