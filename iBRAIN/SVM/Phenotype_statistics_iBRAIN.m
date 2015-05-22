%function Phenotype_statistics_iBRAIN(path)	
clear
shown_genes=100;
path='\\nas-biol-imsb-1\share-2-$\Data\Users\Raphael\070611_Tfn_kinase_screen\';
load([path,'BASICDATA.mat']);
load([path,'CLASSIFICATIONDATA.mat']);
genenames=unique(BASICDATA.GeneData);

classification_names=fields(CLASSIFICATIONDATA);

for classification=32%1:length(classification_names)
	figure
	
	classnames=fields(CLASSIFICATIONDATA.(classification_names{classification}));
	for class=1:length(classnames)
		class
		index=0;
		pheno=[];
		ratio=[];
		name={};
		for gene=1:length(genenames)
			[plates,wells]=find(ismember(BASICDATA.GeneData,genenames{gene}));
			for item=1:length(wells)
				well=wells(item);
				plate=plates(item);
				oligo=BASICDATA.OligoNumber(plate,well);
				phenotypes=CLASSIFICATIONDATA.(classification_names{classification}).(classnames{class})(plate,well);
				
				index=index+1;
				pheno(index)=phenotypes;
				ratio(index)=log2(phenotypes/BASICDATA.TotalCells(plate,well));
				name{index}=[BASICDATA.GeneData{plate,well},'\_',num2str(oligo)];
			end
		end
		ratio(isinf(ratio))=0;
		for type=1:2
			if type==1
				data=pheno;
			else
				data=ratio;
			end
			[values,sorted_indices]=sort(data);
			h=subplot(length(classnames)*2,1,(class-1)*2+type);
			indices=[length(values)-shown_genes+1:length(values)];
			bar(values(indices));
			if type==1
				ylabel('Phenotype Cells');
			else
				ylabel('Ratio');
			end
			set(h,'XTick',[]);
			set(h,'XTickLabel',[]);
			hold on
			title(strrep(classnames{class},'_','\_'));
			for i=1:length(indices)
				h=text(i,0,name{sorted_indices(indices(i))});
				set(h,'Rotation',-90,'FontSize',7);
			end
		end
	end
end