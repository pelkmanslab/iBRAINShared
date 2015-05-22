clear all
close all

% strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\SV40_DG\';
%     strRootPath = '\\Nas-biol-imsb-1\share-3-$\Data\Users\HPV16_DG\';
    strRootPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\SFV_KY\';


% numSDs = 2000

% load(fullfile(strRootPath,sprintf('BASICDATA_%dSDs.mat',numSDs)))

load(fullfile(strRootPath,'BASICDATA.mat'))

% convert geneIDs to fully numerical matrix matGeneIDs
cellGeneIDs = BASICDATA.GeneID;
matNumericGeneIDs = ~cellfun(@isnumeric,cellGeneIDs);
cellGeneIDs(matNumericGeneIDs) = {0};
matGeneIDs = cell2mat(cellGeneIDs);

matUniquePlateNums = unique(BASICDATA.PlateNumber(:,1))';

matCorrs1 = [];
matCorrs2 = [];
matCorrs3 = [];

matPlateCorrelations = nan(9,size(matUniquePlateNums,2));
matPlateCorrelations2 = nan(9,size(matUniquePlateNums,2));
matPlateCorrelations3 = nan(9,size(matUniquePlateNums,2));

for iPlate = matUniquePlateNums

%     disp(sprintf('analyzing plate %d',iPlate))
    for iOligo = unique(BASICDATA.OligoNumber(BASICDATA.PlateNumber(:,1)==iPlate))'
        
%         disp(sprintf('analyzing oligo %d',iOligo))        
        matReplicaIndices = find(BASICDATA.PlateNumber(:,1)==iPlate & BASICDATA.OligoNumber(:,1)==iOligo);
        for i = matReplicaIndices'
            for ii = matReplicaIndices'
                if i > ii

                    % only look at those wells that had siRNAs targeting genes in them
                    matIndices = matGeneIDs(i,:) > 0;

                    matCorrs1 = [matCorrs1, corr(BASICDATA.ZScore(i,matIndices)',BASICDATA.ZScore(ii,matIndices)','rows','complete')]; %#ok<AGROW>
                    matCorrs2 = [matCorrs2, corr(BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(i,matIndices)',BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(ii,matIndices)','rows','complete')]; %#ok<AGROW>
                    matCorrs3 = [matCorrs3, corr(BASICDATA.Log2RelativeCellNumber(i,matIndices)',BASICDATA.Log2RelativeCellNumber(ii,matIndices)','rows','complete')]; %#ok<AGROW>

                    %%% store all correlations per plate in a matrix called
                    %%% matPlateCorrelations, where each column corresponds
                    %%% to the plate-number in the matching column of
                    %%% matUniquePlateNums
                    numPlateIndx = find(matUniquePlateNums==iPlate);
                    matCurPos = matPlateCorrelations(:,numPlateIndx);
                    matCurNaNIndx = find(isnan(matCurPos),1,'first');
                    
                    matPlateCorrelations(matCurNaNIndx,numPlateIndx) = corr(BASICDATA.ZScore(i,matIndices)',BASICDATA.ZScore(ii,matIndices)','rows','complete');
                    matPlateCorrelations2(matCurNaNIndx,numPlateIndx) = corr(BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(i,matIndices)',BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(ii,matIndices)','rows','complete');                    
                    matPlateCorrelations3(matCurNaNIndx,numPlateIndx) = corr(BASICDATA.Log2RelativeCellNumber(i,matIndices)',BASICDATA.Log2RelativeCellNumber(ii,matIndices)','rows','complete');                                        
                end
            end
        end
    end
end

figure()
subplot(4,4,1)
hold on
hist(matCorrs1)
vline(nanmedian(matCorrs1),':r',sprintf('%.2f',nanmedian(matCorrs1)))
set(gca,'fontsize',7)
xlim([0,1])
title('cor.coefs: ZScoreLog2RII')
xlabel('cor.coefs')
ylabel('counts')
hold off

