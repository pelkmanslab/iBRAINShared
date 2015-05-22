function z = tooSmalltoNaN(x,y, iMinimum)

    
    z = x;
    
    z(y<iMinimum) = NaN;

end