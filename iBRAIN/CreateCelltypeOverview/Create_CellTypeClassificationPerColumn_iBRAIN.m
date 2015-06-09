function Create_CellTypeClassificationPerColumn_iBRAIN(strPath)
% Performs the SVM classification for objects

% default input options (works nice for testing)
if nargin==0
%     strPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\VV_KY\060830_VV_KY_50K_3_1_3_CP073-1ac\BATCH\';
%     strPath = 'Z:\Data\Users\50K_final_reanalysis\HRV2_KY\070302_HRV2_KY_50K_rt_P1_1_CP071-1aa\BATCH\';
    strPath = '/BIOL/imsb/fs3/bio3/bio3/Data/Users/50K_final_reanalysis/IV_MZ/061004_IV_MZ_P3_1_3_CP073-1ac/BATCH/';
    strPath = npc(strPath);
end

% checks on input parameters
boolInputPathExists = fileattrib(strPath);
if not(boolInputPathExists)
    error('%s: could not read input strPath %s',mfilename,strPath)    
else
    disp(sprintf('%s: starting on %s',mfilename,strPath))
end

% finding and load/parse the latest classifications for the following svm
% classes
classes{1}='interphase'; %Interphase
classes{2}='mitotic'; %Mitotic
classes{3}='apoptotic'; %Apoptotic
classes{4}='metaphase';
classes{5}='anaphase';
classes{6}='blob';

% loop over all classes, and load data
disp(sprintf('%s: parsing svm files ',mfilename))
handles = struct();
class_list = cell(1,length(classes));
numPositiveClassNumbers = nan(1,length(classes));
for i = 1:length(classes)
    [handles, class_list{i}, numPositiveClassNumbers(i)] = load_latest_svm_file(handles, strPath, classes{i},'newest');
end

% parse per image, and store ouput in handles2
handles2 = struct();
for iImage = 1:length(handles.Measurements.SVM.(class_list{1}))

    % set celltype classification matrices such that 1 matches the
    % phenotype, and 0 does not match the phenotype.
    if not(isempty(strfind(strPath,'VV_DG')))
        matInterphaseIndices = handles.Measurements.SVM.(class_list{1}){iImage} == numPositiveClassNumbers(1);
        matMitoticIndices = handles.Measurements.SVM.(class_list{2}){iImage} == numPositiveClassNumbers(2);
        matApoptoticIndices = ( handles.Measurements.SVM.(class_list{4}){iImage} == numPositiveClassNumbers(4) | ...
                                handles.Measurements.SVM.(class_list{5}){iImage} == numPositiveClassNumbers(5) );
        matBlobIndices = handles.Measurements.SVM.(class_list{6}){iImage} == numPositiveClassNumbers(6);        
    else
        matInterphaseIndices = handles.Measurements.SVM.(class_list{1}){iImage} == numPositiveClassNumbers(1);
        matMitoticIndices = handles.Measurements.SVM.(class_list{2}){iImage} == numPositiveClassNumbers(2);
        matApoptoticIndices = handles.Measurements.SVM.(class_list{3}){iImage} == numPositiveClassNumbers(3);
        matBlobIndices = handles.Measurements.SVM.(class_list{6}){iImage} == numPositiveClassNumbers(6);
    end

    %%% final classification scheme: anything blob is 'other'-class, for
    %%% the non-blob nuclei, check the other classification values.
    %%% (quite a lot of classes convert to interphase)
    % 0 0 0 0 -> other
    % 0 0 0 1 -> Apoptotic
    % 0 0 1 0 -> Mitotic
    % 0 0 1 1 -> Mitotic
    % 0 1 0 0 -> Interphase
    % 0 1 0 1 -> Interphase
    % 0 1 1 0 -> Interphase
    % 0 1 1 1 -> Interphase
    
    %%% all blob instances, independent of other classification values:
    % 1 0 0 0 -> other
    % 1 0 0 1 -> other
    % 1 0 1 0 -> other
    % 1 0 1 1 -> other
    % 1 1 0 0 -> other
    % 1 1 0 1 -> other
    % 1 1 1 0 -> other
    % 1 1 1 1 -> other

    data=[matBlobIndices,matInterphaseIndices,matMitoticIndices,matApoptoticIndices];
    ind{1}=ismember(data,[0 0 0 0],'rows');% -> other
    ind{2}=ismember(data,[0 0 0 1],'rows');% -> Apoptotic
    ind{3}=ismember(data,[0 0 1 0],'rows');% -> Mitotic
    ind{4}=ismember(data,[0 0 1 1],'rows');% -> Mitotic
    ind{5}=ismember(data,[0 1 0 0],'rows');% -> Interphase
    ind{6}=ismember(data,[0 1 0 1],'rows');% -> Interphase
    ind{7}=ismember(data,[0 1 1 0],'rows');% -> Interphase
    ind{8}=ismember(data,[0 1 1 1],'rows');% -> Interphase
    
    ind{9}=ismember(data,[1 0 0 0],'rows');% -> blob/other
    ind{10}=ismember(data,[1 0 0 1],'rows');% -> blob/other
    ind{11}=ismember(data,[1 0 1 0],'rows');% -> blob/other
    ind{12}=ismember(data,[1 0 1 1],'rows');% -> blob/other
    ind{13}=ismember(data,[1 1 0 0],'rows');% -> blob/other
    ind{14}=ismember(data,[1 1 0 1],'rows');% -> blob/other
    ind{15}=ismember(data,[1 1 1 0],'rows');% -> blob/other
    ind{16}=ismember(data,[1 1 1 1],'rows');% -> blob/other

    matInterphaseIndices=ind{5}|ind{6}|ind{7}|ind{8};
    matMitoticIndices=ind{3}|ind{4};
    matApoptoticIndices=ind{2};
    matOthers=ind{1}|ind{9}|ind{10}|ind{11}|ind{12}|ind{13}|ind{14}|ind{15}|ind{16};

    handles2.Measurements.Nuclei.Apoptotic{iImage} = matApoptoticIndices;
    handles2.Measurements.Nuclei.Interphase{iImage} = matInterphaseIndices;
    handles2.Measurements.Nuclei.Mitotic{iImage} = matMitoticIndices;
    handles2.Measurements.Nuclei.Others{iImage} = matOthers;
    
    if (sum(matApoptoticIndices) + sum(matInterphaseIndices) + sum(matMitoticIndices) + sum(matOthers)) ~= length(matOthers)
        error('OOHHH NOO, DOESN''T ADD UP!!!')
    end

end

% store handles2 as handles in Measurements_Nuclei_CellTypeClassificationPerColumn.mat
clear handles
handles = handles2;
disp(sprintf('%s: saving results in %s',mfilename,fullfile(strPath,'Measurements_Nuclei_CellTypeClassificationPerColumn.mat')))
save(fullfile(strPath,'Measurements_Nuclei_CellTypeClassificationPerColumn.mat'),'handles')



		