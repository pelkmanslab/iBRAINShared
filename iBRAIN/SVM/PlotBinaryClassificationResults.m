function PlotBinaryClassificationResults(strBatchPath,strSvmFile)

handles = struct();

if nargin ==0
    strBatchPath = '\\nas-biol-imsb-1.d.ethz.ch\share-2-$\Data\Users\Thomas\iBRAIN\100930_HAFoxa1andHAFoxa2in488_SV40in546\BATCH\';
    strSvmFile = 'Measurements_SVM_transfected_02.mat';
end

% load svm classification
handles = LoadMeasurements(handles,fullfile(strBatchPath,strSvmFile));
handles = LoadMeasurements(handles,fullfile(strBatchPath,'Measurements_Image_FileNames.mat'));

% get classification name
cellSvmFieldNames = fieldnames(handles.Measurements.SVM);
strSvmFieldName = cellSvmFieldNames{cellfun(@isempty,strfind(cellSvmFieldNames,'Features'))};
strSvmFeatureFieldName = cellSvmFieldNames{~cellfun(@isempty,strfind(cellSvmFieldNames,'Features'))};

% get the class names, and find the 'non_' one..
cellSvmFeatureValues = handles.Measurements.SVM.(strSvmFeatureFieldName);
matPositiveClassIndex = find(cellfun(@isempty,regexpi(cellSvmFeatureValues,'^no[nt]?[_-\w]','start')));
matNonPositiveClassIndex = find(~cellfun(@isempty,regexpi(cellSvmFeatureValues,'^no[nt]?[_-\w]','start')));

%convert ImageNames to something we can index
cellFileNames = cell(length(handles.Measurements.Image.FileNames),1);
for l = 1:size(handles.Measurements.Image.FileNames,2)
    cellFileNames{l} = char(handles.Measurements.Image.FileNames{l}(1));
end

% get the location of all image names
[matRow, matCol] = cellfun(@check_image_well_position,cellFileNames);

if (max(matRow) <= 8) & (max(matCol) <= 12)
    intMaxRow = 8;
    intMaxCol = 12;
else
    intMaxRow = 16;
    intMaxCol = 24;
end

matTotal = nan(intMaxRow,intMaxCol);
matClass1 = nan(intMaxRow,intMaxCol);

% let's also output a csv file...
cellWellName = cell(intMaxRow,intMaxCol);
cellFileName = cell(intMaxRow,intMaxCol);
strWellLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

for iRow = 1:intMaxRow
    for iCol = 1:intMaxCol
        cellWellName{iRow,iCol} = sprintf('%s%02d',strWellLetters(iRow),iCol);
        matImageIndices = find(matRow==iRow & matCol == iCol);
        if ~isempty(matImageIndices)
            matTotal(iRow,iCol) = length(cat(1,handles.Measurements.SVM.(strSvmFieldName){matImageIndices}));
            matClass1(iRow,iCol) = nansum(cat(1,handles.Measurements.SVM.(strSvmFieldName){matImageIndices}) == matPositiveClassIndex);
            cellFileName{iRow,iCol} = cellFileNames{matImageIndices(1)};
        end
    end
end

strSvmTextName=strrep(strSvmFile,'_','\_');
strPosClass=strrep(cellSvmFeatureValues{matPositiveClassIndex},'_','\_');

matIndex = matClass1 ./ matTotal;

a = [];

subplot(2,2,1)
hold on
title(sprintf('%s: total ''%s''',strSvmTextName,strPosClass),'fontweight','bold')
imagesc(flipud(matClass1));
a(1)=gca;
axis tight
colorbar
hold off

subplot(2,2,2)
hold on
title(sprintf('%s: ''%s'' index',strSvmTextName,strPosClass),'fontweight','bold')
imagesc(flipud(matIndex));
a(2)=gca;
axis tight
colorbar
hold off

subplot(2,2,3)
hold on
title(sprintf('%s: total ''%s''',strSvmTextName,strPosClass),'fontweight','bold')
hist(matClass1(:))
xlabel(sprintf('total ''%s''',strPosClass))
ylabel('count')
axis tight
hold off

subplot(2,2,4)
hold on
title(sprintf('%s: ''%s'' index',strSvmTextName,strPosClass),'fontweight','bold')
hist(matIndex(:))
xlabel(sprintf('''%s'' index',strPosClass))
ylabel('count')
axis tight
hold off

strOutputDirectory=strrep(strBatchPath,[filesep,'BATCH'],[filesep,'POSTANALYSIS']);
if ~fileattrib(strOutputDirectory); strOutputDirectory=strBatchPath; end

% fix all axis of imagesc's
for i = 1:length(a)
    set(a(i),'YTick',1:2:intMaxRow-1)
    set(a(i),'YTickLabel',cellstr(char(([intMaxRow:-2:2]+64)'))')
    set(a(i),'FontSize',6,'FontName','Arial')
    colorbar('peer',a(i),'FontSize',6)
end

strPathTitle = strrep(strrep(strrep(strBatchPath(strfind(strBatchPath,['Users',filesep])+5:end),[filesep,'BATCH'],''),'\','\\'),'_','\_');
cellstrFigureTitle = sprintf('%s -- %s -- median %s index = %.2f',strPathTitle,strSvmTextName,strPosClass,nanmedian(matIndex(:)));

hold on
axes('Color','none','Position',[0,0,1,.95])
axis off
title(cellstrFigureTitle)
hold off
drawnow    

% try pdf storing.
try
    disp(sprintf('%s: storing PDF file %s',mfilename,['Measurements_SVM_',strSvmFieldName,'_overview.pdf']))
    gcf2pdf(strOutputDirectory,['Measurements_SVM_',strSvmFieldName,'_overview.pdf'],'overwrite','noheader');
catch caughtError
    caughtError
    disp(sprintf('%s: failed to write SVM pdf file',mfilename))
end

% let's try writing a csv file per plate and per measurement also!
strOutputCSV = fullfile(strOutputDirectory,['Measurements_SVM_',strSvmFieldName,'_overview.csv']);
try
    disp(sprintf('%s: storing CSV file %s',mfilename,getlastdir(strOutputCSV)))
    writelists([{cellFileName(:)},{cellWellName(:)},{matTotal(:)},{matClass1(:)},{matIndex(:)}],strOutputCSV,{'FileName','WellName','Total',strPosClass,[strPosClass,'_index']},';')
catch caughtError
    caughtError
    disp(sprintf('%s: failed to write SVM csv file',mfilename))
end
    
close all