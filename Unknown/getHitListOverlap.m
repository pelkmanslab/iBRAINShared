function intOverlap = getHitListOverlap(a,b,c,strDir)

    if nargin<4 || strcmpi(strDir,'down')
        strSortDir = 'ascend';
    elseif  strcmpi(strDir,'up')
        strSortDir = 'descend';
    end

    [~,a1]=sort(a,strSortDir);
    [~,b1]=sort(b,strSortDir);

  
    if any(isinf(a1(1:c))) | any(isnan(a1(1:c))) | any(isinf(b1(1:c))) | any(isnan(b1(1:c)))
        warning('bs:Bla','there''s infs and/or nans in your hitlists... do not trust results!')
    end
    
    intOverlap = 100*(numel(intersect(a1(1:c),b1(1:c)))/c);

end