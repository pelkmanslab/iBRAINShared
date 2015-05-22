function cellMeasurements = createMeasurement(meta_feature_vector, matResults, matObjectCountPerImage) 
%
% Help for createMeasurement
%
% Usage:
%
%  cellMeasurements = createMeasurement(meta_feature_vector, matResults,matObjectCountPerImage) 
%
% meta_feature_vector should have the following meta information per
% row/object in matResults
%
% column 1: object id
% column 2: image id


if size(matObjectCountPerImage,2)>1
    warning('bs:bla','object count input has multiple columns, using the first one.')
    matObjectCountPerImage = matObjectCountPerImage(:,1);
end

if size(matResults,1) ~= size(meta_feature_vector,1)
    error('result data and meta data shold have equal number of rows\n')
end

intNumOfMeasurementColumns = size(matResults,2);

cellMeasurements = arrayfun(@(x) NaN(x,intNumOfMeasurementColumns) , matObjectCountPerImage','UniformOutput',false);

[foo,matSortIx]=sort(meta_feature_vector(:,2));
clear foo
meta_feature_vector = meta_feature_vector(matSortIx,:);
matResults = matResults(matSortIx,:);

[matUniqueImageIDs,m]=unique(meta_feature_vector(:,2), 'last');

% loop over the present images, per image,
matPreviousIX = 1;
for iImage = 1:length(matUniqueImageIDs)
    matObjectIX = (matPreviousIX:m(iImage));
    cellMeasurements{matUniqueImageIDs(iImage)}(meta_feature_vector(matObjectIX,1),:) = matResults(matObjectIX,:);
    matPreviousIX = m(iImage)+1;
end

% little after check
if ~isequal(cellfun(@(x) size(x,1),cellMeasurements),matObjectCountPerImage')
    figure();scatter(cellfun(@numel,cellMeasurements),matObjectCountPerImage'); title('error! scatterplot')
    error('result data and doesn''t have the same size as expected from object count. plotting image :)\n')
end

%     
% NumImages = size(matObjectCountPerImage,1);
% cellMeasurements = cell(1,NumImages);
% 
% if size(matResults,1) ~= size(meta_feature_vector,1)
%    error('funky things') 
% end
% 
% for i=1:NumImages
% 
%     cellMeasurements{i} = NaN(matObjectCountPerImage(i,1),size(matResults,2));
%     
%     matOKObjectIndices = meta_feature_vector(meta_feature_vector(:,2)==i,1);
%     
%     cellMeasurements{i}(matOKObjectIndices,:) = matResults(meta_feature_vector(:,2)==i,:);
% 
% end
% 
% %  for i=1:NumImages
% %      cellMeasurements{i} =NaN(matObjectCountPerImage(i,1),size(matResults,2));
% %  end;
% % 
% %     cellMeasurements{meta_feature_vector(:,2)}(:,:)=matResults(i,:);
