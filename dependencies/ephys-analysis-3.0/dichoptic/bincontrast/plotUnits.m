%% Plotting averaged units. 
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

switch datatype
    case 'kls'
        yL = 'spikes / s';
    case 'auto'
        yL = 'impulses / s';
    case 'csd'
        yL = 'current source density something';
end

% colors
orange = [0.8500, 0.3250, 0.0980];
light_orange = [0.9290, 0.6940, 0.1250];
blue = [0, 0.4470, 0.7410];
green = [0.4940, 0.1840, 0.5560];
cyan = [0.3010, 0.7450, 0.9330];
dark_red = 	[0.6350, 0.0780, 0.1840];
purple = [0.4940, 0.1840, 0.5560];
black = [0.25, 0.25, 0.25];

%% Averaged contrast and units. 
clear mon bin de nde 

% data
clear de nde bin
    
de.units = UNIT.MON.DE_PS.SDF;
nde.units = UNIT.MON.NDE_PS.SDF;
bin.units = UNIT.BIN.PS.SDF;

de.avg = nanmean(de.units,3);
de.err = nanstd(de.units,[],3)./sqrt(size(de.units,3));
nde.avg = nanmean(nde.units,3);
nde.err = nanstd(nde.units,[],3)./sqrt(size(nde.units,3));
bin.avg = nanmean(bin.units,3);
bin.err = nanstd(bin.units,[],3)./sqrt(size(bin.units,3));

de.fullAvg = nanmean(de.avg,1);
nde.fullAvg = nanmean(nde.avg,1);
bin.fullAvg = nanmean(bin.avg,1);
    

% Plot
figure('position',[373,544,801,377]);

plot(sdfWin,de.fullAvg,'color',blue,'linewidth',2); hold on
%ci1 = ciplot(de.avg(cont,:)+de.err(cont,:),...
    %de.avg(cont,:)-de.err(cont,:),sdfWin,'k',0.1); set(ci1,'linestyle','none','handleVisibility','off');
%plot(sdfWin,nde.avg(cont,:),'color',[0,0,0]+0.8,'linewidth',2); hold on
%ci2 = ciplot(nde.avg(cont,:)+nde.err(cont,:),...
    %nde.avg(cont,:)-nde.err(cont,:),sdfWin,'k',0.1); set(ci2,'linestyle','none','handleVisibility','off');
plot(sdfWin,bin.fullAvg,'color',orange,'linewidth',2); hold on
%ci1 = ciplot(bin.avg(cont,:)+bin.err(cont,:),...
    %bin.avg(cont,:)-bin.err(cont,:),sdfWin,'k',0.1); set(ci1,'linestyle','none','handleVisibility','off');

clear h p ci stats
[h,p, stats] = ttest_time(nanmean(bin.units,1),nanmean(de.units,1)); tmh = find(h);
scatter(sdfWin(tmh), ones(1,numel(tmh)) * max(bin.fullAvg) * 1.2,4,'*k')


set(gca,'Box','off','TickDir','out','linewidth',2,'ylim',[-5 110],'xlim',[0 .250],...
    'Fontsize',14)

lgn = legend('Monocular (MON)','Binocular (BIN)','location','southeast'); legend boxoff
set(lgn,'fontsize',16);


xlabel('time from stimulus onset (s)','FontSize',16);
ylabel(sprintf('stimulus evoked \nimpulses per sec'),'FontSize',16);


mCt = sum(Trls.mon(:,1,:),'all'); bCt = sum(Trls.bin(:,1,:),'all');

%legend(sprintf('DE PS (%d trials)',mCt),sprintf('BIN PS (%d trials)',bCt),'location','northwest','FontSize',12); legend boxoff

%legend('dominant eye (DE)','nondominant eye (NDE)','location','northwest');

