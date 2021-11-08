%% CRF_layers

% Figure save directory
if strcmp(getenv('username'),'bmitc')
    figDir = 'C:\Users\bmitc\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'mitchba2')
    figDir = 'C:\Users\mitchba2\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'bmitc_000')
    figDir = 'C:\Users\bmitc_000\OneDrive - Vanderbilt\Maier Lab\Figures\';
end

% toggle to save figures
flag_figsave = 1;

%% Curve Fitting: Dioptic data
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
    s1 = semilogx(predictions,prd(1,:),'color','k','linestyle','-','linewidth',2,'HandleVisibility','off');  hold on
    s2 = semilogx(predictions,prd(2,:),'color',[0 0 0]+0.9,'linestyle','-','linewidth',1.75,'HandleVisibility','off');  hold on
    s3 = semilogx(predictions,prd(3,:),'color','b','linestyle','-','linewidth',2,'HandleVisibility','off');  hold on
    
    s4 = semilogx(Data(1,:),nDE,'o','color','k','linewidth',2,'markersize',5);
    %s5 = semilogx(Data(1,:),nNDE,'o','color',[.4 .4 .4],'linewidth',2,'markersize',5);
    s6 = semilogx(Data(1,:),nBIN,'*','color','b','linewidth',2,'markersize',5);
    
    set(gca,'FontSize',12,'linewidth',1.5,'box','off',...
        'xlim',[1 100],...
        'XTick',x);
    if tw == 1
        set(gca,'ylim',[0 1.4]);
    else
        set(gca,'ylim',[0 0.7]);
    end
    
    
    if L == 1
        xticklabels([]); ylabel([]); xticklabels([]);
    elseif L == 2
        xlabel([]); ylabel([]); xticklabels([]);
    else
        xticks([1,5,10,20,50,100]);
        ylabel('Normalized response','fontsize',12);
        xlabel('contrast','fontsize',12);
    end
end


if flag_figsave == 1
    cd(strcat(figDir,'layers\'));
    saveas(gcf, strcat('CRF-dioptic','.svg'));
    sprintf("Figure saved");
else
    sprintf("Figure was not saved");
end

%% Dichoptic 

clear -global Data
clear nMon nBin bin mon prd1 prd2 cv curves a K n b

if strcmp(getenv('username'),'bmitc')
    figDir = 'C:\Users\bmitc\OneDrive - Vanderbilt\Maier Lab\Figures\';
else
    figDir = 'C:\Users\mitchba2\OneDrive - Vanderbilt\Maier Lab\Figures\';
end

% choice
tw = 1; %1 = transient, 2 = sustained
curves = {'zeroNDE','lowNDE','medNDE','highNDE'};

% data
x = [1 22.5 45 90];

clear DI
for L = 1:3
DI(L).units = LAY.DI.PS(L).RESP;
end

for L = 1:3
    DI(L).avg = nanmean(DI(L).units,3);
    DI(L).err = nanstd(DI(L).units,[],3)./sqrt(size(DI(L).units,3));
end

% Generate Curves and plot the data
    global Data
    Data(1,:) = x;
    figure('position',[360,60.33333333333333,273.6666666666666,557.6666666666666]);
clear de nde di bin prd
for L = 1:3
    di  = DI(L).avg(:,tw);
    de_ref = DI(L).avg(1:4,1);
    
% % % % %  Vertical: colors are NDE strength
%     Horizontal: colors are DE strength
% %         00|00  00|22  00|45  00|90 - yel
% %         22|00  22|22  22|45  22|90 - oran
% %         45|00  45|22  45|45  45|90 - red
% %         90|00  90|22  90|45  90|90 - purp
% %         -yel   -oran  -red   -purp

    zeroNDE     = di(1:4); % curve 1
    lowNDE = di(5:8); % curve 2
    medNDE = di(9:12); % curve 3
    highNDE = di(13:16); % curve 4

            mn             = min(de_ref); 
            mx             = max(de_ref); 
            nzeroNDE       = (zeroNDE - mn)./(mx - mn); % curve 1
            nlowNDE        = (lowNDE - mn)./(mx - mn); % curve 2
            nmedNDE        = (medNDE - mn)./(mx - mn); % curve 3
            nhighNDE       = (highNDE - mn)./(mx - mn); % curve 4

    for curve = 1:size(curves,2)
        switch curves{curve}
            case 'zeroNDE'
                Data(2,:) = nzeroNDE;
            case 'lowNDE'
                Data(2,:) = nlowNDE;
            case 'medNDE'
                Data(2,:) = nmedNDE;
            case 'highNDE'
                Data(2,:) = nhighNDE;
        end
 
        [a, K, n, ~] = BMfitCRdata;
        predictions = 1:100;
            for c = 1:length(predictions)
                prd(curve,c) = a*[(c^n)/((c^n) + (K^n))]; % prediction
            end
    end

% Plot

subplot(3,1,L)
semilogx(predictions,prd(1,:),'color',[0.9290 0.6940 0.1250],'linestyle','-','linewidth',1.7,'HandleVisibility','off');  hold on
semilogx(predictions,prd(2,:),'color',[0.8500 0.3250 0.0980],'linestyle','-','linewidth',1.7,'HandleVisibility','off');  
semilogx(predictions,prd(3,:),'color',[0.6350 0.0780 0.1840],'linestyle','-','linewidth',1.7,'HandleVisibility','off');  
semilogx(predictions,prd(4,:),'color',[0.4940 0.1840 0.5560],'linestyle','-','linewidth',1.7,'HandleVisibility','off');  

semilogx(Data(1,:),nzeroNDE,'o','color',[0.9290 0.6940 0.1250],'linewidth',1.7,'markersize',5);
semilogx(Data(1,:),nlowNDE,'o','color',[0.8500 0.3250 0.0980],'linewidth',1.7,'markersize',5);
semilogx(Data(1,:),nmedNDE,'o','color',[0.6350 0.0780 0.1840],'linewidth',1.7,'markersize',5);
semilogx(Data(1,:),nhighNDE,'o','color',[0.4940 0.1840 0.5560],'linewidth',1.7,'markersize',5);

set(gca,'FontSize',12,'linewidth',1.5,'box','off',...
    'ylim',[0 1],... %'XScale','log',...
    'xlim',[1 100],...
     'XTick',[1 22 45 90]);

    if L == 1
        %title('Upper');
        xlabel([]); ylabel([]); xticklabels([]);
    elseif L == 2 
        %title('Granular'); 
        xlabel([]); ylabel([]); xticklabels([]);
    else
        %title('Deep');
        xlabel('Grating contrast in DE'); ylabel(sprintf('Response normalized \n to transient monocular'));
        %legend('   0 NDE','.22 NDE','.45 NDE','.90 NDE','position',[0.157,0.189,0.42,0.14]); legend box off;
        xticklabels({'0','22','45','90'});
    end
end

cd(strcat(figDir,'layers\'));
saveas(gcf, strcat('CRF-dichoptic_',num2str(tw), '.svg'));