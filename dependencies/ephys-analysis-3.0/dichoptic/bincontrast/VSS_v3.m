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


%% Figure 1: Violin plots

% choices
tw = 1; % timewindow
type = 1; % 1 is mon vs bin, 2 is mon, 3 is bin

% if type 1
cont = 4; % contrast

% data
clear mon bin
 %store mon and bin units into struct
mon.units = UNIT.MON.DE_PS.RESP;
nde.units = UNIT.MON.NDE_PS.RESP;
bin.units = UNIT.BIN.PS.RESP;

mon.avg = nanmean(mon.units,3);
mon.err = nanstd(mon.units,[],3)./sqrt(size(mon.units,3));
nde.avg = nanmean(nde.units,3);
nde.err = nanstd(nde.units,[],3)./sqrt(size(nde.units,3));
bin.avg = nanmean(bin.units,3);
bin.err = nanstd(bin.units,[],3)./sqrt(size(bin.units,3));

% Plot
figure('position',[324,380,577,408]);
if type == 1
    hh = distributionPlot([squeeze(mon.units(cont,tw,:)) squeeze(bin.units(cont,tw,:))],...
        'showMM',3,'color',{[0.2 0.2 0.2]+0.4,[0.2, 0.2, 0.2]},...
        'xNames',{'MON','BIN'},'globalNorm',1,'addSpread',0,'addBoxes',1);
elseif type == 2
    hh = distributionPlot([squeeze(mon.units(2,tw,:)) squeeze(mon.units(3,tw,:)) squeeze(mon.units(4,tw,:))],...
        'showMM',5,'color',{[0.2 0.2 0.2],[0.2, 0.2, 0.2],[0.2 0.2 0.2]},...
        'xNames',{'','',''},'globalNorm',2,'addSpread',0,'addBoxes',1);
           xlabel([]);
elseif type == 3
    hh = distributionPlot([squeeze(nde.units(2,tw,:)) squeeze(nde.units(3,tw,:)) squeeze(nde.units(4,tw,:))],...
        'showMM',5,'color',{[0.4 0.4 0.4],[0.4, 0.4, 0.4],[0.4 0.4 0.4]},...
        'xNames',{'','',''},'globalNorm',1,'addSpread',0);
    xlabel([]);
else
    hh = distributionPlot([squeeze(bin.units(2,tw,:)) squeeze(bin.units(3,tw,:)) squeeze(bin.units(4,tw,:))],...
        'showMM',6,'color',{[0.2 0.2 0.3],[0.2, 0.2, 0.3],[0.2 0.2 0.3]},...
        'xNames',{'','',''},'globalNorm',2,'addSpread',0);
    %xlabel('% contrast','Fontsize',16);
end
%xticks([0, 20, 40, 60, 80, 100]);
%xticklabels([0, 20, 40, 60, 80, 100]);
ylabel('impulses per sec','Fontsize',16);
%xlabel('% contrast','Fontsize',16);
hold on
set(gca,'box','off','linewidth',2,'FontSize',16,...
    'ylim',[0 inf]);

