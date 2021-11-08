%% RFscatter
% Figure save directory
if strcmp(getenv('username'),'bmitc')
    figDir = 'C:\Users\bmitc\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'mitchba2')
    figDir = 'C:\Users\mitchba2\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'bmitc_000')
    figDir = 'C:\Users\bmitc_000\OneDrive - Vanderbilt\Maier Lab\Figures\';
end


% toggle to save figures
flag_figsave = 0;


global ALIGNDIR
if isempty(ALIGNDIR)
    setup('blakeFull')
end


%% directory for V1 Limits

if ~isempty(ALIGNDIR)
    aligndir = ALIGNDIR;
else
    error('ALIGNDIR not found');
end

dataset = 'bincontrast_I';

if strcmp(getenv('username'),'mitchba2')
    didir = strcat('D:\dMUA\',dataset,'\');
elseif strcmp(getenv('username'),'bmitc')
    didir = strcat('C:\Users\bmitc\Documents\MATLAB\Data\',dataset,'\');
elseif strcmp(getenv('username'),'bmitc_000')
    didir = strcat('C:\Users\bmitc_000\Documents\MATLAB\data\',dataset,'\');
end

%didir = aligndir; 

cd(didir)
list = dir([didir '1*.mat']);
I = cellfun(@length,{list.name}) == 15;
list = list(I);

    

clear CENT ECC

%% Collect putative RFs across all penetrations
for i = 1:length(list)
    list(i).name
    load([aligndir list(i).name],'fRF')
    
    uCentroid = nanmedian(fRF(:,1:2));
    uWidth    = nanmedian(fRF(:,3:4));
    ecc   = sqrt(sum(uCentroid .^2,2));
    diam   = mean(uWidth,2);
    area   = sqrt(pi .* uWidth(:,1) .* uWidth(:,2));
    
    CENT(:,i) = uCentroid;
    ECC(:,i) = ecc;
end

%% Plot

figure('position',[411,558,356,279]); 
scatter(CENT(1,:),CENT(2,:),((1.4.*ECC)./2.*pi).^2,'MarkerFaceColor','b','MarkerFaceAlpha',0.4); hold on
xlim([-8 8])
ylim([-8 8]);
hl = hline(0);
vl = vline(0);


scatter(CENT(1,:),CENT(2,:), ((1.4*ECC)./2.*pi).^2,'MarkerFaceColor','r','MarkerFaceAlpha',0.4); hold on

%legend('E48 (N = 24)','location','northeast');

set(gca,'linewidth',0.7,'fontsize',16);
set(vl,'linewidth',0.5,'linestyle','-','color','k');
set(hl,'linewidth',0.5,'linestyle','-','color','k');
xlabel('Horizontal DVA')
ylabel('Vertical DVA')

set(gca,'TickDir','out'); 

%% SAVE

if flag_figsave == 1
    cd(strcat(figDir,'RF\'));
    saveas(gcf, strcat('RFscatter','.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end