% A first version of 3d mutual information
% Uses quantile binning for 1d, 2d, and 3d entropy calculations
function [I,TotalCorrelation]=mutual_information_3d5(x1,x2,x3)
N=length(x1);
bins=3;

h=histogram3d(x1,x2,x3,bins);

%% histogram calculation
% NColX = size(x1,2);
% 
% ncellx = bins;
% ncelly = ncellx;
% ncellz = ncellx;
% 
% quantx = quantile(x1,0:1/ncellx:1);
% quanty = quantile(x2,0:1/ncelly:1);
% quantz = quantile(x3,0:1/ncelly:1);
% 
% h=zeros(ncellx,ncelly,ncellz);
% 
% % make the bin edges open ended, just to be sure
% quantx(1) = -Inf;
% quantx(end) = Inf;
% quanty(1) = -Inf;
% quanty(end) = Inf;
% quantz(1) = -Inf;
% quantz(end) = Inf;
% 
% [foo,xx]=histc(x1,quantx);
% [foo,yy]=histc(x2,quanty);
% [foo,zz]=histc(x3,quantz);
% 
% for n=1:NColX
%   indexx=xx(n);
%   indexy=yy(n);
%   indexz=zz(n);
%   if indexx >= 1 & indexx <= ncellx & indexy >= 1 & indexy <= ncelly & indexz >= 1 & indexz <= ncellz
%     h(indexx,indexy,indexz)=h(indexx,indexy,indexz)+1;
%   end;
% end;


%% mutual information calculation

Hx=zeros(1,3);
Hxy=zeros(1,3);
Hxyz=0;

for dim=1:3
    for i=1:bins
        
        % calculate the single entropy
        if dim==1
            k=h(i,:,:);
        elseif dim==2
            k=h(:,i,:);
        else
            k=h(:,:,i);
        end
        p=sum(k(:))/N;
        if p>0
            Hx(dim)=Hx(dim)-p*log(p);
        end
        
        % calculate the double entropy
        for j=1:bins
            if dim==1
                k=h(i,j,:);
            elseif dim==2
                k=h(i,:,j);
            else
                k=h(:,i,j);
            end
            p=sum(k(:))/N;
            if p>0
                Hxy(dim)=Hxy(dim)-p*log(p);
            end
            
            
            % calculate the triple entropy (only once)
            if dim==1
                for k=1:bins
                    k=h(i,j,k);

                    p=k/N;
                    if p>0
                        Hxyz=Hxyz-p*log(p);
                    end
                end
            end

        end %j
    end %i
end %dim

I=sum(Hx)-sum(Hxy)+Hxyz;
TotalCorrelation=Hx(1)+Hx(2)-Hxy(1) + Hx(1)+Hx(3)-Hxy(2) + Hx(2)+Hx(3)-Hxy(3) + I;