subplot(4,4,2)
hold on
hist(matCorrs2)
vline(nanmedian(matCorrs2),':r',sprintf('%.2f',nanmedian(matCorrs2)))
set(gca,'fontsize',7)
xlim([0,1])
title('cor.coefs: CellTypeOverviewZScoreLog2NonOthersII')
xlabel('cor.coefs')
ylabel('counts')
hold off

subplot(4,4,3)
hold on
hist(matCorrs3)
xlim([0,1])
vline(nanmedian(matCorrs3),':r',sprintf('%.2f',nanmedian(matCorrs3)))
set(gca,'fontsize',7)
title('cor.coefs: Log2RelativeCellNumber')
xlabel('cor.coefs')
ylabel('counts')
hold off


matNOIIs = BASICDATA.CellTypeOverviewNonOthersInfected ./ (BASICDATA.CellTypeOverviewTotalNumber - BASICDATA.CellTypeOverviewOthersNumber);

nanmean(matNOIIs(:))

matNVC_IIs = log10(matNOIIs(BASICDATA.WellCol==1));
matNVC_IIs ( isnan(matNVC_IIs ) | isinf(matNVC_IIs ) ) = [];
%
matIIs = log10(matNOIIs(matGeneIDs>0));
matIIs ( isnan(matNVC_IIs ) | isinf(matNVC_IIs ) ) = [];
matIIs2 = matNOIIs(matGeneIDs>0);
%
subplot(4,4,4)
hold on
matEdges = [-4:.1:0];
[x1,y1]=histc(matNVC_IIs,matEdges);
[x2,y2]=histc(matIIs,matEdges);
plot(   matEdges,x1 / nanmax(x1),'g',...
        matEdges,x2 / nanmax(x2),'b')
vline(nanmedian(matNVC_IIs),':g',sprintf('%.2f',nanmedian(matNVC_IIs)))
vline(nanmedian(matIIs),':b',sprintf('%.2f (%.2f)',nanmedian(matIIs),nanmedian(matIIs2)))
set(gca,'fontsize',7)
title('Log10 Well NonOthers InfectionIndices')
xlabel('Log10 Infection Index')
ylabel('relative counts')
hold off




subplot(4,1,2)
cellstrLabels = {};
for i = matUniquePlateNums; cellstrLabels = [cellstrLabels, {sprintf('%d',i)}]; end %#ok<AGROW>
boxplot(matPlateCorrelations,'labels',cellstrLabels)
ylim([ 0 1])
set(gca,'fontsize',7)
title('cor.coefs: ZscoreLog2RII per plate')
% xlabel('Cell Plate number')
ylabel('cor. coefs')

subplot(4,1,3)
hold on
cellstrLabels = {};
for i = matUniquePlateNums; cellstrLabels = [cellstrLabels, {sprintf('%d',i)}]; end %#ok<AGROW>
boxplot(matPlateCorrelations2,'labels',cellstrLabels)
ylim([ 0 1])
set(gca,'fontsize',7)
title('cor.coefs: CellTypeOverviewZScoreLog2NonOthersII ')
% xlabel('Cell Plate number')
ylabel('cor. coefs')
hold off


subplot(4,1,4)
hold on
cellstrLabels = {};
for i = matUniquePlateNums; cellstrLabels = [cellstrLabels, {sprintf('%d',i)}]; end %#ok<AGROW>
boxplot(matPlateCorrelations3,'labels',cellstrLabels)
ylim([ 0 1])
set(gca,'fontsize',7)
title('cor.coefs: Log2RelativeCellNumber ')
% xlabel('Cell Plate number')
ylabel('cor. coefs')
hold off


drawnow

% nanmedian(matCorrs1)
% nanmedian(matCorrs2)

% gcf2pdf(strRootPath,sprintf('BASICDATA_PlateCorrelations_%dSDs',numSDs))

% gcf2pdf(strRootPath,'BASICDATA_PlateCorrelations','overwrite')
% close(gcf)