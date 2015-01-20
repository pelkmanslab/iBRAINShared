function SVM_Classify_with_Probabilities_iBRAIN(input_file_name,strPath)
% Performs the SVM classification for objects

% default input options (works nice for testing)
if nargin==0
    input_file_name = '\\nas-biol-imsb-1.d.ethz.ch\share-3-$\Data\Users\Frank\100917-10-51-trunc-SGs\SVM_SG_1.mat';%'\\nas-biol-imsb-1\share-2-$\Data\Users\Raphael\070611_Tfn_kinase_screen\classification\SVM_classification16test.mat';
    strPath = '\\nas-biol-imsb-1.d.ethz.ch\share-3-$\Data\Users\Frank\100917-10-51-trunc-SGs\100917-10-51-trunc-SGs\BATCH\';
end

input_file_name = npc(input_file_name);
strPath = npc(strPath);

% checks on input parameters
boolInputFileExists = fileattrib(input_file_name);
boolInputPathExists = fileattrib(strPath);
if not(boolInputFileExists)
    error('SVM_Classify_iBRAIN: could not read input file %s',input_file_name)
elseif not(boolInputPathExists)
    error('SVM_Classify_iBRAIN: could not read input strPath %s',strPath)
else
    disp(sprintf('SVM_Classify_iBRAIN: PERFORMING CLASSIFICATION \n  %s \n  ON %s\n',input_file_name,strPath))
end

cut=strfind(input_file_name,filesep);
strFilename=input_file_name((cut(end)+1):(end-4));

if isempty(strfind(upper(input_file_name),[filesep,'SVM_']))
    warning('classification input filename does not start with ''SVM_''! using default output name ''default_classification_01'' ')
    svmname = 'default_classification_01';
else
    svmname=strrep(strFilename,'SVM_','');
end

strOutputFileName=['Measurements_SVM_',svmname,'.mat'];
boolOutputFileExists = fileattrib(fullfile(strPath,strOutputFileName));

%if boolOutputFileExists
%    disp(sprintf('SVM_Classify_iBRAIN: STOPPING: OUTPUT FILE ALREADY PRESENT FOR %s IN %s',svmname,fullfile(strPath,strOutputFileName)))
%    return
%end

% remove weird characters from svmname...
svmname = strrep(svmname,'-','_');
disp(sprintf('  SVM output name is %s\n',svmname))

%loading the savefile
load(input_file_name);

% Loading the plate measurement data
PlateHandles = struct();
for field=1:length(savedata.Measurement_names)
	if savedata.classifySetup(field)==1
		disp(sprintf('  Loading.. field: %s', savedata.Measurement_names{field}));
		PlateHandles = LoadMeasurements(PlateHandles, [strPath,'Measurements_',savedata.Measurement_names{field},'.mat']);
	end
end

% Loading the MEAN STD and ObjectCount
PlateHandles2 = struct();
PlateHandles2 = LoadMeasurements(PlateHandles2, [strPath,'Measurements_Mean_Std.mat']);
PlateHandles2 = LoadMeasurements(PlateHandles2, [strPath,'Measurements_Image_ObjectCount.mat']);
cellFields=fieldnames(PlateHandles2.Measurements);
for iField=cellFields'
	cellFields2=fieldnames(PlateHandles2.Measurements.(char(iField)));
	for iField2=cellFields2'
		PlateHandles.Measurements.(char(iField)).(char(iField2)) = PlateHandles2.Measurements.(char(iField)).(char(iField2));
	end
end
clear PlateHandles2;

% DEFINE OBJECT NAME TO GRAB AND COUNT (usually 'Nuclei')
objectName = 'Nuclei';


% CALCULATING THE SIGMOID MODEL FOR PROBABILITY CALCULATION
[foo,votes,dfce] = mvsvmclass2(savedata.svm_data.X,savedata.svm_model);
classes=size(votes,1);
if classes==2
    svm_output.y = savedata.svm_data.y';
    svm_output.X = dfce;
    sigmoid_model = mlsigmoid(svm_output);
end

% CLASSIFYING
disp(sprintf('\nClassifying...'))
model=savedata.svm_model;
featurename=[svmname,'_Features'];
handles.Measurements.SVM.(featurename)=savedata.classNames;
handles.Measurements.SVMp.(featurename)=['Probability_of_',savedata.classNames{1}];
images=length(PlateHandles.Measurements.Image.ObjectCount);

for image=1:images
	disp(sprintf('  PROCESSING IMAGE %d OF %d',image,images))
    objectIndex = grabColumnIndex(PlateHandles.Measurements.Image, objectName);
	objects = PlateHandles.Measurements.Image.ObjectCount{image}(objectIndex);

	feature_matrix=zeros(objects,0);
	for nucleus=1:objects
		index=0;
		feature_index=0; %all loaded measurements index
		for field=1:length(savedata.Measurement_names)
			if savedata.classifySetup(field)==1
				cut=strfind(savedata.Measurement_names{field},'_');
				fieldname1=savedata.Measurement_names{field}(1:(cut-1));
				fieldname2=savedata.Measurement_names{field}((cut+1):end);

				for feature=1:size(PlateHandles.Measurements.(fieldname1).(fieldname2){image},2)
					feature_index=feature_index+1;
					if savedata.used_features(feature_index)
						index=index+1;
						try
							feature_matrix(nucleus,index) =...
								(PlateHandles.Measurements.(fieldname1).(fieldname2){image}(nucleus,feature)-...
								PlateHandles.Measurements.(fieldname1).([fieldname2,'_median'])(feature))/...
								PlateHandles.Measurements.(fieldname1).([fieldname2,'_mad'])(feature);

						catch
							feature_matrix(nucleus,index)=PlateHandles.Measurements.(fieldname1).(fieldname2){image}(nucleus,feature);
						end
					end
				end
			end
		end
    end

	if not(isempty(feature_matrix))
        feature_matrix(isnan(feature_matrix))=0;
		% using the stprtool
		% (http://cmp.felk.cvut.cz/cmp/software/stprtool/index.html)

        [y2,votes,dfce] = mvsvmclass2(feature_matrix',model);
        handles.Measurements.SVM.(svmname){image}=y2'; % the final class label

        if classes==2
            handles.Measurements.SVMp.(svmname){image}=sigmoid(dfce,sigmoid_model)';
        else
            handles.Measurements.SVMp.(svmname){image}=[]; %nothing here (yet)
        end

	else
		handles.Measurements.SVM.(svmname){image}=[];
    end

end


% saving results
save(fullfile(strPath,strOutputFileName), 'handles')

% plotting binary classification results overview
PlotBinaryClassificationResults(strPath,strOutputFileName);

clear handles;
clear PlateHandles;

end


function objectIndex = grabColumnIndex(matImage, objectName)
%GRABCOLUMNINDEX Get matrix column index from 'features' cell array

matImageObjectCount = cat(1, matImage.ObjectCount{:});
cellObjectCountFeatures = matImage.ObjectCountFeatures;

if size(unique(matImageObjectCount','rows'),1)==1
    % this means that all object count columns are equal, so it doesn't
    % matter which one we take
   objectIndex = 1;
   return
end

%  otherwise, look for colum index containing object names ("Nuclei"), take that
%  column
objectIndex = find(cellfun(@(name) strcmp(name, objectName), cellObjectCountFeatures), 1, 'first');

end
