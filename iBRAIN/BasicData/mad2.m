function out=mad2(in)
good=find(not(isnan(in)).*not(isinf(in)));
if isempty(good)
	out=NaN;
else
	out=mad(in(good),1);
end