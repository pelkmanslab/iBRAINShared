% A first version of 3d mutual information
% Uses binning for 1d, 2d, and 3d entropy calculations
% TRY WITH QUANTILEs!
function I=mutual_information_3d(x1,x2,x3)
N=length(x1);
bins=ceil(N^(1/3));

x=[x1,x2,x3];

x=x-repmat(min(x),[N 1]);
x=floor(x./repmat(max(x)+0.00000001,[N 1])*bins)+1;

% 1d entropies
for i=1:3
    Hx(i)=0;
    for n=1:N
        value=x(n,i);
        p=sum(x(:,i)==value)/N;
        Hx(i)=Hx(i)-p*own_log2(p);
    end
end

% 2d entropies
for c=1:3
    Hxy(c)=0;
    if c==1
        v=[1 2];
    elseif c==2
        v=[1 3];
    else
        v=[2 3];
    end
    xx=x(:,v);
    for n=1:N
        value=x(n,v);
        p=sum(ismember(xx,value,'rows'))/N;
        Hxy(c)=Hxy(c)-p*own_log2(p);
    end
end

% 3d entropy
Hxyz=0;
for n=1:N
    value=x(n,:);
    p=sum(ismember(x,value,'rows'))/N;
    Hxyz=Hxyz-p*own_log2(p);
end

% Mutual information according to Srinivasa
I=sum(Hx)-sum(Hxy)+Hxyz;

% function that does not crash with p=0
function out=own_log2(in)
out=log2(in);
if in==0
    out=0;
end