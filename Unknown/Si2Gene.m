function matGeneData = Si2Gene(matSiData)

    % calculate median value over replicates (no punishing for missing
    % replicate values)...
    matSiData = nanmedian(matSiData,3);
    
    % for genes with 1 si only, set to nan
    % for genes with 2 sis, set nan to 0 (with small noise).
    matCorrectedSiData = matSiData;
    matTwoOrMoreNaNsIX = sum(isnan(matCorrectedSiData),2)>=2;
    %matCorrectedSiData(isnan(matCorrectedSiData)) = 0.1*rand([sum(lin(isnan(matCorrectedSiData))),1]);
    matCorrectedSiData(isnan(matCorrectedSiData)) = 0.1*rand([sum(isnan(matCorrectedSiData(:))),1]);
    matCorrectedSiData(matTwoOrMoreNaNsIX,:) = NaN;
    
    matGeneData = nanzscore_median(nanmean(matCorrectedSiData,2));
