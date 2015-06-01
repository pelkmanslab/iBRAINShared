function [matImageSnake,matStitchDimensions] = get_image_snake(intMaxImagePosition, strMicroscopeType)
% help for get_image_snake()
% BS, 082015
% usage [intImagePosition,strMicroscopeType] = get_image_snake(strImageName)
%
% possible values for strMicroscopeType are 'CW', 'BD', and 'MD' [NB YY]
% added strMicroscopeType 'CV7K' [MH YY] added 'NIKON'. Latest modification
% on the 12/06/13 by MH.




    if nargin == 0
        intMaxImagePosition = 49;
        strMicroscopeType = 'CW';
    end
    
    if nargin > 0 & ~isnumeric(intMaxImagePosition)
        error('%s: intMaxImagePosition should be a number.',mfilename)        
    end
    
    if nargin == 2
        if ~strcmpi(strMicroscopeType,'CW') && ...
           ~strcmpi(strMicroscopeType,'BD') && ...
           ~strcmpi(strMicroscopeType,'MD') && ...
           ~strcmpi(strMicroscopeType,'CV7K') && ...
           ~strcmpi(strMicroscopeType,'NIKON') && ...
            error('%s: unrecognized microscope type ''%s''. Allowed values are ''CW'', ''BD'', ''MD'', ''CV7K'' and ''NIKON''.',mfilename,strMicroscopeType)
        end
    end

    %%% DEFAULT SNAKE IS A LOT OF ZEROS, ESSENTIALLY ENDING IN ONE IMAGE PER
    %%% JPG...
    matImageSnake = zeros(2,100);
    matStitchDimensions = [1,1];

    % default output is for cellworx microscopes
    if intMaxImagePosition == 0
        matImageSnake = [0;0];
        matStitchDimensions = [1,1];
return
    elseif intMaxImagePosition ==1
        matImageSnake = [0;0];
        matStitchDimensions = [1,1];
return
    elseif intMaxImagePosition ==2
        matStitchDimensions = [1,2];
    elseif intMaxImagePosition ==4
        matStitchDimensions = [2,2];
    elseif intMaxImagePosition ==6
        matStitchDimensions = [2,3];
    elseif intMaxImagePosition == 9 
        matStitchDimensions = [3,3];
    elseif intMaxImagePosition == 12
        matStitchDimensions = [4,3];
    elseif intMaxImagePosition == 15
        matStitchDimensions = [5,3];
    elseif intMaxImagePosition == 16
        matStitchDimensions = [4,4];
    elseif intMaxImagePosition == 20
        matStitchDimensions = [5,4];
    elseif intMaxImagePosition == 25
        matStitchDimensions = [5,5];        
    elseif intMaxImagePosition == 36
        matStitchDimensions = [6,6];
    elseif intMaxImagePosition == 192
        matStitchDimensions = [16,12];   
    elseif intMaxImagePosition == 180
        matStitchDimensions = [15,12];  
    elseif intMaxImagePosition == 42
        matStitchDimensions = [7,6]; 
    elseif intMaxImagePosition == 30
        matStitchDimensions = [6,5];  
        fprintf('%s: warning, doing risky 30 case. %d rows, %d cols\n',mfilename,matStitchDimensions(1),matStitchDimensions(2))
    elseif intMaxImagePosition == 48
        matStitchDimensions = [8,6];  
    elseif intMaxImagePosition == 49
        matStitchDimensions = [7,7];
    elseif intMaxImagePosition == 63
        matStitchDimensions = [9,7];
    elseif intMaxImagePosition == 80
        matStitchDimensions = [8,10];
    elseif intMaxImagePosition == 663
        matStitchDimensions = [39,17];
    elseif intMaxImagePosition == 1242
        matStitchDimensions = [46,27];
    else
        % simple algorithm to guess the correct dimensions for image 
        % stitching
        matI = round(sqrt(intMaxImagePosition))-5 : round(sqrt(intMaxImagePosition))+5; % set up search dimension
        matII = matI' * matI; % symmetric search space
        [i,j] = find(triu(matII)==intMaxImagePosition); % find the multiple that matches our image count
        matStitchDimensions = sort([matI(i(1)),matI(j(1))],'descend');% assume more rows than columns
    end
   

    
    % if requested microscope type is BD, then do the proper conversion...
    % is this the proper conversion???
%     if strcmpi(strMicroscopeType,'MD')
%         matImageSnake(2,:) = fliplr(matImageSnake(2,:));
%     end

    if intMaxImagePosition > 1
        
        % alternative code could be as follows:
        matRows = [];
        matCols = [];

        % for the cellWoRx and BD-Pathway
        if strcmpi(strMicroscopeType,'CW') || strcmpi(strMicroscopeType,'BD')
            for i = 1:matStitchDimensions(1);
                if ~mod(i,2)
                    matRows = [matRows,matStitchDimensions(2)-1:-1:0];
                else
                    matRows = [matRows,0:matStitchDimensions(2)-1];
                end
                matCols = [matCols,repmat((matStitchDimensions(1)-i),1,matStitchDimensions(2))];
            end
            matImageSnake = [matRows;matCols];

        % for the MD microscope
        elseif strcmpi(strMicroscopeType,'MD')...
                || strcmpi(strMicroscopeType,'CV7K')... %line added by NB 10/11/11
            for i = 1:matStitchDimensions(1);
                matRows = [matRows,0:matStitchDimensions(2)-1];
                matCols = [matCols,repmat(i-1,1,matStitchDimensions(2))];
            end
            matImageSnake = [matRows;matCols];
        
        % for the NIKON microscope
        elseif strcmpi(strMicroscopeType,'NIKON')%added by MH 12/06/13
            %make sure "ZigZag Horizontal" was chosen in plate setting
            %for acquisition at the VisiScope microscope, otherwise
            %this will not work !!!
            %"ZigZag Horizontal" helps stabilizing the auto focus
            for i = 1:matStitchDimensions(1);
                if ~mod(i,2)
                    matRows = [matRows,matStitchDimensions(2)-1:-1:0];
                else
                    matRows = [matRows,0:matStitchDimensions(2)-1];
                end
                matCols = [matCols,repmat(i-1,1,matStitchDimensions(2))];
            end
            matImageSnake = [matRows;matCols];
            
        % for the CV7K microscope
%%[NB] The new software does it the same way than the MD. So I
%%comment this out  10/11/11
%         elseif strcmpi(strMicroscopeType,'CV7K')
%             for i = 1:matStitchDimensions(1);
%                 if ~mod(i,2)
%                     matRows = [matRows,matStitchDimensions(2)-1:-1:0];
%                 else
%                     matRows = [matRows,0:matStitchDimensions(2)-1];
%                 end
%                 matCols = [matCols,repmat(i-1,1,matStitchDimensions(2))];
%             end
%             matImageSnake = [matRows;matCols];
%%End of comment out 10/11/11
        end
        
        fprintf('%s: %d images per well, of type %s. cols = %d, rows = %d\n',mfilename,intMaxImagePosition, char(strMicroscopeType), max(matRows(:)+1),max(matCols(:)+1))
    end

end
