%% plotLayers.m 
% plot continuous and discrete responses to stimulus conditions

% Toggle to save figures
flag_figsave = 0;

% Figure save directory
if strcmp(getenv('username'),'bmitc')
    figDir = 'C:\Users\bmitc\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'mitchba2')
    figDir = 'C:\Users\mitchba2\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'bmitc_000')
    figDir = 'C:\Users\bmitc_000\OneDrive - Vanderbilt\Maier Lab\Figures\';
end
%% Plot: DE PS vs BIN PS - sdf

% choices
cont = 2; 

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

figure('position',[774.7142857142857,326.7142857142857,370.8571428571428,724.5714285714284]);
for L = 1:3 % layer
    subplot(3,1,L)
    plot(sdfWin,mon(L).avg(cont,:),'k','linewidth',1.5); hold on
    ci1 = ciplot(mon(L).avg(cont,:)+mon(L).err(cont,:),mon(L).avg(cont,:)-mon(L).err(cont,:),sdfWin,'k',0.1); 
        set(ci1,'linestyle','none','handleVisibility','off');
    plot(sdfWin,bin(L).avg(cont,:),'b','linewidth',1.5)
    ci2 = ciplot(bin(L).avg(cont,:)+bin(L).err(cont,:),bin(L).avg(cont,:)-bin(L).err(cont,:),sdfWin,'b',0.1); 
        set(ci2,'linestyle','none','handleVisibility','off');
    
    [h,p] = ttest_time(mon(L).units,bin(L).units); tmh = find(h(cont,:));
    scatter(sdfWin(tmh), ones(1,numel(tmh)) * max(bin(L).avg(cont,:))+22,4,'*k') % significance bar
    
    set(gca,'Box','off','TickDir','out','linewidth',1.5,'ylim',[-5 max(bin(L).avg(cont,:))+40],'xlim',[0 .250],...
    'Fontsize',12)
    
    if L == 1 
        %title(sprintf('Upper (n = %d)',layerLengths(1)),'FontSize',16);
        yticklabels([]); xticklabels([]);
        mCt = sum(Trls.mon(cont,1,:),'all'); bCt = sum(Trls.bin(cont,1,:),'all');
        lgn = legend(sprintf('DE PS (%d trials)',mCt),sprintf('BIN PS (%d trials)',bCt),'location','southeast'); legend boxoff
        set(lgn,'fontsize',8);
    elseif L == 2 
            %title(sprintf('Middle (n = %d)',layerLengths(2)),'FontSize',16);
            yticklabels([]); xticklabels([]);
    else 
            %title(sprintf('Deep (n = %d)',layerLengths(3)),'FontSize',16);
            if cont == 2
            xlabel('time (s)','FontSize',14); ylabel('Impulses per sec','FontSize',14);
            end
    end
end

%sgtitle(sprintf('dMUA | N = %d | Penetrations: %d',uct,N),'fontsize',16); 

