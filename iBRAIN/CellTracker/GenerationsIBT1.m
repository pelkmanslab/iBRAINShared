function [matMoveGen,matLin]=GenerationsIBT1(matChildren,matDividers,matLatChil)

if isempty(matChildren) || isempty(matDividers) 
    matMoveGen = [];
    matLin = [];
return
end 

%horizontally catenate children and parents together, after getting rid of
%0s (losing time point info)
matPreChildren=sort(matChildren,2);
matSparseChildren=matPreChildren(:,end);
matParChild=[matDividers,matSparseChildren];

%find the lineage from each Id in the child matrix to its root parent
for j=1:length(matSparseChildren)
  
    matCurrChild=matSparseChildren(j);
    [currLin]=linTracer(matParChild,matCurrChild,j);
    matLinNaNs(j,1:length(currLin))=currLin;
end
%get rid of nans
matNaNs=~isnan(matLinNaNs(:,1));
matLin=matLinNaNs(matNaNs,:);

matMoveGen=[];
for j=1:length(matLin(:,1))
    [preMove]=UpDowner(matLin,matLin(j,1));
    matMoveGen=[matMoveGen;preMove];
end

%find teo comparisons of the last frame 
matMemLastChil = ismember(matMoveGen(:,1),matLatChil) + ismember(matMoveGen(:,2),matLatChil) == 2;
matMoveGen = [matMemLastChil matMoveGen];

function [currLin]=linTracer(matParChild,matCurrChild,j)
i=1;
while i~=0
    if isnan(matCurrChild)
        %If child is a nan, set parent as ID in first column at same row
        matCurrParent=matParChild(j,1);
    else
        %find parent at row where child column is equal to current
        %child
        matCurrParent=matParChild((matParChild(:,2)==matCurrChild),1);
    end
    %if no parent found, then it is a root
    if isempty(matCurrParent)
        i=0;
    else
        %keep incrementing the columns in which the child parent
        %combination are saved
        currLin(1,i)=matCurrChild;
        currLin(1,i+1)=matCurrParent;
        matCurrChild=matCurrParent;
        i=i+1;
    end
end

function [matMoveGen]=UpDowner(matLin,matCurrChild)
%set 0s to nans,prevents 0s being equated with eachother
matLin(matLin==0)=nan;
%find all instances of the unique child in the first column
matFoundChild=(matLin(:,1)==matCurrChild);
%find all the lineages associated with the rows in which you found the
%child
matCurrLin=matLin(matFoundChild,:);
%find all locations of the object IDs in the current lineage in the whole
%list of lineages
[r,c]=find(ismember(matLin,matCurrLin)-repmat(matFoundChild,1,size(matLin,2)));
r=unique(r);
matMembers=matLin(r,:);
matMoveGen=[];
for j=2:length(matCurrLin)
    ID=matCurrLin(j);
    upCount=j-1;
    downCount=0;
    preMove=[matCurrChild,ID,upCount,downCount];
    matMoveGen=[matMoveGen;preMove];
    for k=1:size(matMembers,1)
        [rTot,cTot]=find(matMembers(k,:)==matCurrLin(j));
        rTot=rTot(cTot>1);
        cTot=cTot(cTot>1);
        for l=1:(cTot-1)
            ID=matMembers(k,(cTot-l));
            downCount=l;
            preMove=[matCurrChild,ID ,upCount,downCount];
            matMoveGen=[matMoveGen;preMove];
        end
    end
end
%Remove longer paths/paths to oneself
if sum(ismember(matMoveGen(:,2),matCurrChild))>0
    logMem=ismember(matMoveGen(:,2),matCurrChild);
    matMoveGen=matMoveGen(~logMem,:);
end

if sum(sum(isnan(matMoveGen)))>0
    [~,c]=find(isnan(matMoveGen));
    for j=1:size(c,1)
        matMoveGen=matMoveGen(~isnan(matMoveGen(:,c(j))),:);
    end
end

if size(unique(matMoveGen(:,2)),1)<size(matMoveGen(:,2),1)
uniMov=unique(matMoveGen(:,2));
    for j=1:size(unique(matMoveGen(:,2)),1)
        matMulti=(matMoveGen(:,2)==uniMov(j,1));
        if size(matMulti(matMulti>0),1)>1
            [rMulti,~]=find(matMulti);
            matMultiDat=matMoveGen(rMulti,:);
            for k=1:size(matMultiDat,1)
                matSums(k,1)=rMulti(k);
                matSums(k,2)=sum(matMultiDat(k,3:4));
            end
            matSums=sortrows(matSums,2);
            matBad=matSums(2:end,1);
            matMoveGen(matBad,:)=0;
            matNon0=(matMoveGen(:,2)>0);
            matMoveGen=matMoveGen(matNon0,:);
        end
    end
end
    















