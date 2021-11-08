didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Mar14/';
cd(didir);
load('IDX_Mar28a.mat');

%%
clearvars -except IDX

SDF     = 'SDF'; % SDF0 has basline subtracted
tunenot = '';    % 0 to get stats after subtracting baseline
deltaC  = 0; % 1 = diff contrasts in each eye
deltaO  = Inf; % dva orientaion diffrence allowed between tuning and main experement params
alpha   = 0.05; % sig threshold for tuning


% get tuning info
occular = [IDX.(['occ' tunenot])];
tuning  = [IDX.(['ori' tunenot])];
dianov  = [IDX.(['dianov' tunenot])];
prefori = [IDX(:).prefori];
peakori = nansum(tuning(2:3,:));
deltaori = min(abs(wrapTo180([prefori-peakori; prefori-peakori+180])));





if deltaC == 0
    c = 0;
    mstr = '[full contrast, blank]';
    dstr = '[full contrast, full contrast]';
    eyestr = 'DE at full contrast, NDE at full';
else
    c = 3;
    mstr = '[1/2 contrast, blank]';
    dstr = '[1/2 contrast, full contrast]';
    eyestr = 'DE at 1/2 contrast, NDE at full';
end

% setup SDF and STAT vars
clear *M* *Bi* *Di* DEPTH TM STAT
for i = 1:length(IDX);
    Mo(i,:) = IDX(i).(SDF)(1+c, : );
    Bi(i,:) = IDX(i).(SDF)(2+c, : );
    Di(i,:) = IDX(i).(SDF)(3+c, : );
    
    Mbi(i,:) = IDX(i).(SDF)(7, : );
    Mdi(i,:) = IDX(i).(SDF)(8, : );
    
    STAT(i,:) = IDX(i).ts([1 2 3] + c,2);
    
    if strcmp (SDF,'SDF0')
        rMo(i,:) = IDX(i).UV(1+c, 1:3 ) - IDX(i).UV(1+c, 4 );
        rBi(i,:) = IDX(i).UV(2+c, 1:3 ) - IDX(i).UV(2+c, 4 );
        rDi(i,:) = IDX(i).UV(3+c, 1:3 ) - IDX(i).UV(3+c, 4 );
    else
        rMo(i,:) = IDX(i).UV(1+c, 1:3 ) ;
        rBi(i,:) = IDX(i).UV(2+c, 1:3 ) ;
        rDi(i,:) = IDX(i).UV(3+c, 1:3 ) ;
    end
    
end
dBi = Bi - Mo;
dDi = Di - Mo;
TM = [IDX.tm]';
DEPTH = [IDX(:).depth]';

