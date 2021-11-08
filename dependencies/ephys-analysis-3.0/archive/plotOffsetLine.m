function plotOffsetLine(dat,tm,scale,corticaldepth)
if nargin < 4
    corticaldepth = 1:size(dat,2);
    ytickoff = false; 
end


offset = scale * [-1:-1:-length(corticaldepth)];
dat    = bsxfun(@plus,dat,offset);

plot([min(tm) max(tm)],[offset; offset],'m','LineWidth',0.5); hold on
plot(tm,dat,'b','LineWidth',1.5);
ylim([min(offset) + diff(offset(1:2)/2) max(offset) - diff(offset(1:2))/2])
xlim([min(tm) max(tm)]);
plot([0 0],ylim,'k');
set(gca,'Box','off','TickDir','out')
if ytickoff
    set(gca,'YTick',[])
else
    set(gca,'YTick',fliplr(offset(1:4:end)),'YTickLabel',fliplr(corticaldepth(1:4:end)));
end
ylabel(sprintf('y minor = +/- %0.2f',scale))

end