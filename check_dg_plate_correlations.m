function check_dg_plate_correlations(strRootPath)

if nargin==0
    % load('\\Nas-biol-imsb-1\share-2-$\Data\Users\YF_DG\BASICDATA_lowess.mat')
%     strRootPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\DV_KY\';
    strRootPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\HPV16_DG\';
    % load('\\Nas-biol-imsb-1\share-2-$\Data\Users\DG_screen_Salmonella\BASICDATA.mat')
    % load('\\Nas-biol-imsb-1\share-2-$\Data\Users\FLU_DG1\BASICDATA.mat')
    % load('\\Nas-biol-imsb-1\share-3-$\Data\Users\HPV16_DG\BASICDATA.mat')
end

load(fullfile(strRootPath,'BASICDATA.mat'))

% convert geneIDs to fully numerical matrix matGeneIDs
cellGeneIDs = BASICDATA.GeneID;
matNumericGeneIDs = cellfun(@isnumeric,cellGeneIDs) & ~cellfun(@isempty,cellGeneIDs);
cellGeneIDs(~matNumericGeneIDs) = {0};
matGeneIDs = cell2mat(cellGeneIDs);

% get list of available plate numbers
matUniquePlateNums = unique(BASICDATA.PlateNumber(:,1))';


% idea: make a dynamic list of fields-of-interest, to include also model
% corrected values and infection-optimized-values if present. basics
% should include zscore and zscorelog2rcn
cellstrListOfDesiredFields = {'ZScore','Log2RelativeCellNumber','OptimizedInfectionZscoreLog2RIIPerWell'};
matPresentFields=ismember(cellstrListOfDesiredFields,fieldnames(BASICDATA));
cellstrListOfPresentFields = cellstrListOfDesiredFields(matPresentFields);

% init dynamic output
cellCorrs = cell(1,length(cellstrListOfPresentFields));
cellPlateCorrelations = cell(1,length(cellstrListOfPresentFields));
for i = 1:length(cellstrListOfPresentFields)
    cellPlateCorrelations{i} = nan(9,size(matUniquePlateNums,2));
end

for iPlate = matUniquePlateNums

%     disp(sprintf('analyzing plate %d',iPlate))
    for iOligo = unique(BASICDATA.OligoNumber(BASICDATA.PlateNumber(:,1)==iPlate))'
        
%         disp(sprintf('analyzing oligo %d',iOligo))        
        matReplicaIndices = find(BASICDATA.PlateNumber(:,1)==iPlate & BASICDATA.OligoNumber(:,1)==iOligo);
        for i = matReplicaIndices'
            for ii = matReplicaIndices'
                if i > ii
                    
%                     matIndices = BASICDATA.WellCol(i,:) > 2 & BASICDATA.WellCol(i,:) < 22;
                    matIndices1 = matGeneIDs(i,:) > 0;
                    matIndices2 = matGeneIDs(ii,:) > 0;
                    
                    if ~isequal(matGeneIDs(i,:),matGeneIDs(ii,:))
                        warning('%s: plates %d and %d do not have the same plate layouts')
                        BASICDATA.PlateNumber(i,1)
                        BASICDATA.PlateNumber(ii,1)
                    end
                    
                    %%% store all correlations per plate in a matrix called
                    %%% matPlateCorrelations, where each column corresponds
                    %%% to the plate-number in the matching column of
                    %%% matUniquePlateNums
                    
%                     disp(sprintf('replica %d versus %d',i,ii))                            
                    for iField = 1:length(cellstrListOfPresentFields)
                        cellCorrs{iField} = [cellCorrs{iField}, corr(BASICDATA.(cellstrListOfPresentFields{iField})(i,matIndices1)',BASICDATA.(cellstrListOfPresentFields{iField})(ii,matIndices2)','rows','pairwise')];

                        numPlateIndx = find(matUniquePlateNums==iPlate);
                        matCurPos = cellPlateCorrelations{iField}(:,numPlateIndx);
                        matCurNaNIndx = find(isnan(matCurPos),1,'first');                        

                        cellPlateCorrelations{iField}(matCurNaNIndx,numPlateIndx) = corr(BASICDATA.(cellstrListOfPresentFields{iField})(i,matIndices1)',BASICDATA.(cellstrListOfPresentFields{iField})(ii,matIndices2)','rows','pairwise');
                    end
                    
%                     matCorrs2 = [matCorrs2, corr(BASICDATA.Log2RelativeCellNumber(i,matIndices)',BASICDATA.Log2RelativeCellNumber(ii,matIndices)','rows','complete')];
%                     matPlateCorrelations(matCurNaNIndx,numPlateIndx) = corr(BASICDATA.ZScore(i,matIndices)',BASICDATA.ZScore(ii,matIndices)','rows','complete');

                end
            end
        end
    end
end



figure()

for iField = 1:length(cellstrListOfPresentFields)
    subplot(length(cellstrListOfPresentFields)+1,length(cellstrListOfPresentFields),iField)
    hold on
    hist(cellCorrs{iField})
    vline(nanmedian(cellCorrs{iField}),'-g',sprintf('%.2f',nanmedian(cellCorrs{iField})))
    set(gca,'fontsize',8)
    title(sprintf('cor.coefs: %s',cellstrListOfPresentFields{iField}))
    xlabel('cor.coefs')
    ylabel('counts')
    vline(0.5,':r')
    hold off
    
    
    subplot(length(cellstrListOfPresentFields)+1,1,iField+1)
    cellstrLabels = {};
    for i = matUniquePlateNums; cellstrLabels = [cellstrLabels, {sprintf('%d',i)}]; end %#ok<AGROW>
    hold on
    boxplot(cellPlateCorrelations{iField},'labels',cellstrLabels)
    set(gca,'fontsize',8)
    title(sprintf('cor.coefs: %s per plate',cellstrListOfPresentFields{iField}))
    xlabel('Cell Plate number')
    ylabel('cor. coefs')    
    hline(0.5,':r')
    hold off
    drawnow
end

% subplot(2,2,2)
% hold on
% hist(matCorrs2)
% vline(nanmedian(matCorrs2),':r',sprintf('%.2f',nanmedian(matCorrs2)))
% set(gca,'fontsize',8)
% title('cor.coefs: Log2RelativeCellNumber')
% xlabel('cor.coefs')
% ylabel('counts')
% hold off
% 
% subplot(2,2,3:4)
% cellstrLabels = {};
% for i = matUniquePlateNums; cellstrLabels = [cellstrLabels, {sprintf('%d',i)}]; end %#ok<AGROW>
% boxplot(matPlateCorrelations,'labels',cellstrLabels)
% set(gca,'fontsize',8)
% title('cor.coefs: ZscoreLog2RII per plate')
% xlabel('Cell Plate number')
% ylabel('cor. coefs')

drawnow

% add the overwrite parameter to overwrite the old
% BASICDATA_PlateCorrelations.pdf file
gcf2pdf(strRootPath,'BASICDATA_PlateCorrelations','overwrite')
close(gcf)
