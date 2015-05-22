function SpreadObjects(hT,howMuch,strDim)
% [BS] wiggles apart text objects on a plot that are vertically too close
% to eachother.
if nargin<2
    howMuch = 0.03;
end
if nargin<3
    % by default work on the y-dimension
    strDim = 'y';
end

hT(hT==0) = [];
if ~isempty(hT)
    % let's wiggle away overlapping text-labels...
    matCurPos = cell2mat(get(hT,'Position'));
    matPosY = matCurPos;
    switch lower(strDim)
        case 'y'
            matPosY(:,[1,3]) = [];
        case 'x'
            matPosY(:,[2,3]) = [];
        case 'z'
            matPosY(:,[1,2]) = [];
        otherwise
            error('dimension input should be either ''x'', ''y'', or ''z''...')
    end
    while true
        [matPosY,matSortIX] = sort(matPosY);
        hT = hT(matSortIX);
        matTooCloseIX = find(abs(diff(matPosY)) < howMuch);
        if isempty(matTooCloseIX); break; end
        for i = matTooCloseIX
            matPosY(i) = matPosY(i)-(howMuch/5);
            matPosY(i+1) = matPosY(i+1)+(howMuch/5);
        end
    end
    for i = 1:numel(hT) % ideally inherit x-pos from previous state...
        matNewPos = matCurPos(i,:);
        switch lower(strDim)
            case 'y'
                matNewPos(2) = matPosY(i);
            case 'x'
                matNewPos(1) = matPosY(i);
            case 'z'
                matNewPos(3) = matPosY(i);
        end        
        set(hT(i),'Position',matNewPos)
    end
end