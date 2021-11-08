%% CRF ocularity
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

if isfield(UNIT,'DI')
    flag_di = true;
end

switch datatype
    case 'kls'
        ylbl = 'spikes/s';
    case 'auto'
        ylbl = 'impulses/s';
end

% colors
orange = [0.8500, 0.3250, 0.0980];
light_orange = [0.9290, 0.6940, 0.1250];
blue = [0, 0.4470, 0.7410];
green = [0.4660, 0.6740, 0.1880];
cyan = [0.3010, 0.7450, 0.9330];
dark_red = 	[0.6350, 0.0780, 0.1840];
purple = [0.4940, 0.1840, 0.5560];
black = [0.25, 0.25, 0.25];

%% Curve Fitting: Dioptic data
clear -global Data 
clear mon bin prd cv curves a K n b de nde bin de_ref
clear de_all nde_all bin_all

% choices
tw = 2; % time window
error = false;

% strings
curves = {'de','nde','bin'};

% contrast levels
try
x = IDX(1).monLevels*100; x(1) = x(1)+1;
catch
    disp('Using average of binned contrast levels');
    x = mean(IDX(1).cbins,2)*100; x(1) = x(1)+1;
end

% data
de_all.units = UNIT.MON.DE_PS.RESP;
nde_all.units = UNIT.MON.NDE_PS.RESP;
bin_all.units = UNIT.BIN.PS.RESP;

% averaged data
de_all.avg = nanmean(de_all.units,3);
de_all.err = nanstd(de_all.units,[],3)./sqrt(size(de_all.units,3));
nde_all.avg = nanmean(nde_all.units,3);
nde_all.err = nanstd(nde_all.units,[],3)./sqrt(size(nde_all.units,3));
bin_all.avg = nanmean(bin_all.units,3);
bin_all.err = nanstd(bin_all.units,[],3)./sqrt(size(bin_all.units,3));


global Data
Data(1,:) = x;
figure('position',[891,371,423,420]);
    
    DE = de_all.avg(:,tw);
    de_ref = de_all.avg(:,1);
    NDE = nde_all.avg(:,tw);
    BIN = bin_all.avg(:,tw);
    
    mn       = min(de_ref);
    mx       = max(de_ref);
    nDE      = (DE - mn)./(mx - mn);
    nNDE     = (NDE - mn)./(mx - mn);
    nBIN     = (BIN - mn)./(mx - mn);
    
    for curve = 1:size(curves,2) % for each curve (bin and mon)
        switch curves{curve}
            case 'de'
                Data(2,:) = DE;
            case 'nde'
                Data(2,:) = NDE;
            case 'bin'
                Data(2,:) = BIN;
        end
        
        [a,K,n,b] = BMfitCRdata;
        predictions = 1:100;
        for c = 1:length(predictions) % generate prediction for mon
            prd(curve,c) = a*[(c^n)/((c^n) + (K^n))+b]; % mon prediction
        end
    end
    
%     mdl_lin     = prd(1,:) + prd(2,:);
%     mdl_nonlin  = sqrt(prd(1,:).^2 + prd(2,:).^2);
%     mdl_binorm  = sqrt((prd(1,:).^2) + (prd(2,:).^2) - (prd(1,:)-prd(2,:).^2));
    
    % Plot
    s1 = semilogx(predictions,prd(1,:),'color',blue,'linestyle','-','linewidth',2,'HandleVisibility','off');  hold on
    %s2 = semilogx(predictions,prd(2,:),'color',[0 0 0]+0.5,'linestyle','-','linewidth',1.75,'HandleVisibility','off');  hold on
    s3 = semilogx(predictions,prd(3,:),'color',orange,'linestyle','-','linewidth',2,'HandleVisibility','off');  
%     mdl1 = semilogx(predictions,mdl_lin,'color','r','linestyle','--','linewidth',1.75,'HandleVisibility','off');  hold on
%     mdl2 = semilogx(predictions,mdl_nonlin,'color','b','linestyle','--','linewidth',1.75,'HandleVisibility','off');  hold on
%     mdl3 = semilogx(predictions,mdl_binorm,'color','g','linestyle','--','linewidth',1.75,'HandleVisibility','off');  hold on

    
    s4 = semilogx(Data(1,:),DE,'o','color',blue,'linewidth',2,'markersize',5);
    %s5 = semilogx(Data(1,:),NDE,'o','color',[0 0 0]+0.5,'linewidth',2,'markersize',5);
    s6 = semilogx(Data(1,:),BIN,'*','color',orange,'linewidth',2,'markersize',5);
    if error == true
        ci1 = errorbar(Data(1,:),de_all.avg(:,tw),de_all.err(:,tw),'k');
        set(ci1,'linestyle','none','handleVisibility','off');
        
       %ci2 = errorbar(Data(1,:),nde_all.avg(:,tw),nde_all.err(:,tw),'k');
       %set(ci2,'linestyle','none','handleVisibility','off');
        
%         ci3 = errorbar(Data(1,:),bin_all.avg(:,tw),bin_all.err(:,tw),'b');
%         set(ci3,'linestyle','none','handleVisibility','off');
    end
   
    if tw == 1
        set(gca,'ylim',[0 inf]);
    else
        set(gca,'ylim',[0 70]);
    end
    
    set(gca,'FontSize',16,'linewidth',1,'box','off',...
        'xlim',[1 100],...
        'XTick',x);

    
    ylabel(ylbl,'fontsize',16);
    xticks([1,5,10,20,50,100]);
    yticks([0,20,40,60,80,100,120]);
    xlabel('contrast','fontsize',16);
    xticklabels({'0','5','10','20','50','100'});
    %xticklabels([]);
    %ylabel([]); xlabel([]);


