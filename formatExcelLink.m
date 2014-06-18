function strOut = formatExcelLink(GeneInfo)
%
% This will format GeneIDs or GeneSymbols to excel-formatted hyperlinks!
%
% if input is number, treated as GeneID and will output a link to
% ncbi/pubmed
%
% if input is string, treated as gene symbol and will output a link to
% genecard
%
% cheerios!
% Berend

if iscell(GeneInfo)
    strOut = cellfun(@formatExcelLink2,GeneInfo,'UniformOutput',false);
else
    strOut = arrayfun(@formatExcelLink2,GeneInfo,'UniformOutput',false);
end

function strOut = formatExcelLink2(GeneInfo)

strOut = '';
if isempty(GeneInfo)
    return
end

% if we find a hyperlink, remove it, otherwise, add it :)
boolRemovedLink = false;
if ischar(GeneInfo) 
    if strncmp(GeneInfo,'=HYPERLINK("http://',19)
        matIX = strfind(GeneInfo,'"');
        strOut = GeneInfo(matIX(end-1)+1:matIX(end)-1);
        
        % convert to number if thats reasonable...
        if isequal(num2str(str2double(strOut)),strOut)
            strOut = str2double(strOut);
        end
        boolRemovedLink = true;
    end
end

if ~boolRemovedLink
    if ischar(GeneInfo) && ~isequal(num2str(str2double(GeneInfo)),GeneInfo)
        strOut = sprintf('=HYPERLINK("http://www.genecards.org/cgi-bin/carddisp.pl?gene=%s","%s")',GeneInfo,GeneInfo);
    elseif isnumeric(GeneInfo)
        strOut = sprintf('=HYPERLINK("http://www.ncbi.nlm.nih.gov/gene/%d","%d")',GeneInfo,GeneInfo);
    elseif isequal(num2str(str2double(GeneInfo)),GeneInfo)
        strOut = sprintf('=HYPERLINK("http://www.ncbi.nlm.nih.gov/gene/%s","%s")',GeneInfo,GeneInfo);
    end
end