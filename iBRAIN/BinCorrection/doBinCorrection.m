function [matCompleteDataBinReadout,matBinEdges,matBinDimensions,matTensorII,matTensorTCN, matCompleteDataBinIndex, matIIPerBin, matTCNPerBin] = doBinCorrection(matCompleteData, strFinalFieldName, varargin)
%
% help for doBinCorrection
%
% Usage:
%
% [matCompleteDataBinReadout,matBinEdges,matBinDimensions,matTensorII,matTensorTCN, matCompleteDataBinIndex, matIIPerBin, matTCNPerBin] = doBinCorrection(matCompleteData, strFinalFieldName, varargin)
%
% [BS] Does the shizzle ultra fast. Mi nizzle extreme! That's what 3 years
% of PhD are for...
%
% Takes first column of matCompleteMetaData as readout of interest, and
% makes a multidimensional matrix from the remaining columns in
% matCompleteMetaData(:,2:end), using quantile binning, maximally 14 bins
% per dimension (less if bins have less than 14 unique discrete values)
%
% doBinCorrection(..., 'display') 
%
% To get some shnizzle figures feedback in the mix!
%
% doBinCorrection(..., matBinEdges) 
%
% if matBinEdges has the right dimensions (columns equals the number of
% data columns, and rows is less than or equal to the max number of bins),
% it will overwrite automaticcally generated binning. 
%
% doBinCorrection(..., @function_handle) 
%
% will run a different function handle per bin, where @mean is default.
%
% doBinCorrection(..., boolColumnVectorMatrix) 
%
% where boolColumnVectorMatrix has as many rows as matCompleteData, only 1
% column, and is logical, true values mean that cell is left out of the
% tensor, but will get a predicted value.


if nargin==0
%     strSettingsFile = npc('\\nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\ProbModel_Settings.txt');
%     strRootPath = npc('\\nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\VSV_CNX');

%     strRootPath = npc('\\nas-unizh-imsb1.ethz.ch\share-3-$\Data\Users\Prisca\endocytome\090928_A431_w2LAMP1_w3ChtxAW1');
%     strSettingsFile = npc('\\nas-unizh-imsb1.ethz.ch\share-3-$\Data\Users\Prisca\endocytome\Settings_Cells_MeanIntensity_RescaledGreen.txt');
%     [matCompleteData, strFinalFieldName] = getRawProbModelData2(strRootPath,strSettingsFile);
%     matCompleteData(:,[3,5,7]) = [];
%     strFinalFieldName([3,5,7]) = [];
    
    strRootPath = npc('Z:\Data\Users\SV40_DG\20080513073258_M2_ihaterobot_SV40_DG_CP009-1dg');
    strSettingsFile = npc('Z:\Data\Users\SV40_DG\load_sliding_window_SVMInfectionDG.txt');
    
    [matCompleteData, strFinalFieldName] = getRawProbModelData2(strRootPath,strSettingsFile);
    matCompleteData(:,3) = [];
    strFinalFieldName(3) = [];
end

% see if we should print stuff to stdout
boolSilent = any(cellfun(@(x) strcmpi(x,'silent'), varargin));

% Parameter for the maximum number of bins per features, can be user
% supplied.
boolUserSuppliedMaxBins = any(cellfun(@(x) isnumeric(x) & numel(x)==1, varargin));
if boolUserSuppliedMaxBins
    % get the max number of bins from the most likely candidate in varargin
    intMaxBins = varargin{cellfun(@(x) isnumeric(x) & numel(x)==1, varargin)};
    if ~boolSilent;fprintf('%s: Max number of edges determined by user: %d.\n',mfilename,intMaxBins);end
else
    % set max number of bins to default 12
    intMaxBins = 12;
end


% if varargin contains something that seriously looks like matBinEdges
% (same number of columns as matCompleteData, and very few rows, less than
% 24), user this instead of calculating your own
boolUserSuppliedBinEdges = any(cellfun(@(x) isnumeric(x) & size(x,2)==size(matCompleteData,2) & size(x,1)<=intMaxBins+1, varargin));

