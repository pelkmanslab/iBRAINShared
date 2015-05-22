function matData2 = pushDatain384(matData)

    matZDim = size(matData,3);
    
    matData2 = matData;

    if ~iscell(matData)
        if matZDim>1
            if ~isequal(size(matData),[16,24,matZDim])
                %fprintf('CORRECTING MISSING DATA\n')
                matData2 = NaN(16,24,matZDim);
                matData2(1:size(matData,1),1:size(matData,2),1:matZDim) = matData;
            end
        else
            if ~isequal(size(matData),[16,24])
                %fprintf('CORRECTING MISSING DATA\n')
                matData2 = NaN(16,24);
                matData2(1:size(matData,1),1:size(matData,2)) = matData;
            end        
        end
    else
        if matZDim>1
            if ~isequal(size(matData),[16,24,matZDim])
                %fprintf('CORRECTING MISSING DATA\n')
                matData2 = cell(16,24,matZDim);
                matData2(1:size(matData,1),1:size(matData,2),1:matZDim) = matData;
            end
        else
            if ~isequal(size(matData),[16,24])
                %fprintf('CORRECTING MISSING DATA\n')
                matData2 = cell(16,24);
                matData2(1:size(matData,1),1:size(matData,2)) = matData;
            end        
        end        
    end