% setup electrode array with nel
nel = size(uRF,1);

clear h
h(1) = figure('Position',[0 0 601 874]);
if nel == 32
    subsize = [8 4];
elseif nel <= 24
    subsize = [8 3];
else
    error('unexpected channel number')
end

if all(all(all(isnan(uRF))))
    return
end

% plotting
clear h_color
for rf = 1:nel
    
    elabel2 = elabel{rf};
    titlestr = (sprintf('%s',elabel2));
    
    h_color(rf) = subplot(subsize(1),subsize(2),rf);
    cla
    
    dat = squeeze(uRF(rf,:,:));
    if ~all(all(isnan(dat)))
        imagesc(xcord,ycord,dat); hold on;
        
        if exist('fRF','var')
            centroid = fRF(rf,1:2);
            width    = fRF(rf,3:4);
            rfboundary = [centroid(1)-width(1)/2,centroid(2)-width(2)/2, width(1), width(2)];
            
            if ~any(isnan(rfboundary))
                rectangle('Position',rfboundary,'Curvature',[1,1]);
                %plot(fRF(i,1),fRF(i,2),'ko')
                %plot(fRF(i,5),fRF(i,6),'kx')
            end
            
            if rf <= rflim(2) && rf >= rflim(1)
                titlestr = (sprintf('*%s*',elabel2));
            end
        end
        
        if rf == 1
            title(sprintf('%s - %s\n%s',[RF.header '_' RF.el], upper(rfdatatype),titlestr),'interpreter','none');
        else
            title(titlestr)
        end
        
    end
    
    set(gca,...
        'Ydir','normal',...
        'TickDir','out',...
        'Box','off')
    switch rfdatatype(end-2:end)
        case 'zsr'
            set(gca,'Clim',[-1.02 1] *  max(max(max(abs(uRF)))))
        otherwise
           % clim = [min(min(min(uRF))) max(max(max(uRF)))]; 
           % rge  = range(clim) / 65;
            %set(gca,'Clim',[-rge 0] + [min(min(min(uRF))) max(max(max(uRF)))])
    end
    
    axis tight
    axis equal
    
    switch rfdatatype(1:3)
        case 'csd'
            colormap( [1 1 1; fliplr(jet(64))])
            colorbar
        otherwise
            colormap( [1 1 1; jet(64)])
            if rf == nel
                colorbar
            end
    end
    
    
    
    if all(all(isnan(dat)))
        axis off
        if rf == 1
            title(sprintf('%s - %s',[RF.header '_' RF.el],upper(rfdatatype)),'interpreter','none');
        end
    end
    
end

if ~exist('fRF','var')
    return
end

h(2) = figure('Position',[0 0 601 874]);

subplot(2,2,[1 2])
colors = jet(nel);

clear hh legstr; ct = 0;
for rf = 1:nel
    
    centroid = fRF(rf,1:2);
    width    = fRF(rf,3:4);
    rfboundary = [centroid(1)-width(1)/2,centroid(2)-width(2)/2, width(1), width(2)];
    
    if ~any(isnan(rfboundary))
        hold on; ct = ct + 1;
        if ~dRF(dRF(:,1) == rf,4) 
            % OUTSIDE V1 acording to dRF criteria
            rectangle('Position',rfboundary,'Curvature',[1,1],'EdgeColor',colors(rf,:),'LineStyle',':');
        else
            % inside V1 acording to dRF criteria
            rectangle('Position',rfboundary,'Curvature',[1,1],'EdgeColor',colors(rf,:));
        end
        %plot(fRF(i,5),fRF(i,6),'x','Color',colors(i,:))
        hh(ct) = plot(fRF(rf,1),fRF(rf,2),'.','Color',colors(rf,:));
        legstr{ct} = RF.elabel{rf};
    end
end
axis([-10 10 -10 0])
axis equal;
set(gca,...
    'TickDir','out',...
    'Box','off');
try
    legend(hh,legstr,'Location','BestOutside');
end
xlabel('Horz DVA')
ylabel('Vert DVA')
title(sprintf('%s\n%s',[RF.header '_' RF.el],upper(rfdatatype)),'interpreter','none')

subplot(2,2,3)

dz = dRF(:,1);
dxy = dRF(:,2:3);
remove = all(isnan(dxy),2);
dz(remove) = [];
dxy(remove,:) = [];

plot(dxy,dz,'-o'); hold on;
if exist('dthresh','var')
    plot([dthresh dthresh],[1 nel],':k')
    legendstr = {'Horz','Vert','Threshold','V1 Lim', 'V1 Lim'};
    axis tight;
else
    legendstr = {'Horz','Vert','V1 Lim', 'V1 Lim'};
    axis tight;
    ylim([1 nel])
end
plot(xlim,[rflim(1) rflim(1)],'k')
plot(xlim,[rflim(2) rflim(2)],'k')
if exist('dthresh','var')
plot([dthresh dthresh],ylim,':k')
end
set(gca,...
    'TickDir','out',...
    'Box','off',...
    'Ydir','reverse');
legend(legendstr,'Location','best')


xlabel('| diff(DVA) |')
ylabel('Electrodes in Depth')
putativeRF = nanmedian([fRF(:,1),fRF(:,2)]);
title(sprintf('Diffrence from Putitive RF Across Depth\n Putitive RF = (%0.1f,%0.1f)',putativeRF(1), putativeRF(2)))
idx = get(gca,'Ytick'); 
set(gca,'YTickLabel',RF.elabel(idx))


subplot(2,2,4)
z  = 1:nel;
xy = fRF(:,3:4);
remove = any(isnan(xy),2) ;
z(remove)=[];
xy(remove,:)=[];
plot(xy,z,'-o'); hold on;
axis tight;
set(gca,...
    'Ylim',[1 nel],...
    'TickDir','out',...
    'Box','off',...
    'Ydir','reverse');
plot(xlim,[rflim(1) rflim(1)],'k')
plot(xlim,[rflim(2) rflim(2)],'k')
legend('Horz','Vert','V1 Lim', 'V1 Lim','Location','best')

xlabel('Width in DVA')
ylabel('Electrodes in Depth')
title('RF Size Across Depth')

idx = get(gca,'Ytick'); 
set(gca,'YTickLabel',RF.elabel(idx))

%
% %%
%
%
% figure;
% colors = jet(nel);
% for i = 1:nel
%     centroid = fRF(i,1:2);
%     width    = fRF(i,3:4);
%
%     rfboundary = [centroid(1)-width(1)/2,centroid(2)-width(2)/2, width(1), width(2)];
%
%     if ~any(isnan(rfboundary))
%         h = rectangle('Position',rfboundary,'Curvature',[1,1]);
%         set(h,'EdgeColor',colors(i,:))
%     end
% end
%
% %%
%
%
%