if boolUserSuppliedBinEdges
    % get the bin edges from the most likely candidata in varargin
    if ~boolSilent;fprintf('%s: Binning edges defined by user.\n',mfilename);end
    matBinEdges = varargin{cellfun(@(x) isnumeric(x) & size(x,2)==size(matCompleteData,2)  & size(x,1)<=intMaxBins+1, varargin)};
else
    % get quantile bin edges (i.e. quantile binning!)
    matBinEdges = quantile(matCompleteData,linspace(0,1,intMaxBins));
end

% check if the user supplied a different function handle to create the
% tensor with
boolUserSuppliedFunction = any(ismember(cellfun(@class,varargin,'UniformOutput',false),'function_handle'));
if boolUserSuppliedFunction
    strFunctionHandles = varargin{ismember(cellfun(@class,varargin,'UniformOutput',false),'function_handle')};
    if ~boolSilent;fprintf('%s: Running function ''%s'' per bin, as defined by user.\n',mfilename,char(strFunctionHandles));end
else
    strFunctionHandles = @nanmean;
end

% check if the user supplied a different function handle to create the
% tensor with
boolUserSuppliedTensorExclusionData = any(cellfun(@(x) islogical(x) & size(x,1)==size(matCompleteData,1) & size(x,2)==1, varargin));
if boolUserSuppliedTensorExclusionData
    matCompleteDataToExclude = varargin{cellfun(@(x) islogical(x) & size(x,1)==size(matCompleteData,1) & size(x,2)==1, varargin)};
    if ~boolSilent;fprintf('%s: User supplied exclusion criteria for keeping %d%% of cells out of the tensor.\n',mfilename,round(100*nanmean(matCompleteDataToExclude)));end
end


% check if we do experimental method
boolExperimentalMethod = any(cellfun(@(x) strcmpi(x,'doexperimental'), varargin));
if boolExperimentalMethod
    intMinBinSize = 3;
    fprintf('%s: User requested experimental method with minimal number of cells per bin %d%%.\n',mfilename,intMinBinSize)
end

% do binning, assuming first column is readout!
numFeatures = size(matCompleteData,2)-1;
matBinDimensions = NaN(1,numFeatures);
matCompleteDataBinIX = NaN(size(matCompleteData,1),numFeatures);
for iFeature = 1:numFeatures
    
    % do binning. taking unique bin edges solves binary/non-binary readout
    % issue as well as bins with discrete [1,2,3...] numbers that are fewer
    % than the number of bins suggested :)
    matBinEdgesPerColumn = unique(matBinEdges(:,iFeature+1));
    [foo,matCompleteDataBinIX(:,iFeature)] = histc(matCompleteData(:,iFeature+1), matBinEdgesPerColumn);
    clear foo

    % Store the multidimensional matrix dimensions for current column
    matBinDimensions(iFeature) = length(matBinEdgesPerColumn);
    
end



% since unique-rows is slower than getting sub-indices for each bin and
% unqiue on those, let's do this.
if size(matCompleteDataBinIX,2)==1
    % note that if there is only one explaining param, the index equals the
    % sub-index.
    matSubIndices = matCompleteDataBinIX;
else
    matSubIndices = sub2ind2(matBinDimensions,matCompleteDataBinIX);
end

% sort completedata, completemetadata, binindices, and subindices so that
% subindices are sorted from lowest to highest values
[matSubIndices,matSortIX] = sort(matSubIndices);
% matCompleteDataBinIX=matCompleteDataBinIX(matSortIX,:);
% matCompleteMetaData=matCompleteMetaData(matSortIX,:);
matCompleteData=matCompleteData(matSortIX,:);
if boolUserSuppliedTensorExclusionData
    matCompleteDataToExclude=matCompleteDataToExclude(matSortIX,:);
end

% now get the unique values of the sorted subindices, and return the 'last'
% of each occuring unique subindex. this means we can then stepwise loop
% over all unique subindices and batch-wise calculate the readout values
% without ever having to do a 'find' command! sweet fastness.
[matUniqueBinSubIndices, matBinIX1, matBinIX2] = unique(matSubIndices,'last');

