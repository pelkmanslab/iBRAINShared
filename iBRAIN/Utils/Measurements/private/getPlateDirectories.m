function cellOutput = getPlateDirectories(strRootPath)
%
% cellOutput = getPlateDirectories(strRootPath)
%
% loads a list of plate directories from iBRAIN database, which should be
% up to date, so we don't need to check for existence of certain
% measurements :) 

if nargin==0
    strRootPath = npc('Y:\Data\Users\Prisca\090403_A431_Dextran_GM1');
end

% init output
cellOutput = {};

matDataIX = strfind(strRootPath,'Data');
strShareNum = strRootPath(matDataIX-4);
strXmlDir = strrep(strRootPath(matDataIX:end),'\','__');
strXmlDir = strrep(strXmlDir,'/','__');

strXmlPath = sprintf('\\\\nas-biol-imsb-1\\share-2-$\\Data\\Code\\iBRAIN\\database\\project_xml\\__BIOL__imsb__fs%s__bio3__bio3__%s',strShareNum,strXmlDir);

if ~fileattrib(strXmlPath)
    fprintf('%s: no such path in iBRAIN database: ''%s''\n',mfilename,strXmlPath)
    return
end

cellFiles = CPdir(strXmlPath);
cellFiles = struct2cell(cellFiles)';
cellFiles = cellFiles(~cellfun(@isempty,strfind(cellFiles(:,1),'.xml')),1);
strXmlFile = fullfile(strXmlPath,cellFiles{end});

fid = fopen(strXmlFile);
tline = fgetl(fid);
while ischar(tline)
    tline = strtrim(tline);
    if strncmp(tline,'<batch_dir>',11)
        tline = tline(12:end-12);
        cellOutput = cat(1,cellOutput,{npc(sprintf('http://www.ibrain.ethz.ch%s',tline))});
    end
    tline = fgetl(fid);
end

fclose(fid);

end