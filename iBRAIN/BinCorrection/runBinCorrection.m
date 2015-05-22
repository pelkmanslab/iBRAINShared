function runBinCorrection(strRootPath,strSettingsFile, strOutputFileName)

if nargin==0
    % define path of input data
    strRootPath = npc('Z:\Data\Users\Cameron\CHOL-LBPA_HELAMZ_QIAGEN_Druggable\CHOL-LBPA_HELAMZ_Batch_19-20_BSF002795x_CP526-1aa\BATCH\');
end

if nargin<1
    % define path of settings file
%     strSettingsFile = npc('\\nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\ProbModel_Settings.txt');
%     strSettingsFile = npc('\\nas-biol-imsb-1.d.ethz.ch\share-3-$\Data\Users\Berend\Sabrina\100518_SD205_VSV_KY\\ProbModel_Settings.txt');
    strSettingsFile = npc('Z:\Data\Users\Cameron\CHOL-LBPA_HELAMZ_QIAGEN_Druggable\BIN_CellsMeanFilipin_AllSvms.txt');
    
end

if nargin<2
    strOutputFileName = 'Measurements_BIN_test.mat';
end

fprintf('%s: starting on %s\n',mfilename,strRootPath)

% % load standard data
[handles, cellFileNames, matChannelNumber, matImagePositionNumber, cellstrMicroscopeType, matImageWellRow, matImageWellColumn, cellstrImageWellName, matObjectCountPerImage] = LoadStandardData(strRootPath);


% get raw data per cell, with complete meta data that contains:
%     Row, 
%     Column, 
%     Plate number, 
%     Cell Plate number, 
%     Replica number, 
%     Image number, 
%     Object number

% first, create tensor model only on the data coming from images that match
% the user supplied regular expression
[matCompleteData, strFinalFieldName, matCompleteMetaData, structDataColumnsToUse, structMiscSettings] = getRawProbModelData2(strRootPath,strSettingsFile);

% do bin correction, first column is readout, others are used for binning.
matCompleteDataBinReadout = doBinCorrection(matCompleteData, strFinalFieldName,'display');%



% store display figure to POSTANALYSIS as PDF.
try
    strPDFName = strrep(strOutputFileName,'.mat','_overview.pdf');
    strPostAnalysisPath = strrep(strRootPath,[filesep,'BATCH'],[filesep,'POSTANALYSIS']);
    gcf2pdf(strPostAnalysisPath,strPDFName,'overwrite');
catch booError
    booError
end

% create measurement to store in BATCH directory
cellMeasurement = createMeasurement(matCompleteMetaData(:,[7,6]), [matCompleteData(:,1),matCompleteDataBinReadout,matCompleteData(:,1)-matCompleteDataBinReadout],matObjectCountPerImage(:,1));

clear handles

strMeasurementName = strrep(strOutputFileName,'Measurements_BIN_','');
strMeasurementName = strrep(strMeasurementName,'.mat','');

% remove illegal characters from fieldname
strMeasurementName = strrep(strMeasurementName,'-','_');

% note the nicest naming scheme... problem is to extract the object that is
% being corrected from the settings file...
handles.Measurements.BIN.(strMeasurementName) = cellMeasurement;
handles.Measurements.BIN.([strMeasurementName,'Features']) = {['Raw ',strMeasurementName], ['Bin Expected ',strMeasurementName], ['Raw - Expected ',strMeasurementName]};

strOutputFile = fullfile(strRootPath,strOutputFileName);
save(strOutputFile,'handles')
fprintf('%s: stored %s\n',mfilename,strOutputFile)


% % Calculate average values per well of raw bin II and expected bin II.
%
% matImagePos = [matImageWellRow(:,1), matImageWellColumn(:,1)];
% matWellBinRawII = NaN(8,12);
% matWellBinExpII = NaN(8,12);
% for iPos = unique(matImagePos,'rows')'
% 
%     matWellReadouts = nanmean(cat(1,cellMeasurement{ismember(matImagePos,iPos','rows')}),1);
%     matWellBinRawII(iPos(1),iPos(2)) = matWellReadouts(1);
%     matWellBinExpII(iPos(1),iPos(2)) = matWellReadouts(2);
% 
% end
% matWellBinCorII = matWellBinRawII ./ matWellBinExpII;
% figure()
% imagescnan([],[],nanzscore2d(log2(matWellBinCorII)))
 
% % compare current bin correction to previous one.
% load('Y:\Data\Users\50K_final_reanalysis\SV40_MZ\070111_SV40_MZ_MZ_P3_1_1_CP073-1aa\BATCH\ProbModel_TensorCorrectedData.mat')
% matOldBinCorII = reshape(TensorCorrectedData.PlateTensorCorrected.LOG2RII,[24,16])';
% corr(lin(matOldBinCorII(1:8,1:12)),lin(log2(matWellBinCorII)),'rows','pairwise')
