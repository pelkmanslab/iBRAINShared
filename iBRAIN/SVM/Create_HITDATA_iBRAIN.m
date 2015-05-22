%function Create_ADVANCEDDATA_iBRAIN(path)	

% %if nargin==0
      path='X:\Data\Users\VV_DG\';
% %end
%  
 load([path,'ADVANCEDDATA2']);
 dataFields=fieldnames(ADVANCEDDATA);
 genes=length(ADVANCEDDATA.TotalCells);

% ALUSTA gatherData NaN:eilla!
 
for gene=1:genes
    gene
    genename{gene}=ADVANCEDDATA.GeneData{gene}{1};
    geneID(gene)=ADVANCEDDATA.GeneID{gene}{1};
    findex=0;
    for i=1:length(dataFields)
        data=ADVANCEDDATA.(dataFields{i}){gene};
        if isa(data,'double')
            replicas=ADVANCEDDATA.ReplicaNumber{gene};
            oligos=ADVANCEDDATA.OligoNumber{gene};
            if size(data,2)==1
                findex=findex+1;

                fname{findex}=dataFields{i};
                % MEDMED estimator
                data2=length(unique(oligos));
                ii=0;
                for oligo=unique(oligos)'
                    ii=ii+1;
                    data2(ii)=nanmedian(data(oligos==oligo));
                    gatherData{findex}(gene,ii)=data2(ii);
                end
                data3(gene,findex)=nanmedian(data2);
            else
                for iii=1:size(data,2)
                    findex=findex+1;
                    fname{findex}=[dataFields{i},num2str(iii)]; %add here more advanced naming for features that have many fields
                    datab=data(:,iii);
                    % MEDMED estimator
                    data2=length(unique(oligos));
                    ii=0;
                    for oligo=unique(oligos)'
                        ii=ii+1;
                        data2(ii)=nanmedian(datab(oligos==oligo));
                        gatherData{findex}(gene,ii)=data2(ii);
                    end
                    data3(gene,findex)=nanmedian(data2);
                end
            end
        end
    end
end

dataAdHoc=AdHoc_estimator(gatherData, geneID);

data3(isnan(data3))=0;
T=4;
for i=1:length(fname)
   column_data=data3(:,i); 
   Tdown=prctile(column_data,T);
   Tup=prctile(column_data,100-T);
   data4(:,i)=-(column_data<Tdown)+(column_data>Tup);
end

table=cell(size(data4,1)+1,size(data4,2)+2);

table{1,1}='GeneName';
table{1,2}='GeneID';
table(1,3:end)=fname;
table(2:end,1)=genename;
table(2:end,2)=geneID;
table(2:end,3:end)=num2cell(data4);

xlswrite('c:\data\VV_hitlist',table)
% gene_ids=unique(cell2mat(BASICDATA.GeneID(find(cellfun(@isnumeric,BASICDATA.GeneID)))));
% gene_ids=gene_ids(gene_ids~=0); %taking away 0
% genes=length(gene_ids);
% 
% matEmptyindices = find(cellfun('isempty',BASICDATA.GeneID));
% matStringindices = find(~cellfun(@isnumeric,BASICDATA.GeneID));
% for i = [matEmptyindices;matStringindices]
%     BASICDATA.GeneID(i) = {[0]};
% end
% all_ids=cell2mat(BASICDATA.GeneID);
% 
% ADVANCEDDATA = struct();
% for sField = dataFields'
%     ADVANCEDDATA.(char(sField))=cell(1,genes);
% end
% 
% fprintf('\n');
% for gene=1:genes
%     gene
%     [gene_indices_row,gene_indices_col]=find(all_ids==gene_ids(gene));
%     [gene_indices]=find(all_ids==gene_ids(gene));
%     %strEntrezName=['Entrez_',num2str(gene_ids(gene))];
%     
%     % LOOP OVER ALL FIELDNAMES, AND MERGE TO BASICDATA
%     for sField = dataFields'
%         strFieldName = char(sField);
%         
%         intNumOfColumns = size(BASICDATA.(strFieldName),2);
%         intNumOfRows = size(BASICDATA.(strFieldName),1);
% 
%         if intNumOfColumns == 384
%             ADVANCEDDATA.(strFieldName){gene} = BASICDATA.(strFieldName)(gene_indices);
%         else
% 
%             if iscell(BASICDATA.(strFieldName))
%                 [s1,s2] = size(BASICDATA.(strFieldName){1,1});
%                 if s2==384
%                     for iii = 1:length(gene_indices_row)
% 
%                         ADVANCEDDATA.(strFieldName){gene}(iii,:) = BASICDATA.(strFieldName){gene_indices_row(iii),:}(:,gene_indices_col(iii))';
%                     end
%                 else
%                     ADVANCEDDATA.(strFieldName){gene} = BASICDATA.(strFieldName)(gene_indices_row,:);
%                 end
%             else
%                 ADVANCEDDATA.(strFieldName){gene} = BASICDATA.(strFieldName)(gene_indices_row,:);
%             end
%             
%         end    
%     end
% end
% 
% save([path,'ADVANCEDDATA2'],'ADVANCEDDATA');


        