% loop over the each bin-value, and batch-wise calculate the corresponding
% readout of all cells belonging to that bin (i.e. mean infection index,
% and total cell number per bin)

% first check if the user already (perhaps) supplied a tensor for
% correction...
boolUserSuppliedTensor = any(cellfun(@(x) isnumeric(x) & isequal(size(x),size(matUniqueBinSubIndices)),varargin));
if boolUserSuppliedTensor
    matIIPerBin = varargin{cellfun(@(x) isnumeric(x) & isequal(size(x),size(matUniqueBinSubIndices)),varargin)};
    if ~boolSilent;fprintf('%s: Correcting using user supplied tensor.\n',mfilename,char(strFunctionHandles));end
else
    % otherwise, initialize
    matIIPerBin = NaN(size(matUniqueBinSubIndices));
end

matTCNPerBin = NaN(size(matUniqueBinSubIndices));
matPreviousIX = 1;
% disp('BS:WARNING: USING HARDCODED QUICK HACK MINIMAL BIN SIZE = 4')
for iBin = 1:size(matUniqueBinSubIndices,1)
    matCurrentIX = (matPreviousIX:matBinIX1(iBin));
    
    % if user supplied criteria to keep data out of the tensor, kick it out
    % here...
    if boolUserSuppliedTensorExclusionData
        matCurrentIX(matCompleteDataToExclude(matCurrentIX)) = [];
    end
    
    % if user requested a different function to be run...
%     if numel(matCurrentIX) > 3
    if ~boolUserSuppliedTensor
        if boolUserSuppliedFunction
            matIIPerBin(iBin) = strFunctionHandles(matCompleteData(matCurrentIX,1));
        else
            matIIPerBin(iBin) = mean(matCompleteData(matCurrentIX,1));
        end
    end
%     else
%         matIIPerBin(iBin) = NaN;
%     end
    
    matTCNPerBin(iBin) = length(matCurrentIX);
    matPreviousIX = matBinIX1(iBin)+1;
end



