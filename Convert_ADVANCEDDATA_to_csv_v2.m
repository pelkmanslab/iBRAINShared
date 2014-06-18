function Convert_ADVANCEDDATA_to_csv_v2(strRootPath)

    if nargin==0
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\MHV_DG\';
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\VSV_DG\';
%        strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\VV_DG\';
strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\FLU_DG1\';
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Others\3-V\070610_kinase_screen\';
%         strRootPath = '\\nas-biol-micro\share-micro-1-$\DG_screen_Salmonella\';        
    end

    load(fullfile(strRootPath,'ADVANCEDDATA.mat'));
    load('GENEDATA.mat');
    load('PANTHERDATA.mat');

    matGeneDataGeneIDs = zeros(size(genedata,1),1);
    for i = 1:size(genedata,1)
        matGeneDataGeneIDs(i,1) = genedata{i,1};        
    end

    matPantherDataGeneIDs = zeros(size(genedata,1),1);
    for i = 1:size(panther_data,1)
        matPantherDataGeneIDs(i,1) = panther_data{i,1};        
    end
    
    
    filename = fullfile(strRootPath,'ADVANCEDDATA.csv');

    genelist = fieldnames(ADVANCEDDATA);
    header = ...
        { 'Entrez_Gene_Id',...
        'Gene_Symbol',...
        'Gene_Name',...        
        'Median_Log2RII_Hit',...
        'Median_Log2RII',...
        'Median_Log2RII_Oligo1',...
        'Median_Log2RII_Oligo2',...
        'Median_Log2RII_Oligo3',...
        'Median_Log2RII_Oligo4',...  
        'Median_TotalCells',...
        'Median_Log2RCN',...
        };
    
    if isfield(ADVANCEDDATA.(char(genelist{1})).Raw.Log2RII,'ML')
        header = [header,{...
            'ML_Log2RII_value',...
            'ML_Log2RII_Hit',...
            'ML_Log2RII_Best_Oligo',...
            'ML_Log2RII_Best_Oligo_Quality' ...        
        }];
    end

    %%% PANTHER DATA
    header = [header,{...
        'GO_Process',...
        'GO_Function',...
        'GO_Component',...        
        'Panther_Family',...
        'Panther_Sub_Family',...
        'Panther_Molecular_Function_1',...
        'Panther_Biological_Process_1'...
    }];    


    %%% INIT CELL (with wrong column count)
    data = cell(size(genelist,1),6);            
    
    for i = 1:length(genelist)
        GeneID = str2double(strrep(genelist{i},'Entrez_',''));
        [PlateName, PlateNumber, WellName, RowNumber, ColumnNumber, GeneSymbol] = lookupgeneidposition(GeneID);
        
        %%% GENE ENTREZ ID
        intCol = 1;
        data{i,intCol} = GeneID;
        
        %%% GENE SYMBOL
        intCol = intCol + 1;
        data{i,intCol} = GeneSymbol;   

        %%% FULL GENE NAME (GENEDATA)
        intCol = intCol + 1;            
        data{i,intCol} = char(genedata{find(matGeneDataGeneIDs == GeneID),4});
        
        intCol = intCol + 1;
        data{i,intCol} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.Median.Hit;
        
        intCol = intCol + 1;
        data{i,intCol} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.Median.value;

        %%% GET PER OLIGO LOG2RII VALUES
        matOligos = ADVANCEDDATA.(char(genelist{i})).Oligo_number;
        matValues = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.Values;
        for j = 1:4
            intCol = intCol + 1;            
            data{i,intCol} = nanmedian(matValues(find(matOligos==j)));
        end% for j (oligo) loop
            
        intCol = intCol + 1;        
        data{i,intCol} = ADVANCEDDATA.(char(genelist{i})).Raw.TotalCells.Median.value;
        
        intCol = intCol + 1;        
        data{i,intCol} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RelativeCellNumber.Median.value;

        %%% ADD ML-HIT DETECTION DATA IF AVAILABLE
        if isfield(ADVANCEDDATA.(char(genelist{1})).Raw.Log2RII,'ML')
            intCol = intCol + 1;            
            data{i,intCol} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.ML.value;
            intCol = intCol + 1;            
            data{i,intCol} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.ML.Hit;
            intCol = intCol + 1;            
            data{i,intCol} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.ML.Best_Oligo;
            intCol = intCol + 1;            
            data{i,intCol} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RII.ML.Best_Oligo_Quality;        
        end

        %%% GO DATA FROM GENEDATA: GO_PROCESS
        intCol = intCol + 1;            
        data{i,intCol} = char(genedata{find(matGeneDataGeneIDs == GeneID),16});

        %%% GO DATA FROM GENEDATA: GO_FUNCTION
        intCol = intCol + 1;            
        data{i,intCol} = char(genedata{find(matGeneDataGeneIDs == GeneID),17});

        %%% GO DATA FROM GENEDATA: GO_COMPONENT
        intCol = intCol + 1;            
        data{i,intCol} = char(genedata{find(matGeneDataGeneIDs == GeneID),18});
        
        %%% ADD PANTHER ANNOTATION
        matPantherIndex = find(matPantherDataGeneIDs == GeneID);

        %%% PANTHER FAMILY NAME        
        intCol = intCol + 1;            
        data{i,intCol} = char(panther_data{matPantherIndex,4});

        %%% PANTHER SUB FAMILY NAME        
        intCol = intCol + 1;            
        data{i,intCol} = char(panther_data{matPantherIndex,5});
        
        %%% PANTHER MOLECULAR FUNCTION
        intCol = intCol + 1;  
        if not(isempty(matPantherIndex))
            cellMolFunc = panther_data{matPantherIndex,7};
            tmpString = '';
            for ii = 1:size(cellMolFunc,1)
                for iii = 1:size(cellMolFunc,2)
                    if not(isempty(cellMolFunc{ii,iii}))
                        tmpString = [tmpString, char(sprintf('%s >',cellMolFunc{ii,iii}))];
                    end
                end
                tmpString = [tmpString(1,1:end-2), '. '];
            end
            data{i,intCol} = char(tmpString);            
        else
            data{i,intCol} = char('');
        end          

        %%% PANTHER BIOLOGICAL PROCESS
        intCol = intCol + 1;  
        if not(isempty(matPantherIndex))
            cellBiolFunc = panther_data{matPantherIndex,9};
            tmpString = '';
            for ii = 1:size(cellBiolFunc,1)
                for iii = 1:size(cellBiolFunc,2)
                    if not(isempty(cellBiolFunc{ii,iii}))
                        tmpString = [tmpString, char(sprintf('%s >',cellBiolFunc{ii,iii}))];
                    end
                end
                tmpString = [tmpString(1,1:end-2), '. '];
            end
            data{i,intCol} = char(tmpString);            
        else
            data{i,intCol} = char('');
        end        
        
    end

    writelists(data,filename,header,';')
end % function Convert_ADVANCEDDATA_to_csv
