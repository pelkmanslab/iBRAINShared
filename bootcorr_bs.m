function z = bootcorr_bs(x)

z = nan;
if size(x,1) > 1
    z = mean(bootstrp(10,@(x) corr(x(:,1),x(:,2)),x));
end

end