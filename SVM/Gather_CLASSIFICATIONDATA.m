%function Phenotype_statistics_iBRAIN(path)	

path='\\nas-biol-imsb-1\share-2-$\Data\Users\Raphael\070611_Tfn_kinase_screen\';
load([path,'BASICDATA.mat']);

[plates,wells]=size(BASICDATA.ImageIndices);
list=dir([BASICDATA.Path{7},'Measurements_SVM*.mat']);
list2=struct2cell(list);
list3=list2(1,:);
classifications=length(list3);
CLASSIFICATIONDATA=struct();
			
for plate=1:plates
	path2=BASICDATA.Path{plate};
	for classification=1:classifications
				
		disp(['Plate: ',num2str(plate),', Classification: ' num2str(classification)]);
		load([path2,list3{classification}]);
		field=strrep(list3{classification}(18:end-4),' ','_');
		class_names=handles.Measurements.SVM.([field,'_Features']);
		classes=length(class_names);
		
		for class=1:classes
			class_name=strrep(class_names{class},' ','_');
			for well=1:wells
				images=BASICDATA.ImageIndices{plate,well};
				for image=1:length(images)
					try
						CLASSIFICATIONDATA.(field).(class_name)(plate,well)=...
							CLASSIFICATIONDATA.(field).(class_name)(plate,well)+...
							length(find(handles.Measurements.SVM.(field){images(image)}==class));
					catch %the first time this field classname combination is used
						CLASSIFICATIONDATA.(field).(class_name)(plate,well)=length(find(handles.Measurements.SVM.(field){images(image)}==class));
					end
				end
				
			end
		end
	end
end

