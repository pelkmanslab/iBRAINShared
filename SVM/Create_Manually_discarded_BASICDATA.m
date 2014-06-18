clear
path='X:\Data\Users\YF_DG\';

fid=fopen([path,'Manually_discarded_data.txt'],'r'); 

read_wells=0;
read_plates=0;
well_index=0;
plate_index=0;
well_col=[];
plate_number=[];
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    if not(isempty(tline))
        c = textscan(tline,'%s','Delimiter','\t');
        if not(strcmp(c{1}{1}(1),'%'))
            if not(isempty(strfind(c{1}{1},'wells:')))
                read_wells=1;
                read_plates=0;
                continue;
            elseif not(isempty(strfind(c{1}{1},'plates:')))
                read_plates=1;
                read_wells=0;
                continue;
            else
                if read_wells==1
                    well_index=well_index+1;
                    str=c{1}{1};
                    str2=regexp(str,', ','split');
                    well_str=str2{1};
                    batch_str=str2{2};

                    well_col(well_index)=str2double(regexpi(well_str,'\d{1,}','Match'));
                    well_row(well_index)=char(regexpi(well_str,'\D','Match'))-64;

                    if not(isempty(strfind(batch_str,'all')))
                        batch_number(well_index)=inf;
                    else
                        batch_number(well_index)=str2double(regexpi(batch_str,'\d{1,}','Match'));
                    end
                    
                elseif read_plates==1
                    plate_index=plate_index+1;
                    str=c{1}{1};
                    str2=regexp(str,' ','split');
                    plate_name=str2{1};
                    [plate_number(plate_index) replica_number(plate_index)]=filterplatedata(plate_name);
                end
            end
        end
    end
end

load([path,'BASICDATA']);
fields=fieldnames(BASICDATA);
BASICDATA_Manual=BASICDATA;

for i=1:length(well_col)
    if isinf(batch_number(i))
        indices=BASICDATA.WellRow==well_row(i)&BASICDATA.WellCol==well_col(i);
    else
        indices=BASICDATA.WellRow==well_row(i)&BASICDATA.WellCol==well_col(i)&BASICDATA.BatchNumber==batch_number(i);
    end
    for f=1:length(fields)
        if isnumeric(BASICDATA_Manual.(fields{f})) && not(iscell(BASICDATA_Manual.(fields{f})))...
                && not(strcmp(fields{f},'OligoNumber'))...
                && not(strcmp(fields{f},'Images'))...
                && not(strcmp(fields{f},'PlateNumber'))...
                && not(strcmp(fields{f},'ReplicaNumber'))...
                && not(strcmp(fields{f},'BatchNumber'))...
                && not(strcmp(fields{f},'RawImages'))...
                && not(strcmp(fields{f},'WellRow'))...
                && not(strcmp(fields{f},'WellCol'))
            BASICDATA_Manual.(fields{f})(indices)=NaN;         
        end
    end
end

for i=1:length(plate_number)
    indices=BASICDATA.PlateNumber==plate_number(i)&BASICDATA.ReplicaNumber==replica_number(i);
    for f=1:length(fields)
        if isnumeric(BASICDATA_Manual.(fields{f})) && not(iscell(BASICDATA_Manual.(fields{f})))...
                && not(strcmp(fields{f},'OligoNumber'))...
                && not(strcmp(fields{f},'Images'))...
                && not(strcmp(fields{f},'PlateNumber'))...
                && not(strcmp(fields{f},'ReplicaNumber'))...
                && not(strcmp(fields{f},'BatchNumber'))...
                && not(strcmp(fields{f},'RawImages'))...
                && not(strcmp(fields{f},'WellRow'))...
                && not(strcmp(fields{f},'WellCol'))
            BASICDATA_Manual.(fields{f})(indices)=NaN;
        end
    end
end
    
save( [path,'BASICDATA_Manual'],'BASICDATA_Manual') 



