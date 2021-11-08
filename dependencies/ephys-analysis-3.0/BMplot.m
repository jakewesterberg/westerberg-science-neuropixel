%% BMplot - compatible with BMtestscript workspace

unit = 2;

figure('position',[215.6666666666667,200,752,363.3333333333333]);
x = [0 22.5 45 90];
for tw = 1:2
    subplot(1,2,tw)
    y1 = squeeze(dMUA(unit).monRESP(:,tw,[1 3]));
    y2 = squeeze(dMUA(unit).binRESP(:,tw,1));
    plot(x,y1,'-o','MarkerFaceColor','b',...
        'MarkerEdgeColor','b','linewidth',1.5,'markersize',6); hold on
    plot(x,y2,'-d','MarkerFaceColor','r',...
        'MarkerEdgeColor','r','linewidth',1.5,'markersize',6); hold on
    set(gca,'box','off','FontSize',12,'linewidth',1.5,'xlim',[0 100],'ylim',[0 450])
    xlabel('stimulus contrast'); ylabel('impulses per sec');
    legend('DE|PS','NDE|PS','BIN|PS','NDE|NS','BIN|PS','BIN|NS','location','northwest');
    if tw == 1
        title({'Transient (40-140ms)'})
    else
        title('Sustained (141-450ms)')
    end
end
sgtitle({[dMUA(1).penetration,' | AUTO | ','Depth: ' num2str(dMUA(unit).depth(2,1))]},'Interpreter','none')
cd('C:\Users\bmitc\OneDrive\4. Vanderbilt\Maier Lab\Figures\single\')
saveas(gcf, strcat('example RESP', '.svg'));

%%
figure;
x = sdftm;
y = squeeze(dMUA(1).monSDF(4,:,1)); % DE | PS
err = squeeze(dMUA(1).monSDF_SEM(4,:,1));
U = y+1.96.*err;
L = y-1.96.*err;
plot(x,y,'linewidth',2); hold on
%scatter(x,y-err,.8,'b'); scatter(x,y+err,.8,'b');
% for c = 1:4
%confplot(x,y,err); hold on;
ci = ciplot(y+err,y-err,x,'k',0.1); set(ci,'linestyle','none');
%errorbar(x,y,err)
set(gca,'box','off','FontSize',14,'linewidth',1.5,'ylim',[0 180])
xlabel('time (s)'); ylabel('impulses per sec');
legend('High contrast','SEM','location','southeast')
%legend('0%','22.5%','45%','90%','BIN|0','BIN|90','location','northwest');
title({[dMUA(1).penetration,' | AUTO | ','Depth: ' num2str(dMUA(1).depth(2,1))]},'Interpreter','none')

cd('C:\Users\bmitc\OneDrive\4. Vanderbilt\Maier Lab\Figures\single\')
saveas(gcf, strcat('firstdMUA', '.svg'));

%%
cLevel = 4;
tw = 1;
figure;

barh(flipud(squeeze(BIN.dMUA.BIN_PS.resp(cLevel,tw,:))),0.8,...
    'FaceColor',[0.8500, 0.3250, 0.0980],'EdgeColor','k','LineWidth',0.8);
hold on
%bar(MON.dMUA.DE_PS.resp(:,3,selectchannels(c)),...
% 0.4,'FaceColor',[0, 0.4470, 0.7410],'EdgeColor','k','LineWidth',0.8);
barh(flipud(squeeze(MON.dMUA.DE_PS.resp(cLevel,tw,:))),0.6,...
    'FaceColor',[0, 0.4470, 0.7410],'EdgeColor','k','LineWidth',0.8);
set(gca,'box','off','ylim',[0.5 17.5],'xlim',[0 450]);
yticklabels(''); xlabel('impulses per sec')
ylabel('Electrode depth')
yticklabels({'-0.5','0','0.5','1','1.5','2','2.5'})
%title({'Contact',selectchannels(c)});
hold off


% sgtitle({'Monocular vs Binocular responses'...
%     'Collapsed across transient window (40-100ms)',BRdatafile},'Interpreter','none');

% cd('C:\Users\bmitc\OneDrive\4. Vanderbilt\Maier Lab\Figures\')
% export_fig(sprintf('%s_bar-contrasts-transient',BRdatafile), '-jpg', '-transparent');

%%
figure('position',[44.33333333333333,101,893.3333333333333,496]);
clear i
tw = 1;
for i = 1:4
subplot(1,4,i)
plot(squeeze(MON.dMUA.DE_PS.resp(i,tw,:)),STIM.depths(:,2),'linewidth',1.5,'Color',[0, 0.4470, 0.7410]);
hold on 
plot(squeeze(BIN.dMUA.BIN_PS.resp(i,tw,:)),STIM.depths(:,2),'linewidth',1.5','color','r');
grid off
xlim([0 500]);
%hline(0,':','BOL4')
%ylim([-7 17])
set(gca,'Box','off','linewidth',1.5,'FontSize',12)
hold off
    if i == 1
        %title('Low Contrast','FontSize',16);
        legend('One eye','Both eyes','Location','southeast','orientation','vertical');
            xlabel('Impulses per sec','FontSize',16);
            %yticklabels({'-0.5','0','0.5','1','1.5','2','2.5'})
            ylabel('Contact # relative to layer 4/5 boundary','FontSize',16);
    elseif i == 2
            %title('Medium Contrast','FontSize',16);
            %yticklabels([]);
            %xticklabels([]);
        else 
            %title('High Contrast','FontSize',16);
            %xticklabels([]);
            %yticklabels([]);
    end%
end
