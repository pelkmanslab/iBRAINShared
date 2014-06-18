function matSubIndices = sub2ind2(matBinDimensions,matCompleteDataBinIX) %#ok<STOUT,INUSL>

    str2exec = 'matSubIndices = sub2ind(matBinDimensions';
    for i = 1:size(matCompleteDataBinIX,2)
        str2exec = [str2exec,sprintf(',matCompleteDataBinIX(:,%d)',i)]; %#ok<AGROW>
    end
    str2exec = [str2exec,');'];
    eval(str2exec);
    
end