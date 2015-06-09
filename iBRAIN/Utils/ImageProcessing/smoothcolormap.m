function matColorMap = smoothcolormap(colormapSettings,intNumOfRows)

if nargin<=1
    intNumOfRows = 255;
end

if intNumOfRows<1
    intNumOfRows=1;
end

matColorMap = imresize(colormapSettings,[intNumOfRows,3],'lanczos2');
matColorMap(matColorMap>1)=1;
matColorMap(matColorMap<0)=0;
