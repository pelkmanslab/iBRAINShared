function [dOrig2,aOrig,h1,h2,c,matEqualAIX] = altVennDiagram(x,cellLabels)
% help for altVennDiagram
%
% usage:
%
% [dOrig2,aOrig,h1,h2] = altVennDiagram(x,cellLabels)
%
% Plots for each unique row in x the number of occurences present. Most
% useful if x is logical and rows are genes and columns are assays and a
% true means that gene in that assay is a hit. 
%
% [BS, 2011]

if nargin == 0
    x = rand(10000,4)>0.7;
    cellLabels = {'assay1','assay2','assay3','assay4'};
end

if nargin == 1
    cellLabels = strcat('column',num2strcell([1:size(x,2)]));
end

[a,~,c]=unique(x,'rows');
aOrig = a;
d=countNumberOfValues(c);
dOrig2 = d;


% sort counts from most occuring to least.
[dSort,matSortIX]=sort(d,'descend');
d = dSort;
dOrig = d;
a = a(matSortIX,:);

% find columns where all values are equal (i.e. diff is always 0).
matEqualAIX = true(size(a,1),1);
matA2 = a;
while size(matA2,2) > 1
    matEqualAIX = ((matA2(:,1) == matA2(:,2)) & matEqualAIX) | any(matA2(:,1:2)==0,2);
    matA2(:,1) = [];
end


figure;
subplot(2,1,1)
% print strongest outliers as text
% [~,intOutlier] = Detect_Outlier_levels(d,6);
% matDiscardedIX = d>intOutlier;
% d(matDiscardedIX)=0;
matDiscardedIX = d>inf;
hold on 
if any(matEqualAIX)
    bar(find(matEqualAIX),d(matEqualAIX),'facecolor',[0.6 1 0.7],'edgecolor',[0.5 0.5 0.5]);
    xlim([.5,numel(matEqualAIX)+.5])
end
if any(~matEqualAIX)
    bar(find(~matEqualAIX),d(~matEqualAIX),'facecolor',[0.6 0.7 1],'edgecolor',[0.5 0.5 0.5]);
    xlim([.5,numel(matEqualAIX)+.5])
end
text(find(matDiscardedIX)+0.1,ones([1,sum(matDiscardedIX)]),num2strcell(dOrig(matDiscardedIX)),'rotation',90)
text(find(~matDiscardedIX)+0.1,dOrig(~matDiscardedIX),num2strcell(dOrig(~matDiscardedIX)),'rotation',90,'horizontalalignment','left')
h1=gca;
matYLim = get(h1,'YLim');
% add fake data for legend

matXLim = get(h1,'XLim');
bar(-1,-1,'facecolor','g','edgecolor',[0 0 0])
bar(-1,-1,'facecolor','r','edgecolor',[0 0 0])
set(h1,'YLim',matYLim,'XLim',matXLim,'TickDir','out')
ylabel('count')
set(h1,'XTick',[],'XTickLabel',[])
legend({'count','hit','non-hit'},'fontsize',7)
hold off
subplot(2,1,2)
imagesc(a')
% draw dividing lines over imagesc
for i = 1:size(a,2)
    line([0 size(a,1)]+0.5,[i i]+0.5,'color','k')
end
for i = 1:size(a,1)
    line([i i]+0.5,[0 size(a,2)]+0.5,'color','k')
end
colorbar('off')
h2=gca;
% set(h2,'YTick',[1:size(x,2)],'YTickLabel',cellLabels,'XGrid','off','YGrid','off','XTick',[])
set(h2,'YTick',[1:size(x,2)],'YTickLabel',cellLabels,'XTick',[],'XGrid','off','YGrid','off','XTick',[],'TickDir','out')

% add numeric values to imagesc
matImagesc = a';
for i = 1:numel(matImagesc)
    x=ind2sub2(size(matImagesc),i);
    text(x(2),x(1),sprintf('%d',matImagesc(i)),'FontSize',5,'HorizontalAlignment','center','Color','w')
end

matBarPos = get(h1,'Position');
matHeatPos = get(h2,'Position');
matNewHeatPos = matHeatPos;
matNewHeatPos(2) = matBarPos(2)-matHeatPos(4)-0.01;
set(h2,'Position', matNewHeatPos)
colormap(flipud(redgreencmap))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Here be subfunctions %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [lower,upper] = Detect_Outlier_levels(matInput, factor)
% [matOutput, matDiscardedValues, matDiscardedIndices] = DiscardOutliers(matInput, factor)
% 
%   DiscardOutliers does simple outlier discarding dependent on the inter
%   quartile range of the data. Values lower and higher then 1.5 times the
%   IQR from the median are discarded, and filtered data is returned in
%   matOutput. The discarded values are returned in matDiscarded.
% 
%   BS, 070511 bugfix for matDiscardedIndices and NaN handling...
%   Edited for detecting levels forhit selection by Pauli 6.6.2007

    if nargin == 1
        factor = 1.5;
    end

    matSize = size(matInput);
    if matSize(1,1) == 1
        matInput = matInput';
    end

%     [y,IX] = sort(matInput(find(~isnan(matInput))))
    y = sort(matInput);

    % compute 25th percentile (first quartile)
    Q(1) = nanmedian(y(y<nanmedian(y)));

    % compute 50th percentile (second quartile)
    Q(2) = nanmedian(y);

    % compute 75th percentile (third quartile)
    Q(3) = nanmedian(y(y>nanmedian(y)));

    % compute Interquartile Range (IQR)
    IQR = Q(3)-Q(1);
    lower=Q(1)-factor*IQR;
    upper=Q(3)+factor*IQR;





function c = num2strcell(n, format)
% num2strcell Convert vector of numbers to cell array of strings
% function c = num2strcell(n, format)
%
% If format is omitted, we use
% c{i} = sprintf('%d', n(i))

if nargin < 2, format = '%d'; end

N = length(n);
c = cell(1,N);
for i=1:N
  c{i} = sprintf(format, n(i));
end
  

  


function [matCountPerValue,matUniqueValues,matIX2] = countNumberOfValues(x)

% usage:
%
% [matCountPerValue,matUniqueValues] = countNumberOfValues(x)
%
% bar(matUniqueValues,matCountPerValue)

    [x,matSortIX] = sort(x);
    
    if nargout==3
        [matUniqueValues,matIX,matIX2] = unique(x,'last');
        % sort back matIX2 so that it corresponds to the original unsorted
        % "x"
        [~,matSortIX] = sort(matSortIX);        
        matIX2 = matIX2(matSortIX);
    else
        [matUniqueValues,matIX] = unique(x,'last');
    end
    
    matCountPerValue = NaN(size(matUniqueValues));
    
    matPreviousIX = 0;
    for iValue = 1:size(matUniqueValues,1)
        matCountPerValue(iValue) = matIX(iValue)-matPreviousIX;
        matPreviousIX = matIX(iValue);
    end
    
