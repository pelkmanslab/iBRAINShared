assays={'Z:\Data\Users\50K_final_reanalysis\EV1_MZ','Z:\Data\Users\50K_final_reanalysis\EV1_KY','Z:\Data\Users\50K_final_reanalysis\RRV_MZ','Z:\Data\Users\50K_final_reanalysis\RRV_KY'}


for assay=1:4
    infected_name=search_latest_svm_file(assays{assay},'infected');
    interphase_name=search_latest_svm_file(assays{assay},'interphase');
    batch_folders=searchTargetFolders(assays{assay},'BASICDATA_*.mat');

    for i=1:length(batch_folders)
        f=strfind(batch_folders{i},'\');
        pathh=batch_folders{i}(1:f(end));


        PlateHandles=struct();
        PlateHandles = LoadMeasurements(PlateHandles, [pathh,'Measurements_SVM_',infected_name,'.mat']);
        PlateHandles = LoadMeasurements(PlateHandles, [pathh,'Measurements_SVM_',interphase_name,'.mat']);
        
        images=length(PlateHandles.Measurements.SVM.(infected_name)); 
        handles=struct;
        handles.Measurements.SVM.Interphase_2001_Features{1}='interphase';
        handles.Measurements.SVM.Interphase_2001_Features{2}='non_interphase';
        
        for image=1:images
            foo=double(PlateHandles.Measurements.SVM.(infected_name){image}==1 | PlateHandles.Measurements.SVM.(interphase_name){image}==1);
            foo(foo==0)=2;
            handles.Measurements.SVM.Interphase_2001{image}=foo;
        end
        save([pathh,'Measurements_SVM_Interphase_2001.mat'],'handles');
    end
end