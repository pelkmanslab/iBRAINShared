function matSubPlotDimensions = getSubPlotDimensions(n)

if nargin==0
    n=211
end

% init output
matSubPlotDimensions = [];

% find optimal subplot dimensions...
matI = round(sqrt(n))-5 : round(sqrt(n))+5; % set up search dimension
matI(matI<0) = 0;
matII = matI' * matI; % symmetric search space
matSearchSpaceDiff = triu(matII)-n;
matSearchSpaceDiff(matSearchSpaceDiff<0) = Inf;
% allow one off, to find closest 3/4 solution
[i,j] = find(matSearchSpaceDiff<=(min(matSearchSpaceDiff(:))+(1+n*0.05))); % find the multiple that matches our image count
% go for solution whos ratio is closest to a classical tv screen :)
matOptions = sort([matI(i);matI(j)]',2);
[~,matSortIX] = sort(abs(matOptions(:,2)./ matOptions(:,1) - (4/3)),'ascend');

% return dimensions, with less rows than columns.
matSubPlotDimensions = sort([matI(i(matSortIX(1))),matI(j(matSortIX(1)))],'ascend');% assume more columns than rows

end