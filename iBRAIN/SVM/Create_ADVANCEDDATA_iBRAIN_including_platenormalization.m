function Create_ADVANCEDDATA_iBRAIN(path)	

if nargin==0
     path='\\Nas-biol-imsb-1\share-2-$\Data\Users\MHV_DG\';
end
 
load([path,'BASICDATA']);
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

        if intNumOfColumns == 384 && isnumeric(BASICDATA.(strFieldName))
            ADVANCEDDATA.(strFieldName){gene} = BASICDATA.(strFieldName)(gene_indices);
            
            %%% add plate normalized data for every plate matrix of size 1x384
            ADVANCEDDATA.(['ZScore_',strFieldName]){gene} = (BASICDATA.(strFieldName)(gene_indices) - ...
                nanmean(BASICDATA.(strFieldName)(gene_indices_row,:),2)) ./ ...
                nanstd(BASICDATA.(strFieldName)(gene_indices_row,:),0,2);
           
        elseif intNumOfColumns == 384 && iscell(BASICDATA.(strFieldName))
            ADVANCEDDATA.(strFieldName){gene} = BASICDATA.(strFieldName)(gene_indices);
        else

            if iscell(BASICDATA.(strFieldName))
                [s1,s2] = size(BASICDATA.(strFieldName){1,1});
                if s2==384
                    for iii = 1:length(gene_indices_row)

                        ADVANCEDDATA.(strFieldName){gene}(iii,:) = BASICDATA.(strFieldName){gene_indices_row(iii),:}(:,gene_indices_col(iii))';
                    end
                else
                    ADVANCEDDATA.(strFieldName){gene} = BASICDATA.(strFieldName)(gene_indices_row,:);
                end
            else
                ADVANCEDDATA.(strFieldName){gene} = BASICDATA.(strFieldName)(gene_indices_row,:);
            end
            
        end    
    end
end

save([path,'ADVANCEDDATA2'],'ADVANCEDDATA');


        