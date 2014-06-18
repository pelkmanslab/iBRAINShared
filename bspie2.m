function bspie2(scores,offset,txtlabels)
% bspie2: made by berend. diggety!

if nargin==0
    figure;
    scores = [3 7 1 20];
end
theta0 = pi/2;
maxpts = 360;
parts = numel(scores);
x = ones(1,parts) / parts;
matColorMap = smoothcolormap(colormap(jet),parts);

h=NaN(1,parts);
for i=1:parts
    n = max(1,ceil(maxpts*x(i)));
%     r = [0;ones(n+1,1);0] * scores(i);
    r = [0;ones(n+1,1);0]/2;
    theta = theta0 + [0;x(i)*(0:n)'/n;0]*2*pi;
    [xx,yy] = pol2cart(theta,r);
    if nargin>1
        xx = xx + offset(1);
        yy = yy + offset(2);
    end
    theta0 = max(theta);
    h(i) = patch('XData',xx,'YData',yy,'CData',i*ones(size(xx)),'FaceColor',matColorMap(i,:),'FaceAlpha',scores(i),'linestyle','none');
    
    if nargin>2
        [xtext,ytext] = pol2cart(theta0 + x(i)*pi,scores(i)*1.1);
        xtext = xtext + offset(1);
        ytext = ytext + offset(2);        
        text(xtext,ytext,2,txtlabels{i},'HorizontalAlignment','center');    
    end
end