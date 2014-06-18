function Measurements_mean_std_iBRAIN(path)	
%calculates and saves the mean and std of various phenotype measurements

if nargin==0
    disp('start logging time..')
%     path='Z:\Data\Users\Berend\Philip\S6K\221007_Philip_Tfn_S6Kp_DAPI_CP0001-1aa\BATCH\';
    %path='/Users/berendsnijder/Desktop/BATCH/';      
    path='Z:\Data\Users\Prisca\081113_Pool_Tf_40x\2008-11-12\BATCH\';
end

list=dir([path,filesep,'Measurements_*.mat']);
list2=struct2cell(list);
list3=list2(1,:);
index=0;

handles2 = struct();

if isempty(list3)
   disp('Measurements_mean_std_iBRAIN: did not find any measurements') 
   return
end

% init class as empty, if no measurements are found to be produced, store
% an empty Measurements_Mean_Std.mat file anyway, so iBRAIN sees it's
% completed.
class=[];

for field=1:length(list3)
    if ...
            isempty(strfind(list3{field},'Bacterial'))...
            &&(isempty(strfind(list3{field},'Image'))...
            && (not(isempty(strfind(list3{field},'Nuclei')))...
            || not(isempty(strfind(list3{field},'PlasmaMembrane')))...
            || not(isempty(strfind(list3{field},'Perinuclear')))...
            || not(isempty(strfind(list3{field},'Cells'))))...
            && (not(isempty(strfind(list3{field},'Intensity')))...
            || not(isempty(strfind(list3{field},'Texture')))...
            || not(isempty(strfind(list3{field},'AreaShape')))...
            || not(isempty(strfind(list3{field},'ExtractVesicle')))...
            || not(isempty(strfind(list3{field},'ExtractCell')))...
            || not(isempty(strfind(list3{field},'GridNucleiCount')))...
            || not(isempty(strfind(list3{field},'GridNucleiEdges')))))

        index=index+1;
		cut=strfind(list3{field},'_');
		class{index}=list3{field}((cut(1)+1):(cut(2)-1));
		name{index}=list3{field}((cut(2)+1):(end-4));
	end
end

for type=1:length(class)
	disp(sprintf('LOADING/PROCESSING MEASUREMENTS_%s_%s FROM %s ',class{type},name{type},path));    
	load([path,'Measurements_',class{type},'_',name{type},'.mat']);
	disp(sprintf('  loaded MEASUREMENTS_%s_%s FROM %s ',class{type},name{type},path));        
    
    % Pekka's module does not add a dummy cell to empty images, adding the
    % dummy cell here 
    empty_images=find(cellfun(@isempty,handles.Measurements.(class{type}).(name{type})));
    non_empty_images=find(not(cellfun(@isempty,handles.Measurements.(class{type}).(name{type}))));
    feature_length=size(handles.Measurements.(class{type}).(name{type}){non_empty_images(1)},2);
    for i=1:length(empty_images)
        handles.Measurements.(class{type}).(name{type}){empty_images(i)}=zeros(1,feature_length);
    end

    data=cell2mat(handles.Measurements.(class{type}).(name{type})');
    if size(data,1)>10
        data=data(1:10:end,:);
    end
    
    %%% REMOVE ENTIRE NUCLEI WITH NAN OR INF IN THE DATA...
    %size(data)
    
    [i,j]=find(isinf(data));
	[i2,j2]=find(isnan(data));
    data([i;i2],:) = [];

	clear handles;

	new_name1=[name{type},'_mean'];
	new_name2=[name{type},'_std'];
	new_name3=[name{type},'_median'];
	new_name4=[name{type},'_mad'];
	handles2.Measurements.(class{type}).(new_name1)=nanmean(data,1);
	handles2.Measurements.(class{type}).(new_name2)=nanstd(data,0,1);
	handles2.Measurements.(class{type}).(new_name3)=nanmedian(data,1);
	handles2.Measurements.(class{type}).(new_name4)=mad(data,0,1);

    clear data
	disp(sprintf('  processed MEASUREMENTS_%s_%s FROM %s ',class{type},name{type},path));            
end
% cd(path);
handles=handles2;
save(fullfile(path,'Measurements_Mean_Std.mat'), 'handles')
disp(sprintf('\nSTORED RESULTS IN %s',fullfile(path,'Measurements_Mean_Std.mat')))
clear handles;
clear handles2;