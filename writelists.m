
% WRITELISTS write data in file
%    WRITELISTS(data) writes contest of data in file. Data can be cell array
%    matrix, cell array including cell array vectors, or matrix of numbers  
%    WRITELISTS(data,filename) writes data in file "filename.
%    WRITELISTS(data,filename,header) writer context of header above data. 
%    Use header=[] if no header is needed (default).
%    WRITELISTS(data,filename,header,delimiter) write data using given
%    delimiter for fields. Default delimiter is comma (,).
%    WRITELISTS(data,filename,header,delimiter,numformat) uses numformat for
%    numerical data. This is C conversion symbol for numbers, for example 
%    '%f' floting point and '%i' for integer. 
% 
%  Examples:
%    If you have genenames in Gnames cell array and intensity values in Int,
%    data can be written as WRITELISTS({Gnames,Int},'test.csv')
%    You can also define header={'Genename','Intensity'} by 
%    WRITELISTS({Gnames,Int},'test.csv',header)
% 

%  Matti Nykter
%  Version 20060425
% 
function writelists(n1,varargin)
    
   if nargin==1,outfile='test.csv'; else outfile=varargin{1}; end;
   if nargin<3,H=[]; else H=varargin{2}; end;
   if nargin<4,delimiter=','; else delimiter=varargin{3}; end;            
   if nargin<5,numform='%f'; else numform=varargin{4}; end;
        
    A={};
    
    if iscell(n1) & size(n1,1)>1
        % data is already in cell array matrix, nothing to do here
        A=n1;
    else
    for field=1:size(n1,2) % store all inputdata in a cellarray matrix
        if iscell(n1)
            nl=length(n1{field});
        else
            nl=size(n1,1);
        end
        
        for names=1:nl %length(n1{field})
            if iscell(n1)
                cont=n1{field}(names);
            else
                cont=n1(names,field);
            end
            
            if ~iscell(cont)
                cont={cont};
            end
            A(names,field)=cont;
        end
    end
    end    
    
    fid=fopen(outfile,'w');
    
    if ~isempty(H) % print header if given
        for i=1:size(H,1)
            for j=1:size(H,2)-1        
                fprintf(fid,['%s',delimiter],H{i,j});
            end
            fprintf(fid,['%s','\n'],H{i,size(H,2)});
%            fprintf(fid,'\n');
        end
        
    end
    
    for i=1:size(A,1) % print data
        for j=1:size(A,2)-1
            if isempty(A{i,j})
                A{i,j}=' ';
            end
            if isstr(A{i,j})
                k=strfind(A{i,j}, delimiter);
                if ~isempty(k)
                    if ~strcmp(A{i,j}(1,1),'"') || ~strcmp(A{i,j}(1,end),'"')
                        A{i,j}(k)=' ';
                    end
                end
                fprintf(fid,['%s',delimiter],A{i,j});
            elseif iscell(A{i,j})
                a=A{i,j};
                fprintf(fid,['%s',delimiter],a{1});
            else
                fprintf(fid,[numform,delimiter],A{i,j});
            end
            
        end
        j=size(A,2);
        if isempty(A{i,j})
            A{i,j}=' ';
        end
        if isstr(A{i,j})
            k=strfind(A{i,j}, delimiter);
            if ~isempty(k)
                if ~strcmp(A{i,j}(1,1),'"') || ~strcmp(A{i,j}(1,end),'"')
                    A{i,j}(k)=' ';
                end
            end
            fprintf(fid,['%s','\n'],A{i,j});
        elseif iscell(A{i,j})
            a=A{i,j};
            fprintf(fid,['%s','\n'],a{1});
        else
            fprintf(fid,[numform,'\n'],A{i,j});
        end
        
%        fprintf(fid,'\n');
    end
    fclose(fid);
