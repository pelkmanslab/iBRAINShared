function [intCPNumber, intReplicaNumber, intBatchNumber] = filterplatedata(strPath)
% Help for filterplatedata
%
% put in a path of a correctly labelled plate, and it will spit out
% cell-plate number, replica number and batch number where available.
%
% Usage:
%
% [intCPNumber, intReplicaNumber, intBatchNumber] = filterplatedata(strPath)
%
% Cheers, Berend.

    if nargin==0
    % 	strPath='Z:\Data\Users\Others\Jean_Philippe\HCT116KS-BDimages\p53-BaTcH1_CP022-1fd\BATCH';
    % 	strPath='\\nas-biol-imsb-1\share-2-$\Data\Users\Raphael\070611_Tfn_kinase_screen\070610_Tfn_MZ_kinasescreen_CP045-1cd';
%         strPath='070610_Tfn_MZ_kinasescreen_CP068-1cd';
        strPath='/100215_A431_Actin_LDL_CP393-1bi/BATCH';
        
    end

    intCPNumber = 0;
    intReplicaNumber = 0;
    intBatchNumber = 0;

    strPlateName = upper(strPath);
    strPlateName = strrep(strPlateName,[filesep,'BATCH'],'');
    strPlateName = strrep(strPlateName,[filesep,'DATAFUSION'],'');

	if not(isempty(strfind(strPath, filesep)))
        [~, strPlateName] = fileparts(strPlateName);
% 		strPlateName = getlastdir(strPlateName);
%         strPlateName = strrep(strPlateName,filesep,'');
	end

    strCPInfo = regexpi(strPlateName,'CP(\d{2,})[-|_](\d)(\w)(\w)','tokens');
    if isempty(strCPInfo)
        strCPInfo = regexpi(strPlateName,'CP(\d{2,})','tokens');
        if ~isempty(strCPInfo)
            intCPNumber = str2double(strCPInfo{1}{1});
            intReplicaNumber = double(strPlateName(end))-64;
        else
            intCPNumber = NaN;
            intReplicaNumber = NaN;
        end
    else
        if nargin==0
            strCPInfo{1}
        end
        intCPNumber = str2double(strCPInfo{1}{1});
        intReplicaNumber = double(strCPInfo{1}{4})-64;
    end

    if intReplicaNumber<0; intReplicaNumber = NaN; end
    
    strBatchInfo = regexpi(strPlateName,'[-|_]BATCH(\d{1,})','tokens');
    if ~isempty(strBatchInfo)
        intBatchNumber = str2double(strBatchInfo{1}{1});
    end

%     try
%         if isempty(regexp(strPlateName,'batch\dCP', 'ONCE'))
%             platenumindx = strfind(strPlateName,'_CP')+3:strfind(strPlateName,'-')-1;
%         else
%             platenumindx = strfind(strPlateName,'CP')+2:strfind(strPlateName,'-')-1;
%         end
%         if isnumeric(str2double(strPlateName([platenumindx])))    
%             intCPNumber = str2double(strPlateName([platenumindx])); % CP NUMBER
%         end
%     end
% 
%     try
%         batchnumindx = strfind(strPlateName,'_BATCH')+6;
% 
%         if isnumeric(str2double(strPlateName(batchnumindx)))
%             intBatchNumber = str2double(strPlateName(batchnumindx)); % BATCH NUMBER
%         end
%     end
% 
%     try
%         replicaindx = length(strPlateName);
%         if isnumeric(strPlateName(replicaindx(end)) - 96)
%             intReplicaNumber = strPlateName(replicaindx(end)) - 96; % CP REPLICATE NUMBER
%         end
%     end

end
