function [matDividers,matChildren]=SiblingGenerationIBT1(matLineage)

if isempty(matLineage)
    matDividers = [];
    matChildren = [];
return
end 

%as we will be using vertcat, initialise these matrices
matDividers=[];

%loop from 2 as postion 1 in matLineage is always the final frame, i.e.
%there are no divisions
for j=2:size(matLineage,2)
    
    %generate matrices for easier use later
    %matrix containing current time point and later timepoint containing
    %its children
    matCurrentTp=matLineage(:,(j-1):j);
    
    %seperate children and parents
    matCurrentTpChild=matCurrentTp(:,1);
    matCurrentTpPar=matCurrentTp(:,2);
    
    %find locations where there are multiple values, indicating a division
    [logicCurrentDiv]=findXX(matCurrentTpPar);

    %here we generate a list of only the current dividers and children of
    %those dividers
    [matOnlyTpChild,matOnlytTpDiv]=genChildPar(logicCurrentDiv,matCurrentTpChild,matCurrentTpPar);
    
    %here we save these values in such a way that each row is specific to a
    %divider in matDividers and each column in matChildren is equivalent to
    %the timepoint of the column in matLineage
    matDividers=vertcat(matDividers,matOnlytTpDiv);
    matChildren(1+length(matDividers)-length(matOnlyTpChild):length(matDividers),j)=matOnlyTpChild;
end

%sort for clarity
[matDividers,matSortOrder]=sort(matDividers);

%sort the children in the same way as the dividers
for j=1:size(matChildren,1)
    matChildrenSort(j,:)=matChildren(matSortOrder(j),:);
end

%save the final variables
matChildren=matChildrenSort;


function [logicCurrentDiv]=findXX(matCurrentTp)
%find where unique elements begin
[~,matStrtUni]=unique(matCurrentTp,'first');
%find where unique elements end
[~,matEndUni]=unique(matCurrentTp,'last');
%find where unique elements beginning and ending intersect
matInter=intersect(matStrtUni,matEndUni);
%construct a true matrix
logicCurrentDiv=true(size(matCurrentTp));
%set false when the beginning is equal to the end time point (i.e. did not
%divide)
logicCurrentDiv(matInter)=false;


function [matOnlyTpChild,matOnlytTpDiv]=genChildPar(logicCurrentDiv,matCurrentTpChild,matCurrentTpPar)
%apply the logical to the data

matOnlytTpDiv=matCurrentTpPar(logicCurrentDiv);
matOnlyTpChild=matCurrentTpChild(logicCurrentDiv);

logNewChild=ismember(matOnlytTpDiv,matOnlyTpChild);

matOnlytTpDiv=matOnlytTpDiv(~logNewChild);
matOnlyTpChild=matOnlyTpChild(~logNewChild);

[matOnlyTpChild,matSort]=unique(matOnlyTpChild);
matOnlytTpDiv=matOnlytTpDiv(matSort);







