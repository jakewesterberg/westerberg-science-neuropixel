%% usefulPlots.m 
% (1) Plots oldstyle probe with channels in the horizontal 

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
    
%% Plot

h1 = figure('position',[905,239,288,563]);
clear i

pen = 14;

channels = size(PEN(pen).BIN.PS.SDF,3);

newWin = sdfWin(100:400);

f_ShadedLinePlotbyDepthMod(squeeze(PEN(pen).MON.DE_PS.SDF(4,100:400,:)),0:(1/channels):1,newWin, 1:channels,true); % this function baseline corrects and scales
hold on
vl = vline(0,'k');
set(vl, 'linestyle',':','linewidth',1,'color','k');
%plot([STIM.off STIM.off], ylim,'k','linestyle','-.','linewidth',0.5)
xlabel('time (s)','fontsize',14)
ylabel('contacts indexed down from surface','fontsize',14)
hold off

set(gca,'Fontsize',14)


if flag_figsave == 1
    cd(strcat(figDir,'probe\'));
    saveas(gcf, strcat('VSS_2020_ephys-example','.svg'));
    sprintf("Figure saved");
else
    sprintf("Figure was not saved");
end