% plotTuning
flag_figsave = 0;

% Figure save directory
if strcmp(getenv('username'),'bmitc')
    figDir = 'C:\Users\bmitc\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'mitchba2')
    figDir = 'C:\Users\mitchba2\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'bmitc_000')
    figDir = 'C:\Users\bmitc_000\OneDrive - Vanderbilt\Maier Lab\Figures\';
end

%% Size

unit = 7;
sizes = IDX(1).sizes;
sfs = IDX(1).sfs;


figure('position',[736,535,453,185]); 
b1 = bar(1:length(sizes),squeeze(UNIT.size.RESP(:,1,unit)));

set(b1,'FaceColor','none','BarWidth',1);


ylabel('spikes / sec');
xlabel('stimulus diameter (degrees)');
ylim([0 90]);

% Set the remaining axes properties
set(gca,'XTick',[1 2 3 4 5 6 7],'XTickLabel',...
    {'0.1','0.2','0.5','1','2','3','4'},'box','off');

if flag_figsave == 1
    cd(strcat(figDir,'RF\'));
    saveas(gcf, strcat('sizeTuned_',num2str(unit),'.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end


%% Orientation
figure('position',[264,120,1171,806]); 

for i = 1:length(IDX)
subplot(4,4,i)
plot(IDX(i).orituning(:,1),IDX(i).orituning(:,2),'o'); hold on
plot(IDX(i).oriFit);
legend off
end




%% Spatial frequency

unit = 5;
sfs = IDX(1).sfs;


figure('position',[736,535,453,185]); 
b1 = bar(1:length(sfs),squeeze(UNIT.sf.RESP(:,1,unit)));

set(b1,'FaceColor','none','BarWidth',1);


ylabel('spikes / sec');
xlabel('spatial frequency (cycles/degree)');
ylim([0 75]);

% Set the remaining axes properties
set(gca,'XTick',1:length(sfs),'XTickLabel',...
    num2str(sfs),'box','off');

if flag_figsave == 1
    cd(strcat(figDir,'RF\'));
    saveas(gcf, strcat('sfTuned_',num2str(unit),'.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end