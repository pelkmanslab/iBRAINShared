% function drawCellProfilerObjectRelationships(strPath)

% strPath = 'Y:\Data\Users\Prisca\100224_A431_EGF_Cav1\100224_A431_EGF_Cav1_CP392-1ba\BATCH\';
% strPath = 'Y:\Data\Users\Prisca\100402_A431_Macropinocytosis\100402_A431_Macropinocytosis_CP392-1bd\BATCH';
strPath = 'Y:\Data\Users\Prisca\090203_Mz_Tf_EEA1\090203_Mz_Tf_EEA1_CP392-1ad\BATCH'
% strPath = 'Y:\Data\Users\HPV16_DG\2008-08-18_HPV16_batch1_CP004-1ea\BATCH';

handles = struct();
load(fullfile(strPath,'Batch_data.mat'))

handles = LoadMeasurements(handles, fullfile(strPath,'Measurements_Image_ObjectCount.mat'));

cellParentMeasurements = findfilewithregexpi(strPath,'Measurements_.*_(Parent|Children).mat');

for i = 1:length(cellParentMeasurements)
    handles = LoadMeasurements(handles, fullfile(strPath,cellParentMeasurements{i}));
end


cellObjects = fieldnames(handles.Measurements);

% remove some obvious ones
cellObjects(strcmpi(cellObjects,'Image')) = [];
cellObjects(strcmpi(cellObjects,'Well')) = [];

intNumOfObjects = length(cellObjects);

%%%
% analyze child & parent measurement information

matParentChildMatrix = zeros(intNumOfObjects);

for i = 1:length(cellObjects)
    
    cellParents = {};
    cellChildren = {};
    if isfield(handles.Measurements.(cellObjects{i}),'ParentFeatures')
        cellParents = handles.Measurements.(cellObjects{i}).ParentFeatures';
    end
    if isfield(handles.Measurements.(cellObjects{i}),'ChildrenFeatures')
        cellChildren = handles.Measurements.(cellObjects{i}).ChildrenFeatures';
        % remove trailing word 'Count'
        cellChildren = cellfun(@(x) x(1:end-5),cellChildren,'UniformOutput',false);
    end
    
    matChildren = ismember(cellObjects,cellChildren);
    matParents = ismember(cellObjects,cellParents);
    
    % children of object i
    matParentChildMatrix(i,matChildren) = 1;
    % parents of object i
    matParentChildMatrix(matParents,i) = 1;
    
end

%%%
% also analyze from the pipeline
cellModules = handles.Settings.ModuleNames;

% Modules that imply relationships: Prim, Secondary, Tertiary & Relate
matLoadSegmentedIX = ~cellfun(@isempty,strfind(cellModules,'LoadSegmentedCells'));
mat1stIX = ~cellfun(@isempty,strfind(cellModules,'Prim'));
mat2ndIX = ~cellfun(@isempty,strfind(cellModules,'Secondary'));
mat3rdIX = ~cellfun(@isempty,strfind(cellModules,'Tertiary'));
matRelateIX = ~cellfun(@isempty,strfind(cellModules,'Relate'));
matExpOrShrinkIX = ~cellfun(@isempty,strfind(cellModules,'ExpandOrShrink'));

% parse secondary objects
for i = find(mat2ndIX)
    strParent = handles.Settings.VariableValues{i,1};
    strChild = handles.Settings.VariableValues{i,2};
    
    intChildIX = find(ismember(cellObjects,strChild));
    intParentIX = find(ismember(cellObjects,strParent));
    
    % parent of child..
    matParentChildMatrix(intParentIX,intChildIX) = 1;
end

% parse tertiary objects (has two parents)
for i = find(mat3rdIX)
    strParent1 = handles.Settings.VariableValues{i,1};
    strParent2 = handles.Settings.VariableValues{i,2};
    strChild = handles.Settings.VariableValues{i,3};

    intChildIX = find(ismember(cellObjects,strChild));
    intParentIX1 = find(ismember(cellObjects,strParent1));
    intParentIX2 = find(ismember(cellObjects,strParent2));
    
    % parents of child..
    matParentChildMatrix(intParentIX1,intChildIX) = 1;
    matParentChildMatrix(intParentIX2,intChildIX) = 1;
end

% parse relate modules
for i = find(matRelateIX)
    strParent = handles.Settings.VariableValues{i,2};
    strChild = handles.Settings.VariableValues{i,1};

    intChildIX = find(ismember(cellObjects,strChild));
    intParentIX = find(ismember(cellObjects,strParent));
    
    % parent of child..
    matParentChildMatrix(intParentIX,intChildIX) = 1;
end

% parse expand or shrink modules
for i = find(matExpOrShrinkIX)
    strParent = handles.Settings.VariableValues{i,1};
    strChild = handles.Settings.VariableValues{i,2};

    intChildIX = find(ismember(cellObjects,strChild));
    intParentIX = find(ismember(cellObjects,strParent));
    
    % parent of child..
    matParentChildMatrix(intParentIX,intChildIX) = 1;
end


% draw graph
drawGraph(matParentChildMatrix,cellObjects)

% cytoscape(matParentChildMatrix,cellObjects)