%%%%%%%%%%
% experimental method
if boolExperimentalMethod
    % find bins with too few cells
    matTooFewIX = matTCNPerBin<intMinBinSize;

    fprintf('%s: NOTE, STARTING EXPERIMENTAL PROCEDURE..\n',mfilename)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% THIS DOES NOT ACTUALLY INCREASE THE R-SQUARED MUCH %%%
    % we could inherit predictions for bins with too few cells from nearest
    % neighboring bins (in pop context space) with enough cells, rather
    % than to the mean. We can judge by the r-squared if this improves or
    % decreases model fit.
    matSubIndicesPerBin = ind2sub2(matBinDimensions,matUniqueBinSubIndices);
    matMaxBinIX = matBinDimensions;
    intMaxSearchStep = 4;
    % prepare search space steps
    cellSearchSpace = cell(1,intMaxSearchStep);
    cellSearchSteps = cell(1,intMaxSearchStep); 
    for iSteps = 1:intMaxSearchStep
        matSearchSpace = all_possible_combinations2((iSteps+1)*ones(1,size(matBinDimensions,2)))-1;
        cellSearchSpace{iSteps} = unique([matSearchSpace;-matSearchSpace],'rows');    
        % weighted step-sizes to make single-steps in binary params weigh
        % heavier than 1?
        matStepWeights = repmat(((max(matMaxBinIX)-matMaxBinIX)/2)+1,[size(cellSearchSpace{iSteps},1),1]);
        % step size is a function of weighted difference
        cellSearchSteps{iSteps} = sum(abs(cellSearchSpace{iSteps}.*matStepWeights),2);
    end


    for iBin = find(matTooFewIX)'
        % increment search step if no bin is found..
        intSearchStep = 1;
        while true
            matSearchSpace = cellSearchSpace{intSearchStep};
            matSearchSteps = cellSearchSteps{intSearchStep};
            matSearchSpaceIX = repmat(matSubIndicesPerBin(iBin,:),[size(matSearchSpace,1),1]) + matSearchSpace;
            % limit search space to present indices (necessary? perhaps not as
            % there is anyway no data available for these indices..) 
            matSearchSpaceIX(matSearchSpaceIX<1) = 1;
            matMax = repmat(matMaxBinIX,[size(matSearchSpace,1),1]);
            matSearchSpaceIX(matSearchSpaceIX>matMax) = matMax(matSearchSpaceIX>matMax);
            % convert search space to indices
            if numel(matMaxBinIX)>1
                matSearchSubIndices = sub2ind2(matMaxBinIX, matSearchSpaceIX);
            else
                matSearchSubIndices = matSearchSpaceIX;
            end
            % find corresponding cell numbers
            [b,a] = ismember(matSearchSubIndices,matUniqueBinSubIndices);
            % store preliminary candidate TCN and MEAN values
            matPresentSearchIndicesTCN = zeros(size(matSearchSubIndices));
            matPresentSearchIndicesMEAN = zeros(size(matSearchSubIndices));
            matPresentSearchIndicesTCN(b) = matTCNPerBin(a(b));
            matPresentSearchIndicesMEAN(b) = matIIPerBin(a(b));
            matAnyOkTCNsIX = matPresentSearchIndicesTCN >= (intMinBinSize*4);
            if any(matAnyOkTCNsIX);
                % find data with smallest step-difference and biggest cell
                % number
                matPotentialOkIX = find(matSearchSteps == min(matSearchSteps(matAnyOkTCNsIX)) & matAnyOkTCNsIX);
                [~,maxIX] = max(matPresentSearchIndicesTCN(matPotentialOkIX));
                % fprintf('%.3f = %.3f\n',matIIPerBin(iBin),matPresentSearchIndicesMEAN(matPotentialOkIX(maxIX)))
                % weighted mean, including current datapoints?
                matIIPerBin(iBin) = ((matIIPerBin(iBin) * matTCNPerBin(iBin)) + (matPresentSearchIndicesMEAN(matPotentialOkIX(maxIX)) * matPresentSearchIndicesTCN(matPotentialOkIX(maxIX)))) / ((matPresentSearchIndicesTCN(matPotentialOkIX(maxIX)) + matTCNPerBin(iBin)));
                % or just inherit more common phenotype
                % matIIPerBin(iBin) = matPresentSearchIndicesMEAN(matPotentialOkIX(maxIX));

                % experimental, if we set the TCN to inherit the bin
                % number as well, this means we increase the number of
                % viable bins from which to inherit datapoints...
                % matTCNPerBin(iBin) = matPresentSearchIndicesTCN(matPotentialOkIX(maxIX));

                % or set TCN to minimal acceptable value, to give real
                % estimates a better shot.
                matTCNPerBin(iBin) = (intMinBinSize*4);
                disp('fixed a bin...')
                break
            else
                if intSearchStep>=intMaxSearchStep
                    % fprintf('NOT FOUND NEAREST BIG-ENOUGH NEIGHBOUR IN %d STEPS\n',intSearchStep)
                    matIIPerBin(iBin) = matMeanReadout;
                    break
                end
                intSearchStep = intSearchStep + 1;
                disp('no neighbor bin with enough cells found...')
            end
        end
        %fprintf('found nearest big enough neighbor bin in %d steps\n',intSearchStep)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




% % calculate the subindices per bin back to original indices per feature.
% matUniqueBinIX = ind2sub2(matBinDimensions,matUniqueBinSubIndices);
% 
% % calculate the subindices per cell back to original indices per feature.
% matCompleteBinIX = ind2sub2(matBinDimensions,matBinIX2);


