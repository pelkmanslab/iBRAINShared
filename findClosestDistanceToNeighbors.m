function matAllDists = findClosestDistanceToNeighbors(matNucleiPositions)
% totalleh diggeteh! timmeh! cheers, b.
    matAllDists = NaN(size(matNucleiPositions,1),1);
    if size(matNucleiPositions,1)<2;return;end    
    for iRow = 1:size(matNucleiPositions,1)
        matNonSelfIX = true(size(matNucleiPositions,1),1);
        matNonSelfIX(iRow) = false;
        matAllDists(iRow,1) = min( sqrt( ...
                (matNucleiPositions(matNonSelfIX,1) - matNucleiPositions(iRow,1)) .^2 + ...
                (matNucleiPositions(matNonSelfIX,2) - matNucleiPositions(iRow,2)) .^2 ...
            ) );
    end