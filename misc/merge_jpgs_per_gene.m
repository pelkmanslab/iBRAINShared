% Merging well jpegs into gene jpegs
%clear;
%load('Z:\Berend\RISC\Standard_CP_Functions\GENEDATA\GENEDATA');
%load('\\Nas-biol-imsb-1\share-2-$\Data\Users\VV_DG\ADVANCEDDATA');
%load('\\Nas-biol-imsb-1\share-2-$\Data\Users\VV_DG\BASICDATA');
% strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\VV_DG\';
strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\Others\Jean_Philippe\HCT116KS-BDimages\';

%%% looks for target plate folders
cellstrTargetFolderList = SearchTargetFolders(strRootPath,'JPG');

intNumOfFolders = length(cellstrTargetFolderList);

%%% gives you plate number per path
for i = 1:intNumOfFolders
    [intCPNumber(i), intReplicaNumber(i)] = filterplatedata(cellstrTargetFolderList{i});
end

%%% loop over geneid and lookup corresponding images from corresponding
%%% plate paths

genedata_ids=cell2mat(genedata(:,1));
gene_ids0=fieldnames(ADVANCEDDATA);
genes=length(gene_ids0);

for gene=1:genes
	gene
	%try
	% getting gene related information
	geneid=str2double(gene_ids0{gene}((8:end)));
	geneindex=find(genedata_ids==geneid);
	if isempty(geneindex);
		genename=['NONAME_',num2str(geneid)];
		genefullname='';
		geneGOprocess='';
		geneGOfunction='';
		geneGOlocation='';
	else
		genename=genedata{geneindex,2};
		genefullname=genedata{geneindex,4};
		geneGOprocess=strrep(genedata{geneindex,16},'_',' ');
		geneGOfunction=strrep(genedata{geneindex,17},'_',' ');
		geneGOlocation=strrep(genedata{geneindex,18},'_',' ');
	end
	geneRIImedian=round(100*ADVANCEDDATA.(gene_ids0{gene}).Raw.Log2RII.Median.value)/100;
	geneRIIZScore=round(100*ADVANCEDDATA.(gene_ids0{gene}).ZScore.Log2RII.Median.value)/100;
	geneTotalCellsMedian=ADVANCEDDATA.(gene_ids0{gene}).Raw.TotalCells.Median.value;
	geneInfectedCellsMedian=ADVANCEDDATA.(gene_ids0{gene}).Raw.InfectedCells.Median.value;
	geneInfectionIndexMedian=round(1000*ADVANCEDDATA.(gene_ids0{gene}).Raw.InfectionIndex.Median.value)/1000;
	hit=ADVANCEDDATA.(gene_ids0{gene}).Raw.Log2RII.Median.Hit;
	
	% oligo&replica related information
	totalcells=zeros(3);
	Log2RII=zeros(3);
	infectedcells=zeros(3);
	infectionindex=zeros(3);
	values=length(ADVANCEDDATA.(gene_ids0{gene}).Oligo_number);
	for value=1:values
		oligo=ADVANCEDDATA.(gene_ids0{gene}).Oligo_number(value);
		replica=mod(ADVANCEDDATA.(gene_ids0{gene}).Replica_number(value)-1,3)+1;
		
		totalcells(oligo,replica)=ADVANCEDDATA.(gene_ids0{gene}).Raw.TotalCells.Values(value);
		infectedcells(oligo,replica)=ADVANCEDDATA.(gene_ids0{gene}).Raw.InfectedCells.Values(value);
		infectionindex(oligo,replica)=round(1000*ADVANCEDDATA.(gene_ids0{gene}).Raw.InfectionIndex.Values(value))/1000;
		Log2RII(oligo,replica)=round(100*ADVANCEDDATA.(gene_ids0{gene}).Raw.Log2RII.Values(value))/100;	
	end
	
	[PlateName, PlateNumber, WellName, RowNumber, ColumnNumber, GeneSymbol] = lookupgeneidposition(geneid);
	
	% finds the plate path from cellstrTargetFolderList that matches the PlateNumber
	%genewells=BASICDATA.WellCol>2&BASICDATA.WellCol<23;
	
	JPGfused=uint8(zeros(3*702,3*1080,3));
	for oligo=1:min(3,length(PlateNumber))
		plate=PlateNumber(oligo);
		plate_indices=find(intCPNumber==plate);
		for replica=1:min(3,length(plate_indices))
			PlateIndex=plate_indices(replica);
			plate_path=cellstrTargetFolderList{PlateIndex};

			strJPGName = [plate_path,'JPG\',getlastdir(cellstrTargetFolderList{PlateIndex}),'_',WellName{oligo},'_RGB.jpg'];
			strJPGNameBACKUPHACK = [plate_path,'JPG\VV_DG',getlastdir(cellstrTargetFolderList{PlateIndex}),'_',WellName{oligo},'_RGB.jpg'];
			
			JPGimage=zeros(702,1080,3);
			try
				JPGimage=imread(strJPGName);
			catch
				
				try
					JPGimage=imread(strJPGNameBACKUPHACK);
				catch
					JPGimage=zeros(702,1080,3);
					disp(sprintf('failed to read: %s', strJPGName))
				end
			end
			JPGfused(((replica-1)*702+1):(replica*702),((oligo-1)*1080+1):(oligo*1080),:)=JPGimage;
		
			%plate median values
			
			plateind=find(BASICDATA.PlateNumber==PlateNumber(oligo)&BASICDATA.WellCol>2&BASICDATA.WellCol<23&BASICDATA.ReplicaNumber==(replica)); %+3
			totalcellsPlateMedian(oligo,replica)=round(nanmedian(BASICDATA.TotalCells(plateind)));
			totalinfectedcellsPlateMedian(oligo,replica)=round(nanmedian(BASICDATA.InfectedCells(plateind)));
			infectionindexPlateMedian(oligo,replica)=round(1000*nanmedian(BASICDATA.InfectionIndex(plateind)))/1000;
			plateIndices(oligo,replica)=PlateNumber(oligo);
			wellIndices{oligo,replica}=WellName{oligo};
			
			
			plateind2=find(BASICDATA.PlateNumber==PlateNumber(oligo)&BASICDATA.WellCol==ColumnNumber(oligo)&BASICDATA.WellRow==RowNumber(oligo)&BASICDATA.ReplicaNumber==(replica)); %+3
			if not(isempty(plateind2))
				outoffocus(oligo,replica)=9-BASICDATA.Images(plateind2(1));
			else
				outoffocus(oligo,replica)=NaN;
			end
		end	
	end
	
	% creating the text overlays
	step=25;
	fontsize=20;
	figure
	for oligo=1:min(3,length(PlateNumber))
		plate=PlateNumber(oligo);
		plate_indices=find(intCPNumber==plate);
		for replica=1:min(3,length(plate_indices))
			overlay=zeros(702,1080);
			imshow(overlay);
			
			if oligo==1 & replica==1
				h=text(10,40,[genename]);
				set(h,'Color',[1 1 1],'FontSize',50);
				
				h=text(10,3.5*step,[genefullname]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				h=text(10,6*step,['GeneId: ',num2str(geneid)]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				h=text(10,7*step,['GO pro: ',geneGOprocess]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				h=text(10,8*step,['GO func: ',geneGOfunction]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				h=text(10,9*step,['GO loc: ',geneGOlocation]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				h=text(10,10*step,['Median Cells: ',num2str(geneTotalCellsMedian)]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				
				h=text(10,11*step,['Median Total Cells: ',num2str(geneTotalCellsMedian)]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				h=text(10,12*step,['Median Infected Cells: ',num2str(geneInfectedCellsMedian)]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				h=text(10,13*step,['Median Infection Index: ',num2str(geneInfectionIndexMedian)]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				h=text(10,14*step,['Median Log2RII: ',num2str(geneRIImedian)]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				h=text(10,15*step,['ZScore Log2RII: ',num2str(geneRIIZScore)]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				
				if hit==-1
					h=text(10,16*step,['DOWN REGULATED HIT']);
					set(h,'Color',[1 1 1],'FontSize',fontsize);
				elseif hit==1
					h=text(10,16*step,['UP REGULATED HIT']);
					set(h,'Color',[1 1 1],'FontSize',fontsize);
				end
			end
			
			if replica==1
				h=text(10,20*step,['Oligo: ',num2str(oligo)]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				%h=text(10,20*step,['Replica: ',num2str(replica)]);
				%set(h,'Color',[1 1 1],'FontSize',fontsize);
				
				h=text(10,21*step,['Plate: ',num2str(plateIndices(oligo,replica))]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
				
				h=text(10,22*step,['Well: ',wellIndices{oligo,replica}]);
				set(h,'Color',[1 1 1],'FontSize',fontsize);
			end
				
			h=text(10,23*step,['Out of focus: ',num2str(outoffocus(oligo,replica))]);
			set(h,'Color',[1 1 1],'FontSize',fontsize);
			
			h=text(10,24*step,['Cells: ',num2str(totalcells(oligo,replica)),' (',num2str(totalcellsPlateMedian(oligo,replica)),')']);
			set(h,'Color',[1 1 1],'FontSize',fontsize);
			h=text(10,25*step,['Infected Cells: ',num2str(infectedcells(oligo,replica)),' (',num2str(totalinfectedcellsPlateMedian(oligo,replica)),')']);
			set(h,'Color',[1 1 1],'FontSize',fontsize);
			h=text(10,26*step,['Infection Index: ',num2str(infectionindex(oligo,replica)),' (',num2str(infectionindexPlateMedian(oligo,replica)),')']);
			set(h,'Color',[1 1 1],'FontSize',fontsize);
			h=text(10,27*step,['Log2RII: ',num2str(Log2RII(oligo,replica))]);
			set(h,'Color',[1 1 1],'FontSize',fontsize);
			
			tim = getframe(gca);
			tim2 = tim.cdata;
			overlays{replica,oligo}=tim2(1:702,1:1080,3);	
		end
	end
	close;
	% putting overlays to the fused image
	for oligo=1:min(3,length(PlateNumber))
		plate=PlateNumber(oligo);
		plate_indices=find(intCPNumber==plate);
		for replica=1:min(3,length(plate_indices))
			JPGfused(((replica-1)*702+1):(replica*702),((oligo-1)*1080+1):(oligo*1080),:)=JPGfused(((replica-1)*702+1):(replica*702),((oligo-1)*1080+1):(oligo*1080),:)+255*repmat(overlays{replica,oligo}(1:702,1:1080),[1 1 3]);
		end
	end
	JPGfused(JPGfused>255)=255;
	
	imwrite(JPGfused,[strRootPath,'\JPG_GENES\',genename,'.jpg'],'JPG');
	%end
end
