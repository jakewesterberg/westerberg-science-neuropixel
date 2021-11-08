%% Plotting as a function of ocularity
% Toggle to save figures
flag_figsave = 1;

% Figure save directory
if strcmp(getenv('username'),'bmitc')
    figDir = 'C:\Users\bmitc\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'mitchba2')
    figDir = 'C:\Users\mitchba2\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'bmitc_000')
    figDir = 'C:\Users\bmitc_000\OneDrive - Vanderbilt\Maier Lab\Figures\';
end


%% DE_PS vs BIN_PS - resp (simple lineplot)
% choices
tw = 1; % timewindow
smoothie = 0;

% strings

try
cLevels = string(IDX(1).monLevels*100);
catch
    %cLevels = string(IDX(1).stimcontrast*100);
    cLevels = mean(IDX(1).cbins,2)*100; 
end

% data
clear *de* *nde* *bin*
for o = 1:length(occGroups)  %store mon and bin units into struct
de(o).units = OCC.MON.DE_PS(o).RESP;
nde(o).units = OCC.MON.NDE_PS(o).RESP;
bin(o).units = OCC.BIN.PS(o).RESP;
end

for o = 1:length(occGroups) %retrieve avg and error
    de(o).avg = nanmean(de(o).units,3);
    de(o).err = nanstd(de(o).units,[],3)./sqrt(size(de(o).units,3));
    nde(o).avg = nanmean(nde(o).units,3);
    nde(o).err = nanstd(nde(o).units,[],3)./sqrt(size(nde(o).units,3));
    bin(o).avg = nanmean(bin(o).units,3);
    bin(o).err = nanstd(bin(o).units,[],3)./sqrt(size(bin(o).units,3));
end
%for t = 1:size(UNIT.MON.DE_PS.RESP,2)
    
%tw = t;
% Plot
figure('position',[301,201,282,554]);
for o = 1:length(occGroups)
subplot(length(occGroups),1,o);
    if smoothie == 1
        plot(smooth(squeeze(de(o).avg(:,tw,:))),'k','linewidth',2); hold on
        plot(smooth(squeeze(bin(o).avg(:,tw,:))),'b','linewidth',2)
        plot(smooth(squeeze(nde(o).avg(:,tw,:))),'color',[0,0,0]+0.9,'linewidth',2);
    else 
        plot(squeeze(de(o).avg(:,tw,:)),'k','linewidth',2); hold on
        plot(squeeze(bin(o).avg(:,tw,:)),'b','linewidth',2)
        plot(squeeze(nde(o).avg(:,tw,:)),'color',[0,0,0]+0.9,'linewidth',2); 
    end
    
set(gca,'box','off','linewidth',2,'FontSize',12,...
   'ylim',[0 200]);
xlabel([]); xticklabels([]);

[h,p] = ttest_time(de(o).units,bin(o).units); %tmh = find(h(tw,:));

       if o == 3
            occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
            bCt = sum(Trls.bin(2:end,1,:),'all'); mCt = sum(Trls.mon(2:end,1,:),'all');
            lgn = legend(sprintf('MON (%d trials)',mCt),...
                sprintf('BIN (%d trials)',bCt),'location','northwest'); legend boxoff
            set(lgn,'FontSize',10);
            title(sprintf('Index [%.3g : %.3g]',occRange(1),occRange(2)),'FontSize',16);
            xticks([0, 20, 40, 60, 80, 100]);
            xticklabels([0, 20, 40, 60, 80, 100]);
            ylabel('impulses per sec','Fontsize',14);
            xlabel('% contrast','Fontsize',14);
    elseif o == 2
            occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
            title(sprintf('Index [%.3g : %.3g]',occRange(1),occRange(2)),'FontSize',16);
        else 
            occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
            title(sprintf('Index [%.3g : %.3g]',occRange(1),occRange(2)),'FontSize',16);
        end
%occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
%title(sprintf('(n = %d)\n [%.3g : %.3g]',occLengths(o),occRange(1),occRange(2)),'FontSize',12);
end