% extract good unints based on di condition
clear good*
goodBi  = ~all(isnan(dBi)');
goodDi  = ~all(isnan(dDi)');
goodAll = goodDi & goodBi;



%% timecourse w/ t-test bar plots

figure('Unit','Inches','Position',[0 0 8.5 11]);

ylimits = NaN(3,2);

win_s = IDX(1).win ./ 1000;
for u = 1:2
    if u == 1
        tunestr = 'main effects in di task'; % see below
    else
        tunestr = 'ori effect in di task but not eye'; % see below
    end
    
clear tI oI eI
switch tunestr
    case 'main effects in di task'
        tI = all(dianov(1:2,:)<alpha);
    case 'ori effect in di task but not eye'
        tI = (dianov(2,:)<alpha) & (dianov(1,:)>=alpha);
    case 'effect of ori but not eye'
        oI = (dianov(2,:)<alpha)  | tuning(1,:)  < alpha ;
        eI = (dianov(1,:)>=alpha) | occular(1,:) >= alpha;
        tI  = oI & eI;
    case 'effect of ori and eye'
        oI = dianov(2,:)<alpha | tuning(1,:)  < alpha ;
        eI = dianov(1,:)<alpha | occular(1,:) < alpha;
        tI  = oI & eI;
    otherwise
        error('bad tunestr')
end
tI = tI & deltaori <= deltaO;

if strcmp (tunenot,'0')
    tunestr = sprintf('%s (tune0), dOri = %u',tunestr,deltaO);
else
    tunestr = sprintf('%s, dOri = %u',tunestr,deltaO);
end

for di = 1:2
    clear r d cl m tstr val keep tm
    if di == 1
        r = Bi;
        d = dBi;
        m = Mbi;
        cl = 'b';
        keep = goodAll;

        
        for win = 1:2
            [~, p, ci, stats]=ttest(rBi(tI & keep,win),rMo(tI & keep,win));
            uu = mean(rBi(tI & keep,win)-rMo(tI & keep,win));
            tstr{win} = sprintf('t(%u) = %0.2f, p = %0.3f',stats.df,stats.tstat,p);
            val(win,:) = [uu; ci];
        end
        
        
    else
        r = Di;
        d = dDi;
        cl = 'r';
        m = Mdi;
         keep = goodAll;
        
        for win = 1:2
            [~, p, ci, stats]=ttest(rDi(tI & keep,win),rMo(tI & keep,win));
            uu = mean(rDi(tI & keep,win)-rMo(tI & keep,win));
            tstr{win} = sprintf('t(%u) = %0.2f, p = %0.3f',stats.df,stats.tstat,p);
            val(win,:) = [uu; ci];
        end
        
        
    end
    subplot(3,2,u + 0)
    tm   = mode(TM(tI & keep,:),1);

    clear x s
    x = nanmean(Mo(tI & keep,:),1);
    plot(tm,x,'k','LineWidth',2);hold on
    
    clear x
    x = nanmean(r(tI & keep,:),1);
    plot(tm,x,cl,'LineWidth',2);hold on
    clear x
    x = nanmean(m(tI & keep,:),1);
    plot(tm,x,cl,'LineWidth',1);hold on
    
    axis tight;
%     if u == 1
%         ylimits(1,:) = ylim;
%     else
%         ylim(ylimits(1,:));
%     end
    plot([0 0],ylim,'k')
    set(gca,'TickDir','out','Box','off')
    xlabel('Time (s)')
    ylabel(sprintf('%s (spk./s)',SDF))
    
    title(sprintf('%s\nn = %u units over %u sessions\n%s',tunestr,sum(tI&keep),length(unique({IDX(tI&keep).penetration})),eyestr))
    
    
    subplot(3,2,u + 2)
    
    
    clear x s
    x = nanmean(d(tI&keep,:),1);
    s = bootci(1000,@mean,d(tI&keep,:));
    plot(tm,x,cl,'LineWidth',2); hold on
    plot(tm,s(1,:),cl,'LineWidth',0.5); hold on
    plot(tm,s(2,:),cl,'LineWidth',0.5); hold on
    
    
    for win = 1:2
        errorbar(mean(win_s(win,:)),val(win,1),val(win,2)-val(win,1),val(win,3)-val(win,1),[cl 'o'])
        hold on
    end
    
    
    
     axis tight;
%     if u == 1
%         ylimits(2,:) = ylim;
%     else
%         ylim(ylimits(2,:));
%     end
    plot([0 0],ylim,'k')
    plot(xlim,[0 0],'k')
    set(gca,'TickDir','out','Box','off')
    xlabel('Time (s)')
    ylabel('Delta Spks')
    title(sprintf('%s\n%s',tstr{1},tstr{2}))
    
    
    for w = 1:2
        plot(win_s(w,1)*[1 1],ylim,':k')
        plot(win_s(w,2)*[1 1],ylim,':k')
    end
    
    subplot(3,2,u + 4)
    x = deltaori(tI & keep); 
    edges = 0:5:90;
    ct=histc(x,edges);
    bar(edges,ct,'histc'); 
    title(sprintf('%u of %u NaN',sum(isnan(x)), length(x)))
     axis tight;
    if u == 1
        ylimits(3,:) = ylim;
    else
        ylim(ylimits(3,:));
    end
    set(gca,'TickDir','out','Box','off')
    xlabel('Delta from Peak Ori')
    
end

end



