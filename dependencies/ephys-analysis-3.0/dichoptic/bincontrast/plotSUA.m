%% For display of single units
flag_figsave = 0;
labmeeting = 1;

% Figure save directory
if strcmp(getenv('username'),'bmitc')
    figDir = 'C:\Users\bmitc\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'mitchba2')
    figDir = 'C:\Users\mitchba2\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'bmitc_000')
    figDir = 'C:\Users\bmitc_000\OneDrive - Vanderbilt\Maier Lab\Figures\';
end



%% Single: SDF 
monCond     = {'DE_PS','NDE_PS','DE_NS','NDE_NS'};
binCond     = {'PS','NS'};

% choices
unit = 1;
cont = 4;
mon = 1;
bin = 1;

% data
y1 = squeeze(UNIT.MON.(monCond{mon}).SDF(cont,:,unit));
y2 = squeeze(UNIT.MON.NDE_PS.SDF(cont,:,unit));
y3 = squeeze(UNIT.BIN.PS.SDF(cont,:,unit));

err1 = squeeze(UNIT.MON.DE_PS.SDF_error(cont,:,unit));
err2 = squeeze(UNIT.MON.NDE_PS.SDF_error(cont,:,unit));
err3 = squeeze(UNIT.BIN.PS.SDF_error(cont,:,unit));

figure('position',[215.6666666666667,200,752,363.3333333333333]);

plot(sdfWin,y1,'k','linewidth',2); hold on
ci1 = ciplot(y1+err1,y1-err1,sdfWin,'k',0.1); set(ci1,'linestyle','none','handleVisibility','off');

%plot(sdfWin,y2,'color',[0,0,0]+0.8,'linewidth',2); hold on
%ci2 = ciplot(y2+err2,y2-err2,sdfWin,[0 0 0]+0.2,0.1); set(ci2,'linestyle','none','handleVisibility','off');

%plot(sdfWin,y3,'color','b','linewidth',2); hold on
%ci3 = ciplot(y3+err3,y3-err3,sdfWin,'b',0.1); set(ci3,'linestyle','none','handleVisibility','off');

set(gca,'Box','off','TickDir','out','linewidth',2.5,'ylim',[-5 max(y3)+40],'xlim',[-.15 .500],'FontSize',16)

ylabel('spikes / sec','Fontsize',20);
xlabel('time (s) from stim onset','Fontsize',20);

%xlabel([]); ylabel([]); yticklabels([]);xticklabels([]);

