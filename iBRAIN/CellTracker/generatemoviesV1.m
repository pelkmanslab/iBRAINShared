function generatemoviesV1(strTrackingPath)


%This function uses ffmpeg to generate all final movies. 

strTrackingPath  = npc(strTrackingPath);
%check if it exists, if not output error
if ~fileattrib(strTrackingPath)
    error('%s: %s directory not found.',mfilename,strTrackingPath);
end

% get list of files in directory
cellFileList = struct2cell(CPdir(strTrackingPath))';
cellFileList  = cellFileList(:,1);
%cellFileList = {cellFileList(~[cellFileList.isdir]).name};

% only look at Well_
matNonImageIX = cellfun(@isempty,regexpi(cellFileList,'Well_*','once'));
cellFileList(matNonImageIX) = [];
fprintf('%s: found %d wells.\n',mfilename,length(cellFileList));

% now generate the movies. all movies will be saved in strTrackingPath

n = 1;
numTotalMovies = size(cellFileList,1)*4;
fprintf('%s: %d movies will be created.\n',mfilename,numTotalMovies);
for i = 1:size(cellFileList,1)
    
    strInputName = fullfile(strTrackingPath,cellFileList{i},'%04d.jpg');
    strNameMovie =  fullfile(strTrackingPath,strcat(cellFileList{i},'.avi'));
    fprintf('%s:  creating movie %s. %d out of %d movies.\n',mfilename,strcat(cellFileList{i},'.avi'),n,numTotalMovies);
    strComandToPass = sprintf('ffmpeg -r 10 -i %s -vcodec libx264 -b 480k -maxrate 1024k -profile baseline %s', strInputName,strNameMovie);
    system(strComandToPass);
    n = n+1;
    
    strNameMovie =  fullfile(strTrackingPath,strcat(cellFileList{i},'_hq.avi'));
    fprintf('%s:  creating movie %s. %d out of %d movies.\n',mfilename,strcat(cellFileList{i},'_hq.avi'),n,numTotalMovies);
    strComandToPass = sprintf('ffmpeg -r 10 -i %s -vcodec libx264 -b 1800k -maxrate 4096k -profile baseline %s', strInputName,strNameMovie);
    system(strComandToPass);
    n = n+1;
    
    strNameMovie =  fullfile(strTrackingPath,strcat(cellFileList{i},'.webm'));
    fprintf('%s:  creating movie %s. %d out of %d movies.\n',mfilename,strcat(cellFileList{i},'.webm'),n,numTotalMovies);
    strComandToPass = sprintf('ffmpeg -r 10 -i %s -vcodec libvpx -b 480k -maxrate 1024k -f webm %s', strInputName,strNameMovie);
    system(strComandToPass);
    n = n+1;
    
    strNameMovie =  fullfile(strTrackingPath,strcat(cellFileList{i},'.mkv'));
    fprintf('%s:  creating movie %s. %d out of %d movies.\n',mfilename,strcat(cellFileList{i},'_hq.mkv'),n,numTotalMovies);
    strComandToPass = sprintf('ffmpeg -r 10 -i %s -vcodec libtheora -b 480k -maxrate 1024k -f matroska %s', strInputName,strNameMovie);
    system(strComandToPass);
    n = n+1;
    % ffmpeg -r 4 -i %04d.jpg -vcodec libx264 -b 1800k -maxrate 4096k -profile baseline out_hq.avi
    %
    % ffmpeg -r 4 -i %04d.jpg -vcodec libvpx -b 480k -maxrate 1024k -f webm out.webm
    % ffmpeg -r 4 -i %04d.jpg -vcodec libtheora -b 480k -maxrate 1024k -f matroska out.mkv
end



% Do a final check
% get list of movie files
cellMovieList = CPdir(strTrackingPath);
cellMovieList = {cellMovieList(~[cellMovieList.isdir]).name};

% only look at .avi or .webm or .mkv files
matNonImageIX = cellfun(@isempty,regexpi(cellMovieList,'.*(\.avi|\.webm|\.mkv)$','once'));
cellMovieList(matNonImageIX) = [];
fprintf('%s: found %d Movies\n',mfilename,length(cellMovieList));

if length(cellMovieList) == numTotalMovies
   fprintf('%s: Movie check successfull. The correct number of movies were generated.\n',mfilename);
else
    warning('%s: Movie check UNSUCCESSFULL.\nThe number of expected movies is %d. The number of generated movies is %d.\nPlease notify Nico, Berend or Johann.\n',mfilename,numTotalMovies,length(cellMovieList));
end


