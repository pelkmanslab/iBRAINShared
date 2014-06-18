% check_dg_plate_correlations_different_infection_3 selects the optimal
% combination of infection-scoring-SD-parameter settings per replicate-set
% that optimizes the product of all three plate correlation coefficients
% between all three replicates.
% the different SD settings are stored in different BASICDATA files, which
% are combined stored in BASICDATA_ALL

clear all
close all

strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\SV40_DG\';
%     strRootPath = '\\Nas-biol-imsb-1\share-3-$\Data\Users\HPV16_DG\';

matSDs = [50, 250, 500, 750, 1000, 1500, 2000];

% Create BASICDATA_OPTIMIZED, containing the complete optimized infection
% data, and a copy of the optimal non-optimized dataset (for SV40, SD=750
% seems to be optimal)
BASICDATA_OPTIMIZED = struct();

BASICDATA = {};
load(fullfile(strRootPath,'BASICDATA_ALL'))

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

% store all standard data in BASICDATA_OPTIMIZED BASICDATA_OPTIMIZED;
BASICDATA_OPTIMIZED = BASICDATA{4}.BASICDATA;

% matResults = nan(length(matSDs));

matUniquePlateNums = unique(BASICDATA{i}.BASICDATA.PlateNumber(:,1))';

matPlateCorrelations = nan(9,size(matUniquePlateNums,2));

% store the optimal corcoefs per plate
matOptimalCorCoefs = NaN(3,70);
% store the optimal stdev settings per plate
matOptimalStds = NaN(3,70);
% store the new avg infection index per plate
matOptimalAvgIIs = NaN(3,70);

% store original data
matRawAvgIIs = NaN(3,70);
matRawCorCoefs = NaN(3,70);
matPlateReplicaNumbers = NaN(3,70);

% get all possible combinations of replica & settings
matAllPossibleCombinations = all_possible_combinations2([7,7,7]);

