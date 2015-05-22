function intDatenum = getDatenumLastAccessed(strFile)
    intDatenum = NaN;
    if fileattrib(strFile)
        if ispc
            foo=GetFileTime(strFile);
            intDatenum = datenum(foo.Access);
        else
            warning('BS:Bla','%s: getting date last accessed only works on PCs',mfilename)
        end
    else
        warning('BS:Bla','%s: file not found: %s',mfilename,strFile)
    end