if flag_figsave == 1
    cd(strcat(figDir,'layers\'));
    saveas(gcf, strcat('MONvsBIN_sdf_',c,'.svg'));
    sprintf("Figure saved");
else
    sprintf("Figure was not saved");
end

clear L mCt bCt

%% DE_PS vs BIN_PS - resp (superbar)
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
C = [.2 .2 .2;.2 .2 .8];
tw = 3; 
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
    end
end

%mCt = sum(Trls.mon(:,1,:),'all'); bCt = sum(Trls.bin(:,1,:),'all');

%legend([1 5],sprintf('DE PS (%d trials)',mCt),sprintf('BIN PS (%d trials)',bCt),'location','northwest','FontSize',12); legend boxoff
%itle(sprintf('dMUA | N = %d | Penetrations: %d \nWindow: %s',uct,N,windows{tw}),'Fontsize',16); 

if flag_figsave == 1
    cd(strcat(figDir,'layers\'));
    saveas(gcf, strcat('MONvsBIN_resp', '.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end
clear L y1 y2 bsl_y1 bsl_y2 mCt bCt bin mon x data_flag

%% DE_PS vs BIN_PS - resp (violin plots)

% choices
windows = {'40-140ms','141-450ms','40-250ms'};
tw = 3; 
cont = 4;

% data
clear mon bin
for L = 1:3  %store mon and bin units into struct
mon(L).units = LAY.MON.DE_PS(L).RESP;
bin(L).units = LAY.BIN.PS(L).RESP;
end

for L = 1:3 %retrieve avg and error
    mon(L).avg = nanmean(mon(L).units,3);
    mon(L).err = nanstd(mon(L).units,[],3)./sqrt(size(mon(L).units,3));
    bin(L).avg = nanmean(bin(L).units,3);
    bin(L).err = nanstd(bin(L).units,[],3)./sqrt(size(bin(L).units,3));
end

% Plot
figure('position',[573,92,347,765]);
for L = 1:3
subplot(3,1,L);
distributionPlot([squeeze(mon(L).units(cont,tw,:)) squeeze(bin(L).units(cont,tw,:))],...
    'showMM',4,'color',{[0.1 0.1 0.1],[0.2, 0.2, 0.5]},...
    'xNames',{'MON','BIN'},'globalNorm',2,'addSpread',0)
hold on
set(gca,'box','off','linewidth',2,'FontSize',16,...
    'ylim',[-100 max(bin(1).units(cont,tw,:))*1.2]);

    if L == 1
        title(sprintf('Upper',layerLengths(1)),'FontSize',16);
        xlabel([]); xticklabels([]); yticklabels([]);
        
    elseif L == 2
            title(sprintf('Middle',layerLengths(2)),'FontSize',16);
            yticklabels([]); xlabel([]); xticklabels([]);
        else 
            title(sprintf('Deep',layerLengths(3)),'FontSize',16);  
            ylabel('impulses per sec','Fontsize',16);
    end
end

% mCt = sum(Trls.mon(:,1,:),'all'); bCt = sum(Trls.bin(:,1,:),'all');

if flag_figsave == 1
    cd(strcat(figDir,'layers\'));
    saveas(gcf, strcat('MONvsBIN_violin_',num2str(tw),'.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end

clear L y1 y2 bsl_y1 bsl_y2 mCt bCt bin mon x data_flag

%% Model Predictions - sdf
models = {'LSM','AVE','QSM','SUP'};
x = sdfWin;

% choices
cont = 4;
model = 'SUP';

if ~exist('data_flag')
    % data
    clear de nde bin
    for L = 1:3
        de(L).units = LAY.MON.DE_PS(L).SDF;
        nde(L).units = LAY.MON.NDE_PS(L).SDF;
        bin(L).units = LAY.BIN.PS(L).SDF;
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
        [LSM(L).units,AVE(L).units,QSM(L).units,SUP(L).units] = modelAnalysis(de(L).units,nde(L).units);
    end
    
    for L = 1:3
        LSM(L).avg = nanmean(LSM(L).units,3);
        LSM(L).err = nanstd(LSM(L).units,[],3)./sqrt(size(LSM(L).units,3));
        AVE(L).avg = nanmean(AVE(L).units,3);
        AVE(L).err = nanstd(AVE(L).units,[],3)./sqrt(size(AVE(L).units,3));
        QSM(L).avg = nanmean(QSM(L).units,3);
        QSM(L).err = nanstd(QSM(L).units,[],3)./sqrt(size(QSM(L).units,3));
        SUP(L).avg = nanmean(SUP(L).units,3);
        SUP(L).err = nanstd(SUP(L).units,[],3)./sqrt(size(SUP(L).units,3));
    end
    data_flag = 1;
else 
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
plot(x,bin(L).avg(cont,:),'b','linewidth',2); hold on
ci1 = ciplot(bin(L).avg(cont,:)+bin(L).err(cont,:),...
    bin(L).avg(cont,:)-bin(L).err(cont,:),x,'b',0.1); set(ci1,'linestyle','none','handleVisibility','off');
plot(x,mdl(L).avg(cont,:),'k','linewidth',1); 
ci2 = ciplot(mdl(L).avg(cont,:)+mdl(L).err(cont,:),...
    mdl(L).avg(cont,:)-mdl(L).err(cont,:),x,'k',0.1); set(ci2,'linestyle','none','handleVisibility','off');

[h,p] = ttest_time(bin(L).units,mdl(L).units); tmh = find(h(cont,:));
%scatter(sdfWin(tmh), ones(1,numel(tmh)) * max(bin(L).avg(cont,:)) * 1.2,4,'*k') % significance bar

ylimit = max(bin(L).avg(cont,:));
set(gca,'Box','off','TickDir','out','linewidth',1.5,'ylim',[-10 ylimit*1.5],'xlim',[0 .300],'FontSize',12)

    if L == 1
        %title(sprintf('Upper (n = %d)',layerLengths(1)),'FontSize',16);
        bCt = sum(Trls.bin(cont,1,:),'all'); 
        legend(sprintf('BIN %d|%d (%d trials)',c,c,bCt),sprintf('Model %s',model),'location','southeast'); legend boxoff
        ylabel([]);
        xticklabels([]); xlabel([]);
    elseif L == 2
            %title(sprintf('Middle (n = %d)',layerLengths(2)),'FontSize',16);
            ylabel([]);
            xticklabels([]); xlabel([]);
        else 
            %title(sprintf('Deep (n = %d)',layerLengths(3)),'FontSize',16); 
            if cont == 2
            xlabel('time (s) from stim onset','Fontsize',16); 
            ylabel('impulses per sec','Fontsize',16);
            end
    end

end

%sgtitle(sprintf('dMUA | N = %d | Penetrations: %d \nContrast: %d|%d | Model: %s',uct,N,c,c,model),'Fontsize',16); 
if flag_figsave == 1
    cd(strcat(figDir,'layers\'));
    saveas(gcf, strcat(model,'_',num2str(c),'_sdf', '.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end


