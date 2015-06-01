function ADVANCEDDATA = convert_basic_to_advanced_data(BASICDATA)

if nargin == 0
    strRootPath = 'Z:\Data\Users\VV_rescreen\';
    load(fullfile(strRootPath,'BASICDATA.mat'))
end

% makes the old-school advanced data structure, but if present adds the
% CellTypeOverviewZScoreLog2NonOthersII infection index, discarding wrongly
% segmented nuclei and blob-nuclei.

ADVANCEDDATA = struct();

gene_ids=unique(cell2mat(BASICDATA.GeneID(find(cellfun(@isnumeric,BASICDATA.GeneID)))));
genes=length(gene_ids);

matEmptyindices = find(cellfun('isempty',BASICDATA.GeneID));
matStringindices = find(~cellfun(@isnumeric,BASICDATA.GeneID));
for i = [matEmptyindices;matStringindices]
	BASICDATA.GeneID(i) = {[0]};
end
all_ids=cell2mat(BASICDATA.GeneID);

data=[];

fprintf('\n');
for gene=1:genes
	%gene
    if gene_ids(gene) < 0
        %skip controls with gene_ids lower than 0
        continue
    end

    if ~mod(gene,250)
        disp(sprintf('%s: processing %%%.0f',mfilename,(gene/genes)*100))
    end
    
	gene_indices=find(all_ids==gene_ids(gene));
    
	oligos=BASICDATA.OligoNumber(gene_indices);
	replicas=BASICDATA.ReplicaNumber(gene_indices);

	% Removing oligos with oligonumber 0
	if not(isempty(find(oligos==0)))
		fprintf(['Warning: Geneid: ',num2str(gene_ids(gene)),' has an oligo with oligonumber 0\n']);
		bad_data=find(oligos==0);
		replicas(bad_data)=[];
		oligos(bad_data)=[];
		gene_indices(bad_data)=[];
	end
	
	% Renaming duplicate replicas as different replicas of the same oligo
	for oligo=1:max(oligos);
		indi=find(oligos==oligo);
		replicas_of_oligo=replicas(indi);
		if length(replicas_of_oligo)~=length(unique(replicas_of_oligo))
% 			fprintf(['Warning: Geneid: ',num2str(gene_ids(gene)),' has additional replicas for oligo ',num2str(oligo),'\n']);
			foo_index=0;
			for replica=1:length(replicas_of_oligo)
				if length(find(replicas_of_oligo==replica))>1; %this only renames a replicas that appear twice (not 3 times of more)
					foo_index=foo_index+1;
					replicas(indi(replica))=max(replicas_of_oligo)+foo_index;
				end
			end
		end
	end
	
	ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Oligo_number=oligos;
	ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Replica_number=replicas;
	ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Raw.Log2RII.Values=BASICDATA.Log2RelativeInfectionIndex(gene_indices);

    if isfield(BASICDATA,'CellTypeOverviewZScoreLog2NonOthersII')
    	ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).SVM.ZscoreLog2RII.Values=BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(gene_indices);    
    end    

    if isfield(BASICDATA,'OptimizedInfectionZscoreLog2RIIPerWell')
    	ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Optimized.ZscoreLog2RII.Values=BASICDATA.OptimizedInfectionZscoreLog2RIIPerWell(gene_indices);
    end
    
	ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Raw.Log2RelativeCellNumber.Values=BASICDATA.Log2RelativeCellNumber(gene_indices);
	ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Raw.TotalCells.Values=BASICDATA.TotalCells(gene_indices);
	
	oligoss=unique(oligos);
% 	if length(oligoss)<3
% 		fprintf(['Warning: Geneid: ',num2str(gene_ids(gene)),' does not have all 3 oligos\n']);
% 	end
	
	% calculating the median estimator
	% Add here more advanced estimators!
	datafoo1=[];
	datafoo2=[];
	datafoo3=[];
	datafoo4=[];% svm data
	datafoo5=[];% optimized infection
	for oligo=oligoss'
		indi=find(oligos==oligo);
		datafoo1(end+1)=nanmedian(BASICDATA.Log2RelativeInfectionIndex(gene_indices(indi)));
		datafoo2(end+1)=nanmedian(BASICDATA.Log2RelativeCellNumber(gene_indices(indi)));
		datafoo3(end+1)=nanmedian(BASICDATA.TotalCells(gene_indices(indi)));
        if isfield(BASICDATA,'CellTypeOverviewZScoreLog2NonOthersII')
            datafoo4(end+1)=nanmedian(BASICDATA.CellTypeOverviewZScoreLog2NonOthersII(gene_indices(indi)));
        end
        if isfield(BASICDATA,'OptimizedInfectionZscoreLog2RIIPerWell')
            datafoo5(end+1)=nanmedian(BASICDATA.OptimizedInfectionZscoreLog2RIIPerWell(gene_indices(indi)));            
        end        
	end
	ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Raw.Log2RII.Median.value=nanmedian(datafoo1);
	ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Raw.Log2RelativeCellNumber.Median.value=nanmedian(datafoo2);
	ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Raw.TotalCells.Median.value=nanmedian(datafoo3);
    
    if isfield(BASICDATA,'CellTypeOverviewZScoreLog2NonOthersII')
        ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).SVM.ZscoreLog2RII.Median.value=nanmedian(datafoo4);
    end    
    
    if isfield(BASICDATA,'OptimizedInfectionZscoreLog2RIIPerWell')
        ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Optimized.ZscoreLog2RII.Median.value=nanmedian(datafoo5);
    end        
    
	data(gene)=nanmedian(datafoo1);
end

[lower,upper]=Detect_Outlier_levels(data);

% Detecting and marking hits
for gene=1:genes
    
    if gene_ids(gene) < 0
        %skip controls with gene_ids lower than 0
        continue
    end
    
	if ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Raw.Log2RII.Median.value<lower;
		ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Raw.Log2RII.Median.Hit=-1;
	elseif ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Raw.Log2RII.Median.value>upper;
		ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Raw.Log2RII.Median.Hit=1;
	else
		ADVANCEDDATA.(['Entrez_',num2str(gene_ids(gene))]).Raw.Log2RII.Median.Hit=0;
	end
end

% save([path,'ADVANCEDDATA'],'ADVANCEDDATA');
if nargin == 0
    save(fullfile(strRootPath,'ADVANCEDDATA.mat'))
end
