function tiff2png(path)
a=dir(path);
items=length(a);
for i=1:items
    filename=a(i).name;
    try
    if not(isempty(strfind(filename(end-5:end),'.tif')))
       png_filename=[path,'\',filename(1:end-4),'.png'];
       foo=fileattrib(png_filename);
        if foo
            disp(['ok: ',num2str(i)])
        else
            disp(['not ok: ',filename])
            return
        end
    end
    end
end