function Convert_BASICDATA_to_csv(strRootPath)

    if nargin==0
        strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\YF_DG\';
%         strRootPath = '\\Nas-biol-imsb-1\shclear are-2-$\Data\Users\VSV_DG\';
%         strRootPath = 'Z:\DG_screen_Salmonella\';
    end

    load(fullfile(strRootPath,'BASICDATA.mat'));
    
    filename = fullfile(strRootPath,sprintf('BASICDATA_%s.csv',getlastdir(strRootPath)));

%     cellstrFieldnames = fieldnames(BASICDATA);
    
    header = ...
        { 'Path',... 1
        'Plate',... 2
        'Batch',... 3
        'Replica',... 4
        'Total_Genes',... 5
        'Median_TotalCells',... 6
        'Median_InfectionIndex',... 7
        'OOF-%',... 8
        'Total Images',... 9
        'Total_Discarded',... 10
        'Median_Discarded_Index',... 11
        'Total_Interphase',... 12
        'Total_Mitotic',... 13
        'Median_Mitotic_Index',... 14
        'Total_Apoptotic',... 15
        'Median_Apoptotic_Index',... 16
        'Total_Others',... 17
        'Median_Others_Index',... 18
        'Median_OptimizedInfection_Index'... 19
        'Median_InfectionSVM_Index'... 20
        };

    
    data = cell(size(BASICDATA.Path,1),size(header,2));        
    
    for i = 1:size(BASICDATA.Path,1)
        matPlateOKIndices = (BASICDATA.Images(i,:) > 0);
        matPlateGeneIndices = ~cellfun(@isempty,BASICDATA.GeneID(i,:));
        if ~isempty(find(matPlateGeneIndices))
            matPlateOKIndices = logical(matPlateGeneIndices & matPlateGeneIndices);
        end
        
        data{i,1} = getlastdir(strrep(BASICDATA.Path{i},'/BATCH',''));
        data{i,2} = BASICDATA.PlateNumber(i,1);        
        data{i,3} = BASICDATA.BatchNumber(i,1);
        data{i,4} = BASICDATA.ReplicaNumber(i,1);
        data{i,5} = nansum(matPlateGeneIndices);
        data{i,6} = sprintf('%.0f',nanmedian(BASICDATA.TotalCells(i,matPlateOKIndices)));
        data{i,7} = sprintf('%.3f',nanmedian(BASICDATA.InfectionIndex(i,matPlateOKIndices)));
        try
            data{i,8} = sprintf('%.0f',100*(1 - (sum(BASICDATA.Images(i,matPlateOKIndices)) / sum(BASICDATA.RawImages(i,matPlateOKIndices)))));
            data{i,9} = sprintf('%.0f',(sum(BASICDATA.RawImages(i,matPlateOKIndices))));
        end
        try
            data{i,10} = sprintf('%.0f',nansum(BASICDATA.CellTypeOverviewOthersNumber(i,matPlateOKIndices)));
            data{i,11} = sprintf('%.3f',nanmedian(BASICDATA.CellTypeOverviewOthersIndex(i,matPlateOKIndices)));
            data{i,12} = sprintf('%.0f',nansum(BASICDATA.CellTypeOverviewInterphaseNumber(i,matPlateOKIndices)));
            data{i,13} = sprintf('%.0f',nansum(BASICDATA.CellTypeOverviewMitoticNumber(i,matPlateOKIndices)));
            data{i,14} = sprintf('%.3f',nanmedian(BASICDATA.CellTypeOverviewMitoticIndex(i,matPlateOKIndices)));
            data{i,15} = sprintf('%.0f',nansum(BASICDATA.CellTypeOverviewApoptoticNumber(i,matPlateOKIndices)));
            data{i,16} = sprintf('%.5f',nanmedian(BASICDATA.CellTypeOverviewApoptoticIndex(i,matPlateOKIndices)));
            data{i,17} = sprintf('%.0f',nansum(BASICDATA.CellTypeOverviewOthersNumber(i,matPlateOKIndices)));
            data{i,18} = sprintf('%.3f',nanmedian(BASICDATA.CellTypeOverviewOthersIndex(i,matPlateOKIndices)));
            data{i,19} = sprintf('%.4f',nanmedian(BASICDATA.OptimizedInfectionInfectionIndex(i,matPlateOKIndices)));
        end
        try
            data{i,20} = sprintf('%.4f',nanmedian(BASICDATA.CellTypeOverviewZScoreLog2InfectedSVMindex(i,matPlateOKIndices)));
        end

    end
    writelists(data,filename,header,';')
    disp(sprintf('%s: stored %s',mfilename,filename))
end % function Convert_BASICDATA_to_csv
