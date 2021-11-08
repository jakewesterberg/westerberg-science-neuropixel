clearvars -except ATTN


unittype = 'all units';
stimtype = 'Monocular';
restriction = 'Positive'; 

p  = [ATTN.p];
mc = [ATTN.mc];
tstat = [ATTN.tstat];


clear I
if strcmp(unittype,'all units') || strcmp(unittype,'all')
     I = true(1,length(p));
else
    clear rn
    switch stimtype
        case 'Monocular'
            rn = 1; 
        case 'Binocular';
            rn = 2; 
        case 'dCOS'
            rn = 3; 
        otherwise
            error('bad stimtype')
    end
    switch restriction
        case 'Sig'
             I = p(rn,:) < 0.05;
        case 'Positive'
            I = mc(rn,:) > 0;
        case 'Sig & Positive'
            I = tstat(rn,:) > 0 & p(rn,:) < 0.05;
    end
    unittype = [restriction ' on ' stimtype];
end


signal = {ATTN(I).type};
signal = unique(signal);
if length(signal) > 1
    signal = 'mixed units';
else
    signal = [lower(signal{1}) ' units'];
end

%%

mc = [ATTN.mc];
tstat = [ATTN.tstat];
di = [mc(1,:); tstat(1,:); mc(2,:); tstat(2,:); mc(3,:); tstat(3,:)];

clf
pvec = [1 4 2 5 3 6];
for p = 1:6
    
    subplot(2,3,pvec(p))
    dat = di(p,I); 
    hist(dat); hold on
    plot([0 0],ylim,'k','LineWidth',1.5)
    plot(nanmean(dat)+[0 0],ylim,'m','LineWidth',1.5)
    plot(nanmedian(dat)+[0 0],ylim,'g','LineWidth',1.5)
    set(gca,'TickDir','out','Box','off')
    
    if mod(p,2) == 0
        xlim([-4 4])
         xlabel('tstat(attn,unattn)')
    else
        xlim([-0.5 0.5])
        xlabel('mc(attn-unattn)')
    end
    if p < 3
        title('Monocular')
    elseif p < 5
         title('Binocular')
    else
         title('dCOS')
    end
    
    if pvec(p) == 1
        n = (~all(isnan(di)) );
        ylabel(sprintf('%s\n %u %s over %u sessions ',unittype,sum(n),signal,length(unique({ATTN(n).penetration}))))
    end
end
%%

clf

mc = [ATTN.mc];
tstat = [ATTN.tstat];
di = [mc(1,:); tstat(1,:); mc(2,:); tstat(2,:); mc(3,:); tstat(3,:)];
depths = [ATTN.depth];

measures  = {'mc(attn-unattn)','tstat(attn,unattn)'};
stim = {'Monocular','Binocular','dCOS'};
p = 0;
for m = 1:length(measures)
    for c = 1:length(stim)
        p = p +1; 
        clear dat depth 
        switch stim{c}
            case 'Monocular'
                dat = di(0 + m,I);
            case 'Binocular'
                 dat = di(2 + m,I);
            case 'dCOS'
                dat = di(4 + m,I);
        end
        depth = depths(2,I); 

        [uy,my,ci,n,x] = grpstats(dat,{depth},{'mean','median','meanci','numel','gname'});
        x = str2double(x); 
%         x(n<3) = []; 
%         uy(n<3) = [];
%         my(n<3) = [];
%         ci(n<3,:) = [];
        subplot(2,3,p)
        
       % errorbar(x,y,ci(:,1) - y,ci(:,2) - y,'-d'); 
       scatter(depth,dat); hold on; 
         plot(x,uy,'-d','LineWidth',1.5);
        set(gca,'view',[90 -90])
        axis tight; hold on; 
        plot(xlim,[0 0],'k')
        plot([0 0],ylim,'k')
         plot([5 5],ylim,':k')
        set(gca,'TickDir','out','Box','off')
        title(stim{c})
        ylabel((measures{m}))
        if c== 1
            n = (~all(isnan(di)) );
            xlabel(sprintf('%s\n %u %s over %u sessions ',unittype,sum(n),signal,length(unique({ATTN(n).penetration}))))
        end
    end
end

%%
clf
sdfwin = [-0.05 0.3];
clear SDF
for i = 1:length(ATTN); 
    clear tm pad
    tm = ATTN(i).tm; 
    
    if tm(end) < sdfwin(2)
        pad = [tm(end):diff(tm(1:2)):sdfwin(2)];
        pad(1) = []; 
        en = length(tm); 
        tm = [tm pad];
    else
        pad = [];
        en = find(tm > sdfwin(2),1)-1;
    end
    
    SDF(:,:,i) = [ATTN(i).SDF(:, find(tm> sdfwin(1),1) : en) pad];
end
tm = tm(tm> sdfwin(1) & tm <= sdfwin(2));

clear SDF2
SDF2 = SDF([1 2 4 5 7 8],:,:); 
for p = 1:6
    subplot(3,2,p)
    plot(tm,squeeze(SDF2(p,:,I))); hold on
    plot(tm,nanmean(SDF2(p,:,I),3),'LineWidth',2,'Color',[0 0 0])
    axis tight; ylim([0 400])
    plot([0 0],ylim,'k');
    set(gca,'TickDir','out','Box','off')
    
    if p < 3
        ylabel('Monocular')
        if mod(p,2) == 0
            title('Unattended')
        else
            title('Attended')
        end
    elseif p < 5
         ylabel('Binocular')
    else
         ylabel('dCOS')
         xlabel('Time (ms)')
    end
    
    
    
    
