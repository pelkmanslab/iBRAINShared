% A first version of 3d mutual information
% Uses quantile binning for 1d, 2d, and 3d entropy calculations
function [I,TotalCorrelation]=mutual_information_3d(x1,x2,x3)
N=length(x1);
bins=3;
h=histogram3d(x1,x2,x3,bins);

for dim=1:3
    Hx(dim)=0;
    for i=1:bins
        if dim==1
            k=h(i,:,:);
        elseif dim==2
            k=h(:,i,:);
        else
            k=h(:,:,i);
        end
        p=sum(k(:))/N;
        Hx(dim)=Hx(dim)-p*own_log2(p);
    end
end

for dim=1:3
    Hxy(dim)=0;
    for i=1:bins
        for j=1:bins
            if dim==1
                k=h(i,j,:);
            elseif dim==2
                k=h(i,:,j);
            else
                k=h(:,i,j);
            end
            p=sum(k(:))/N;
            Hxy(dim)=Hxy(dim)-p*own_log2(p);
        end
    end
end

Hxyz=0;
for i=1:bins
    for j=1:bins
        for k=1:bins
            k=h(i,j,k);
      
            p=k/N;
            Hxyz=Hxyz-p*own_log2(p);
        end
    end
end

I=sum(Hx)-sum(Hxy)+Hxyz;
TotalCorrelation=Hx(1)+Hx(2)-Hxy(1) + Hx(1)+Hx(3)-Hxy(2) + Hx(2)+Hx(3)-Hxy(3) + I;


% %check
% hy=sum(h(:,:,1));
% hx=sum(h(:,:,1)');
% estimate=0;
% count=0;
% for nx=1:bins
%   for ny=1:bins
%     if h(nx,ny,1)~=0 
%       logf=log(h(nx,ny,1)/hx(nx)/hy(ny));
%     else
%       logf=0;
%     end;
%     count=count+h(nx,ny);
%     estimate=estimate+h(nx,ny)*logf;
%   end;
% end;
% 
% % biased estimate
% estimate=estimate/count;
% estimate=estimate+log(count)
% 
% I2d=Hx(1)+Hx(2)-Hxy(1)



% 
% for i=1:3
%     pp(i,:)=[sum(x(:,i)==1)/N sum(x(:,i)==2)/N sum(x(:,i)==3)/N];
% end
% 
% % 1d entropies
% for i=1:3
%     Hx(i)=0;
%     for n=1:N
%         value=x(n,i);
%         p=pp(i,value);%sum(x(:,i)==value)/N;
%         Hx(i)=Hx(i)-p*own_log2(p);
%     end
% end
% 
% % 2d entropies
% for c=1:3 
%     Hxy(c)=0;
%     if c==1
%         v=[1 2];
%     elseif c==2
%         v=[1 3];
%     else
%         v=[2 3];
%     end
%     xx=x(:,v);
%     for n=1:N
%         value=x(n,v);
%         p=pp(v(1),value(1))*pp(v(2),value(2));%sum(ismember(xx,value,'rows'))/N;
%         Hxy(c)=Hxy(c)-p*own_log2(p);
%     end
% end
% 
% % 3d entropy
% Hxyz=0;
% for n=1:N
%     value=x(n,:);
%     p=pp(1,value(1))*pp(2,value(2))*pp(3,value(3));%sum(ismember(x,value,'rows'))/N;
%     Hxyz=Hxyz-p*own_log2(p);
% end
% 
% % Mutual information according to Srinivasa
% I=sum(Hx)-sum(Hxy)+Hxyz;
% TotalCorrelation=Hx(1)+Hx(2)-Hxy(1) + Hx(1)+Hx(3)-Hxy(2) + Hx(2)+Hx(3)-Hxy(3) + I;
% 
% 
% % function that does not crash with p=0
function out=own_log2(in)
out=log2(in);
if in==0
    out=0;
end