if flag_figsave == 1
    cd(strcat(figDir,'sua\'));
    saveas(gcf, strcat('MONvsBIN_',num2str(unit),'.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end


%% Single Unit: RESP

% choices
tw = 1;
unit = 8;
cont = 4;

% data
y1 = squeeze(UNIT.MON.DE_PS.RESP(4,tw,:));
y2 = squeeze(UNIT.MON.NDE_PS.RESP(4,tw,:));
y3 = squeeze(UNIT.BIN.PS.RESP(4,tw,:));

err1 = squeeze(UNIT.MON.DE_PS.SDF_error(:,:,:));
err2 = squeeze(UNIT.MON.NDE_PS.SDF_error(:,:,:));
err3 = squeeze(UNIT.BIN.PS.SDF_error(:,:,:));

meanline = median(y1);

figure;
scatter(1:8,y1); hold on
hline(meanline);

set(gca,'Box','off','TickDir','out','linewidth',2.5,'FontSize',16)
ylabel('peak spikes / sec','Fontsize',20);
xlabel('Unit #','Fontsize',20);
%plot(1:8,y3,'color','b'); hold on





%% UNIT: Dichoptic

unit = 16;
clear y1 y2 y3
figure;
x = sdftm;
y1 = squeeze(dMUA(unit).monSDF(4,:,1)); y1 = bsxfun(@minus, y1, mean(y1(:,50:100,1),2)); % DE | PS
y2 = squeeze(dMUA(unit).diSDF(5:6,:,1)); y2 = bsxfun(@minus, y2, mean(y2(:,50:100,1),2)); % DI | PS
y3 = squeeze(dMUA(unit).binSDF(4,:,1)); y3 = bsxfun(@minus, y3, mean(y3(:,50:100,:),2)); % BIN | PS
err1 = squeeze(dMUA(unit).monSDF_SEM(4,:,1));
err2 = squeeze(dMUA(unit).diSDF_SEM(5:6,:,1));
err3 = squeeze(dMUA(unit).binSDF_SEM(4,:,1));
% U1 = y1+1.96.*err1; % CI 95% upper
% L1 = y1-1.96.*err1; % CI 95% lower
plot(x,y1,'linewidth',2); hold on
%ci1 = ciplot(y1+err1,y1-err1,x,'k',0.1); set(ci1,'linestyle','none','handleVisibility','off');
plot(x,y2,'linewidth',2); 
%ci2 = ciplot(y2+err2,y2-err2,x,'k',0.1); set(ci2,'linestyle','none','handleVisibility','off');
plot(x,y3,'linewidth',2); 
%ci3 = ciplot(y3+err3,y3-err3,x,'k',0.1); set(ci3,'linestyle','none','handleVisibility','off');
set(gca,'box','off','FontSize',14,'linewidth',1.5,'ylim',[-20 350],'xlim',[-.050 .300])
xlabel('time (s) from stim onset'); ylabel('impulses per sec');
legend('90|0','90|22','90|45','90|90','location','northeast')
title({[dMUA(unit).penetration,' | dMUA | ','Depth: ' num2str(dMUA(unit).depth(2,1))]},'Interpreter','none')

cd('C:\Users\bmitc\OneDrive\4. Vanderbilt\Maier Lab\Figures\single\')
saveas(gcf, strcat('sdf-dichoptic', '.svg'));

%% UNIT: DE vs NDE vs BIN vs QSM
clear y1 y2 y3 y4 y5 y6
unit = 17;
figure;
x = sdftm;
y1 = squeeze(dMUA(unit).monSDF(4,:,1)); y1 = bsxfun(@minus, y1, mean(y1(:,50:100,:),2));% DE | PS
y2 = squeeze(dMUA(unit).monSDF(4,:,3)); y2 = bsxfun(@minus, y2, mean(y2(:,50:100,:),2));% NDE | PS
y3 = squeeze(dMUA(unit).binSDF(4,:,1)); y3 = bsxfun(@minus, y3, mean(y3(:,50:100,:),2));% BIN | PS
y4 = sqrt((y1.^2) + (y2.^2));
y5 = (y1 + y2)./2;
y6 = y1 + y2;
err1 = squeeze(dMUA(unit).monSDF_SEM(4,:,1));
err2 = squeeze(dMUA(unit).monSDF_SEM(4,:,3));
err3 = squeeze(dMUA(unit).binSDF_SEM(4,:,1));
% U1 = y1+1.96.*err1; % CI 95% upper
% L1 = y1-1.96.*err1; % CI 95% lower
plot(x,y1,'-b','linewidth',2); hold on
ci1 = ciplot(y1+err1,y1-err1,x,'k',0.1); set(ci1,'linestyle','none','handleVisibility','off');
plot(x,y2,'b','linewidth',1); 
ci2 = ciplot(y2+err2,y2-err2,x,'k',0.1); set(ci2,'linestyle','none','handleVisibility','off');
plot(x,y3,'r','linewidth',2); 
ci3 = ciplot(y3+err3,y3-err3,x,'k',0.1); set(ci3,'linestyle','none','handleVisibility','off');
plot(x,y4,'--k','linewidth',2.5); 
set(gca,'box','off','FontSize',14,'linewidth',1.5,'ylim',[-20 450],'xlim',[-.100 .500])
xlabel('time (s) from stim onset'); ylabel('impulses per sec');
legend('DE','NDE','BIN','location','northeast')
title({[dMUA(unit).penetration,' | dMUA | ','Depth: ' num2str(dMUA(unit).depth(2,1))]},'Interpreter','none')

cd('C:\Users\bmitc\OneDrive\4. Vanderbilt\Maier Lab\Figures\single\')
saveas(gcf, strcat('sdf-BIN-QSM', '.svg'));

