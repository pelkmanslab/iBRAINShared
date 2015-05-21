clear
% strrootpathh='\\nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\';
% strrootpathh='\\nas-biol-imsb-1\share-3-$\Data\Users\Berend\50K_copy\';
strrootpathh='Z:\Data\Users\Berend\100907_50K_SFV_KY_followup\SFV-ABl-Trio-replica1\BATCH\';

cell50kdirs=dir([strrootpathh,'*.']);
cell50kdirs=struct2cell(cell50kdirs);
cell50kdirs=cell50kdirs(1,:);


for i = 4:length(cell50kdirs)
    cell50kdirs{i}
    strpath=fullfile(strrootpathh,cell50kdirs{i},filesep);
    load([strpath,'BASICDATA.mat']);
    BASICDATA0=BASICDATA;
    for plate=1:length(BASICDATA0.Path)
        plate
        p=BASICDATA0.Path{plate};
        p=strrep(p,'/','\');
        pp=strfind(p,'\');
        
        strRootPath=[strpath(1:end-1),p(pp((end-2)):end)];

        handles = struct();
        handles = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_Image_FileNames.mat'));
        handles = LoadMeasurements(handles,fullfile(strRootPath,'Measurements_Image_ObjectCount.mat'));
        [handles, class_list, numPositiveClassNumbers]=load_latest_svm_file(handles, strRootPath,'infect','newest');
        
        handles2 = struct();
        for iImage = 1:length(handles.Measurements.Image.FileNames)
            objects=length(handles.Measurements.SVM.(class_list){iImage});
            objects2=handles.Measurements.Image.ObjectCount{iImage}(1);
            if objects~=objects2
                disp('FATAL ERROR!!!!!!!!!! object counts do not match')
            end            
            handles2.Measurements.Nuclei.SVMInfected{iImage} = double(handles.Measurements.SVM.(class_list){iImage}==numPositiveClassNumbers);
            handles2.Measurements.Nuclei.SVMInfected_Features = ['SVMInfected_',class_list];
        end
        handles=handles2;    
        save([strRootPath,'Measurements_Nuclei_SVMInfected'], 'handles')
    end
end