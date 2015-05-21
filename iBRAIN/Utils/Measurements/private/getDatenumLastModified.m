function intDatenum = getDatenumLastModified(strFile)
    intDatenum = NaN;
    if fileattrib(strFile)
        if ispc
            foo=GetFileTime(strFile);
            intDatenum = datenum(foo.Write);
        else
            foo=dir(strFile);
            intDatenum = foo.datenum;
        end
    else
%         warning('BS:Bla','%s: file not found: %s',mfilename,strFile)
    end