% % If user supplied matIIPerBin already as input, use this for correction,
% % otherwise, use the one made in this run with the current data
% matHasGoodMatchFormatIIPerBin = cellfun(@(x) all(size(x)==size(matIIPerBin)),varargin);
% if any(matHasGoodMatchFormatIIPerBin)
%     fprintf('%s: using user-supplied tensor model\n',mfilename)
%     matIIPerBinFromUser = varargin{matHasGoodMatchFormatIIPerBin};
%     % make readout per single cell of bin-expected value, from user
%     % supplied i.i. tensor model.
%     
%     % init as NaNs to have values outside user supplied bin range
%     matCompleteDataBinReadout = NaN(size(matBinIX2));
%     % put expected infection indices in place.
%     matCompleteDataBinReadout(~isnan(matBinIX2)) = matIIPerBinFromUser(matBinIX2);
%     
% else
%     % make readout per single cell of bin-expected value
    matCompleteDataBinReadout = matIIPerBin(matBinIX2);
% end


% shuffle matCompleteData and back to original sorting
matOrigSortingIX = 1:size(matCompleteData,1);
matOrigSortingIX = matOrigSortingIX(matSortIX);
[foo,matOrigSortingIX] = sort(matOrigSortingIX);

clear foo
% (is there another way to sort back from original sorting?)
matCompleteDataBinReadout = matCompleteDataBinReadout(matOrigSortingIX,:);
matCompleteDataBinIndex = matUniqueBinSubIndices(matBinIX2(matOrigSortingIX,:));

% if it's requested, also return actual tensors with IIs and TCNs
if nargout>3
    % to actually make this a multidimensional matrix (tensor), do this:
    matTensorII = NaN(matBinDimensions);
    matTensorTCN = NaN(matBinDimensions);
    matTensorII(matUniqueBinSubIndices) = matIIPerBin;
    matTensorTCN(matUniqueBinSubIndices) = matTCNPerBin;
end


% if the user wants some standard figures to be displayed...
if any(cellfun(@(x) strcmpi(x,'display'),varargin))% || nargin == 0
    
    try

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Visualization gimmicks! %%%


        % plot the sorted prediction against local average of input. note that
        % we still need to sort back matCompleteData
        figure()
        subplot(2,2,1)
        plotmean(matCompleteDataBinReadout,matCompleteData(matOrigSortingIX,1));
        xlabel('bin-predicted output')
        ylabel('local average of input')

        % it's good to check the distribution of number of cells per bin, so let's
        % plot the (y=) number of cells per bin greater than x, where (x=) all
        % unique bin sizes.
        matUniqueTCN = unique(matTCNPerBin)';
        matCumSumTCN = NaN(size(matUniqueTCN));
        for i = 1:length(matUniqueTCN)
            matCumSumTCN(i) = sum(matTCNPerBin(matTCNPerBin>=matUniqueTCN(i)));
        end
        matCumSumTCN = 100*(matCumSumTCN/sum(matTCNPerBin));

        % plot bin size against cumulative #-cells for all bins bigger than x.
        subplot(2,2,2)
        plot(matUniqueTCN,matCumSumTCN)
        ylabel('cumulative % of total cells in bins bigger than x')
        xlabel('bin size threshold')
        title(sprintf('95%% of all cells is present in a bin bigger than %d cells.\n%.0f%% of all cells is present in a bin bigger than 20 cells.',matUniqueTCN(find(matCumSumTCN>=95,1,'last')),matCumSumTCN(find(matUniqueTCN>=20,1,'first'))))

        % to actually make this a multidimensional matrix (tensor), do this:
        matTensorII = NaN(matBinDimensions);
        matTensorTCN = NaN(matBinDimensions);
        matTensorII(matUniqueBinSubIndices) = matIIPerBin;
        matTensorTCN(matUniqueBinSubIndices) = matTCNPerBin;
        matTensorTCN(isnan(matTensorTCN)) = 0;
        
% % %         % multidimensional weighted smoothing for a lowess type of non-parametric
% % %         % fit, which corrects for noise from small bin sizes.
% % %         warning('BS:Bla','[BS] smoothing tensors for display purposes!')
% % %         matTensorII = smoothn(matTensorII,matTensorTCN,0.15);
% % %         matTensorTCN = smoothn(matTensorTCN,0.15);

        matMedianIndices = round(matBinDimensions/2);
