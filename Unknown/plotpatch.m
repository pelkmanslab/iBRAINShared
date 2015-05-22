function hP = plotpatch(X,Y,C,alpha)
% berend snijder: plot a surface simple style

X = [X(:);flipud(X(:))];
intSize2Dim = find(size(Y)==2);
if intSize2Dim
    % make sure first dimension is more than 2
    if intSize2Dim==1
        Y = Y';
    end
    Y = [Y(:,1);flipud(Y(:,2))];
else
    Y = [Y(:);zeros(numel(Y),1)];
end
    

hP = patch(X,Y,C,'linestyle','none');

if nargin==4
    set(hP,'FaceAlpha',alpha)
end

end