for iPlate = matUniquePlateNums
    disp(sprintf('optimizing plate %d',iPlate))


    matPlateResults = nan(size(matAllPossibleCombinations,1),3);
    matPlateAvgIIs = nan(size(matAllPossibleCombinations,1),3);    
    for matSDCombination = 1:size(matAllPossibleCombinations,1)

        numSDs1 = matAllPossibleCombinations(matSDCombination,1);
        numSDs2 = matAllPossibleCombinations(matSDCombination,2);
        numSDs3 = matAllPossibleCombinations(matSDCombination,3);    

        % look up which rows match the current plate and oligo
        matReplicaIndices1 = find(BASICDATA{numSDs1}.BASICDATA.PlateNumber(:,1)==iPlate);
        % look up which replica numbers are available for this plate and oligo
        matUniqueReplicas = unique(BASICDATA{numSDs1}.BASICDATA.ReplicaNumber(matReplicaIndices1,1));

        % get the row numbers for each replica, of each analysis
        numReplicaRow1 = find(BASICDATA{numSDs1}.BASICDATA.ReplicaNumber(:,1)==matUniqueReplicas(1) & BASICDATA{numSDs1}.BASICDATA.PlateNumber(:,1)==iPlate);
        numReplicaRow2 = find(BASICDATA{numSDs2}.BASICDATA.ReplicaNumber(:,1)==matUniqueReplicas(2) & BASICDATA{numSDs2}.BASICDATA.PlateNumber(:,1)==iPlate);
        numReplicaRow3 = find(BASICDATA{numSDs3}.BASICDATA.ReplicaNumber(:,1)==matUniqueReplicas(3) & BASICDATA{numSDs3}.BASICDATA.PlateNumber(:,1)==iPlate);

        % only look at those wells that had siRNAs targeting genes in them
        matIndices1 = cellGeneIdsMats{numSDs1}(numReplicaRow1,:) > 0;
        matIndices2 = cellGeneIdsMats{numSDs2}(numReplicaRow2,:) > 0;
        matIndices3 = cellGeneIdsMats{numSDs3}(numReplicaRow3,:) > 0;    

        % 1 vs 2
        intCorCoef1 = corrcoef(BASICDATA{numSDs1}.BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(numReplicaRow1,matIndices1)',BASICDATA{numSDs2}.BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(numReplicaRow2,matIndices2)','rows','complete');
        intCorCoef1 = intCorCoef1(1,2);
        % 1 vs 3
        intCorCoef2 = corrcoef(BASICDATA{numSDs1}.BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(numReplicaRow1,matIndices1)',BASICDATA{numSDs3}.BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(numReplicaRow3,matIndices3)','rows','complete');
        intCorCoef2 = intCorCoef2(1,2);        
        % 2 vs 3
        intCorCoef3 = corrcoef(BASICDATA{numSDs2}.BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(numReplicaRow2,matIndices2)',BASICDATA{numSDs3}.BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(numReplicaRow3,matIndices3)','rows','complete');    
        intCorCoef3 = intCorCoef3(1,2);        

        matPlateResults(matSDCombination,:) = [intCorCoef1, intCorCoef2, intCorCoef3];
        matPlateAvgIIs(matSDCombination,:) = [...
            nanmedian(BASICDATA{numSDs1}.BASICDATA.CellTypeOverviewNonOthersInfected(numReplicaRow1,matIndices1) ./ (BASICDATA{numSDs1}.BASICDATA.CellTypeOverviewTotalNumber(numReplicaRow1,matIndices1) - BASICDATA{numSDs1}.BASICDATA.CellTypeOverviewOthersNumber(numReplicaRow1,matIndices1))), ...
            nanmedian(BASICDATA{numSDs2}.BASICDATA.CellTypeOverviewNonOthersInfected(numReplicaRow2,matIndices2) ./ (BASICDATA{numSDs2}.BASICDATA.CellTypeOverviewTotalNumber(numReplicaRow2,matIndices2) - BASICDATA{numSDs2}.BASICDATA.CellTypeOverviewOthersNumber(numReplicaRow2,matIndices2))), ...
            nanmedian(BASICDATA{numSDs3}.BASICDATA.CellTypeOverviewNonOthersInfected(numReplicaRow3,matIndices3) ./ (BASICDATA{numSDs3}.BASICDATA.CellTypeOverviewTotalNumber(numReplicaRow3,matIndices3) - BASICDATA{numSDs3}.BASICDATA.CellTypeOverviewOthersNumber(numReplicaRow3,matIndices3)))  ...
        ];
    
        % only get the raw corcoefs / iis once
        if matSDCombination == 1
            matRawAvgIIs(:,iPlate) = [ ...
                nanmedian(BASICDATA{numSDs1}.BASICDATA.InfectionIndex(numReplicaRow1,matIndices1)); ...
                nanmedian(BASICDATA{numSDs2}.BASICDATA.InfectionIndex(numReplicaRow2,matIndices2)); ...
                nanmedian(BASICDATA{numSDs3}.BASICDATA.InfectionIndex(numReplicaRow3,matIndices3))  ...
            ];

            intCorCoef1 = corrcoef(BASICDATA{numSDs1}.BASICDATA.ZScore(numReplicaRow1,matIndices1)', BASICDATA{numSDs2}.BASICDATA.ZScore(numReplicaRow2,matIndices2)','rows','complete');
            intCorCoef1 = intCorCoef1(1,2);                
            intCorCoef2 = corrcoef(BASICDATA{numSDs2}.BASICDATA.ZScore(numReplicaRow2,matIndices2)', BASICDATA{numSDs3}.BASICDATA.ZScore(numReplicaRow3,matIndices3)','rows','complete');
            intCorCoef2 = intCorCoef2(1,2);                
            intCorCoef3 = corrcoef(BASICDATA{numSDs2}.BASICDATA.ZScore(numReplicaRow2,matIndices2)', BASICDATA{numSDs3}.BASICDATA.ZScore(numReplicaRow3,matIndices3)','rows','complete');
            intCorCoef3 = intCorCoef3(1,2);
        
            matRawCorCoefs(:,iPlate) = [ intCorCoef1; intCorCoef2; intCorCoef3; ];        
            
            matPlateReplicaNumbers(:,iPlate) = matUniqueReplicas;
        end
    end

    % how to score which combination of cor.coefs is optimal
    matPlateResultScores = prod(matPlateResults,2);
    
    [A,I]=max(matPlateResultScores);
    if length(find(matPlateResultScores==A)) > 1
        disp(sprintf('  (multiple optimal solutions found for plate %d)',iPlate))
    end
    matOptimalCorCoefs(:,iPlate) = matPlateResults(I,:)';
    matOptimalStds(:,iPlate) = matAllPossibleCombinations(I,:)';
    matOptimalAvgIIs(:,iPlate) = matPlateAvgIIs(I,:)';    
    
end%iPlate


