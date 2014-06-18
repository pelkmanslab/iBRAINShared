function Convert_ADVANCEDDATA2_to_full_csv_iBRAIN(strRootPath)

if nargin==0
    strRootPath = 'Y:\Data\Users\50K_final_reanalysis\Ad3_KY_NEW';
end
strRootPath = npc(strRootPath);

load(fullfile(strRootPath,'ADVANCEDDATA2.mat'));
filename = fullfile(strRootPath,'ADVANCEDDATA2_full.csv');
fields = fieldnames(ADVANCEDDATA);
genes=size(ADVANCEDDATA.(fields{1}),2);
table = cell(genes,0);
header = {};

row_index=1;
for gene = 1:genes
    oligos=ADVANCEDDATA.OligoNumber{gene};
    for oligo=unique(oligos)'
        row_index=row_index+1;
        col_index=0;
        for head=1:length(fields)
            data=ADVANCEDDATA.(fields{head}){gene};
            if isa(data,'double');
                try
                    data2=nanmedian(data(oligos==oligo,:));
                    if size(data2,2)>1
                        for i=1:size(data2,2)
                            col_index=col_index+1;
                            table{row_index,col_index} = num2str(data2(i));
                            header{col_index}=[fields{head},'_',num2str(i)];
                        end
                    else
                        col_index=col_index+1;
                        table{row_index,col_index} = num2str(data2);
                        header{col_index}=fields{head};
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
                        header{col_index}=fields{head};
                    else
                        data2=data2{1};
                        col_index=col_index+1;
                        if isa(data2,'double')
                            table{row_index,col_index} = data2(1);
                        else
                            table{row_index,col_index} = data2;
                        end
                        header{col_index}=fields{head};
                    end
                end
            end

        end
    end
end
table(1,:)=header';

writelists(table,filename,[],';')

