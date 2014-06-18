function Create_ADVANCEDDATA_iBRAIN(strRootPath)

if nargin==0
    strRootPath='X:\Data\Users\MHV_DG\';
end

try
    load(fullfile(strRootPath,'BASICDATA_Manual.mat'));
    BASICDATA=BASICDATA_Manual;
catch
    load(fullfile(strRootPath,'BASICDATA.mat'));
end
dataFields=fieldnames(BASICDATA);

gene_ids=unique(cell2mat(BASICDATA.GeneID(find(cellfun(@isnumeric,BASICDATA.GeneID)))));
gene_ids=gene_ids(gene_ids~=0); %taking away 0
genes=length(gene_ids);

matEmptyindices = find(cellfun('isempty',BASICDATA.GeneID));
matStringindices = find(~cellfun(@isnumeric,BASICDATA.GeneID));
for i = [matEmptyindices;matStringindices]
    BASICDATA.GeneID(i) = {[0]};
end
all_ids=cell2mat(BASICDATA.GeneID);

ADVANCEDDATA = struct();
for sField = dataFields'
    ADVANCEDDATA.(char(sField))=cell(1,genes);
end

fprintf('\n');
for gene=1:genes
    gene
    [gene_indices_row,gene_indices_col]=find(all_ids==gene_ids(gene));
    [gene_indices]=find(all_ids==gene_ids(gene));
    %strEntrezName=['Entrez_',num2str(gene_ids(gene))];
    
    % LOOP OVER ALL FIELDNAMES, AND MERGE TO BASICDATA
    for sField = dataFields'
        strFieldName = char(sField);
        
        intNumOfColumns = size(BASICDATA.(strFieldName),2);
        intNumOfRows = size(BASICDATA.(strFieldName),1);

        if intNumOfColumns == 384
            
            ADVANCEDDATA.(strFieldName){gene} = BASICDATA.(strFieldName)(gene_indices);

        else

            if iscell(BASICDATA.(strFieldName))
                [s1,s2] = size(BASICDATA.(strFieldName){1,1});
                if s2==384
                    for iii = 1:length(gene_indices_row)

                        try
                            ADVANCEDDATA.(strFieldName){gene}(iii,:) = BASICDATA.(strFieldName){gene_indices_row(iii),:}(:,gene_indices_col(iii))';
                        catch
                        end
                    end
                else
                    ADVANCEDDATA.(strFieldName){gene} = BASICDATA.(strFieldName)(gene_indices_row,:);
                end
            else
                try
                    ADVANCEDDATA.(strFieldName){gene} = BASICDATA.(strFieldName)(gene_indices_row,:);
                catch
                end
            end

        end    
    end
end

save(fullfile(strRootPath,'ADVANCEDDATA2.mat'),'ADVANCEDDATA');


        