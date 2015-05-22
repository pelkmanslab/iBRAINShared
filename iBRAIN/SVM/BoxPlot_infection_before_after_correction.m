% beginning of script: load data, parse to access more easily, prepare
% clustering 

clear all
% close all

% input parameters:
strRootPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\';
% strRootPath = 'C:\Documents and Settings\imsb\Desktop\';
% strDataFieldname = 'Log2RelativeCellNumber';
% strDataFieldname = 'Log2RelativeInfectionIndex';
% strDataFieldname = 'OptimizedInfectionZscoreLog2RIIPerWell';
strDataFieldname = 'ModelCorrectedZSCORELOG2RII'

matGeneIDsToExclude = [9077];%i.e. PLK1
% cellProjectsToExclude = {'SV40_MZ','HIV_MZ_2','DV_KY2','DV_KY','DV_MZ'};
% cellProjectsToExclude = {'SV40_MZ','DV_KY2','DV_KY','DV_MZ'};
% cellProjectsToExclude = {'VSV_KY','VSV_MZ','SV40_MZ','SV40_MZ_NEW','SV40_CNX','SV40_TDS','DV_KY2','DV_KY','DV_MZ'};
% cellProjectsToExclude = {'SV40_MZ','SV40_MZ_NEW'};
cellProjectsToExclude = {'SV40_MZ_NEW'};
% cellProjectsToExclude = {'DV_KY2','DV_KY','DV_MZ'};
% cellProjectsToExclude = {'DV_KY2','DV_KY','DV_MZ','SV40_MZ','SV40_MZ_NEW'};
% cellProjectsToExclude = {};

% load data
%load(fullfile(strRootPath,'BASICDATA.mat'));
figure   
for method=1:4
    clear BASICDATA
    if method==1
        load('Z:\Data\Users\50K_final_reanalysis\BASICDATA_CorrectedPerPlate_tensor.mat')
        strDataFieldname = 'ModelRawZSCORELOG2RII'
    elseif method==2
        load('Z:\Data\Users\50K_final_reanalysis\BASICDATA_CorrectedPerPlate_tensor.mat')
        strDataFieldname = 'ModelCorrectedZSCORELOG2RII'
    elseif method==3
        load('Z:\Data\Users\50K_final_reanalysis\BASICDATA_CorrectedPerAssay_tensor.mat')
        strDataFieldname = 'ModelCorrectedZSCORELOG2RII'
    elseif method==4
        load('Z:\Data\Users\50K_final_reanalysis\BASICDATA_CorrectedPerAssay_tensor.mat')
        strDataFieldname = 'Log2RelativeCellNumber'
    end
    disp(sprintf('%s: loaded basicdata',mfilename))

    % parse plate and project names of all entries
    cellPlateNames = getplatenames(BASICDATA.Path);
    cellProjectNames = getprojectnames(BASICDATA.Path);
    cellUniqueProjectNames = unique(cellProjectNames);
    disp(sprintf('%s: detected %d plates in %d projects (before discarding)',mfilename,length(unique(cellPlateNames)),length(cellUniqueProjectNames)))

    % remove all projects from the 'to exclude' list from the entire BASICDATA
    cellFieldNames = fieldnames(BASICDATA);
    matProjectToExcludeIndices = ismember(cellProjectNames,cellProjectsToExclude);
    for i = cellProjectsToExclude
        if find(strcmpi(cellProjectNames,i))
            disp(sprintf('%s: +-- discarding project %s',mfilename,char(i)))
        end
    end
    for iField = cellFieldNames'
        BASICDATA.(char(iField))(matProjectToExcludeIndices,:) = [];
    end

    % parse plate and project names of all entries
    cellPlateNames = getplatenames(BASICDATA.Path);
    cellProjectNames = getprojectnames(BASICDATA.Path);
    cellUniqueProjectNames = unique(cellProjectNames);
    disp(sprintf('%s: detected %d plates in %d projects (after discarding)',mfilename,length(unique(cellPlateNames)),length(cellUniqueProjectNames)))


    % get GeneIDs in matrix format for easier indexing
    matGeneIDs = BASICDATA.GeneID;
    matEmptyGeneIDIndices = cellfun(@isempty,matGeneIDs);
    matGeneIDs(matEmptyGeneIDIndices) = {NaN};
    matGeneIDs = cell2mat(matGeneIDs);

    % check GeneIDs present
    matAllEmptyWells = all(isnan(matGeneIDs),1);
    matAllEmptyPlates = all(isnan(matGeneIDs),2);
    matSelectedGeneIDs = matGeneIDs(:,~matAllEmptyWells);
    matSelectedGeneIDs = matSelectedGeneIDs(~matAllEmptyPlates,:);
    matPlateLayout = unique(matSelectedGeneIDs,'rows');

    matPlateLayout(ismember(matPlateLayout,matGeneIDsToExclude))=[];
    disp(sprintf('%s: detected %d genes (excluding %d genes)',mfilename,length(matPlateLayout),length(matGeneIDsToExclude)))

    % indices of wells to include in data
    matOkWellIndices = ismember(matGeneIDs(1,:),matPlateLayout);

    % get data for clustering
    matData = BASICDATA.(strDataFieldname)(:,matOkWellIndices);

    cellProjectOligoData = cell(length(cellUniqueProjectNames),3);% assuming 3 oligos!

    % create matrix of data for clustering (per project)
    for iProject = 1:length(cellUniqueProjectNames)

        % indices of wors belonging to current project
        a1=ismember(cellProjectNames,cellUniqueProjectNames{iProject});

        % current project data
        matProjectData = matData(a1,:);
        matProjectOligoNumbers = BASICDATA.OligoNumber(a1,matOkWellIndices);

        % get plates belonging to current project
        for iOligo = unique(matProjectOligoNumbers(:,1))'
            % get plates belonging to current oligo
            a2=ismember(matProjectOligoNumbers(:,1),iOligo);
            cellProjectOligoData{iProject,iOligo} = nanmedian(matProjectData(a2,:),1);
        end

        % check for missing oligo data and fill with NaNs
        matEmptyOligos = cellfun(@isempty,cellProjectOligoData(iProject,:));
        cellProjectOligoData(iProject,matEmptyOligos) = {NaN(1,length(matPlateLayout))};
    end

    % get data for clustering
    data4bootstrap = cell2mat(cellProjectOligoData);
    datalabels4bootstrap = cellUniqueProjectNames;
    % discard nans and infs, set these to 0
    data4bootstrap(isinf(data4bootstrap) | isnan(data4bootstrap))=0;

    % redo zscoring after discarding of genes, nans and infs...
    data4bootstrap = zscore(data4bootstrap,1,2);

    % get the gene labels
    genelabels = BASICDATA.GeneData(1,matOkWellIndices);
    genelabels = [strcat(genelabels,'_1'),strcat(genelabels,'_2'),strcat(genelabels,'_3')];

  
   
    for assay=1:length(datalabels4bootstrap)
        subplot(6,6,assay)
        hold on;
        title(strrep(datalabels4bootstrap{assay},'_',' '));


        data(1,:)=data4bootstrap(assay,1:49);
        data(2,:)=data4bootstrap(assay,50:98);
        data(3,:)=data4bootstrap(assay,99:147);

        foo=corr(data');

        plot(method,foo(1,2),'r.');
        plot(method,foo(1,3),'g.');
        plot(method,foo(2,3),'b.');
        axis([0.5 4.5 -1 1]);
    end
end
















