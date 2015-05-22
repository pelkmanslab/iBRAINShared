 function h = densityscatter(X,Y,S)
%  DENSITYSCATTER 
%
%     DENSITYSCATTER(X,Y,S,C) displays circles at the locations specified
%     by the vectors X and Y (which must be the same size), wherre the
%     color is determined by the local density of the data and the Jet
%     colormap. 
%  
%     S determines the area of each marker (in points^2). S can be a
%     vector the same length a X and Y or a scalar. If S is a scalar, 
%     MATLAB draws all the markers the same size. If S is empty, the
%     default size is used.
%     
%     The color is determined by the local density estimate of the data,
%     using colormap Jet.
%
%     DENSITYSCATTER(X,Y) draws the markers in the default size.
%     DENSITYSCATTER(X,Y,S) draws the markers at the specified sizes (S)
%     with a single color. This type of graph is also known as
%     a bubble plot.
%  
%     H = DENSITYSCATTER(...) returns handles to the scatter objects created.
%
% BS, 2010-03-12

if nargin==0
    matFoo = randn(10000,1);
    data=[matFoo, (matFoo * .5)+(randn(10000,1) * .5)];
%         randn(1000,1)+18, randn(1000,1);
%         randn(1000,1)+15, randn(1000,1)/2-18;];
    X = data(:,1);
    Y = data(:,2);
end

if nargin<3
    % by default set markersize to 15
    S = 15;
end

matBadIX  =isinf(X) | isnan(X) | isinf(Y) | isnan(Y);
X(matBadIX) = [];
Y(matBadIX) = [];


[~,density,matXEdges,matYEdges]=kde2d([X(:),Y(:)]);

% rescale density to [1 - 255]
density = density - min(density(:));
density = uint8(255 * (density / max(density(:))));

% get for each point the indices to get the density from.
[~,matXIX] = histc(X,matXEdges(1,:));
[~,matYIX] = histc(Y,matYEdges(:,1));

% get density per point.
matDensityPerPoint = density(sub2ind(size(density),matYIX,matXIX));
matDensityPerPoint(matDensityPerPoint<=0)=1;

% sort ascending
[matDensityPerPoint, matSortIX] = sort(matDensityPerPoint,'ascend');

% if there are a lot of datapoints to plot, switch to part filled contour
% and part scatter plot

h = [];

if size(matDensityPerPoint,1)>=10000
    hold on
    
    % get the jet colormap and rescale to make 255 colors sweetness.
    matColorMap = colormap(jet);
    matColorMap = imresize(matColorMap,[255,3],'lanczos2');
    matColorMap(matColorMap>1)=1;
    matColorMap(matColorMap<0)=0;
    matFirstColorOrig = matColorMap(1,:);
    matColorMap(1,:) = [1,1,1];
    colormap(matColorMap)    
    
    % plot contour of highest density areas.
    density(density<quantile(matDensityPerPoint,0.15)) = 0;
    [C,h(1)] = contourf(matXEdges,matYEdges,density,100,'linecolor','none');

    colormap(matColorMap)    
    
    
    % get lower 10% of data
    matSparseDataIX = (matDensityPerPoint<=quantile(matDensityPerPoint,0.2));
    
    % draw points in order of lowest --> highest density
    matColorData = matColorMap(matDensityPerPoint(matSparseDataIX),:);
    matColorData(matDensityPerPoint(matSparseDataIX)==1,:) = repmat(matFirstColorOrig,sum(matDensityPerPoint(matSparseDataIX)==1),1);
    h(2) = scatter(X(matSortIX(matSparseDataIX)),Y(matSortIX(matSparseDataIX)),S,matColorData,'filled');
    hold off
else
    matColorMap = colormap(jet);
    matColorMap = imresize(matColorMap,[255,3],'lanczos2');
    matColorMap(matColorMap>1)=1;
    matColorMap(matColorMap<0)=0;

    % draw points in order of lowest --> highest density    
    h = scatter(X(matSortIX),Y(matSortIX),S,matColorMap(matDensityPerPoint,:),'filled');
    hold off
end


