function Create_ADVANCEDDATA_iBRAIN(strDataPath,strRootPath)

if nargin==0
    strDataPath='X:\Data\Users\VSV_DG\070309_VSV_DG_batch1_CP004-1ab\BATCH\';
    strRootPath='X:\Data\Users\VSV_DG\';
end

% finding the latest classifications
classes{1}='Interphase';
classes{2}='Mitotic';
classes{3}='Apoptotic';
classes{4}='metaphase';
classes{5}='Anaphase';

class_latest=zeros(1,length(classes));
class_list=cell(1,5);
files=dir(sprintf('%s%s*SVM*.mat',strRootPath,filesep));
for i=1:size(files,1)
    name=files(i).name;
    for class=1:length(classes)
        if not(isempty(strfind(name,classes{class})))
            cellNumber = regexpi(name,'\d{1,}','Match');
            number=str2double(cellNumber{1});
            if class_latest(class)<number
                class_latest(class)=number;
                class_list{class}=name(5:end-4);
            end
        end
    end
end


%%% ADD MODEL SPECIFIC MEASUREMENTS, LIKE A OUT-OF-FOCUS IMAGE CORRECTED
%%% TOTAL CELL NUMBER AND TOTAL INFECTED NUMBER PER WELL. ALL FUNCTIONS
%%% SHOULD SKIP IF THE MEASUREMENT IS ALREADY PRESENT.
disp('parsing cell type classification data')

% load classification data
handles = struct();
for class=1:length(classes)
    if not(isempty(class_list{class}))
        handles = LoadMeasurements(handles,fullfile(strDataPath,['Measurements_SVM_',class_list{class},'.mat']));
    end
end

% parse per image, and store ouput in handles2
handles2 = struct();
for iImage = 1:length(handles.Measurements.SVM.(class_list{1}))
    % original datastructure: phenotype = 1, non-phenotype = 2. set this
    % to phenotype = 1, non-phenotype = 0.

    if not(isempty(strfind(strRootPath,'VV')))
        matApoptoticIndices = double(~(handles.Measurements.SVM.Apoptotic_classification03{iImage} - 1));
        matInterphaseIndices = double(~(handles.Measurements.SVM.Interphase_classification03{iImage} - 1));
        matMitoticIndices = double(~(handles.Measurements.SVM.Anaphase_classification{iImage}-1) | ~(handles.Measurements.SVM.metaphase_classification{iImage}-1));
    else
        matApoptoticIndices = double(~(handles.Measurements.SVM.(class_list{3}){iImage} - 1));
        matInterphaseIndices = double(~(handles.Measurements.SVM.(class_list{1}){iImage} - 1));
        matMitoticIndices = double(~(handles.Measurements.SVM.(class_list{2}){iImage} - 1));
    end

    % Objects to discard are those with 0 or with more than 1 annotation
    %(for MZ cell lines, the best cell line for SVM results)
    if not(isempty(strfind(strRootPath,'VV'))) || not(isempty(strfind(strRootPath,'VSV')))
        % Interphase, Mitotic, Apoptotic -> choice
        % 0 0 0 -> other
        % 0 0 1 -> Apoptotic
        % 0 1 0 -> Mitotic
        % 0 1 1 -> other
        % 1 0 0 -> Interphase
        % 1 0 1 -> other
        % 1 1 0 -> other
        % 1 1 1 -> other
        matIndexCount = sum([matApoptoticIndices,matInterphaseIndices,matMitoticIndices],2);
        matOthers = double(matIndexCount == 0 | matIndexCount > 1);

        % Set objects with more than 1 annotation to 0
        matApoptoticIndices(boolean(matOthers)) = 0;
        matInterphaseIndices(boolean(matOthers)) = 0;
        matMitoticIndices(boolean(matOthers)) = 0;
    else
        % For other cell lines (Apoptotic classification is not reliable):
        % Interphase, Mitotic, Apoptotic -> choice
        % 0 0 0 -> other
        % 0 0 1 -> Apoptotic
        % 0 1 0 -> Mitotic
        % 0 1 1 -> Mitotic
        % 1 0 0 -> Interphase
        % 1 0 1 -> Interphase
        % 1 1 0 -> other
        % 1 1 1 -> other


        data=[matInterphaseIndices,matMitoticIndices,matApoptoticIndices];
        ind{1}=ismember(data,[0 0 0],'rows');
        ind{2}=ismember(data,[0 0 1],'rows');
        ind{3}=ismember(data,[0 1 0],'rows');
        ind{4}=ismember(data,[0 1 1],'rows');
        ind{5}=ismember(data,[1 0 0],'rows');
        ind{6}=ismember(data,[1 0 1],'rows');
        ind{7}=ismember(data,[1 1 0],'rows');
        ind{8}=ismember(data,[1 1 1],'rows');

        matInterphaseIndices=ind{5}|ind{6};
        matMitoticIndices=ind{3}|ind{4};
        matApoptoticIndices=ind{2};
        matOthers=ind{1}|ind{7}|ind{8};
    end

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
disp(sprintf('SAVING %s',fullfile(strDataPath,'Measurements_Nuclei_CellTypeClassificationPerColumn.mat')))
save(fullfile(strDataPath,'Measurements_Nuclei_CellTypeClassificationPerColumn.mat'),'handles')



