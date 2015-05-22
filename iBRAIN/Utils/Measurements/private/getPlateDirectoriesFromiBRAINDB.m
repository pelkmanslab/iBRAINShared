function cellOutput = getPlateDirectoriesFromiBRAINDB(strRootPath,varargin)
%
% cellOutput = getPlateDirectoriesFromiBRAINDB(strRootPath)
%
% loads a list of plate directories (BATCH) from iBRAIN database, which
% should be up to date, so we don't need to check for existence of certain
% measurements :) 
%
%
% cellOutput = getPlateDirectoriesFromiBRAINDB(strRootPath, 'basicdata')
%
% input option 'basicdata' returns basicdata files rather than BATCH
% directories (default) 
%
% input option 'platejpgs' returns plate overview jpg files rather than
% BATCH directories (default) 
% 

if nargin==0
    strRootPath = npc('\\nas-biol-imsb-1.d.ethz.ch\share-2-$\Data\Users\SV40_DG');
%     strRootPath = npc('\\nas-biol-imsb-1.d.ethz.ch\share-2-$\Data\Users\Cameron\CHOL-LBPA_HELAMZ_QIAGEN_Druggable\');
%     strRootPath = npc('\\nas-biol-imsb-1.d.ethz.ch\share-2-$\Data\Users\Berend\50K_FollowUps\100101_SFV_KY_CB_35h\');
end

% do npc conversion
strRootPath = npc(strRootPath);

% see if the user added the input option 'basicdata' to return basicdata
% files rather than BATCH directories (default)
boolReturnBasicData = false;
if any(strcmpi(varargin,'basicdata'))
    boolReturnBasicData = true;
end

% see if the user added the input option 'basicdata' to return basicdata
% files rather than BATCH directories (default)
boolReturnPlateJpgs = false;
if any(strcmpi(varargin,'platejpgs'))
    boolReturnPlateJpgs = true;
end

% report activity
fprintf('%s: checking %s\n',mfilename,strRootPath)

% init output
cellOutput = {};



% check if last character is either / or \
if strcmp(strRootPath(end),'\') || strcmp(strRootPath(end),'/')
    strRootPath = strRootPath(1:end-1);
end

matDataIX = strfind(strRootPath,'Data');
strShareNum = strRootPath(matDataIX-4);
strXmlDir = strrep(strRootPath(matDataIX:end),'\','__');
strXmlDir = strrep(strXmlDir,'/','__');

strXmlPath = sprintf('\\\\nas-biol-imsb-1\\share-2-$\\Data\\Code\\iBRAIN\\database\\project_xml\\__BIOL__imsb__fs%s__bio3__bio3__%s',strShareNum,strXmlDir);

if ~fileattrib(strXmlPath)
    fprintf('%s: no such path in iBRAIN database: ''%s''\n',mfilename,strXmlPath)
    return
else
    fprintf('%s: checking: ''%s''\n',mfilename,strXmlPath)
end

cellFiles = CPdir(strXmlPath);
cellFiles = struct2cell(cellFiles)';
cellFiles = cellFiles(~cellfun(@isempty,strfind(cellFiles(:,1),'project.xml')),1);

% we should check if the date modified is very evry recent, take the second
% last one, otherwise take the last one...
cellFullFiles = cellfun(@(x) fullfile(strXmlPath,x),cellFiles,'uniformoutput',false);
a = cellfun(@dir,cellFullFiles);
[b,ix]=sort(cat(1,a.datenum),'descend');

% if the newest file is more than 5 minutes old, take that one, otherwise
% take the second newest file, as the first one might still be edited...
s1 = dir(fullfile(strXmlPath,cellFiles{ix(1)}));
if now>addtodate(b(1),5,'minute') & s1.bytes > 1024;
    strXmlFile = fullfile(strXmlPath,cellFiles{ix(1)});
else
    strXmlFile = fullfile(strXmlPath,cellFiles{ix(2)});
end

fid = fopen(strXmlFile);
tline = fgetl(fid);
while ischar(tline)
    tline = strtrim(tline);

    if ~boolReturnBasicData && ~boolReturnPlateJpgs
        % we found a plate
        if strncmp(tline,'<batch_dir>',11)
            tline = tline(12:end-12);
            cellOutput = cat(1,cellOutput,{npc(sprintf('http://www.ibrain.ethz.ch%s',tline))});
        end

    elseif boolReturnBasicData
        % we can also list BASICDATA_*.mat files per plate if the user
        % requests, and if we find it in the 
        if strncmp(tline,'<file type="plate_basic_data_mat">',34)
            tline = tline(35:end-7);
            cellOutput = cat(1,cellOutput,{npc(sprintf('http://www.ibrain.ethz.ch%s',tline))});
        end

    elseif boolReturnPlateJpgs
        % we can also list BASICDATA_*.mat files per plate if the user
        % requests, and if we find it in the 
        if strncmp(tline,'<file type="plate_overview_jpg">',32)
            tline = tline(33:end-7);
            cellOutput = cat(1,cellOutput,{npc(sprintf('http://www.ibrain.ethz.ch%s',tline))});
        end
        
    end
    
    % get next line
    tline = fgetl(fid);
end

fclose(fid);

end