if flag_figsave == 1
    cd(strcat(figDir,'units\'));
    saveas(gcf, strcat('CRF_units-', num2str(tw),'.svg'));
    fprintf('Figure was ') ; cprintf('green', 'saved') ; fprintf('\n') ;
else
    fprintf('Figure was '); cprintf('red', 'not saved');
end

%% Dichoptic

if flag_di == true
    clear -global Data
    clear DE NDE BIN DI de nde bin di prd1 prd2 cv curves a K n b
    clear nMon nmedNDE nhighNDE nlowNDE
    
    % choices
    tw = 1; %1 = transient, 2 = sustained
    
    % strings
    curves = {'zeroNDE','lowNDE','medNDE','highNDE'};
    
    % data
    try
        x = IDX(1).monLevels*100; x(1) = x(1)+1;
    catch
        disp('Not currently set up for this analysis');
    end
    
    for o = 1:3
        DI(o).units = LAY.DI.PS(o).RESP;
    end
    
    for o = 1:3
        DI(o).avg = nanmean(DI(o).units,3);
        DI(o).err = nanstd(DI(o).units,[],3)./sqrt(size(DI(o).units,3));
    end
    
    global Data
    Data(1,:) = x;
    figure('position',[135,404.3333333333333,1420.666666666667,432.6666666666667]);
    for o = 1:3
        di  = DI(o).avg(:,tw);
        de_ref = DI(o).avg(1:4,1); %
        
        %     Vertical: colors are NDE strength
        %     Horizontal: colors are DE strength
        % %         00|00  00|22  00|45  00|90 - yel
        % %         22|00  22|22  22|45  22|90 - oran
        % %         45|00  45|22  45|45  45|90 - red
        % %         90|00  90|22  90|45  90|90 - purp
        % %         -yel   -oran  -red   -purp
        
        zeroNDE     = di(1:4); % curve 1
        lowNDE      = di(5:8); % curve 2
        medNDE      = di(9:12); % curve 3
        highNDE     = di(13:16); % curve 4
        
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
        
        subplot(1,3,o)
        semilogx(predictions,prd(1,:),'color',[0.9290 0.6940 0.1250],'linestyle','-','linewidth',1.7,'HandleVisibility','off');  hold on
        semilogx(predictions,prd(2,:),'color',[0.8500 0.3250 0.0980],'linestyle','-','linewidth',1.7,'HandleVisibility','off');
        semilogx(predictions,prd(3,:),'color',[0.6350 0.0780 0.1840],'linestyle','-','linewidth',1.7,'HandleVisibility','off');
        semilogx(predictions,prd(4,:),'color',[0.4940 0.1840 0.5560],'linestyle','-','linewidth',1.7,'HandleVisibility','off');
        
        semilogx(Data(1,:),nzeroNDE,'o','color',[0.9290 0.6940 0.1250],'linewidth',1.7,'markersize',5);
        semilogx(Data(1,:),nlowNDE,'o','color',[0.8500 0.3250 0.0980],'linewidth',1.7,'markersize',5);
        semilogx(Data(1,:),nmedNDE,'o','color',[0.6350 0.0780 0.1840],'linewidth',1.7,'markersize',5);
        semilogx(Data(1,:),nhighNDE,'o','color',[0.4940 0.1840 0.5560],'linewidth',1.7,'markersize',5);
        
        set(gca,'FontSize',12,'linewidth',1.5,'box','off',...
            'ylim',[0 max(nzeroNDE)],... %'XScale','log',...
            'xlim',[1 100],...
            'XTick',x);
        
        if o == 1
            occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
            title(sprintf('Lowest (n = %d)\n OccIndex [%.3g : %.3g]',occLengths(o),occRange(1),occRange(2)),'FontSize',16);
            xlabel('Stimulus contrast'); ylabel(sprintf('Normalized Multi-unit \n response'));
            xticklabels({x});
            
        elseif o == 2
            occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
            title(sprintf('Average (n = %d)\n OccIndex [%.3g : %.3g]',occLengths(o),occRange(1),occRange(2)),'FontSize',16);
            %mCt = sum(Trls.mon(:,1,:),'all'); bCt = sum(Trls.bin(:,1,:),'all');
            %legend(sprintf('MON (%d trials)',mCt),sprintf('BIN (%d trials)',bCt),'location','northwest'); legend boxoff
            xlabel([]); ylabel([]); xticklabels([]);
        else
            occRange = abs([occValues(occGroups{o,1}(1)),occValues(occGroups{o,1}(end))]);
            title(sprintf('Highest (n = %d)\n OccIndex [%.3g : %.3g]',occLengths(o),occRange(1),occRange(2)),'FontSize',16);
            xlabel([]); ylabel([]); xticklabels([]);
        end
    end
    
    if flag_figsave == 1
        cd(strcat(figDir,'ocularity\'));
        saveas(gcf, strcat('CRF-dichoptic_',num2str(tw), '.svg'));
        sprintf("Figure saved");
    else
        sprintf("Figure was not saved");
    end
    
end

