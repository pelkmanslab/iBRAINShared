function showColorMap(x)
matColorMap = x;
figure;imshow(cat(3,repmat(matColorMap(:,1),[1,1000]),repmat(matColorMap(:,2),[1,1000]),repmat(matColorMap(:,3),[1,1000])))
end