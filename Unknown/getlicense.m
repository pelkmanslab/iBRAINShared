function getlicense(funchandle)

% repeatedly tries to get a license handle

if nargin==0
    funchandle = @matlabpool;
end

while true
    
    try
        funchandle()
    catch objFoo
        fprintf('%s: %s - failed: %s\n',mfilename,datestr(now,0),objFoo.identifier)
        if iscell(objFoo.cause) & not(isempty(objFoo.cause))
            if isempty(strfind(objFoo.cause{1}.message,'license'))
                fprintf('%s: %s - stopping as error message does not contain the word ''license''\n\n%s\n',mfilename,datestr(now,0),objFoo.cause{1}.message)                
                break
            else
                pause(0.5)
            end
        else
            break
        end
    end
end