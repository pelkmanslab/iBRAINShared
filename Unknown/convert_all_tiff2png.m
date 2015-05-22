function convert_all_tiff2png(strRootPath,b)

if nargin==0
    strRootPath = '\\nas-biol-imsb-1\share-3-$\Data\Users\Berend\081015_MD_HDMECS_Tfn_pFAK\TIFF\';
    strRootPath = npc(strRootPath);
    b = 'c';
end

disp(sprintf('%s: analyzing %s',mfilename,strRootPath))

% get list of all tif files in directory
tifflist = SearchTargetFolders(strRootPath,'*.tif','rootonly');

disp(sprintf('%s: found %d .tif files',mfilename,length(tifflist)))

if nargin==2 || nargin==0
    % if not empty, randomize the tif list, so multiple parallel copies are
    % less likely to overlap drastically in processing the tiff files.
    if ~isempty(tifflist)
        for i = 1:min([double(lower(b(1))) - 96,10])
            disp(sprintf('%s: randomizing tiff file list: %d',mfilename,i))    
            tifflist = tifflist(randperm(size(tifflist,1)),1);
        end
    end
end

% create list of corresponding png file names
% pnglist = strrep(strrep(tifflist,'.tif','.png'),[filesep,'TIFF',filesep],[filesep,'PNG',filesep]);
pnglist = strrep(tifflist,'.tif','.png');


% start timer
tic