for i = 1:size(matPlateReplicaNumbers,2)
    for ii = 1:size(matPlateReplicaNumbers,1)
        numOptimalReplicaRow = find(BASICDATA{matOptimalStds(ii,i)}.BASICDATA.ReplicaNumber(:,1)==matPlateReplicaNumbers(ii,i) & BASICDATA{matOptimalStds(ii,i)}.BASICDATA.PlateNumber(:,1)==i);
        numTargetReplicaRow = find(BASICDATA_OPTIMIZED.ReplicaNumber(:,1)==matPlateReplicaNumbers(ii,i) & BASICDATA_OPTIMIZED.PlateNumber(:,1)==i);
        
        if ~(BASICDATA_OPTIMIZED.ReplicaNumber(numTargetReplicaRow,1)==BASICDATA{matOptimalStds(ii,i)}.BASICDATA.ReplicaNumber(numOptimalReplicaRow,1)) || ...
            ~(BASICDATA_OPTIMIZED.PlateNumber(numTargetReplicaRow,1)==BASICDATA{matOptimalStds(ii,i)}.BASICDATA.PlateNumber(numOptimalReplicaRow,1))
            error('aaargghhh')
        end
        
        BASICDATA_OPTIMIZED.CellTypeOverviewZScoreLog2NonOthersII(numTargetReplicaRow,:) = BASICDATA{matOptimalStds(ii,i)}.BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(numOptimalReplicaRow,:);
    end
end
BASICDATAORIG = BASICDATA;
BASICDATA = BASICDATA_OPTIMIZED;
save(fullfile(strRootPath,'BASICDATA_OPTIMIZED.mat'),'BASICDATA')
BASICDATA = BASICDATAORIG;



nanmedian(matOptimalCorCoefs(:))
nanmedian(matRawCorCoefs(:))

nanmedian(matRawAvgIIs(:))
nanmedian(matOptimalAvgIIs(:))

cellstrLabels = {};
for iPlate = matUniquePlateNums
    cellstrLabels = [cellstrLabels, {sprintf('%d',iPlate)}];
end

figure

subplot(4,3,1)
hold on
hist(matOptimalCorCoefs(:))
vline(nanmedian(matOptimalCorCoefs(:)),':r',sprintf('%.3f',nanmedian(matOptimalCorCoefs(:))))
vline(nanmedian(matRawCorCoefs(:)),':c')
set(gca,'fontsize',7)
title('Optimized cor.coefs: CellTypeOverviewZScoreLog2NonOthersII')
xlabel('cor.coefs')
ylabel('counts')
hold off

subplot(4,3,2)
hold on
hist(matOptimalStds(:),7)
set(gca,'xticklabel',matSDs)
vline(nanmean(matOptimalStds(:)),':r',sprintf('%.3f',nanmean(matOptimalStds(:))))
set(gca,'fontsize',7)
title('Optimized stdev settings: CellTypeOverviewZScoreLog2NonOthersII')
xlabel('cor.coefs')
ylabel('counts')
hold off

subplot(4,3,3)
hold on
hist(matOptimalAvgIIs(:))
vline(nanmean(matOptimalAvgIIs(:)),':r',sprintf('%.3f',nanmean(matOptimalAvgIIs(:))))
vline(nanmean(matRawAvgIIs(:)),':c')
set(gca,'fontsize',7)
title('Optimized avg plate IIs: CellTypeOverviewZScoreLog2NonOthersII')
xlabel('avg plate II')
ylabel('counts')
hold off

subplot(4,1,2)
hold on
boxplot(matRawCorCoefs,'colors','cccc')
boxplot(matOptimalCorCoefs,'labels',cellstrLabels)
ylim([0,1])
set(gca,'fontsize',7)
title('Optimized cor.coefs: CellTypeOverviewZScoreLog2NonOthersII per plate')
xlabel('Cell Plate number')
ylabel('cor. coefs')
hold off
drawnow

subplot(4,1,3)
hold on
boxplot(matOptimalStds,'labels',cellstrLabels)
ylim([1,7])
set(gca,'yticklabel',matSDs)
set(gca,'fontsize',7)
title('Optimized stdev settings: CellTypeOverviewZScoreLog2NonOthersII per plate')
xlabel('Cell Plate number')
ylabel('stdev setting')
hold off
drawnow

subplot(4,1,4)
hold on
boxplot(matRawAvgIIs,'colors','cccc')
boxplot(matOptimalAvgIIs,'labels',cellstrLabels)
% ylim([0,1])
set(gca,'fontsize',7)
title('Optimized plate infection levels: CellTypeOverviewZScoreLog2NonOthersII per plate')
xlabel('Cell Plate number')
ylabel('average plate infection index')
hold off
drawnow



% gcf2pdf(strRootPath,'BASICDATA_OptimizedPlateCorrelations')