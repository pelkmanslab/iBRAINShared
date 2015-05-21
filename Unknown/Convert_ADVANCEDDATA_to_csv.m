function Convert_ADVANCEDDATA_to_csv(strRootPath)

    if nargin==0
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\MHV_DG\';
%         strRootPath = '\\Nas-biol-imsb-1\shclear are-2-$\Data\Users\VSV_DG\';
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Others\3-V\070610_kinase_screen\';
        strRootPath = 'Z:\DG_screen_Salmonella\';        
    end

    load(fullfile(strRootPath,'ADVANCEDDATA.mat'));
    
    filename = fullfile(strRootPath,'ADVANCEDDATA.csv');

    genelist = fieldnames(ADVANCEDDATA);
    header = ...
        { 'Entrez_Gene_Id',...
        'Gene_Symbol',...
        'Median_Log2RII_Hit',...
        'Median_Log2RII',...
        'Median_TotalCells',...
        'Median_Log2RCN',...
        'ML_Log2RII_value',...
        'ML_Log2RII_Hit',...
        'ML_Log2RII_Best_Oligo',...
        'ML_Log2RII_Best_Oligo_Quality'...        
        };
    
%         'ML_Log2RII_a',...
%         'ML_Log2RII_b',...        
%         'ML_Log2RII_sigma_b',...        
%         'ML_Log2RII_sigma_c',...
    
    data = cell(size(genelist,1),6);            
    
    for i = 1:length(genelist)
        GeneID = str2double(strrep(genelist{i},'Entrez_',''));
        [PlateName, PlateNumber, WellName, RowNumber, ColumnNumber, GeneSymbol] = lookupgeneidposition(GeneID);
        data{i,1} = GeneID;
        data{i,2} = GeneSymbol;        
        data{i,3} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.Median.Hit;
        data{i,4} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.Median.value;
        data{i,5} = ADVANCEDDATA.(char(genelist{i})).Raw.TotalCells.Median.value;
        data{i,6} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RelativeCellNumber.Median.value;

%         data{i,7} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.ML.value;
%         data{i,8} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.ML.Hit;
%         data{i,9} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.ML.Best_Oligo;
%         data{i,10} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.ML.Best_Oligo_Quality;        

%         data{i,11} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.ML.a;
%         data{i,12} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.ML.b; 
%         data{i,13} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.ML.sigma_b;
%         data{i,14} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.ML.sigma_c;

        
        
    end

    writelists(data,filename,header,';')
end % function Convert_ADVANCEDDATA_to_csv
