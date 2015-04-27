function [cellstrFolderList] = SearchTargetFolders2(strRootPath,strNameToLookFor,varargin)
% bs: added the 'rootonly' (varargin) option, to only search current
% directory

    % output
    cellstrFolderList = {};
    
    % bool to ensure long search notifications are only displayed once.
    boolLongSearchNotified = 0;
    
%     if ischar(varargin)
%         varargin = {varargin};
%     end

    if nargin == 0
%         strRootPath = '\\Nas-biol-imsb-1\share-2-$\Data\Users\VV_DG\20071022102932_M2_071020_VV_DG_batch1_CP002-1dc\BATCH\'
        strRootPath = npc('\\Nas-biol-imsb-1\share-3-$\Data\Users\50K_final_reanalysis\')
        strNameToLookFor = 'test'
%         strNameToLookFor = '*P24*.*'
%         varargin={'rootonly'}
    end

%     if nargin == 0
%         error('%s: no input given',mfilename)
%     end
    if isempty(strRootPath) || ~fileattrib(strRootPath)
        error('%s: input directory ''%s'' does not exist',mfilename,strRootPath)
    end
    if isempty(strNameToLookFor)
        error('%s: input search string should not be empty',mfilename,strRootPath)        
    end
    
	%%% added unix specific implementation
    %%% using system command 'find' is much faster :-)
	if isunix && ~ismac
        if nargin==0
            strRootPath=npc('/BIOL/imsb/fs3/bio3/bio3/Data/Users/HPV16_DG/2008-08-14_HPV16_batch1_CP001-1ea');
            strNameToLookFor='Dapi* - n000000.tif';
        end
%         disp(sprintf('executing ''find "%s" -name "%s" -printf "%%p%%%%%%%%"''',strRootPath,strNameToLookFor))
		[a,b]=system(sprintf('find "%s" -name "%s" -printf "%%p%%%%%%%%"',strRootPath,strNameToLookFor));
		if a==0
			b = regexpi(b,'%%','split')';
			b(cellfun(@isempty,b))=[];
			cellstrFolderList = b;
			return
		else
			error('failed to find stuff')
		end
	end



    cellstrFolderList = {};

    % ADD FILESEP TO END OF PATH IN CASE IT IS MISSING
    if ~strcmpi(strRootPath(end),filesep)
        strRootPath = [strRootPath,filesep];
    end
    
    % MAKE SURE THAT THE START FOLDER IS NOT LEFT OUT
    path = fullfile(strRootPath,filesep);
    if nargin==0; disp(sprintf(' searching %s for %s',path,strNameToLookFor)); end
    [boolFileFound,strucMess] = fileattrib(fullfile(path,strNameToLookFor));
    if boolFileFound
        cellstrFolderList = [cellstrFolderList;{strucMess.Name}'];
    end
    
    
    %%% CRAWL THROUGH SUBDIRECTORIES
    list=CPdir(strRootPath);
    list=struct2cell(list);
    list=list';
    item_isdir=cell2mat(list(:,2));
    RootPathFolderList=list(item_isdir,1);
    if strcmp(RootPathFolderList(1),'.') && ...
        strcmp(RootPathFolderList(2),'..')
        RootPathFolderList(1:2)=[];
    end


    if size(RootPathFolderList,1) > 0 && not(isempty(RootPathFolderList)) && isempty(find(strcmpi(varargin,'rootonly'), 1))
        if size(RootPathFolderList,1) > 20 && boolLongSearchNotified == 0
            disp(sprintf('%s: Warning, many subdirectories are going to be searched. This search may take some time.',mfilename))
            boolLongSearchNotified = 1;
        end
        for folderLoop = 1:size(RootPathFolderList,1)
            
            %%% LOOK IN CURRENT SUBFOLDER
            path = strcat(strRootPath,RootPathFolderList{folderLoop,1},filesep);
            if nargin==0; disp(sprintf(' searching subdir %s',path)); end
            [boolFileFound,strucMess] = fileattrib(fullfile(path,strNameToLookFor));
            if boolFileFound
                cellstrFolderList = [cellstrFolderList;{strucMess.Name}']; %#ok<AGROW>
            end
            
            % LOOK FOR SUBFOLDERS IN CURRENT SUBFOLDER
            cellstrCurrentFolderList = SearchTargetFolders2(path,strNameToLookFor);
            cellstrFolderList = unique([cellstrFolderList;cellstrCurrentFolderList]);
        end
    end

end