if flag_figsave == 1
    cd(strcat(figDir,'VSS_v3\'));
    saveas(gcf, strcat('Figure 1','.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end

clear L y1 y2 bsl_y1 bsl_y2 mCt bCt x data_flag

%% Figure 2: Probe plot

cont = 4;
tw = 1;
pen = 12;

clear *de* *nde* *bin*
switch cont
    case 2
        cLevel = '22';
    case 3
        cLevel = '45';
    case 4
        cLevel = '90';
end

depth = 12:-1:-4;

% data
de.units = PEN(12).MON.DE_PS.RESP;
nde.units = PEN(pen).MON.NDE_PS.RESP;
bin.units = PEN(pen).BIN.PS.RESP;

% plot 1
figure('position',[452,234,376,666]);
plot(squeeze(de.units(cont,tw,:)), depth,'linewidth',2,'Color',[0.2 0.2 0.2]+0.5); hold on
plot(squeeze(bin.units(cont,tw,:)), depth,'linewidth',2,'Color',[0.2 0.2 0.2]);
grid off

% gca
set(gca,'box','off','linewidth',2,'fontsize',14,...
    'xlim',[-5 350],'ylim',[-4 12]);

% labels
yticklabels({'-0.4','-0.2','0','0.2','0.4','0.6','0.8','1.0','1.2'})
xlabel('impulses per sec','FontSize',16);
ylabel('Depth (mm) relative to layer 4/5 boundary','FontSize',16);
legend('MON','BIN','Location','southeast','orientation','vertical'); legend boxoff
%title(sprintf('Monocular\n responses'),'FontSize',16);

hold off

if flag_figsave == 1
    cd(strcat(figDir,'VSS_v3\'));
    saveas(gcf, strcat('Figure 2', '.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end


%% Figure 3: SDF plot

% choices
cont = 4;
poster = false;
legendflag = false;
axes = 'set'; % set or relative

% strings
try
cLevels = string(IDX(1).monLevels*100);
catch
    %cLevels = string(IDX(1).stimcontrast*100);
    cLevels = mean(IDX(1).cbins,2)*100; 
end

switch cont
    case 2
        c = '22';
    case 3 
        c = '45';
    case 4
        c = '90';
end

% Data
clear mon bin
for L = 1:3
mon(L).units = LAY.MON.DE_PS(L).SDF;
bin(L).units = LAY.BIN.PS(L).SDF;
end

for L = 1:3
    mon(L).avg = nanmean(mon(L).units,3);
    mon(L).err = nanstd(mon(L).units,[],3)./sqrt(size(mon(L).units,3));
    bin(L).avg = nanmean(bin(L).units,3);
    bin(L).err = nanstd(bin(L).units,[],3)./sqrt(size(bin(L).units,3));
end

figure('position',[373,155,543,766]);
for L = 1:3 % layer
    subplot(3,1,L)
    plot(sdfWin,mon(L).avg(cont,:),'color',[0.2 0.2 0.2]+0.5,'linewidth',2); hold on
    %ci1 = ciplot(mon(L).avg(cont,:)+mon(L).err(cont,:),mon(L).avg(cont,:)-mon(L).err(cont,:),sdfWin,'k',0.1); 
        %set(ci1,'linestyle','none','handleVisibility','off');
    plot(sdfWin,bin(L).avg(cont,:),'color',[0.2 0.2 0.2],'linewidth',2)
    %ci2 = ciplot(bin(L).avg(cont,:)+bin(L).err(cont,:),bin(L).avg(cont,:)-bin(L).err(cont,:),sdfWin,'k',0.1); 
        %set(ci2,'linestyle','none','handleVisibility','off');
    
    [h,p] = ttest_time(mon(L).units,bin(L).units); tmh = find(h(cont,:));
    scatter(sdfWin(tmh), ones(1,numel(tmh)) * max(bin(L).avg(cont,:))+22,4,'*k') % significance bar
    
    if strcmp(axes,'set')
    set(gca,'Box','off','TickDir','out','linewidth',2,'ylim',[-5 200],'xlim',[0 .250],...
    'Fontsize',14)
    else 
    set(gca,'Box','off','TickDir','out','linewidth',2,'ylim',[-5 max(bin(L).avg(cont,:))+40],'xlim',[0 .250],...
    'Fontsize',14)
    end
    
    if L == 1 
        %title(sprintf('Upper (n = %d)',layerLengths(1)),'FontSize',16);
        yticklabels([]); xticklabels([]);
        if legendflag == true
        mCt = sum(Trls.mon(cont,1,:),'all'); bCt = sum(Trls.bin(cont,1,:),'all');
        lgn = legend(sprintf('DE PS (%d trials)',mCt),sprintf('BIN PS (%d trials)',bCt),'location','southeast'); legend boxoff
        set(lgn,'fontsize',8);
        end
    elseif L == 2 
            %title(sprintf('Middle (n = %d)',layerLengths(2)),'FontSize',16);
            yticklabels([]); xticklabels([]);
    else         
            xlabel('time (s)','FontSize',16); 
            %yticklabels([]);
            ylabel('Impulses per sec','FontSize',16);
            
    end
end

if poster == true
    yticklabels([]); xticklabels([]);
    ylabel([]); xlabel([]);
end


if flag_figsave == 1
    cd(strcat(figDir,'VSS_v3\'));
    saveas(gcf, strcat('Figure 3','.svg'));
    sprintf("Figure saved");
else
    sprintf("Figure was not saved");
end

clear L mCt bCt


%% Figure 4-1: Barplots

% choices
poster = false;
axes = 'set'; % set or relative
tw = 2; 

% data
clear mon bin
for L = 1:3
mon(L).units = LAY.MON.DE_PS(L).RESP;
bin(L).units = LAY.BIN.PS(L).RESP;
end

for L = 1:3
    mon(L).avg = nanmean(mon(L).units,3);
    mon(L).err = nanstd(mon(L).units,[],3)./sqrt(size(mon(L).units,3));
    bin(L).avg = nanmean(bin(L).units,3);
    bin(L).err = nanstd(bin(L).units,[],3)./sqrt(size(bin(L).units,3));
end

% Plot: DE PS vs BIN PS - resp
C = [.4 .4 .4;.2 .2 .2];

figure('position',[573,92,347,765]);

for L = 1:3
subplot(3,1,L);
[h,p] = ttest_time(mon(L).units,bin(L).units); %tmh = find(h(cont,:));
P = nan(8,8);
P(1,5) = p(1,tw);
P(2,6) = p(2,tw);
P(3,7) = p(3,tw);
P(4,8) = p(4,tw);
PT = P';
lidx = tril(true(size(P)), -1);
P(lidx) = PT(lidx);

ylimit = max(bin(L).avg(:,1));
set(gca,'box','off','linewidth',2,'FontSize',16,'ylim',[0 ylimit+((1/2)*ylimit)],'xlim',[0.5 4.5]);
superbar([mon(L).avg(:,tw),bin(L).avg(:,tw)],...
    'E',[mon(L).err(:,tw),bin(L).err(:,tw)],...
    'P', P, 'PStarThreshold',[0.01 0.001 0.0001],'PStarOffset',20,...
    'BarWidth',0.665,'BarFaceColor',permute(C,[3 1 2]),...
    'BarEdgeColor','k'); hold on

    if L == 1
        %title(sprintf('Upper (n = %d)',layerLengths(1)),'FontSize',18);
        %yticklabels([]); 
        xticklabels([]); yticklabels([]);
    elseif L == 2
            %title(sprintf('Middle (n = %d)',layerLengths(2)),'FontSize',18);
             xticklabels([]);
             yticklabels([]);
        else 
            %title(sprintf('Deep (n = %d)',layerLengths(3)),'FontSize',18);
            %xlabel('stimulus contrast','Fontsize',18);
            %ylabel('impulses per sec','Fontsize',18);
            xticklabels({'','','',''});
            yticklabels([]);
            %ylabel('impulses per sec','fontsize',16);
    end
    
    
end

%mCt = sum(Trls.mon(:,1,:),'all'); bCt = sum(Trls.bin(:,1,:),'all');

%legend([1 5],sprintf('DE PS (%d trials)',mCt),sprintf('BIN PS (%d trials)',bCt),'location','northwest','FontSize',12); legend boxoff
%itle(sprintf('dMUA | N = %d | Penetrations: %d \nWindow: %s',uct,N,windows{tw}),'Fontsize',16); 

if flag_figsave == 1
    cd(strcat(figDir,'VSS_v3\'));
    saveas(gcf, strcat(sprintf('Figure_3-%d',tw),'.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end
clear L y1 y2 bsl_y1 bsl_y2 mCt bCt bin mon x data_flag

%% Figure 4-2: CRFs

clear -global Data
clear bin mon bin clear prd prd1 prd2 cv curves a K n b 

% choices
tw = 2; % time window
error = 1;

% strings
curves = {'de','nde','bin'};

try
x = IDX(1).monLevels*100; x(1) = x(1)+1;
catch
    disp('Using average of binned contrast levels');
    x = mean(IDX(1).cbins,2)*100; x(1) = x(1)+1;
end

% data
clear mon_all bin_all
for L = 1:3
de_all(L).units = LAY.MON.DE_PS(L).RESP;
nde_all(L).units = LAY.MON.NDE_PS(L).RESP;
bin_all(L).units = LAY.BIN.PS(L).RESP;
end

for L = 1:3
    de_all(L).avg = nanmean(de_all(L).units,3);
    de_all(L).err = nanstd(de_all(L).units,[],3)./sqrt(size(de_all(L).units,3));
    nde_all(L).avg = nanmean(nde_all(L).units,3);
    nde_all(L).err = nanstd(nde_all(L).units,[],3)./sqrt(size(nde_all(L).units,3));
    bin_all(L).avg = nanmean(bin_all(L).units,3);
    bin_all(L).err = nanstd(bin_all(L).units,[],3)./sqrt(size(bin_all(L).units,3));
end

global Data
Data(1,:) = x;
figure('position',[573,92,347,765]);
clear nMon nBin mon bin

for L = 1:3  % number of layers
    de = de_all(L).avg(:,tw); %using the baseline corrected variable here
    de_ref = de_all(L).avg(:,1);
    nde = nde_all(L).avg(:,tw);
    bin = bin_all(L).avg(:,tw);
    
    mn       = min(de_ref);
    mx       = max(de_ref);
    nDE      = (de - mn)./(mx - mn);
    nNDE     = (nde - mn)./(mx - mn);
    nBIN     = (bin - mn)./(mx - mn);
    
    for curve = 1:size(curves, 2)
        switch curves{curve}
            case 'de'
                Data(2,:) = nDE;
            case 'nde'
                Data(2,:) = nNDE;
            case 'bin'
                Data(2,:) = nBIN;
        end
        
        [a,K ,n ,~] = BMfitCRdata;
        predictions = 1:100;
        for c = 1:length(predictions)
            prd(curve,c) = a*[(c^n)/((c^n) + (K^n))]; % prediction
        end
    end
    
    % Plot
    subplot(3,1,L)
    s1 = semilogx(predictions,prd(1,:),'color',[0.2 0.2 0.2]+0.5,'linestyle','-','linewidth',2,'HandleVisibility','off');  hold on
    %s2 = semilogx(predictions,prd(2,:),'color',[0 0 0]+0.9,'linestyle','-','linewidth',1.75,'HandleVisibility','off');  hold on
    s3 = semilogx(predictions,prd(3,:),'color',[0.2 0.2 0.2],'linestyle','-','linewidth',2,'HandleVisibility','off');  hold on
    
    s4 = semilogx(Data(1,:),nDE,'o','color',[0.2 0.2 0.2]+0.5,'linewidth',2,'markersize',5);
    %s5 = semilogx(Data(1,:),nNDE,'o','color',[.4 .4 .4],'linewidth',2,'markersize',5);
    s6 = semilogx(Data(1,:),nBIN,'*','color',[0.2 0.2 0.2],'linewidth',2,'markersize',5);
    
    set(gca,'FontSize',14,'linewidth',2,'box','off',...
        'xlim',[1 100],...
        'XTick',x);
    
    if tw == 1
        set(gca,'ylim',[0 1.4]);
    else
        set(gca,'ylim',[0 0.7]);
    end
    
    if L == 1 || L == 2 
        xticklabels([]); ylabel([]); 
        yticklabels([]);
    elseif L == 3 && tw == 1
        xticks([1,5,10,20,50,100]);
        ylabel('Normalized response','fontsize',16);
        xlabel('% contrast','fontsize',16);
    elseif L == 3 && tw == 2
        ylabel([]); 
        xticks([1,5,10,20,50,100]);
    end
    

end


if flag_figsave == 1
    cd(strcat(figDir,'VSS_v3\'));
    saveas(gcf, strcat('Figure 4_', num2str(tw),'.svg'));
    sprintf("Figure saved");
else
    sprintf("Figure was not saved");
end


%% Figure 5: Probe-wide model comparison
clear LSM AVE QSM SUP mdl Model1 Model2
cont = 4;
tw = 3;
pen = 12;
Model1 = 'LSM';
Model2 = 'QSM';
Model3 = 'SUP';

clear *de* *nde* *bin*
switch cont
    case 2
        cLevel = '22';
    case 3
        cLevel = '45';
    case 4
        cLevel = '90';
end

depth = 12:-1:-4;

% data
de.units = PEN(12).MON.DE_PS.RESP;
nde.units = PEN(pen).MON.NDE_PS.RESP;
bin.units = PEN(pen).BIN.PS.RESP;

% models
[LSM,~,QSM,SUP] = modelAnalysis(de.units,nde.units);

% plot 1
figure('position',[224,238,1383,600]);
subplot(1,5,1)
plot(squeeze(de.units(cont,tw,:)), depth,'linewidth',2,'linestyle','-','Color',[0.4 0.4 0.4]+0.3); hold on
plot(squeeze(nde.units(cont,tw,:)), depth,'linewidth',2,'linestyle',':','Color',[0.4 0.4, 0.4]+0.3);
grid off

% gca
set(gca,'box','off','linewidth',2,'fontsize',14,...
    'xlim',[-5 350],'ylim',[-4 12]);

% labels
yticklabels({'-0.4','-0.2','0','0.2','0.4','0.6','0.8','1.0','1.2'})
xlabel('impulses per sec','FontSize',16);
ylabel('Depth (mm) relative to layer 4/5 boundary','FontSize',16);
legend(sprintf('%s DE',cLevel),sprintf('%s NDE',cLevel),'Location','southeast','orientation','vertical'); legend boxoff
title(sprintf('Monocular\n responses'),'FontSize',16);

hold off

% plot 2
subplot(1,5,2)
plot(squeeze(bin.units(cont,tw,:)), depth,'linewidth',1.5,'Color',[0.2 0.2 0.2]);
hold on 
plot(squeeze(LSM(cont,tw,:)), depth,'linestyle',':','linewidth',2.2,'Color',[0.8, 0.2, 0.2]);
grid off
xlim([-5 350]);

% gca
set(gca,'box','off','linewidth',2,'fontsize',14,...
    'xlim',[-5 350],'ylim',[-4 12]);

% labels
yticklabels({'-0.4','-0.2','0','0.2','0.4','0.6','0.8','1.0','1.2'})
yticklabels([]); xticklabels([]);
%xlabel('impulses per sec','FontSize',16);
%ylabel('Depth (mm) relative to layer 4/5 boundary','FontSize',16);
legend('BIN','LS','Location','southeast','orientation','vertical'); legend box off
title(sprintf('Linear \nSummation (LS)'),'FontSize',16);
hold off

% plot 3
subplot(1,5,3)
plot(squeeze(bin.units(cont,tw,:)), depth,'linewidth',1.5,'Color',[0.2 0.2 0.2]);
hold on 
plot(squeeze(QSM(cont,tw,:)), depth,'linestyle',':','linewidth',2.2,'Color',[0.1, 0.4, 0.8]);
grid off
xlim([-5 350]);

% gca
set(gca,'box','off','linewidth',2,'fontsize',14,...
    'xlim',[-5 350],'ylim',[-4 12]);

% labels
yticklabels({'-0.4','-0.2','0','0.2','0.4','0.6','0.8','1.0','1.2'})
yticklabels([]); xticklabels([]);
legend('BIN','QS','Location','southeast','orientation','vertical'); legend box off
title(sprintf('Quadratic \nSummation (QS)'),'FontSize',16);
hold off

% plot 4
subplot(1,5,4)
plot(squeeze(bin.units(cont,tw,:)), depth,'linewidth',1.5,'Color',[0.2 0.2 0.2]);
hold on 
plot(squeeze(SUP(cont,tw,:)), depth,'linestyle',':','linewidth',2.2,'Color',[0.4, 0.6, 0.2]);
grid off
xlim([-5 350]);

% gca
set(gca,'box','off','linewidth',2,'fontsize',14,...
    'xlim',[-5 350],'ylim',[-4 12]);

% labels
yticklabels({'-0.4','-0.2','0','0.2','0.4','0.6','0.8','1.0','1.2'})
yticklabels([]); xticklabels([]);
legend('BIN','SUP','Location','southeast','orientation','vertical'); legend boxoff
title(sprintf('QS with\nsuppressive term'),'FontSize',16);
hold off

% plot 5
subplot(1,5,5)
plot(squeeze(LSM(cont,tw,:)) - squeeze(bin.units(cont,tw,:)), depth,'linestyle',':','linewidth',2.2,'Color',[0.8, 0.2, 0.2]);
hold on
plot(squeeze(QSM(cont,tw,:)) - squeeze(bin.units(cont,tw,:)), depth,'linestyle',':','linewidth',2.2,'Color',[0.1, 0.4, 0.8]);
plot(squeeze(SUP(cont,tw,:)) - squeeze(bin.units(cont,tw,:)), depth,'linestyle',':','linewidth',2.2,'Color',[0.4, 0.6, 0.2]);
grid off
xlim([-5 350]);

% gca
set(gca,'box','off','linewidth',1.5,'fontsize',14,...
    'xlim',[-150 150],'ylim',[-4 12]);
yticklabels([]);
vl = vline(0, 'k');
set(vl,'linewidth',1);

% labels
yticklabels({'-0.4','-0.2','0','0.2','0.4','0.6','0.8','1.0','1.2'})
yticklabels([]); 
%xlabel('residual','FontSize',16);
%ylabel('Depth (mm) relative to layer 4/5 boundary','FontSize',16);
%legend('QSM error','SUP error','Location','southeast','orientation','vertical'); legend boxoff
title(sprintf('Model\n prediction error'),'FontSize',16);
hold off

if flag_figsave == 1
    cd(strcat(figDir,'VSS_v3\'));
    saveas(gcf, strcat('Figure_5', '.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end

%% Figure 6: Bar plot of model residuals by layer
clear -global Data
clear bin mon bin cv curves a K n b 
clear LSM SUP QSM lsm sup qsm gof_QSM gof_LSM gof_SUP

% strings
curves = {'bin','lsm','qsm','sup'};

try
x = IDX(1).monLevels*100; x(1) = x(1)+1;
catch
    disp('Using average of binned contrast levels');
    x = mean(IDX(1).cbins,2)*100; x(1) = x(1)+1;
end

% data
clear mon_all bin_all
for L = 1:3
de_all(L).units = LAY.MON.DE_PS(L).SDF;
nde_all(L).units = LAY.MON.NDE_PS(L).SDF;
bin_all(L).units = LAY.BIN.PS(L).SDF;
end

for L = 1:3
    de_all(L).avg = nanmean(de_all(L).units,3);
    de_all(L).err = nanstd(de_all(L).units,[],3)./sqrt(size(de_all(L).units,3));
    nde_all(L).avg = nanmean(nde_all(L).units,3);
    nde_all(L).err = nanstd(nde_all(L).units,[],3)./sqrt(size(nde_all(L).units,3));
    bin_all(L).avg = nanmean(bin_all(L).units,3);
    bin_all(L).err = nanstd(bin_all(L).units,[],3)./sqrt(size(bin_all(L).units,3));
end

% models
for L = 1:3
[LSM(L).units,~,QSM(L).units,SUP(L).units] = modelAnalysis(de_all(L).units,nde_all(L).units);

SUP(L).units = real(SUP(L).units);
end



for L = 1:3
    LSM(L).avg = nanmean(LSM(L).units,3);
    LSM(L).err = nanstd(LSM(L).units,[],3)./sqrt(size(LSM(L).units,3));
    QSM(L).avg = nanmean(QSM(L).units,3);
    QSM(L).err = nanstd(QSM(L).units,[],3)./sqrt(size(QSM(L).units,3));
    SUP(L).avg = nanmean(SUP(L).units,3);
    SUP(L).err = nanstd(SUP(L).units,[],3)./sqrt(size(SUP(L).units,3));
end

% binp2 = rmmissing(binp(:,:));
% LSMp2 = rmmissing(LSMp(:,:));
% QSMp2 = rmmissing(QSMp(:,:));
% SUPp2 = rmmissing(SUPp(:,:));


clear gof_LSM c gof_QSM gof_SUP
% 201 251; 301 501; 201 501; 101 151
sdftw = 201:501;
cost_func = 'NRMSE';

for L = 1:3
    LSMp = permute(LSM(L).avg,[2 1]);
    QSMp = permute(QSM(L).avg,[2 1]);
    SUPp = permute(SUP(L).avg,[2 1]);
    binp = permute(bin_all(L).avg,[2 1]);
    
    binp = squeeze(binp(:,2:4));
    LSMp = squeeze(LSMp(:,2:4));
    QSMp = squeeze(QSMp(:,2:4));
    SUPp = squeeze(SUPp(:,2:4));
    
    for c = 1:3
        gof_LSM(L).fit(c,:) = goodnessOfFit(LSMp(sdftw,c), binp(sdftw,c),cost_func);
        gof_QSM(L).fit(c,:) = goodnessOfFit(QSMp(sdftw,c), binp(sdftw,c),cost_func);
        gof_SUP(L).fit(c,:) = goodnessOfFit(SUPp(sdftw,c), binp(sdftw,c),cost_func);
    end
end

for L = 1:3
mF(L).avg = [mean(gof_LSM(L).fit,'all') mean(gof_QSM(L).fit,'all') mean(gof_SUP(L).fit,'all')];
end

% bar plot

figure('position',[573,92,347,765]);

for L = 1:3
    subplot(3,1,L);
    b = bar(1:3,mF(L).avg,'EdgeColor',[.2 .2 .2],'LineWidth',1.5); hold on
    b.FaceColor = 'flat';
    b.CData(1,:) = [0.8, 0.2, 0.2];
    b.CData(2,:) = [0.1, 0.4, 0.8];
    b.CData(3,:) = [0.4, 0.6, 0.2];
    
    set(gca,'box','off','linewidth',2,'fontsize',14,...
        'ylim',[-1 1]);
    
    xticklabels([]); xlabel([]);
    
    if L == 3
        xticklabels({'LS','QS','SUP'});
        ylabel(sprintf('Goodness of fit \n (NRMSE)'));
        
    end
end



% figure;
% c = 4;
% plot(sdfWin, binp(:,c),'k');
% hold on
% plot(sdfWin, LSMp(:,c),'r');
% 
% plot(sdfWin, QSMp(:,c),'b');
% plot(sdfWin, SUPp(:,c),'g');

if flag_figsave == 1
    cd(strcat(figDir,'VSS_v3\'));
    saveas(gcf, strcat('Figure 6','.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end


%% Figure 7: CRF models
clear -global Data
clear bin mon bin cv curves a K n b 
clear LSM SUP QSM lsm sup qsm 

% choices
tw = 2; % time window
error = 1;

% strings
curves = {'bin','lsm','qsm','sup'};

try
x = IDX(1).monLevels*100; x(1) = x(1)+1;
catch
    disp('Using average of binned contrast levels');
    x = mean(IDX(1).cbins,2)*100; x(1) = x(1)+1;
end

% data
clear mon_all bin_all
for L = 1:3
de_all(L).units = LAY.MON.DE_PS(L).RESP;
nde_all(L).units = LAY.MON.NDE_PS(L).RESP;
bin_all(L).units = LAY.BIN.PS(L).RESP;
end

for L = 1:3
    de_all(L).avg = nanmean(de_all(L).units,3);
    de_all(L).err = nanstd(de_all(L).units,[],3)./sqrt(size(de_all(L).units,3));
    nde_all(L).avg = nanmean(nde_all(L).units,3);
    nde_all(L).err = nanstd(nde_all(L).units,[],3)./sqrt(size(nde_all(L).units,3));
    bin_all(L).avg = nanmean(bin_all(L).units,3);
    bin_all(L).err = nanstd(bin_all(L).units,[],3)./sqrt(size(bin_all(L).units,3));
end

% models
for L = 1:3
[LSM(L).units,AVE(L).units,QSM(L).units,SUP(L).units] = modelAnalysis(de_all(L).units,nde_all(L).units);

SUP(L).units = real(SUP(L).units);
end



for L = 1:3
    LSM(L).avg = nanmean(LSM(L).units,3);
    LSM(L).err = nanstd(LSM(L).units,[],3)./sqrt(size(LSM(L).units,3));
    QSM(L).avg = nanmean(QSM(L).units,3);
    QSM(L).err = nanstd(QSM(L).units,[],3)./sqrt(size(QSM(L).units,3));
    SUP(L).avg = nanmean(SUP(L).units,3);
    SUP(L).err = nanstd(SUP(L).units,[],3)./sqrt(size(SUP(L).units,3));
end


global Data
Data(1,:) = x;
figure('position',[573,92,347,765]);
clear nBIN nLSM nQSM nSUP

for L = 1:3  % number of layers
    bin_ref = bin_all(L).avg(:,1);
    bin = bin_all(L).avg(:,tw);
    lsm = LSM(L).avg(:,tw);
    qsm = QSM(L).avg(:,tw);
    sup = SUP(L).avg(:,tw);
    
    mn       = min(bin_ref);
    mx       = max(bin_ref);
    nBIN     = (bin - mn)./(mx - mn);
    nLSM     = (lsm - mn)./(mx - mn);
    nQSM     = (qsm - mn)./(mx - mn);
    nSUP     = (sup - mn)./(mx - mn);
    
    for curve = 1:size(curves, 2)
        switch curves{curve}
            case 'bin'
                Data(2,:) = nBIN;
            case 'lsm'
                Data(2,:) = nLSM;
            case 'qsm'
                Data(2,:) = nQSM;
            case 'sup'
                Data(2,:) = nSUP;
        end
        
        [a,K ,n ,~] = BMfitCRdata;
        predictions = 1:100;
        for c = 1:length(predictions)
            prd(curve,c) = a*[(c^n)/((c^n) + (K^n))]; % prediction
        end
    end
    
    % Plot
    subplot(3,1,L)
    s1 = semilogx(predictions,prd(1,:),'color',[0.2, 0.2, 0.2],'linestyle','-','linewidth',2,'HandleVisibility','off');  hold on
    s2 = semilogx(predictions,prd(2,:),'color',[0.8, 0.2, 0.2],'linestyle',':','linewidth',2.2,'HandleVisibility','off');  hold on
    s3 = semilogx(predictions,prd(3,:),'color',[0.1, 0.4, 0.8],'linestyle',':','linewidth',2.2,'HandleVisibility','off');  hold on
    s4 = semilogx(predictions,prd(4,:),'color',[0.4, 0.6, 0.2],'linestyle',':','linewidth',2.2,'HandleVisibility','off');  hold on
    
%     s4 = semilogx(Data(1,:),nDE,'o','color',[0.2 0.2 0.2]+0.5,'linewidth',2,'markersize',5);
%     s5 = semilogx(Data(1,:),nNDE,'o','color',[.4 .4 .4],'linewidth',2,'markersize',5);
     s6 = semilogx(Data(1,:),nBIN,'*','color',[0.2 0.2 0.2],'linewidth',2,'markersize',5);
    
    set(gca,'FontSize',14,'linewidth',2,'box','off',...
        'xlim',[1 100],...
        'XTick',x);
    
    if tw == 1
        set(gca,'ylim',[0 1.4]);
    else
        set(gca,'ylim',[0 0.9]);
    end
    
    if L == 1 || L == 2 
        xticklabels([]); ylabel([]); 
        yticklabels([]);
    elseif L == 3 && tw == 1
        xticks([1,5,10,20,50,100]);
        ylabel('Normalized response','fontsize',16);
        xlabel('% contrast','fontsize',16);
    elseif L == 3 && tw == 2
        ylabel([]); 
        xticks([1,5,10,20,50,100]);
    end
    

end


if flag_figsave == 1
    cd(strcat(figDir,'VSS_v3\'));
    saveas(gcf, strcat('Figure 7_', num2str(tw),'.svg'));
    sprintf("Figure saved");
else
    sprintf("Figure was not saved");
end


%% Table
clear *LSM* *AVE* *QSM* *SUP*
clear de nde bin
models = {'LSM','AVE','QSM','SUP'};

% choices
model = 'LSM';
tw = 2;

    clear de nde bin
    for L = 1:3
        de(L).units = LAY.MON.DE_PS(L).RESP;
        nde(L).units = LAY.MON.NDE_PS(L).RESP;
        bin(L).units = LAY.BIN.PS(L).RESP;
    end
    
    for L = 1:3
        de(L).avg = squeeze(nanmean(de(L).units,3));
        de(L).err = squeeze(nanstd(de(L).units,[],3)./sqrt(size(de(L).units,3)));
        nde(L).avg = squeeze(nanmean(nde(L).units,3));
        nde(L).err = squeeze(nanstd(nde(L).units,[],3)./sqrt(size(nde(L).units,3)));
        bin(L).avg = nanmean(bin(L).units,3);
        bin(L).err = nanstd(bin(L).units,[],3)./sqrt(size(bin(L).units,3));
    end
    
    for L = 1:3
        [LSM(L).units,~,QSM(L).units,SUP(L).units] = modelAnalysis(de(L).units,nde(L).units);
    end
    
    for L = 1:3
        LSM(L).avg = nanmean(LSM(L).units,3);
        LSM(L).err = nanstd(LSM(L).units,[],3)./sqrt(size(LSM(L).units,3));
        QSM(L).avg = nanmean(QSM(L).units,3);
        QSM(L).err = nanstd(QSM(L).units,[],3)./sqrt(size(QSM(L).units,3));
        SUP(L).avg = nanmean(SUP(L).units,3);
        SUP(L).err = nanstd(SUP(L).units,[],3)./sqrt(size(SUP(L).units,3));
    end


switch cont
    case 4
        c = 90;
    case 3
        c = 45;
    case 2 
        c = 22;
end

switch model
    case 'LSM'
        mdl = LSM;
    case 'AVE'
        mdl = AVE;
    case 'QSM'
        mdl = QSM;
    case 'SUP'
        mdl = SUP;
end
% Plot  
figure('position',[784.4285714285713,76.42857142857143,368.5714285714287,847.4285714285713]);
for L = 1:3
subplot(3,1,L)

%plot([0,22.5,45,90],smooth(squeeze(nde.avg(:,tw,:))),'Color',[0.1,0.1,0.1]+0.4,'linewidth',2);hold on
plot([0,22.5,45,90],smooth(squeeze(LSM(L).avg(:,tw))),':r','linewidth',2); hold on
plot([0,22.5,45,90],smooth(squeeze(QSM(L).avg(:,tw))),':b','linewidth',2)
plot([0,22.5,45,90],smooth(squeeze(SUP(L).avg(:,tw))),':g','linewidth',2)
plot([0,22.5,45,90],smooth(squeeze(bin(L).avg(:,tw))),'k','linewidth',2)

err1 = errorbar([0,22.5,45,90],smooth(bin(L).avg(:,tw)),smooth(bin(L).err(:,tw)));
set(err1,'color','k','linestyle','none','handleVisibility','off');
%err2 = errorbar([0,22.5,45,90],smooth(nde.avg(:,tw,:)),smooth(nde.err(:,tw,:)));
%set(err2,'color','k','linestyle','none','handleVisibility','off');
%err3 = errorbar([0,22.5,45,90],smooth(bin.avg(:,tw,:)),smooth(bin.err(:,tw,:)));
%set(err3,'color','k','linestyle','none','handleVisibility','off');

[h,p] = ttest_time(bin(L).units,mdl(L).units); tmh = find(h(tw,:));
%scatter(mon.units(tmh), ones(1,numel(tmh)) * max(bin.avg(3,:)) * 1.2,4,'*k') % significance bar

set(gca,'box','off','linewidth',2,'FontSize',16,...
   'ylim',[0 130]);
% xlabel([]); 
xticks([0, 20, 40, 60, 80, 100]);
xticklabels([0, 20, 40, 60, 80, 100]);
ylabel('impulses per sec','Fontsize',16);
xlabel('% contrast','Fontsize',16);

    if L == 1
        %title(sprintf('Upper (n = %d)',layerLengths(1)),'FontSize',16);
        %bCt = sum(Trls.bin(cont,1,:),'all'); 
        %legend(sprintf('BIN %d|%d (%d trials)',c,c,bCt),sprintf('Model %s',model),'location','southeast'); legend boxoff
        ylabel([]);
        xticklabels([]); xlabel([]);
        yticklabels([]); xticklabels([]);
    elseif L == 2
            %title(sprintf('Middle (n = %d)',layerLengths(2)),'FontSize',16);
            ylabel([]);
            xticklabels([]); xlabel([]);
            yticklabels([]); xticklabels([]);
                    lgn = legend('LS','QS','SUP','BIN','location','northwest'); legend boxoff
        set(lgn,'fontsize',10);  
    else 
  
    end

end

%sgtitle(sprintf('dMUA | N = %d | Penetrations: %d \nContrast: %d|%d | Model: %s',uct,N,c,c,model),'Fontsize',16); 
if flag_figsave == 1
    cd(strcat(figDir,'VSS_v3\'));
    saveas(gcf, strcat(model,'_',num2str(c),'_RESP', '.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end
