function tiff2png(path)
a=dir(path);
items=length(a);
for i=1:items
    i
    filename=a(i).name;
    if not(isempty(strfind(filename,'.tif')))
       im=imread([path,'\',filename]);
       imwrite(im,[path,'\',filename(1:end-4),'.png'],'PNG');
    end
end