if flag_figsave == 1
    cd(strcat(figDir,'units\'));
    saveas(gcf, strcat('MONvsBIN_fullAVG','.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end
%% MON vs BIN - sdf 
clear mon bin de nde 
% choices
cont = 3;

switch cont
    case 4
        c = '90';
    case 3
        c = '45';
    case 2 
        c = '22';
end

% data
clear de nde bin
    
de.units = UNIT.MON.DE_PS.SDF;
nde.units = UNIT.MON.NDE_PS.SDF;
bin.units = UNIT.BIN.PS.SDF;

de.avg = nanmean(de.units,3);
de.err = nanstd(de.units,[],3)./sqrt(size(de.units,3));
nde.avg = nanmean(nde.units,3);
nde.err = nanstd(nde.units,[],3)./sqrt(size(nde.units,3));
bin.avg = nanmean(bin.units,3);
bin.err = nanstd(bin.units,[],3)./sqrt(size(bin.units,3));
    
% colors
orange = [0.8500, 0.3250, 0.0980];
light_orange = [0.9290, 0.6940, 0.1250];
blue = [0, 0.4470, 0.7410];
green = [0.4940, 0.1840, 0.5560];
cyan = [0.3010, 0.7450, 0.9330];
dark_red = 	[0.6350, 0.0780, 0.1840];
purple = [0.4940, 0.1840, 0.5560];
black = [0.25, 0.25, 0.25];

% Plot
figure('position',[324,549,493,288]);

plot(sdfWin,de.avg(cont,:),'color',blue,'linewidth',2); hold on
ci1 = ciplot(de.avg(cont,:)+de.err(cont,:),...
    de.avg(cont,:)-de.err(cont,:),sdfWin,'k',0.1); set(ci1,'linestyle','none','handleVisibility','off');
%plot(sdfWin,nde.avg(cont,:),'color',[0,0,0]+0.8,'linewidth',2); hold on
%ci2 = ciplot(nde.avg(cont,:)+nde.err(cont,:),...
    %nde.avg(cont,:)-nde.err(cont,:),sdfWin,'k',0.1); set(ci2,'linestyle','none','handleVisibility','off');
plot(sdfWin,bin.avg(cont,:),'color',orange,'linewidth',2); hold on
ci1 = ciplot(bin.avg(cont,:)+bin.err(cont,:),...
    bin.avg(cont,:)-bin.err(cont,:),sdfWin,'k',0.1); set(ci1,'linestyle','none','handleVisibility','off');

clear h p ci stats
[h,p, stats] = ttest_time(bin.units,de.units); tmh = find(h(cont,:));
scatter(sdfWin(tmh), ones(1,numel(tmh)) * max(bin.avg(cont,:)) * 1.1,4,'*k')

ylabel(yL,'fontsize',16);
xlabel('time (s) from stim onset','Fontsize',16);
% if cont > 2 && pres = true
%     xlabel([]); ylabel([]); xticklabels([]);
% end
ylimit = max(bin.avg(cont,:));
set(gca,'Box','off','TickDir','out','linewidth',1.5,'ylim',[-5 160],'xlim',[0 .250],'FontSize',16)

mCt = sum(Trls.mon(cont,1,:),'all'); bCt = sum(Trls.bin(cont,1,:),'all');

%legend(sprintf('DE PS (%d trials)',mCt),sprintf('BIN PS (%d trials)',bCt),'location','northwest','FontSize',12); legend boxoff

%legend('dominant eye (DE)','nondominant eye (NDE)','location','northwest');

if flag_figsave == 1
    cd(strcat(figDir,'units\'));
    saveas(gcf, strcat('MONvsBIN_',c,'.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end

%% DE_PS vs BIN_PS - resp (simple lineplot)
% choices
tw = 1; % timewindow

% strings
contrasts = 0:100;

% data
clear *mon* *bin*
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
figure('position',[891,371,423,420]);

plot([0,22.5,45,90],smooth(squeeze(mon.avg(:,tw,:))),'color',cyan,'linewidth',2);hold on
%plot([0,22.5,45,90],smooth(squeeze(nde.avg(:,tw,:))),'Color',[0.1,0.1,0.1]+0.4,'linewidth',2);hold on
plot([0,22.5,45,90],smooth(squeeze(bin.avg(:,tw,:))),'color',dark_red,'linewidth',2)

err1 = errorbar([0,22.5,45,90],smooth(mon.avg(:,tw,:)),smooth(mon.err(:,tw,:)));
set(err1,'color','k','linestyle','none','handleVisibility','off');
%err2 = errorbar([0,22.5,45,90],smooth(nde.avg(:,tw,:)),smooth(nde.err(:,tw,:)));
%set(err2,'color','k','linestyle','none','handleVisibility','off');
err3 = errorbar([0,22.5,45,90],smooth(bin.avg(:,tw,:)),smooth(bin.err(:,tw,:)));
set(err3,'color','k','linestyle','none','handleVisibility','off');

respwin = length(mon.units);
[h,p] = ttest_time(mon.units,bin.units); tmh = find(h(tw,:));
%scatter([0,22.5,45,90], ones(1,numel(tmh)) * max(bin.avg(3,:)) * 1.2,4,'*k') % significance bar

set(gca,'box','off','linewidth',2,'FontSize',16,...
   'ylim',[0 150]);
% xlabel([]); 
xticks([0, 20, 40, 60, 80, 100]);
xticklabels([0, 20, 40, 60, 80, 100]);
ylabel('impulses per sec','Fontsize',16);
xlabel('% contrast','Fontsize',16);

if flag_figsave == 1
    cd(strcat(figDir,'units\'));
    saveas(gcf, strcat('MONvsBIN_',num2str(tw), '.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end


%% DE_PS vs BIN_PS - resp (violin plots)

% choices
tw = 3; % timewindow
type = 1; % 1 is mon vs bin, 2 is mon, 3 is bin

% if type 1
cont = 2; % contrast

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
        'showMM',1,'color',{blue,dark_red},...
        'xNames',{'MON','BIN'},'globalNorm',2,'addSpread',0);
elseif type == 2
    hh = distributionPlot([squeeze(mon.units(2,tw,:)) squeeze(mon.units(3,tw,:)) squeeze(mon.units(4,tw,:))],...
        'showMM',5,'color',{[0.2 0.2 0.2],[0.2, 0.2, 0.2],[0.2 0.2 0.2]},...
        'xNames',{'','',''},'globalNorm',2,'addSpread',0);
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
%ylabel('impulses per sec','Fontsize',16);
%xlabel('% contrast','Fontsize',16);
hold on
set(gca,'box','off','linewidth',2,'FontSize',16,...
    'ylim',[0 inf]);

if flag_figsave == 1
    cd(strcat(figDir,'units\'));
    saveas(gcf, strcat('MON_violin_', num2str(tw),'.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end

clear L y1 y2 bsl_y1 bsl_y2 mCt bCt x data_flag

%% MON vs BIN - superbar
% data
orange = [0.8500, 0.3250, 0.0980];
light_orange = [0.9290, 0.6940, 0.1250];
blue = [0, 0.4470, 0.7410];
green = [0.4660, 0.6740, 0.1880];
cyan = [0.3010, 0.7450, 0.9330];
dark_red = 	[0.6350, 0.0780, 0.1840];
purple = [0.4940, 0.1840, 0.5560];
black = [0.25, 0.25, 0.25];

clear mon bin

mon.units = UNIT.MON.DE_PS.RESP;
bin.units = UNIT.BIN.PS.RESP;

mon.avg = nanmean(mon.units,3);
mon.err = nanstd(mon.units,[],3)./sqrt(size(mon.units,3));
bin.avg = nanmean(bin.units,3);
bin.err = nanstd(bin.units,[],3)./sqrt(size(bin.units,3));


% Plot: DE PS vs BIN PS - resp
C = [0.3010, 0.7450, 0.9330;0.6350, 0.0780, 0.1840];
tw = 1; 
figure('position',[562,269,323,307]);


[h,p] = ttest_time(mon.units,bin.units); %tmh = find(h(cont,:));
P = nan(8,8);
P(1,5) = p(1,tw);
P(2,6) = p(2,tw);
P(3,7) = p(3,tw);
P(4,8) = p(4,tw);
PT = P';
lidx = tril(true(size(P)), -1);
P(lidx) = PT(lidx);

ylimit = max(bin.avg(:,1));
set(gca,'box','off','linewidth',1.8,'FontSize',16,'ylim',[0 160],'xlim',[0.5 4.5]);
superbar([mon.avg(:,tw),bin.avg(:,tw)],...
    'E',[mon.err(:,tw),bin.err(:,tw)],...
    'P', P, 'PStarThreshold',[0.01 0.001 0.0001],'PStarOffset',20,...
    'BarWidth',0.665,'BarFaceColor',permute(C,[3 1 2]),...
    'BarEdgeColor','k'); hold on


xlabel([]);
ylabel('impulses per sec','Fontsize',16);
xticklabels([]);



%mCt = sum(Trls.mon(:,1,:),'all'); bCt = sum(Trls.bin(:,1,:),'all');

%legend([1 5],sprintf('DE PS (%d trials)',mCt),sprintf('BIN PS (%d trials)',bCt),'location','northwest','FontSize',12); legend boxoff
%itle(sprintf('dMUA | N = %d | Penetrations: %d \nWindow: %s',uct,N,windows{tw}),'Fontsize',16); 

if flag_figsave == 1
    cd(strcat(figDir,'units\'));
    saveas(gcf, strcat('MONvsBIN_superbar',num2str(tw), '.svg'));
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