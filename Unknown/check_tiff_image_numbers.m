strRootPath = '\\nas-biol-imsb-1\share-2-$\Data\Users\VSV_DG\';


dirlist = CPdir(strRootPath);
isdir = cat(1,dirlist.isdir);
dirlist = cat(1,{dirlist.name});
dirlist(~isdir) = [];
dirlist(cellfun(@isempty,regexpi(dirlist,'.*_CP\d{3,}.*'))) = [];
fprintf('%s: %d PLATES FOUND IN %s\n\n',mfilename,length(dirlist),strRootPath)

matPngCount=nan(length(dirlist),1);
for i = 1:length(dirlist)
    matTmpList = CPdir(fullfile(strRootPath,dirlist{i},'TIFF'));
    matPngCount(i,1) = sum(~cellfun(@isempty,strfind(cat(1,{matTmpList.name}),'.png')));
    fprintf('CHECKED %s: %d IMAGES\n',dirlist{i},matPngCount(i,1))
end
