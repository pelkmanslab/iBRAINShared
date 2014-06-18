% clear all
% close all

strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\SV40_DG\';
%     strRootPath = '\\Nas-biol-imsb-1\share-3-$\Data\Users\HPV16_DG\';

matSDs = [50, 250, 500, 750, 1000, 1500, 2000];

% BASICDATA = {};
% load(fullfile(strRootPath,'BASICDATA_ALL')

cellGeneIdsMats = {};
matMeanIIs = [];
for i = 1:length(matSDs)
    
%     disp(sprintf('loading %s',fullfile(strRootPath,sprintf('BASICDATA_%dSDs.mat',matSDs(i)))))
    
%     BASICDATA{i} = load(fullfile(strRootPath,sprintf('BASICDATA_%dSDs.mat',matSDs(i))));

    disp(sprintf('processing %s',fullfile(strRootPath,sprintf('BASICDATA_%dSDs.mat',matSDs(i)))))

    % convert geneIDs to fully numerical matrix matGeneIDs
    cellGeneIDs = BASICDATA{i}.BASICDATA.GeneID;
    matNumericGeneIDs = ~cellfun(@isnumeric,cellGeneIDs);
    cellGeneIDs(matNumericGeneIDs) = {0};
    cellGeneIdsMats{i} = cell2mat(cellGeneIDs);
    
    % get average II's
    
    matNOIIs = BASICDATA{i}.BASICDATA.CellTypeOverviewNonOthersInfected ./ (BASICDATA{i}.BASICDATA.CellTypeOverviewTotalNumber - BASICDATA{i}.BASICDATA.CellTypeOverviewOthersNumber);
    matIIs = matNOIIs(cellGeneIdsMats{i}>0);
    matIIs( isnan(matIIs ) | isinf(matIIs ) ) = [];
    matMedianIIs(i) = nanmedian(matIIs);
    
end

matResults = nan(length(matSDs));

matUniquePlateNums = unique(BASICDATA{i}.BASICDATA.PlateNumber(:,1))';

for numSDs1 = 1:length(matSDs)
    for numSDs2 = 1:length(matSDs)

        if numSDs1 >= numSDs2

    %         % convert geneIDs to fully numerical matrix matGeneIDs
    %         cellGeneIDs = BASICDATA.GeneID;
    %         matNumericGeneIDs = ~cellfun(@isnumeric,cellGeneIDs);
    %         cellGeneIDs(matNumericGeneIDs) = {0};
    %         matGeneIDs = cell2mat(cellGeneIDs);



            matCorrs2 = [];

            for iPlate = matUniquePlateNums
                for iOligo = unique(BASICDATA{numSDs1}.BASICDATA.OligoNumber(BASICDATA{numSDs1}.BASICDATA.PlateNumber(:,1)==iPlate))'

                    matReplicaIndices1 = find(BASICDATA{numSDs1}.BASICDATA.PlateNumber(:,1)==iPlate & BASICDATA{numSDs1}.BASICDATA.OligoNumber(:,1)==iOligo);
                    matReplicaIndices2 = find(BASICDATA{numSDs2}.BASICDATA.PlateNumber(:,1)==iPlate & BASICDATA{numSDs2}.BASICDATA.OligoNumber(:,1)==iOligo);        
                    for i = matReplicaIndices1'
                        for ii = matReplicaIndices2'

                            % compare each replicate plate combination of
                            % scoring with SD-1 and scoring with SD-2.
                            if BASICDATA{numSDs1}.BASICDATA.ReplicaNumber(i,1) ~= BASICDATA{numSDs2}.BASICDATA.ReplicaNumber(ii,1)

                                % only look at those wells that had siRNAs targeting genes in them
                                matIndices1 = cellGeneIdsMats{numSDs1}(i,:) > 0;
                                matIndices2 = cellGeneIdsMats{numSDs2}(ii,:) > 0;                                
                                matCorrs2 = [matCorrs2, corr(BASICDATA{numSDs1}.BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(i,matIndices1)',BASICDATA{numSDs2}.BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(ii,matIndices2)','rows','complete')]; %#ok<AGROW>

                            end

                        end
                    end
                end
            end

            matResults(numSDs1,numSDs2) = nanmedian(matCorrs2);
            matResults(numSDs2,numSDs1) = nanmedian(matCorrs2);
        end
    end %numSDs2
end %numSDs1


figure()
subplot(4,1,1:3)
% colormap(hot)
imagesc(matResults)
set(gca,'XTickLabel',matSDs)
set(gca,'YTickLabel',matSDs)
colorbar
title('median correlation coefficients among replicates of differently scored plates')
subplot(4,1,4)
bar(matMedianIIs)
set(gca,'XTickLabel',matSDs)
ylabel('Median infection index')
xlabel('stdevs away from mean')

% gcf2pdf(strRootPath,'BASICDATA_Global_AssayCorrelations')

