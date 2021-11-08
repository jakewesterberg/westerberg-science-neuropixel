%% Probe-wide Ocularity and Binocularity
for el = 1:length(IDX)
    bioIndex(el,:) = IDX(el).bio(3);
    occIndex(el,:) = IDX(el).occ(3);
end

figure('position',[643,162.3333333333333,364.6666666666666,419.9999999999999]); 
plot(occIndex(:,:),STIM.depths(:,2),'-k','linewidth',1.5);
set(gca,'xlim',[-.5 .5],'linewidth',.8,'Fontsize',12)
v = vline(0,'k'); set(v, 'linewidth',0.5);
xlabel('Occularity','Fontsize',14); ylabel('Electrode depth relative to layer 4/5 boundary','FontSize',14);

cd('C:\Users\bmitc\OneDrive\4. Vanderbilt\Maier Lab\Figures\probe\')
saveas(gcf, strcat('occularity', '.svg'));

figure('position',[643,162.3333333333333,364.6666666666666,419.9999999999999]);
plot(bioIndex(:,:),STIM.depths(:,2),'-k','linewidth',1.5);
set(gca,'xlim',[-.25 .25],'linewidth',.8,'Fontsize',12)
v = vline(0,'k'); set(v, 'linewidth',0.5);
xlabel('Binocularity','Fontsize',14); ylabel('Electrode depth relative to layer 4/5 boundary','Fontsize',14);

cd('C:\Users\bmitc\OneDrive\4. Vanderbilt\Maier Lab\Figures\probe\')
saveas(gcf, strcat('binocularity', '.svg'));

%% Probe: Summary DE vs NDE
clear y1 y2 bsl_y1 bsl_y2

y2 = MON.dMUA.DE_PS.resp(:,:,:);
y1 = MON.dMUA.NDE_PS.resp(:,:,:);
bsl_y1 = bsxfun(@minus, y1,mean(y1(:,4,:),2));
bsl_y2 = bsxfun(@minus, y2,mean(y2(:,4,:),2));
tw = 3;
figure('position',[213,89.66666666666666,587.3333333333333,540.6666666666666]);

for i = 1:3
subplot(1,3,i)
barh(STIM.depths(:,2),squeeze(bsl_y2(i+1,tw,:)),1,...
    'FaceColor',[0, 0.4470, 0.7410],'EdgeColor','k','LineWidth',0.8);
hold on
barh(STIM.depths(:,2),squeeze(bsl_y1(i+1,tw,:)),0.6,...
    'FaceColor','k','EdgeColor','k','LineWidth',0.8);
set(gca,'box','off','linewidth',1.5,'ylim',[-4.5 12.5],'xlim',[0 500],'FontSize',12);
    if i == 1
    xlabel('impulses per sec','FontSize',16)
    ylabel('Electrode depth relative to layer 4/5 boundary','FontSize',16)
    ylabel([]);yticklabels([]);
    lgn = legend('DE','NDE','location','southeast'); legend boxoff;
    else 
        xlabel([]); ylabel([]);
        yticklabels([]);
    end
hold off
end

cd('C:\Users\bmitc\OneDrive\4. Vanderbilt\Maier Lab\Figures\probe\')
saveas(gcf, strcat('DEvsNDE_bsl', '.svg'));

%% Probe: Summary DE vs BIN
clear y1 y2 bsl_y1 bsl_y2

y1 = MON.dMUA.DE_PS.resp(:,:,:);
y2 = BIN.dMUA.PS.resp(:,:,:);

bsl_y1 = bsxfun(@minus, y1,mean(y1(:,4,:),2));
bsl_y2 = bsxfun(@minus, y2,mean(y2(:,4,:),2));
tw = 3;
figure('position',[213,89.66666666666666,587.3333333333333,540.6666666666666]);

for i = 1:3
subplot(1,3,i)
barh(STIM.depths(:,2),squeeze(y2(i+1,tw,:)),1,...
    'FaceColor',[0.8500, 0.3250, 0.0980],'EdgeColor','k','LineWidth',0.8);
hold on
barh(STIM.depths(:,2),squeeze(y1(i+1,tw,:)),0.6,...
    'FaceColor',[0, 0.4470, 0.7410],'EdgeColor','k','LineWidth',0.8);
set(gca,'box','off','linewidth',1.5,'ylim',[-4.5 12.5],'xlim',[0 500],'FontSize',12);
    if i == 1
    xlabel('impulses per sec','Fontsize',16)
    ylabel('Electrode depth relative to layer 4/5 boundary','Fontsize',16)
    ylabel([]);yticklabels([]);
    lgn = legend('BIN','DE','location','southeast'); legend boxoff;
    else 
        xlabel([]); ylabel([]);
        yticklabels([]);
    end
hold off
end

cd('C:\Users\bmitc\OneDrive\4. Vanderbilt\Maier Lab\Figures\probe\')
saveas(gcf, strcat('DEvsBIN', '.svg'));

%% Probe: RESP - Mon vs Bin
clear y1 y2 bsl_y1 bsl_y2

y1 = MON.dMUA.NDE_PS.resp(:,:,:);
y2 = BIN.dMUA.PS.resp(:,:,:);
bsl_y1 = bsxfun(@minus, y1,mean(y1(:,4,:),2));
bsl_y2 = bsxfun(@minus, y2,mean(y2(:,4,:),2));

figure('position',[44.33333333333333,101,893.3333333333333,496]);
clear i
tw = 1;
for i = 1:3
subplot(1,3,i)
plot(squeeze(bsl_y1(i+1,tw,:)),STIM.depths(:,2),'linewidth',1.5,'Color',[0, 0.4470, 0.7410]);
hold on 
plot(squeeze(bsl_y2(i+1,tw,:)),STIM.depths(:,2),'linewidth',1.5','color',[0.8500, 0.3250, 0.0980]);
grid off
xlim([0 500]);
set(gca,'Box','off','linewidth',1.5,'FontSize',12)
hold off
    if i == 1
        title('0.22 Contrast');
        lgn = legend('DE','BIN','Location','southeast','orientation','vertical'); legend box off;
        set(lgn, 'FontSize',8);
            xlabel('Impulses per sec');
            ylabel('Contact # relative to layer 4/5 boundary');
    elseif i == 2
            title('0.45 Contrast');
            yticklabels([]);
            xticklabels([]);
    else 
            title('0.90 Contrast');
            xticklabels([]);
            yticklabels([]);
    end
end

sgtitle({[dMUA(1).penetration,' | dMUA | ','Electrodes: ' num2str(length(STIM.depths))]},'Interpreter','none')

cd('C:\Users\bmitc\OneDrive\4. Vanderbilt\Maier Lab\Figures\probe\')
saveas(gcf, strcat('NDEvsBIN_bsl', '.svg'));