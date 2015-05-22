function Convert_ADVANCEDDATA_to_csv_HTML(strRootPath)

    persistent genedata panther_data

    if nargin==0
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\MHV_DG\';
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\VSV_DG\';
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\VV_DG\';
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\Others\3-V\070610_kinase_screen\';
        strRootPath = 'Y:\Data\Users\50K_final_reanalysis\HIV_MZ_2\';        
%         strRootPath = 'Y:\Data\Users\Lilli\080401_A431_SV40_Lilli\';        
    end

    load(fullfile(strRootPath,'ADVANCEDDATA.mat'));
    disp(sprintf('loaded advanceddata from %s',fullfile(strRootPath,'ADVANCEDDATA.mat')))
    if ~exist('genedata','var') || isempty(genedata)
        load('GENEDATA.mat');
        disp('loaded GO annotations')    
    end
    if ~exist('panther_data','var') || isempty(panther_data)
        load('PANTHERDATA.mat');
        disp('loaded Panther annotations')    
    end    

    
    matPlates = [22,23,24,45,46,68,69,70]
    
    matGeneDataGeneIDs = cell2mat(genedata(:,1));
    
    matPantherDataGeneIDs = cell2mat(panther_data(:,1));
    
    filename = fullfile(strRootPath,'ADVANCEDDATA_html2.csv');
    
    genelist = fieldnames(ADVANCEDDATA);
    
    % gather the number of unique oligos
    matUniqueOligos = [];
    boolSVMDataPresent = 0;
    boolMLDataPresent = 0;
    for i = genelist'
        matUniqueOligos = unique([matUniqueOligos; ADVANCEDDATA.(char(i)).Oligo_number]);

        % check if there is SVM data anywhere        
        if ~boolSVMDataPresent && isfield(ADVANCEDDATA.(char(i)),'SVM') 
            if isfield(ADVANCEDDATA.(char(i)).SVM,'ZscoreLog2RII')
                boolSVMDataPresent = 1;
            end
        end

        % check if there is ML data anywhere
        if ~boolMLDataPresent && isfield(ADVANCEDDATA.(char(i)).Raw.Log2RII,'ML')
            boolMLDataPresent = 1;
        end
        
    end
    matNumOfOligos = length(matUniqueOligos);
    
    header = {...
        'Entrez_Gene_Id',...
        'Gene_Symbol',...
        'Gene_Name',...        
        'MedMed_Log2RII_Hit',...
        'MedMed_Log2RII',...
    };

    % add the per oligo headers
    for i = matUniqueOligos'
        header = [header, {sprintf('Median_Log2RII_Oligo%d',i)}];
    end
    
    header = [header,{...
        'Median_TotalCells',...
        'Median_Log2RCN',...
    }];
    
    if boolSVMDataPresent
        header = [header, {'SVM_MedMed_ZscLog2RII'}];
        % add the per oligo headers
        for i = matUniqueOligos'
            header = [header, {sprintf('SVM_Median_ZscLog2RII_Oligo%d',i)}];
        end            
    end
    
    if boolMLDataPresent        
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
%     data = cell(100,6);            
    
    for i = 1:length(genelist)
        GeneID = str2double(strrep(genelist{i},'Entrez_',''));
        if ~mod(i,100)
            disp(sprintf('processing gene id %d',GeneID))
        end
        [PlateName, PlateNumber, WellName, RowNumber, ColumnNumber, GeneSymbol] = lookupgeneidposition(GeneID);
        
        %%% GENE ENTREZ ID
        intCol = 1;
%         data{i,intCol} = GeneID;
        % add HTML hyperlink to pubmed page :-)
        data{i,intCol} = sprintf('"=HYPERLINK(""http://www.ncbi.nlm.nih.gov/sites/entrez?cmd=retrieve&db=gene&list_uids=%d&dopt=full_report"";""%d"")"',GeneID,GeneID);
        
        %%% GENE SYMBOL
        intCol = intCol + 1;
%         data{i,intCol} = GeneSymbol;   
        % add HTML hyperlink to pubmed page :-)
%         char(GeneSymbol{end})
%         sprintf('"=HYPERLINK(""http://www.ncbi.nlm.nih.gov/sites/entrez?cmd=retrieve&db=gene&list_uids=%d&dopt=full_report"";""%s"")"',GeneID,char(GeneSymbol{end}))
        data{i,intCol} = sprintf('"=HYPERLINK(""http://www.ncbi.nlm.nih.gov/sites/entrez?cmd=retrieve&db=gene&list_uids=%d&dopt=full_report""; ""%s"")"',GeneID,GeneSymbol{end});        
        

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
        for j = matUniqueOligos'
            intCol = intCol + 1;            
            data{i,intCol} = nanmedian(matValues(find(matOligos==j)));
        end% for j (oligo) loop
            
        intCol = intCol + 1;        
        data{i,intCol} = ADVANCEDDATA.(char(genelist{i})).Raw.TotalCells.Median.value;
        
        intCol = intCol + 1;        
        data{i,intCol} = ADVANCEDDATA.(char(genelist{i})).Raw.Log2RelativeCellNumber.Median.value;

        %%% ADD SVM CORRECTED DATA IF AVAILABLE
        if boolSVMDataPresent        
            intCol = intCol + 1;            
            data{i,intCol} = ADVANCEDDATA.(char(genelist{i})).SVM.ZscoreLog2RII.Median.value;

            matOligos = ADVANCEDDATA.(char(genelist{i})).Oligo_number;
            matValues = ADVANCEDDATA.(char(genelist{i})).SVM.ZscoreLog2RII.Values ;
            for j = matUniqueOligos'
                intCol = intCol + 1;            
                data{i,intCol} = nanmedian(matValues(find(matOligos==j)));
            end% for j (oligo) loop
        end          
        
        
        %%% ADD ML-HIT DETECTION DATA IF AVAILABLE
        if boolMLDataPresent        
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

    if ~isempty(data)
        writelists(data,filename,header,';')
    else
        warning('berend:Bla','%s: not writing empty data',mfilename)
    end
% end % function Convert_ADVANCEDDATA_to_csv