end

%%
clf; clear h II

II = I & any(isnan(squeeze(SDF(:,50,:))));

subplot(1,3,1); h(1)= gca;
set(gca,'ColorOrder',[0 0 0; 0 0 1; 1 0 0]); hold on;
attn = nanmean(SDF(1:3:end,:,II),3);
plot(tm,attn); axis tight;
set(gca,'TickDir','out','Box','off')
title('RF Cued');
%legend({'Monocular','Binocular','dCOS'})


subplot(1,3,2); h(2)= gca;
set(gca,'ColorOrder',[0 0 0; 0 0 1; 1 0 0]); hold on;
unat = nanmean(SDF(2:3:end,:, II),3);
plot(tm,unat); axis tight;
set(gca,'TickDir','out','Box','off')
title('Cued Away');
%legend({'Monocular','Binocular','dCOS'})
ylimits = ylim;
xlabel('Time (s)')

subplot(1,3,3); h(3)= gca;
set(gca,'ColorOrder',[0 0 0; 0 0 1; 1 0 0]); hold on;
null = nanmean(SDF(3:3:end,:,II),3);
plot(tm,null); axis tight;
set(gca,'TickDir','out','Box','off')
title('No Cue');
%legend({'Monocular','Binocular','dCOS'})

yl = cell2mat(get(h,'Ylim')); 
yl = [min(yl(:,1)) max(yl(:,2))];
set(h,'Ylim',yl)

% 
subplot(1,3,1)
xlabel('Time (s)')
n = II;
ylabel(sprintf('Mean Response (imp./s)\n%s\n %u %s over %u sessions ',unittype,sum(n),signal,length(unique({ATTN(n).penetration}))))



%%

clf
sdfwin = [-0.05 0.3];
clear D1 D2 D3
for i = 1:length(ATTN); 
    clear tm pad
    tm = ATTN(i).tm; 
    
    if tm(end) < sdfwin(2)
        pad = [tm(end):diff(tm(1:2)):sdfwin(2)];
        pad(1) = []; 
        en = length(tm); 
        tm = [tm pad];
    else
        pad = [];
        en = find(tm > sdfwin(2),1)-1;
    end
    
    D1(i,:) = [ATTN(i).SDFd(1, find(tm> sdfwin(1),1) : en) pad];
    D2(i,:) = [ATTN(i).SDFd(2, find(tm> sdfwin(1),1) : en) pad];
    D3(i,:) = [ATTN(i).SDFd(3, find(tm> sdfwin(1),1) : en) pad];
end
tm = tm(tm> sdfwin(1) & tm <= sdfwin(2));

subplot(1,3,1)
plot(tm,D1(I,:)); hold on; 
plot(tm,nanmean(D1(I,:),1),'LineWidth',2','Color',[0 0 0])
axis tight
plot([0 0],ylim,'k'); plot(xlim,[0 0],'k'); 
set(gca,'TickDir','out','Box','off')
ylabel(sprintf('Attn - Unattn\n%s',unittype))
xlabel('Time (s)')
title('Monocular')

subplot(1,3,2)
plot(tm,D2(I,:)); hold on; 
plot(tm,nanmean(D2(I,:),1),'LineWidth',2','Color',[0 0 0])
axis tight
plot([0 0],ylim,'k'); plot(xlim,[0 0],'k'); 
set(gca,'TickDir','out','Box','off')
title('Binocular')

subplot(1,3,3)
plot(tm,D3(I,:)); hold on; 
plot(tm,nanmean(D3(I,:),1),'LineWidth',2','Color',[0 0 0])
axis tight
plot([0 0],ylim,'k'); plot(xlim,[0 0],'k'); 
set(gca,'TickDir','out','Box','off')
title('dCOS')

%%
clf
sdfwin = [-0.05 0.3];
clear SDF
for i = 1:length(ATTN); 
    clear tm pad
    tm = ATTN(i).tm; 
    
    if tm(end) < sdfwin(2)
        pad = [tm(end):diff(tm(1:2)):sdfwin(2)];
        pad(1) = []; 
        en = length(tm); 
        tm = [tm pad];
    else
        pad = [];
        en = find(tm > sdfwin(2),1)-1;
    end
    
    SDF(:,:,i) = [ATTN(i).SDF(:, find(tm> sdfwin(1),1) : en) pad];
end
tm = tm(tm> sdfwin(1) & tm <= sdfwin(2));

clear SDF2
SDF2 = SDF([1 2 4 5 7 8],:,:); 
for p = 1:6
    subplot(1,3,ceil(p/2))
    %plot(tm,squeeze(SDF2(p,:,I))); hold on
    h = plot(tm,nanmean(SDF2(p,:,I),3),'LineWidth',1);
    axis tight; ylim([0 180]); hold on
    set(gca,'TickDir','out','Box','off')
    
    if p < 3
        title('Monocular')
        xlabel('Time (ms)')
    elseif p < 5
         title('Binocular')
    else
         title('dCOS')
    end
    
    if mod(p,2) == 0
        legend('Attended','Unattended')
            plot([0 0],ylim,'k');
    end
    
    
    
    
end