%         matSurfSmooth = squeeze(matSmoothTensorII(:,matMedianIndices(2), :,matMedianIndices(4),matMedianIndices(5),matMedianIndices(6)));
        
        [matDimToPlotSizes,matDimToPlotIX] = sort(matBinDimensions,'descend');
        
        matSurfII = NaN(matDimToPlotSizes(1,2));
        matSurfTCN = NaN(matDimToPlotSizes(1,2));
        for iDim1 = 1:matDimToPlotSizes(1)
            for iDim2 = 1:matDimToPlotSizes(2)
                
                matCurrentIndices = matMedianIndices;
                matCurrentIndices(matDimToPlotIX(1)) = iDim1;
                matCurrentIndices(matDimToPlotIX(2)) = iDim2;
                matSurfII(iDim1,iDim2) = matTensorII(sub2ind2(matBinDimensions,matCurrentIndices));
                matSurfTCN(iDim1,iDim2) = matTensorTCN(sub2ind2(matBinDimensions,matCurrentIndices));
                
                matSurfX(iDim1,iDim2) = iDim2;
                matSurfY(iDim1,iDim2) = iDim1;
            end
        end

        % i don't quite trust squeeze...
%         matSurfII = squeeze(matTensorII(:,matMedianIndices(2), :,matMedianIndices(4),matMedianIndices(5),matMedianIndices(6)));
%         matSurfTCN = squeeze(matTensorTCN(:,matMedianIndices(2), :,matMedianIndices(4),matMedianIndices(5),matMedianIndices(6)));
        matSurfII(matSurfTCN<20) = NaN;
        matSurfTCN(matSurfTCN<20) = NaN;

        matBadCols = all(isnan(matSurfTCN),1);
        matBadRows = all(isnan(matSurfTCN),2);
        
        matSurfX(:,matBadCols) = [];
        matSurfY(:,matBadCols) = [];
        matSurfII(:,matBadCols) = [];
        matSurfTCN(:,matBadCols) = [];

        matSurfX(matBadRows,:) = [];
        matSurfY(matBadRows,:) = [];
        matSurfII(matBadRows,:) = [];
        matSurfTCN(matBadRows,:) = [];
        
        subplot(2,2,3)

%         figure()
        hold on
    %     matSurfX = fliplr(flipud(matSurfX));
    %     matSurfY = flipud(matSurfY);
    %     scatter3(matSurfX(~isnan(matSurf)),matSurfY(~isnan(matSurf)),matSurf(~isnan(matSurf)),'ok','filled')

        % make smooth colormap
        matColorMap = colormap(jet);
        matColorMap = imresize(matColorMap,[16000,3],'lanczos2');
        matColorMap(matColorMap>1)=1;
        matColorMap(matColorMap<0)=0;
        colormap(matColorMap)

        surf(matSurfX,matSurfY,matSurfII,'linewidth',1,'FaceColor','interp','EdgeColor','none')% , 'FaceLighting','phong'
        axis tight
        grid on
        % camlight right
        xlabel(strFinalFieldName(matDimToPlotIX(2)+1))% +1 because first column skipped
        ylabel(strFinalFieldName(matDimToPlotIX(1)+1))
        zlabel(strFinalFieldName(1))
        view(40, 50);
        hold off

        subplot(2,2,4)
%         figure()
        hold on

        surf(matSurfX,matSurfY,matSurfTCN,'linewidth',1,'FaceColor','interp','EdgeColor','none')% , 'FaceLighting','phong'
        axis tight
        grid on
        % camlight right
        xlabel(strFinalFieldName(matDimToPlotIX(2)+1))% +1 because first column skipped
        ylabel(strFinalFieldName(matDimToPlotIX(1)+1))
        zlabel('Total cell number')
        view(40, 50);
        hold off
        
    catch lastErr
        
        lastErr.message
        lastErr.identifier
        if ~boolSilent;fprintf('%s: drawing stuff crashed\n',mfilename);end
        
    end

end

end