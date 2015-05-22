function bspie(scores,offset,txtlabels)
% bspie: made by berend. diggety!

if nargin==0
    figure;
    scores = [3 7 1 20];
end
if any(scores<0)
    fprintf('%s: setting negative scores to 0...\n',mfilename)
    scores(scores<0) = 0;
end
theta0 = pi/2;
maxpts = 360;
parts = numel(scores);
x = ones(1,parts) / parts;
% inversion...
matColorMap = smoothcolormap(colormap(jet),parts);
scores = flipud(scores(:));
if nargin>2
    txtlabels = flipud(txtlabels(:));
end

h=NaN(1,parts);
for i=1:parts
    n = max(1,ceil(maxpts*x(i)));
    r = [0;ones(n+1,1);0] * scores(i);
    theta = theta0 + [0;x(i)*(0:n)'/n;0]*2*pi;
    [xx,yy] = pol2cart(theta,r);
    if nargin>1
        xx = xx + offset(1);
        yy = yy + offset(2);
    end
    theta0 = max(theta);
    h(i) = patch('XData',xx,'YData',yy,'CData',i*ones(size(xx)),'FaceColor',matColorMap(i,:),'LineStyle','none');
    
    if nargin>2
        [xtext,ytext] = pol2cart(theta0 + x(i)*pi,scores(i)*1.1);
        xtext = xtext + offset(1);
        ytext = ytext + offset(2);        
        text(xtext,ytext,txtlabels{i},'HorizontalAlignment','left','rotation',(360*((i+.5)/parts)) + 90,'FontSize',6,'FontName','Arial');
%         if i==parts
%             text(xtext,ytext,txtlabels{1},'HorizontalAlignment','left','rotation', (360*((i+.5)/parts)) + 90,'FontSize',6,'FontName','Arial');
%         else
%             text(xtext,ytext,txtlabels{i+1},'HorizontalAlignment','left','rotation',(360*((i+.5)/parts)) + 90,'FontSize',6,'FontName','Arial');
%         end
    end
end