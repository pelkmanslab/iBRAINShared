function matCompleteDataBinIX = ind2sub2(matBinDimensions,matSubIndices) %#ok<STOUT,INUSD>

    str2exec = '[I1';
    for i = 2:size(matBinDimensions,2)
        str2exec = [str2exec,sprintf(',I%d',i)]; %#ok<AGROW>
    end
    str2exec = [str2exec,']'];
    
    eval(sprintf('%s = ind2sub(matBinDimensions,matSubIndices);',str2exec));
    eval(sprintf('matCompleteDataBinIX = %s;',str2exec));
    
end