if flag_figsave == 1
    cd(strcat(figDir,'ocularity\'));
    saveas(gcf, strcat('MONvsBIN_',num2str(tw), '.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end


%% DE_PS vs BIN_PS - resp (violin plots)

% choices
tw = 3; % timewindow
type = 1; % 1 is mon, 2 is bin, 3 is comparison between mon and bin

% if type 3
cont = 4; % contrast

% strings
windows = {'40-140ms','141-450ms','40-250ms'};

% switch approach
%     case 
% cLevels = string(IDX(1).monLevels*100);
% catch
%     cLevels = string(IDX(1).stimcontrast*100);
% end

% data
clear mon bin
for o = 1:length(occGroups) %store mon and bin units into struct
de(o).units = OCC.MON.DE_PS(o).RESP;
bin(o).units = OCC.BIN.PS(o).RESP;
end

for o = 1:length(occGroups) %retrieve avg and error
    de(o).avg = nanmean(de(o).units,3);
    de(o).err = nanstd(de(o).units,[],3)./sqrt(size(de(o).units,3));
    bin(o).avg = nanmean(bin(o).units,3);
    bin(o).err = nanstd(bin(o).units,[],3)./sqrt(size(bin(o).units,3));
end

% Plot
figure('position',[313,551,1095,268]);
for o = 1:length(occGroups)
subplot(1,length(occGroups),o);
if type == 3
    hh = distributionPlot([squeeze(de(o).units(cont,tw,:)) squeeze(bin(o).units(cont,tw,:))],...
        'showMM',1,'color',{[0.1 0.1 0.1],[0.1, 0.2, 0.5]},...
        'xNames',{'MON','BIN'},'globalNorm',2,'addSpread',0);
elseif type == 2
    hh = distributionPlot([squeeze(bin(o).units(2,tw,:)) squeeze(bin(o).units(3,tw,:)) squeeze(bin(o).units(4,tw,:))],...
        'showMM',6,'color',{[0.2 0.3 0.5],[0.2, 0.3, 0.5],[0.2 0.3 0.5]},...
        'xNames',{'Low','Med','High'},'globalNorm',2,'addSpread',0);
else
    hh = distributionPlot([squeeze(de(o).units(2,tw,:)) squeeze(de(o).units(3,tw,:)) squeeze(de(o).units(4,tw,:))],...
        'showMM',6,'color',{[0.2 0.2 0.3],[0.2, 0.2, 0.3],[0.2 0.2 0.3]},...
        'xNames',{'~22','~45','~90'},'globalNorm',2,'addSpread',0);
end
%set(hh{4}{1},'color','r','marker','o')
hold on
set(gca,'box','off','linewidth',2,'FontSize',12,...
    'ylim',[0 max(bin(3).units(end,tw,:))*1.2]);

       if o == 1
            occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
%             bCt = sum(Trls.bin(cont,1,:),'all'); mCt = sum(Trls.mon(cont,1,:),'all');
%             lgn = legend(sprintf('MON %s|0 (%d trials)',cLevels(cont),mCt),...
%                 sprintf('BIN %s|%s (%d trials)',cLevels(cont),cLevels(cont),bCt),'location','northwest'); legend boxoff
%             set(lgn,'FontSize',10);
%             title(sprintf('Lowest (n = %d)\n Index [%.3g : %.3g]',occLengths(o),occRange(1),occRange(2)),'FontSize',16);
            ylabel('impulses per sec','Fontsize',14);
             xlabel('% Stimulus contrast','Fontsize',14);
    elseif o == 2
%             occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
%             title(sprintf('Average (n = %d)\n Index [%.3g : %.3g]',occLengths(o),occRange(1),occRange(2)),'FontSize',16);
xlabel([]); xticklabels([]);
        else 
%             occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
%             title(sprintf('Highest (n = %d)\n Index [%.3g : %.3g]',occLengths(o),occRange(1),occRange(2)),'FontSize',16);
xlabel([]); xticklabels([]);
        end
end

%sgtitle(sprintf('Transient window | only one contrast level shown\ndMUA | N = %d | Penetrations: %d',uct,N),'fontsize',20); 

if flag_figsave == 1
    cd(strcat(figDir,'ocularity\'));
    saveas(gcf, strcat('MON_violin_', num2str(tw),'.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end

clear L y1 y2 bsl_y1 bsl_y2 mCt bCt bin mon x data_flag


%% Model Fit
% choices
cont = 4;
model = 'SUP';

% strings
models = {'LSM','AVE','QSM','SUP','CWM'};
x = sdfWin;

% data
    clear de nde bin
    for o = 1:length(occGroups)
        de(o).units = OCC.MON.DE_PS(o).SDF;
        nde(o).units = OCC.MON.NDE_PS(o).SDF;
        bin(o).units = OCC.BIN.PS(o).SDF;
    end

    for o = 1:length(occGroups)
        de(o).avg = squeeze(nanmean(de(o).units,3));
        de(o).err = squeeze(nanstd(de(o).units,[],3)./sqrt(size(de(o).units,3)));
        nde(o).avg = squeeze(nanmean(nde(o).units,3));
        nde(o).err = squeeze(nanstd(nde(o).units,[],3)./sqrt(size(nde(o).units,3)));
        bin(o).avg = nanmean(bin(o).units,3);
        bin(o).err = nanstd(bin(o).units,[],3)./sqrt(size(bin(o).units,3));
    end
    
    for o = 1:length(occGroups)
        [LSM(o).units,AVE(o).units,QSM(o).units,SUP(o).units,CWM(o).units] = modelAnalysis(de(o).units,nde(o).units);
    end
    
        
    for o = 1:length(occGroups)
        LSM(o).avg = nanmean(LSM(o).units,3);
        LSM(o).err = nanstd(LSM(o).units,[],3)./sqrt(size(LSM(o).units,3));
        AVE(o).avg = nanmean(AVE(o).units,3);
        AVE(o).err = nanstd(AVE(o).units,[],3)./sqrt(size(AVE(o).units,3));
        QSM(o).avg = nanmean(QSM(o).units,3);
        QSM(o).err = nanstd(QSM(o).units,[],3)./sqrt(size(QSM(o).units,3));
        SUP(o).avg = nanmean(SUP(o).units,3);
        SUP(o).err = nanstd(SUP(o).units,[],3)./sqrt(size(SUP(o).units,3));
        CWM(o).avg = nanmean(CWM(o).units,3);
        CWM(o).err = nanstd(CWM(o).units,[],3)./sqrt(size(CWM(o).units,3));
    end
    data_flag = 1;
    
switch model
    case 'LSM'
        mdl = LSM;
    case 'AVE'
        mdl = AVE;
    case 'QSM'
        mdl = QSM;
    case 'SUP'
        mdl = SUP;
    case 'CWM'
        mdl = CWM;
end

switch cont
    case 4
        cLevel = 90;
    case 3
        cLevel = 45;
    case 2 
        cLevel = 22;
end

% Plot
figure('position',[135,404.3333333333333,1420.666666666667,432.6666666666667]);
for o = 1:length(occGroups)
subplot(1,length(occGroups),o)
plot(x,bin(o).avg(cont,:),'b','linewidth',2); hold on
ci1 = ciplot(bin(o).avg(cont,:)+bin(o).err(cont,:),...
    bin(o).avg(cont,:)-bin(o).err(cont,:),x,'b',0.1); set(ci1,'linestyle','none','handleVisibility','off');
plot(x,mdl(o).avg(cont,:),'k','linewidth',1); 
ci2 = ciplot(mdl(o).avg(cont,:)+mdl(o).err(cont,:),...
    mdl(o).avg(cont,:)-mdl(o).err(cont,:),x,'k',0.1); set(ci2,'linestyle','none','handleVisibility','off');
ylimit = max(bin(o).avg(cont,:));
set(gca,'Box','off','TickDir','out','linewidth',1.5,'ylim',[-10 ylimit*1.5],'xlim',[0 .300],'FontSize',12)
    if o == 1
            occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
            bCt = sum(Trls.bin(cont,1,:),'all');
            legend(sprintf('BIN (%s|%s) (%d trials)',num2str(cLevel),num2str(cLevel),bCt),sprintf('Model: %s',model),'position',[0.4477,0.01504,0.14069,0.09759]); legend boxoff
            title(sprintf('Lowest (n = %d)\n OccIndex [%.3g : %.3g]',occLengths(o),occRange(1),occRange(2)),'FontSize',16);
            xlabel('time (s)','Fontsize',16); ylabel('impulses per sec','Fontsize',16);
    elseif o == 2
            occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
            title(sprintf('Average (n = %d)\n OccIndex [%.3g : %.3g]',occLengths(o),occRange(1),occRange(2)),'FontSize',16);
            xticklabels([]);
        else 
            occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
            title(sprintf('Highest (n = %d)\n OccIndex [%.3g : %.3g]',occLengths(o),occRange(1),occRange(2)),'FontSize',16);
            xticklabels([]);
    end
end

if flag_figsave == 1
    cd(strcat(figDir,'ocularity\'));
    saveas(gcf, strcat('model_',model,'_',cLevel,'.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end


clear o y1 y2 y3 y4

%% Ocularity distribution
figure('position',[242,464,705,299]);
histogram(test,20)
xlim([-1 1]);

set(gca,'Box','off','TickDir','out','linewidth',1.5,'xlim',[-1 1],'FontSize',16)
xlabel('ocularity index (OCI)')
ylabel('# of units')


if flag_figsave == 1
    cd(strcat(figDir,'ocularity\'));
    saveas(gcf, strcat('occDistribtion','.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end


%% binocular modulation as a function of contrast (and ocularity)

figure('position',[262,293,361,642]);

for oc = 1:3
    subplot(3,1,oc)
    sub = bin(oc).avg(:,1)./de(oc).avg(:,1);
    sub2 = bin(oc).avg(:,2)./de(oc).avg(:,2);
    plot(sub,'color',light_orange); hold on
    plot(sub2,'color',dark_red);
    hline(1);
    
    ylim([0.5 1.8]);
    
    set(gca,'FontSize',16,'linewidth',1,'box','off',...
        'ylim',[0.5 1.8]);
    
    xlabel('contrast')
    if oc == 2
        ylabel('binocular modulation index');
    else
        ylabel([]);
    end
    
    if oc == 3
        xlabel('contrast')
        xticklabels({'0','22.5','45','90'});
    else
        xlabel([]);
        xticklabels([]);
    end
end

if flag_figsave == 1
    cd(strcat(figDir,'ocularity\'));
    saveas(gcf, strcat('modulation_occxCont','.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end
