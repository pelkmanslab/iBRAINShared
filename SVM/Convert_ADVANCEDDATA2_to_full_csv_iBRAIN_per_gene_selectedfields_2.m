function Convert_ADVANCEDDATA2_to_full_csv_iBRAIN_per_gene_selectedfields(strRootPath)

if nargin==0
    strRootPath = 'Z:\Data\Users\VSV_DG';
    strRootPath = npc(strRootPath);
end

strAssayName = getlastdir(strRootPath);

load(fullfile(strRootPath,'ADVANCEDDATA2.mat'));
filename = fullfile(strRootPath,sprintf('ADVANCEDDATA2_%s_per_gene_selected_temp.csv',getlastdir(strRootPath)));
fields = fieldnames(ADVANCEDDATA);

% make sure the plot starts with gene_id and gene_symbol
startfields = {'GeneData'; 'GeneID'; 'OligoNumber'; 'ReplicaNumber'};
fields(ismember(fields,startfields))=[];
fields = [startfields;fields];

% fields to only process once
cellstrSingleFields = {'GeneData','GeneID','Images','PlateNumber','BatchNumber'}; %

% fields to process at all
%cellstrIncludedFields = fieldnames(ADVANCEDDATA)
cellstrIncludedFields = {...
    'GeneData',...
    'GeneID',...
    'OligoNumber',...
    'ReplicaNumber',...
    'TotalCells',...
    'CellTypeOverviewZScoreLog2RelativeCellNumber',...
    'CellTypeOverviewInfectedSVMNumber',...
    'CellTypeOverviewInfectedSVMIndex',...
    'CellTypeOverviewZScoreLog2InfectedSVMIndex',...
    'CellTypeOverviewZScoreLog2MitoticIndex',...
    'CellTypeOverviewZScoreLog2ApoptoticIndex'...
    %     'ModelRawII',...
    %     'ModelRawZSCORELOG2RII',...
    %     'ModelCorrectedII',...
    %     'ModelCorrectedZSCORELOG2RII',...
    %     'ModelPredictedII',...
    %     'ModelPredictedZSCORELOG2RII',...
    %     'CellTypeOverview.*'...
    };

genes=size(ADVANCEDDATA.(fields{1}),2);
cellOutput = cell(genes,0);
header = {};

% let's check for the entire screen what the maximum oligo number present
% is.
intMaxOligoNumberInData = nanmax(cat(1,ADVANCEDDATA.OligoNumber{:}));

row_index=1;
for gene = 1:genes
    gene
    % look up oligo info for current gene
    oligos=ADVANCEDDATA.OligoNumber{gene};
    uniqueoligos=unique(oligos);
    
    % check if this meets our expectations
    if ~isequal(uniqueoligos,[1:intMaxOligoNumberInData]')
        warning('%s: Note, not all %d oligos are present for gene %d',mfilename,intMaxOligoNumberInData,gene)
        uniqueoligos = [1:intMaxOligoNumberInData]';
    end
    
    for fieldindex=1:length(cellstrIncludedFields)

        % check if this field should only be processed once, or that we
        % should give values per oligo, and calculate a med-med value.
        boolSingleField = 0;
        if sum(~cellfun(@isempty,regexp(fields{fieldindex}, cellstrSingleFields)))>0
            boolSingleField = 1;
        end

        % get the current data, note that this can have different
        % class-types.
        data=ADVANCEDDATA.(fields{fieldindex}){gene};

        % if this field should only be processed once, let's check if it
        % has only one unique value
        if boolSingleField
            
            % check if there is only one unique value
            if length(unique(data))>1
                warning('%s: Note, field %s is set to be only processed once, but it has multiple unique values for gene %d.',mfilename,fields{fieldindex},gene)
            end            
        end
        
        
        
        end
    end % head
end % gene

cellOutput(1,:)=header';

try
    writelists(cellOutput,filename,[],';')
    disp(sprintf('%s: Saved %s',mfilename,filename))
catch bla
    disp(sprintf('%s: !!! Failed to store %s',mfilename,filename))
end
