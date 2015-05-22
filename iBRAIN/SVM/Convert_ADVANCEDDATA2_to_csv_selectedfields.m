function Convert_ADVANCEDDATA2_to_full_csv_iBRAIN_per_gene(strRootPath)

if nargin==0
    strRootPath = 'X:\Data\Users\YF_DG';
    strRootPath = npc(strRootPath);
end

strAssayName = getlastdir(strRootPath);

load(fullfile(strRootPath,'ADVANCEDDATA2.mat'));
filename = fullfile(strRootPath,sprintf('ADVANCEDDATA2_%s_per_gene_selected.csv',getlastdir(strRootPath)));
fields = fieldnames(ADVANCEDDATA);

% make sure the plot starts with gene_id and gene_symbol
startfields = {'GeneData'; 'GeneID'; 'Images'; 'PlateNumber'; 'BatchNumber'};
fields(ismember(fields,startfields))=[];
fields = [startfields;fields];

% fields to only process once
cellstrSingleFields = {'GeneData','GeneID','Images','PlateNumber','BatchNumber'}; %

% fields to process at all
%cellstrIncludedFields = fieldnames(ADVANCEDDATA)
cellstrIncludedFields = {...
    'GeneData',...
    'GeneID',...
    'Images',...
    'PlateNumber',...
    'BatchNumber',...
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
%
% % potential hits to exclude in any case
cellstrExtraFieldsToSkip = {' '};%{'CellTypeOverviewSVM*'};

genes=size(ADVANCEDDATA.(fields{1}),2);
table = cell(genes,0);
header = {};


row_index=1;
for gene = 1:genes
    gene
    oligos=ADVANCEDDATA.OligoNumber{gene};
    row_index=row_index+1

    col_index=0;

    for head=1:length(fields)
        data=ADVANCEDDATA.(fields{head}){gene};
        if not(isempty(data))
            % check if this field should processed at all (opt-in)
            if sum(~cellfun(@isempty,regexp(fields{head}, cellstrIncludedFields)))==0 || ...
                    sum(~cellfun(@isempty,regexp(fields{head}, cellstrExtraFieldsToSkip)))>0
                continue
            end

            % check if this field should only be processed once
            boolSingleField = 0;
            if sum(~cellfun(@isempty,regexp(fields{head}, cellstrSingleFields)))>0
                boolSingleField = 1;
            end

            % keep track of how many oligos for this field we have processed
            oligocounter = 0;
            for oligo=unique(oligos)'

                % mention fields listed in cellstrSingleFields only once, not
                % for all oligos separately
                oligocounter = oligocounter + 1;
                if boolSingleField & oligocounter > 1
                    continue
                end

                if isa(data,'double');
                    try
                        data2=nanmedian(data(oligos==oligo,:));
                        if size(data2,2)>1
                            for i=1:size(data2,2)
                                col_index=col_index+1;
                                table{row_index,col_index} = num2str(data2(i));
                                %                             header{col_index}=[fields{head},'_',num2str(i)];
                                if boolSingleField
                                    header{col_index}=sprintf('%s_%s_%d',strAssayName,fields{head},i);
                                else
                                    header{col_index}=sprintf('%s_%s_%d_O%d',strAssayName,fields{head},i,oligo);
                                end
                            end
                        else
                            col_index=col_index+1;
                            table{row_index,col_index} = num2str(data2);
                            if boolSingleField
                                header{col_index}=sprintf('%s_%s',strAssayName,fields{head});
                            else
                                header{col_index}=sprintf('%s_%s_O%d',strAssayName,fields{head},oligo);
                            end
                        end
                    catch bla
                        col_index=col_index+1;
                        table{row_index,col_index} = num2str(NaN);
                        if boolSingleField
                            header{col_index}=sprintf('%s_%s',strAssayName,fields{head});
                        else
                            header{col_index}=sprintf('%s_%s_O%d',strAssayName,fields{head},oligo);
                        end
                    end
                elseif isa(data,'cell');
                    % from textual fields selecting only the first one of the
                    % replicas
                    try
                        data2=data(oligos==oligo,:);
                        if size(data2,2)>1
                            col_index=col_index+1;
                            str='';
                            for i=1:size(data2,2)
                                foo= data2{1,i};
                                str(end+1:end+length(foo)+5)=[num2str(i),': ',foo,', '];
                            end
                            str=str(1:end-2);
                            table{row_index,col_index}=str;
                        else
                            data2=data2{1};
                            col_index=col_index+1;
                            if isa(data2,'double')
                                table{row_index,col_index} = data2(1);
                            else
                                table{row_index,col_index} = data2;
                            end
                        end
                        if boolSingleField
                            header{col_index}=sprintf('%s_%s',strAssayName,fields{head});
                        else
                            header{col_index}=sprintf('%s_%s_O%d',strAssayName,fields{head},oligo);
                        end

                    end
                end % if double/cell/char
            end % oligo
            
            % if not boolSingleField, and data type is double, let's add a
            % medmed field here...
            if isa(data,'double');
                try
                    % calculate med-med
                    data3 = [];
                    for oligo2=unique(oligos)'
                        data3=[data3,nanmedian(data(oligos==oligo2,:))];
                    end
                    data3 = nanmedian(data3);

                    if numel(data3)==1
                        col_index=col_index+1;
                        table{row_index,col_index} = num2str(data3);
                        header{col_index}=sprintf('%s_%s_MedMed',strAssayName,fields{head});
                    else
                        col_index=col_index+1;
                        table{row_index,col_index} = num2str(NaN);
                        header{col_index}=sprintf('%s_%s_MedMed',strAssayName,fields{head});
                    end
                end
            end
        end
    end % head
end % gene
table(1,:)=header';

try
    writelists(table,filename,[],';')
    disp(sprintf('%s: Saved %s',mfilename,filename))
catch bla
    disp(sprintf('%s: !!! Failed to store %s',mfilename,filename))
end