for i = 1:length(tifflist)
    
    if ~fileattrib(tifflist{i})
        disp(sprintf('%s: skipping %s (%.0fm) progress = %.0f%%',mfilename,getlastdir(tifflist{i}),(toc/60), (i/length(tifflist))*100 ))
        continue
    end
    
    if strncmp(getlastdir(tifflist{i}),'._',2)
        disp(sprintf('%s: deleting %s. starts with a ''._'' (%.0fm)',mfilename,tifflist{i},(toc/60)))            
        try
            delete(tifflist{i})
        catch caughtError
            disp(sprintf('%s: failed to delete %s',mfilename,tifflist{i}))
            disp(caughtError.message)
            disp(caughtError.identifier)
        end
        continue
    elseif ~isempty(regexpi(getlastdir(tifflist{i}),'_s\d{1,}_w\d{1,}_thumb'))
        disp(sprintf('%s: deleting %s. looks like an MD-thumb file (%.0fm)',mfilename,tifflist{i},(toc/60)))            
        try
            delete(tifflist{i})
        catch caughtError
            disp(sprintf('%s: failed to delete %s',mfilename,tifflist{i}))
            disp(caughtError.message)
            disp(caughtError.identifier)
        end
        continue
    else
        disp(sprintf('%s: processing %s (%.0fm) progress = %.0f%%',mfilename,getlastdir(tifflist{i}),(toc/60), (i/length(tifflist))*100 ))
    end
    
    % counter for the number of conversion & check attempts
    intAttempts = 0;

    % boolean that checks if the png is equal to the tif image
    boolConversionSuccess = 0;
    % boolean that checks if we succesfulle loaded the tif image
    boolImageLoadedSuccess = 0;    
    
    % start (re)try while loop
    while fileattrib(tifflist{i}) && intAttempts<3
        intAttempts = intAttempts + 1;        
        matTifImage = [];
        matPngImage = [];
        if intAttempts == 1
            disp(sprintf('%s: +-- starting attempt %d',mfilename,intAttempts));        
        else
            pause(2)
            disp(sprintf('%s: +-- starting attempt %d (with a 2 seconds delay)',mfilename,intAttempts));        
        end
        
        try
            % open tif image
            boolImageLoadedSuccess = 0;                    
            disp(sprintf('%s: +-- reading tif',mfilename));
            matTifImage = imread(tifflist{i});
            boolTiffImageLoadedSuccess = 1;
        catch caughtError
            if strcmpi(caughtError.identifier, 'MATLAB:imread:fileFormat')
                disp(sprintf('%s: +-- CORRUPT FILE FOUND: %s',getlastdir(tifflist{i})))
            elseif strcmpi(caughtError.identifier, 'MATLAB:imread:fileOpen') & ~isempty(strfind(caughtError.message,'does not exist.'))
                disp(sprintf('%s: +-- FILE NOT FOUND: %s',getlastdir(tifflist{i})))
            else
                disp(sprintf('\n\n%s: UNKNOWN ERROR FOUND WHILE TRYING TO READ TIFF FILE, RETHROWING ERROR',mfilename))
                % unknown error, scary!
                rethrow(caughtError)
            end
        end

        % if failed to load image, do not continue but try again...
        if ~boolTiffImageLoadedSuccess
            boolConversionSuccess = 0;
            continue        
        end
        
        
        if boolTiffImageLoadedSuccess && ~isempty(matTifImage)
                % if corresponding png file does not exists, and this is the 
                % first attempt, do the conversion and store the result
            if ~fileattrib(pnglist{i})% && (intAttempts==1)
                % convert to png and store
                
                try                
                    disp(sprintf('%s: +-- converting and storing png',mfilename));          
                    imwrite(matTifImage,pnglist{i},'png');
                catch caughtError
                    % if an error occured, display error message
                    disp(caughtError.message)
                    disp(caughtError.identifier)
                end
                    
            elseif fileattrib(pnglist{i})
                % png exists, check if it is readable, and try again.
                try                
                    disp(sprintf('%s: +-- png already present, checking',mfilename));
                    imread(pnglist{i});
                catch caughtError
                    % if an error occured, display error message
                    % failed to read png image, let's write it again
                    disp(caughtError.message)
                    disp(caughtError.identifier)
                    pause(2)                    
                    disp(sprintf('%s: +-- failed to read png, converting and storing png again',mfilename));
                    imwrite(matTifImage,pnglist{i},'png');                    
                end
                
            end

           try                
                % open png image
                disp(sprintf('%s: +-- reading png',mfilename));          
                matPngImage = imread(pnglist{i});
            catch caughtError
                % if an error occured, display error message
                % failed to read png image, let's write it again
                disp(sprintf('%s: +-- failed to read png',mfilename));
                disp(caughtError.message)
                disp(caughtError.identifier)                    
            end                

            % compare TIFF and PNG image
            disp(sprintf('%s: +-- comparing',mfilename));                     
            boolConversionSuccess = isequal(matTifImage,matPngImage);            

        end
        
        % check if the conversion went ok
        if boolConversionSuccess
            disp(sprintf('%s: +-- OK!',mfilename));
            
            % the question is, should we remove the tif file here, or in
            % iBRAIN/shell scripts? If we do it here, we are sure the
            % conversion went OK. If we do it in iBRAIN/shell we can never
            % be sure...
            
            disp(sprintf('%s: +-- deleting tif',mfilename));
            try
                delete(tifflist{i})
            catch caughtError
                disp(sprintf('%s: +-- failed to delete %s',mfilename,tifflist{i}))
                disp(caughtError.message)
                disp(caughtError.identifier)
            end            

        else
            disp(sprintf('%s: +-- NOT OK!',mfilename));
            warning('berend:Fail','%s: png conversion failed (attempt %d). Something is wrong!',mfilename,intAttempts)
        end

    end
    
    % after 3 tries, panick and error
    if ~boolConversionSuccess && ~fileattrib(tifflist{i}) && fileattrib(pnglist{i})
        disp(sprintf('%s: +-- tiff file disappeared and png found, moving on...',mfilename));
    elseif ~boolConversionSuccess
        disp(caughtError.message)
        disp(caughtError.identifier)
        boolConversionSuccess 
        fileattrib(tifflist{i})
        fileattrib(pnglist{i})
        error('%s: +-- png conversion failed (%d attempts). PANIC!!!\n TIFF = %s\n PNG = %s',mfilename,intAttempts,tifflist{i},pnglist{i})        
    end
    
end

