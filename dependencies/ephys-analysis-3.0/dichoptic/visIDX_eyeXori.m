didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Aug24/';
cd(didir);
load('IDX_Oct7a.mat');

%%
clearvars -except IDX

klstype  = 'kls only';
SDF = 'SDF';
alpha = 0.05;

diwin        = flipud(IDX(1).statwin);
dimeasures   = {'mc','tstat','sigdir'};


close all

for deltaC = 1:-1:0
    
    if deltaC == 0
        c = [0 0];
        mstr = '[full contrast, blank]';
        dstr = '[full contrast, full contrast]';
        eyestr = 'DE at full contrast, NDE at full';
    else
        c = [3 2];
        mstr = '[1/2 contrast, blank]';
        dstr = '[1/2 contrast, full contrast]';
        eyestr = 'DE at 1/2 contrast, NDE at full';
    end
    
    % setup SDF vars
    clear *Mo* *Bi* *Di* *Oi* DEPTH TM R
    for i = 1:length(IDX);
        Mo(i,:) = IDX(i).(SDF)(1+c(1), :);
        Bi(i,:) = IDX(i).(SDF)(2+c(1), :);
        Di(i,:) = IDX(i).(SDF)(3+c(1), :);
        
        dBi(i,:) = IDX(i).(SDF)( 9+c(2), :);
        dDi(i,:) = IDX(i).(SDF)(10+c(2), :);
        
        DEPTH(i,:) =  IDX(i).depth(2);
        TM(i,:)    =  IDX(i).tm;
        
    end
    
    % extract good unints based on condition
    clear good
    goodBi  = ~all(isnan(dBi)');
    goodDi  = ~all(isnan(dDi)');
    goodAll = goodDi & goodBi;
    
    % setup MC and TSTAT for windows
    for w = 1:size(diwin,1)
        for m = 1:length(dimeasures)
            
            for i = 1:length(IDX);
                
                switch dimeasures{m}
                    case 'mc'
                        
                        clear tm tmlim
                        tm = TM(i,:);
                        tmlim = tm >= diwin(w,1) & tm <= diwin(w,2);
                        sBi.(dimeasures{m}).dat(i,:,w) = nanmean(IDX(i).(SDF)( 9+c(2), tmlim)) ./ (nanmean(IDX(i).(SDF)(2+c(1), tmlim)) + nanmean(IDX(i).(SDF)(1+c(1), tmlim))) ;
                        sDi.(dimeasures{m}).dat(i,:,w) = nanmean(IDX(i).(SDF)(10+c(2), tmlim)) ./ (nanmean(IDX(i).(SDF)(3+c(1), tmlim)) + nanmean(IDX(i).(SDF)(1+c(1), tmlim)));
                        sOi.(dimeasures{m}).dat(i,:,w) = ...
                                (nanmean(IDX(i).(SDF)(2+c(1), tmlim)) - nanmean(IDX(i).(SDF)(3+c(1), tmlim)))...
                             ./ (nanmean(IDX(i).(SDF)(2+c(1), tmlim)) + nanmean(IDX(i).(SDF)(3+c(1), tmlim)));
                        
                    case 'tstat'
                        
                        window = ismember(IDX(i).statwin,diwin(w,:));
                        [a,~]  = find(window);
                        a = unique(a);
                        sBi.(dimeasures{m}).dat(i,:,w) = IDX(i).distats(1 + c(1)  + (a-1)*12);
                        sDi.(dimeasures{m}).dat(i,:,w) = IDX(i).distats(2 + c(1)  + (a-1)*12);
                        sOi.(dimeasures{m}).dat(i,:,w) = IDX(i).distats(3 + c(1)  + (a-1)*12);
                        
                        sBi.('pvalue').dat(i,:,w) = IDX(i).distats(7 + c(1)  + (a-1)*12);
                        sDi.('pvalue').dat(i,:,w) = IDX(i).distats(8 + c(1)  + (a-1)*12);
                        sOi.('pvalue').dat(i,:,w) = IDX(i).distats(9 + c(1)  + (a-1)*12);
                        
                        
                    case 'sigdir'
                        % -2 = negative and sig, -1 = negative and non sig
                        % +2 = positive and sig, +1 = positive and non sig
                        clear bi di
                        bi = [...
                            sign(IDX(i).distats(1 + c(1)  + (a-1)*12)) ...
                            (IDX(i).distats(7 + c(1)  + (a-1)*12) < alpha)+1 ...
                            ];
                        sBi.(dimeasures{m}).dat(i,:,w) = bi(1)*bi(2);
                        clear bi di
                        di = [...
                            sign(IDX(i).distats(2 + c(1)  + (a-1)*12)) ...
                            (IDX(i).distats(8 + c(1)  + (a-1)*12) < alpha)+1 ...
                            ];
                        sDi.(dimeasures{m}).dat(i,:,w) = di(1)*di(2);
                end
            end
        end
    end
    
    II = cell(2,1); clear xII
    for u = 1:2
        
        if u == 1
            unittype = 'effect of ori and eye';
            %unittype = 'main effects in di task';
        else
            unittype = 'effect of ori but not eye';
            %unittype = 'ori effect in di task but not eye';
        end
        
        occular = [IDX.occ];
        tuning  = [IDX.ori];
        dianov  = [IDX.dianov];
        kls     = [IDX.kls];
        
        clear I
        switch unittype
            case 'main effects in di task'
                I = all(dianov(1:2,:)<alpha);
            case 'ori effect in di task but not eye'
                I = (dianov(2,:)<alpha) & (dianov(1,:)>=alpha);
            case 'effect of ori but not eye'
                oI = (dianov(2,:)<alpha) | (tuning(1,:) < alpha & min(abs([tuning(2,:); tuning(2,:)+180] - [IDX.prefori;IDX.prefori])) <= 20);
                eI = (dianov(1,:)>=alpha) | occular(1,:) >= alpha;
                I  = oI & eI;
            case 'effect of ori and eye'
                oI = (dianov(2,:)<alpha) | (tuning(1,:) < alpha & min(abs([tuning(2,:); tuning(2,:)+180] - [IDX.prefori;IDX.prefori])) <= 20);
                eI = (dianov(1,:)<alpha) | occular(1,:) < alpha;
                I  = oI & eI;
            otherwise
                error('bad unittype')
        end
        
        switch klstype
            case 'kls only'
                I = I & kls;
                unittype = [unittype ', kls only'];
            case 'auto only'
                I = I & ~kls;
                unittype = [unittype ', auto only'];
        end
        
        II{u} = I;
        if u == 2
            xII = II;
            II = II{1} | II{2};
        end
        
        
        
        %% timecourse w/ t-test bar plots
        
        %diwin =[ 50 250; 80 100] ./ 1000;
        
        if u == 1
            h(1) = figure('Unit','Inches','Position',[0 0 8.5 11]);
        else
            figure(h(1));
        end
        
        clear tm keep
        keep = goodAll;
        tm   = mode(TM(I & keep,:),1);
        
        subplot(2,2,u + 0)
        
        clear x s
        x = nanmean(Mo(I & keep,:),1); s = nanstd(Mo(I & keep,:),[],1) ./ sqrt(sum(I & keep));
        plot(tm,x,'k','LineWidth',2);hold on
%         plot(tm,x+s,'k','LineWidth',0.5);hold on
%         plot(tm,x-s,'k','LineWidth',0.5);hold on
%         
        clear x s
        x = nanmean(Bi(I & keep,:),1); s = nanstd(Bi(I & keep,:),[],1) ./ sqrt(sum(I & keep));
        plot(tm,x,'b','LineWidth',2);hold on
%         plot(tm,x+s,'b','LineWidth',0.5);hold on
%         plot(tm,x-s,'b','LineWidth',0.5);hold on
        
        clear x s
        x = nanmean(Di(I & keep,:),1); s = nanstd(Bi(I & keep,:),[],1) ./ sqrt(sum(I & keep));
        plot(tm,x,'r','LineWidth',2);hold on
%         plot(tm,x+s,'r','LineWidth',0.5);hold on
%         plot(tm,x-s,'r','LineWidth',0.5);hold on
        
        axis tight; ylim([6.1669   62.2298])
        plot([0 0],ylim,'k')
        set(gca,'TickDir','out','Box','off')
        xlabel('Time (s)')
        ylabel('spk./s')
        title(sprintf('%s\nn = %u units over %u sessions\n%s',unittype,sum(I&keep),length(unique({IDX(I&keep).penetration})),eyestr))
        for w = 1:size(diwin,1)
            plot(diwin(w,1)*[1 1],ylim,':k')
            plot(diwin(w,2)*[1 1],ylim,':k')
        end
        
        
        subplot(2,2,u + 2)
        
        clear x s
        x = nanmean(dBi(I&keep,:),1); 
        s = nanstd(dBi(I&keep,:),[],1) ./ sqrt(sum(I&keep)); s = [x-s ;x+s];
        % s = bootci(1000,@nanmean,dBi(I&keep,:));
        plot(tm,x,'b','LineWidth',2); hold on
    plot(tm,s(1,:),'b','LineWidth',0.5); hold on
    plot(tm,s(2,:),'b','LineWidth',0.5); hold on
    
     for win = 1:size(diwin,1)
         clear tmlim v1 v2 p ci stats
         tmlim = tm >= diwin(win,1) & tm <= diwin(win,2);
         v1 = nanmean(Bi(I&keep,tmlim),2);
         v2 = nanmean(Mo(I&keep,tmlim),2);
          [~, p, ci, stats]=ttest(v1,v2);
            uu = mean(v1-v2);
            ci = ci - uu;
            tstr{win} = sprintf('t(%u) = %0.2f, p = %0.3f',stats.df,stats.tstat,p);
            errorbar(mean(diwin(win,:)),uu,ci(1),ci(2),'co')
     end
       
       
        clear x s
        x = nanmean(dDi(I&keep,:),1); 
        s = nanstd(dDi(I&keep,:),[],1) ./ sqrt(sum(I&keep));s = [x-s ;x+s];
       %  s = bootci(1000,@mean,dDi(I&keep,:));

        plot(tm,x,'r','LineWidth',2); hold on
       plot(tm,s(1,:),'r','LineWidth',0.5); hold on
    plot(tm,s(2,:),'r','LineWidth',0.5); hold on
     for win = 1:size(diwin,1)
         clear tmlim v1 v2 p ci stats
         tmlim = tm >= diwin(win,1) & tm <= diwin(win,2);
         v1 = nanmedian(Di(I&keep,tmlim),2);
         v2 = nanmedian(Mo(I&keep,tmlim),2);
          [~, p, ci, stats]=ttest(v1,v2);
            uu = mean(v1-v2);
            ci = ci - uu;
            tstr{win+2} = sprintf('t(%u) = %0.2f, p = %0.3f',stats.df,stats.tstat,p);
            errorbar(mean(diwin(win,:)),uu,ci(1),ci(2),'mo')
     end
     title(sprintf('%s\t%s\n%s\t%s',tstr{1},tstr{2},tstr{3},tstr{4}))

    
    
        
        axis tight; ylim([-12.2758   33.6243])
        plot([0 0],ylim,'k')
        plot(xlim,[0 0],'k')
        set(gca,'TickDir','out','Box','off')
        xlabel('Time (s)')
        ylabel('Delta Spks')
        
        for w = 1:size(diwin,1)
            plot(diwin(w,1)*[1 1],ylim,':k')
            plot(diwin(w,2)*[1 1],ylim,':k')
        end
        
%         subplot(3,2,u + 4)
%         
%         clear n  xstr ystr
%         for w = 1:size(diwin,1)
%             clear di bi
%             di = sDi.sigdir.dat(I & keep,:,w);
%             bi = sBi.sigdir.dat(I & keep,:,w);
%             
%             n(:,1 + (w-1)*2)  = hist(di(:,1),-2:2);
%             n(:,2 + (w-1)*2)  = hist(bi(:,1),-2:2);
%             xstr{1 + (w-1)*2} = sprintf('Di-win%u',w);
%             xstr{2 + (w-1)*2} = sprintf('Bi-win%u',w);
%             ystr{1 + (w-1)*2} = sprintf('%u%%\n',flipud(round(n([1 2 4 5],1 + (w-1)*2) ./ sum(n(:,1 + (w-1)*2)) * 100)));
%             ystr{2 + (w-1)*2} = sprintf('%u%%\n',flipud(round(n([1 2 4 5],2 + (w-1)*2) ./ sum(n(:,2 + (w-1)*2)) * 100)));
%             
%         end
%         
%         bar(n','stacked'); colormap('gray');
%         ylim([0 sum(I & keep)]);
%         set(gca,'xticklabel',xstr)
%         view([0 90])
%         set(gca,'TickDir','out','Box','off')
%         set(gca,'xaxislocation','top')
%         for y = 1:length(ystr)
%             text(y,sum(I & keep)/2,ystr{y},'horizontalalignment','center')
%         end
%         
        
        
        
   
        %% scatter hist
        
        clear keep
        keep = goodAll & I;
        
        for m = 1:2
            
            if u == 1
                h(1+m) = figure('Unit','Inches','Position',[0 0 8.5 11]);
            else
                figure(h(1+m));
            end
            
            for w = 1:size(diwin,1)
                
                clear dat lim dpt
                dat = [sDi.(dimeasures{m}).dat(keep,:,w) ...
                    sBi.(dimeasures{m}).dat(keep,:,w)];
                dat(abs(dat)>11) = nan;
                clear lim edges
                lim = [-1.1 1.1] * round(max(max(abs(dat))),1);
                edges = lim(1):lim(2)/10:lim(2);
                
                %dcos histogram
                subplot(4,4,2 + 2*(u-1) + (w-1)*8); cla
                n=histc(dat(:,1),lim(1):lim(2)/10:lim(2));
                bar(edges,n,'histc'); hold on
                axis tight
                set(gca,'TickDir','out','Box','on')
                plot([0 0],ylim,'g');
                plot([1 1]*  nanmean(dat(:,1)),ylim,'r');
                plot([1 1]*nanmedian(dat(:,1)),ylim,'--r')
                title(sprintf('win = %0.2f to %0.2f s\n%s\nn = %uU over %uS in %uM\n%s',diwin(w,1),diwin(w,2),unittype,sum(keep),length(unique({IDX(keep).penetration})), length(unique({IDX(keep).monkey})),eyestr))
                xlabel([dimeasures{m} '(dCOS)'])
                
                
                %Binocular histogram
                subplot(4,4,5 + 2*(u-1) + (w-1)*8); cla
                n=histc(dat(:,2),lim(1):lim(2)/10:lim(2));
                bar(edges,n,'histc'); hold on
                axis tight
                set(gca,'TickDir','out','Box','on')
                plot([0 0],ylim,'g');
                plot([1 1]*  nanmean(dat(:,2)),ylim,'b');
                plot([1 1]*nanmedian(dat(:,2)),ylim,'--b')
                view([-90 90])
                
                
                % scatter
                subplot(4,4,6 + 2*(u-1) + (w-1)*8); cla
                scatter(dat(:,1),dat(:,2)); hold on;
                axis([lim lim]);
                set(gca,'TickDir','out','Box','on')
                plot([0 0],ylim,'g');
                plot(ylim,[0 0],'g')
                [r,p]=corrcoef(dat(~any(isnan(dat')),:));
                r = r(2);
                p = p(2);
                lsline
                title(sprintf('r = %0.2f, p = %0.3f',r,p))
                xlabel([dimeasures{m} '(dCOS)'])
                ylabel([dimeasures{m} '(BI)'])
                
                
                
            end
        end
        
    end
    
    
    %% histrogram w/ layers, acroass all unit groups
    %  measures now combined in depth plot
    for dicond = 1:3
        figure('Unit','Inches','Position',[0 0 11 8.5]);
        for m = 1:2
            
            for w = 1:size(diwin,1)
                
                clear dat keep condstr dicolor unittype2 good dat2
                if dicond == 1
                    condstr = '(dCOSvM)';
                    dicolor = 'r';
                    keep = goodDi & II;
                    unittype2 = 'main effect of ori';
                    dat = sDi.(dimeasures{m}).dat(keep,:,w);
                    if strcmp(dimeasures{m},'tstat')
                        dat2 = sDi.('pvalue').dat(keep,:,w);
                    end
                    good = goodDi;
                elseif dicond == 2
                    condstr = '(BIvM)';
                    dicolor = 'b';
                    keep = goodBi & II;
                    unittype2 = 'main effect of ori';
                    dat = sBi.(dimeasures{m}).dat(keep,:,w);
                    if strcmp(dimeasures{m},'tstat')
                        dat2 = sBi.('pvalue').dat(keep,:,w);
                    end
                    good = goodBi;
                elseif dicond == 3
                    condstr = '(BIvdCOS)';
                    dicolor = 'm';
                    keep = goodAll & II;
                    unittype2 = 'main effect of ori';
                    dat = sDi.(dimeasures{m}).dat(keep,:,w);
                    if strcmp(dimeasures{m},'tstat')
                        dat2 = sDi.('pvalue').dat(keep,:,w);
                    end
                    good = goodAll;
                end
                    
                    
                dat(abs(dat)>11) = nan;
                
                
                
                clear lim edges dpt
                lim = [-1.1 1.1] * round(max(abs(dat)),1);
                edges = lim(1):lim(2)/10:lim(2);
                dpt = DEPTH(keep,:);
                
                % anova
                clear dgroup
                dgroup = nan(size(dpt));
                dgroup(dpt < 0) = -1;
                dgroup(dpt >= 0 & dgroup <= 5) = 0;
                dgroup(dpt > 5 & dpt < 10) = 1;
                dgroup(dpt >= 10) = 2;
                anp(1) = anovan(dat,dpt,'display','off');
                anp(2) = anovan(dat,dgroup,'display','off');
                
                % histrogram 1
                if m == 1
                    subplot(3,4,2 + (w-1))
                    clear n
                    n=histc(dat,lim(1):lim(2)/10:lim(2));
                    bar(edges,n,'histc'); hold on
                    axis tight
                    set(gca,'TickDir','out','Box','off')
                    plot([0 0],ylim,'g');
                    plot([1 1]*  nanmean(dat),ylim,dicolor);
                    plot([1 1]*nanmedian(dat),ylim,['--' dicolor])
                    alim(3:4) = xlim;
                    
                    title(sprintf('win = %0.2f to %0.2f s',diwin(w,1),diwin(w,2)))
                end
                
                % histrogram 2 - depth n
                if w == 1
                    subplot(3,4,[5 9])
                    clear n1 n2
                    n1 = hist(DEPTH(xII{1} & good),min(dpt):max(dpt));
                    n2 = hist(DEPTH(xII{2} & good),min(dpt):max(dpt));
                    bb = bar(min(dpt):max(dpt),[n2; n1]','stacked'); hold on
                    bb(1).BarWidth = 1;
                    bb(2).BarWidth = 1;
                    axis tight
                    view([-90 90])
                    set(gca,'TickDir','out','Box','off')
                    set(gca,'xaxislocation','top')
                    xlabel('Cortical Depth')
                    plot([0 0],ylim,'g')
                    alim(1:2) = xlim;
                    title(sprintf('%s\nn = %uU over %uS in %uM\n%s',unittype2,sum(keep),length(unique({IDX(keep).penetration})), length(unique({IDX(keep).monkey})),eyestr))
                    legend(bb,{'pop2','pop1'},'Location','Best')
                    set(gca,'yaxislocation','right')
                end
                
                % histrogram 3 - dcos / layer
                if m == 1
                    subplot(3,4,[6 10] + (w-1))
                    scatter(dpt,dat,[dicolor 'x']); hold on
                    clear uu gname
                    [uu,gname]= grpstats(dat,{dpt},{'mean','gname'});
                    uu = [uu str2double(gname)];
                    plot(uu(:,2),uu(:,1),'d','LineWidth',1.5,'MarkerFaceColor',dicolor, 'MarkerEdgeColor','none');
                    hold on
                    axis(alim)
                    view([90 -90])
                    set(gca,'TickDir','out','Box','off')
                    plot([0 0],ylim,'g')
                    plot(xlim,[0 0],'g')
                    set(gca,'yaxislocation','right')
                    ylabel([dimeasures{m} condstr])
                end
                
                
                
                % measures of layer averages
                if m == 2
                    subplot(3,4,[8 12]);
                    
                    %                     clear uu gname
                    %                     [uu,gname]= grpstats(dat,{dpt},{'mean','gname'});
                    %                     uu = [uu str2double(gname)];
                    %                     plot(uu(:,2),uu(:,1),[':' dicolor],'LineWidth',1); hold on
                    
                    mm=[];
                    for dp = min(dpt): max(dpt);
                        ii = dpt >= dp-1 & dpt <= dp+1;
                        y =dat( ii');
                        mm = [mm; nanmean(y) dp];
                    end
                    
                    lh=plot(mm(~any(isnan(mm),2),2),mm(~any(isnan(mm),2),1),dicolor,'LineWidth',1.5); hold on
                    if w == 1
                        set(lh,'linestyle','--')
                    end
                    hold on
                    if w == 2
                        view([90 -90])
                        axis tight
                        xlim(alim(1:2))
                        %                         ylim([-1 1] * max(abs([uu(:,1);mm(:,1)])))
                        set(gca,'TickDir','out','Box','off')
                        plot([0 0],ylim,'g')
                        plot(xlim,[0 0],'g')
                        %                         plot(xlim,[-1 -1]*min(abs(dat(dat2 < alpha))),'y')
                        %                         plot(xlim,[ 1  1]*min(abs(dat(dat2 < alpha))),'y')
                        set(gca,'yaxislocation','right')
                        ylabel([dimeasures{m} condstr]);
                        %                         ylabel(sprintf('%s\nanova p = [%0.3f %0.3f]',[dimeasures{m} condstr],anp))
                    end
                end
            end
        end
    end
    
    %% Ocularity and Sigma Distrobutions
    figure
    
    clear keep
    keep = II & (goodDi | goodBi);
    
    clear occ
    occ = [IDX.occ];
    for m = 1:2
        subplot(2,2,m)
        dat = occ(m+1,keep)';
        lim = [-1.1 1.1] * round(max(abs(dat)),1);
        edges = lim(1):lim(2)/10:lim(2);
        n=histc(dat,edges);
        bar(edges,n,'histc')
        
        axis tight;
        set(gca,'Box','off','TickDir','out')
        if m == 1
            xlabel('tstat'); hold on
            tcrit = mode(abs(occ(2,occ(1,:) < alpha))); 
            plot([-1 -1]*tcrit,ylim,'y');
            plot([ 1  1]*tcrit,ylim,'y');            
        elseif m == 2
            xlabel('m.c.')
        end
        title(sprintf('occularity\nn = %uU over %uS in %uM\n%s',sum(keep),length(unique({IDX(keep).penetration})), length(unique({IDX(keep).monkey})),eyestr))
    end
    
    clear lim edges data centers 
    ori = [IDX.ori];
    dat = (ori([4 10 13],keep)); dat(dat>180) = NaN;
    centers = 10:10:round(max(max(dat)),-1); 
    subplot(2,2,4)
    hist(dat',centers);
    xlabel('sigma')
    legend('gaus1-sigma','gaus2-sigma1','gaus2-sigma2')
    
    axis tight;
    set(gca,'Box','off','TickDir','out')
        title(sprintf('ori tuning\nn = %uU over %uS in %uM\n%s',sum(keep),length(unique({IDX(keep).penetration})), length(unique({IDX(keep).monkey})),eyestr))

    
    %% N table
    
      clear units
    switch klstype
        case 'kls only'
            units = kls;
        case 'auto only'
            units = ~kls;
        otherwise
            units = true(size(kls));
    end
    fdffdfdfd
    
    N = [...
        length(unique({IDX((goodDi | goodBi) & units).penetration}))... % total penetrations used
        sum((goodDi | goodBi) & units) ... % total with either good condition
        sum((goodDi | goodBi) & units & (xII{1} | xII{2})) ...
        sum((goodDi | goodBi) & units & xII{1}) ...
        sum((goodDi | goodBi) & units & xII{2}); ...
        ...
        length(unique({IDX((goodDi & goodBi) & units).penetration}))... % total penetrations used
        sum((goodDi & goodBi) & units) ... % total with either good condition
        sum((goodDi & goodBi) & units & (xII{1} | xII{2})) ...
        sum((goodDi & goodBi) & units & xII{1}) ...
        sum((goodDi & goodBi) & units & xII{2}); ...
       ...
        length(unique({IDX((goodDi ) & units).penetration}))... % total penetrations used
        sum((goodDi) & units) ... % total with either good condition
        sum((goodDi) & units & (xII{1} | xII{2})) ...
        sum((goodDi) & units & xII{1}) ...
        sum((goodDi) & units & xII{2}); ...
        ...
        length(unique({IDX(( goodBi) & units).penetration}))... % total penetrations used
        sum((goodBi) & units) ... % total with either good condition
        sum((goodBi) & units & (xII{1} | xII{2})) ...
        sum((goodBi) & units & xII{1}) ...
        sum((goodBi) & units & xII{2}); ...
        ]
        
        
%     fprintf('\nN = [Total P examened, Total P w/ unit, Total P w/ unit & tasks,] - %s - %s',klstype,eyestr)
%     N = [...
%         length(unique({IDX(:).penetration})) ...% total penetrations
%         length(unique({IDX(logical(units)).penetration})) ...; % penetrations with a unit
%         length(unique({IDX((goodDi | goodBi) & units).penetration}))] % total units
%     
%     fprintf('\nUnit N - %s - %s',klstype,eyestr)
%     U = [...
%         sum((goodDi | goodBi) & units) ... % total with either good condition
%         sum(goodDi&units) ... % total with good condition
%         sum(goodBi&units) ...% total with good condition
%         sum(goodAll&units); ... % total with both good condition
%         ...
%         sum((goodDi | goodBi)  & units & (xII{1} | xII{2})) ...
%         sum(goodDi  & units & (xII{1} | xII{2})) ...
%         sum(goodBi  & units & (xII{1} | xII{2})) ...
%         sum(goodAll & units & (xII{1} | xII{2})); ...
%         ...
%         sum((goodDi | goodBi)  & units & xII{1}) ...
%         sum(goodDi  & units & xII{1}) ...
%         sum(goodBi  & units & xII{1}) ...
%         sum(goodAll & units & xII{1}); ...
%         ...
%         sum((goodDi | goodBi)  & units & xII{2}) ...
%         sum(goodDi  & units & xII{2}) ...
%         sum(goodBi  & units & xII{2}) ...
%         sum(goodAll & units & xII{2})]
%     
%     
%     mon     = grp2idx({IDX.monkey})';
%     fprintf('\nUnit N by MONKEY - %s - %s',klstype,eyestr)
%     M = [...
%         sum(mon==1 & (goodDi | goodBi) & units) ... % total with either good condition
%         sum(mon==1 & goodDi&units) ... % total with good condition
%         sum(mon==1 & goodBi&units) ...% total with good condition
%         sum(mon==1 & goodAll&units); ... % total with both good condition
%         ...
%         sum(mon==1 & (goodDi | goodBi)  & units & (xII{1} | xII{2})) ...
%         sum(mon==1 & goodDi  & units & (xII{1} | xII{2})) ...
%         sum(mon==1 & goodBi  & units & (xII{1} | xII{2})) ...
%         sum(mon==1 & goodAll & units & (xII{1} | xII{2})); ...
%         ...
%         sum(mon==1 & (goodDi | goodBi)  & units & xII{1}) ...
%         sum(mon==1 & goodDi  & units & xII{1}) ...
%         sum(mon==1 & goodBi  & units & xII{1}) ...
%         sum(mon==1 & goodAll & units & xII{1}); ...
%         ...
%         sum(mon==1 & (goodDi | goodBi)  & units & xII{2}) ...
%         sum(mon==1 & goodDi  & units & xII{2}) ...
%         sum(mon==1 & goodBi  & units & xII{2}) ...
%         sum(mon==1 & goodAll & units & xII{2})];
%     U1 = M
%     U2 = U-M
%     
%     fprintf('\nPenetration N - %s - %s',klstype,eyestr)
%     P = [...
%         length(unique({IDX((goodDi | goodBi) & units).penetration})) ... 
%         length(unique({IDX(goodDi&units).penetration})) ... % total with good condition
%         length(unique({IDX(goodBi&units).penetration})) ...% total with good condition
%         length(unique({IDX(goodAll&units).penetration})); ... % total with good condition
%         ...
%         length(unique({IDX((goodDi | goodBi)   & units & (xII{1} | xII{2})).penetration})) ...
%         length(unique({IDX(goodDi  & units & (xII{1} | xII{2})).penetration})) ...
%         length(unique({IDX(goodBi  & units & (xII{1} | xII{2})).penetration})) ...
%         length(unique({IDX(goodAll & units & (xII{1} | xII{2})).penetration})); ...
%         ...
%         length(unique({IDX((goodDi | goodBi)  & units & xII{1}).penetration})) ...
%         length(unique({IDX(goodDi  & units & xII{1}).penetration})) ...
%         length(unique({IDX(goodBi  & units & xII{1}).penetration})) ...
%         length(unique({IDX(goodAll & units & xII{1}).penetration})); ...
%         ...
%         length(unique({IDX((goodDi | goodBi)  & units & xII{2}).penetration})) ...
%         length(unique({IDX(goodDi  & units & xII{2}).penetration})) ...
%         length(unique({IDX(goodBi  & units & xII{2}).penetration})) ...
%         length(unique({IDX(goodAll & units & xII{2}).penetration}))]
%     
%     
%      fprintf('\nPenetration N by MONKEY - %s - %s',klstype,eyestr)
%      M = [...
%         length(unique({IDX(mon==1 & (goodDi | goodBi) & units).penetration})) ... 
%         length(unique({IDX(mon==1 & goodDi&units).penetration})) ... % total with good condition
%         length(unique({IDX(mon==1 & goodBi&units).penetration})) ...% total with good condition
%         length(unique({IDX(mon==1 & goodAll&units).penetration})); ... % total with good condition
%         ...
%         length(unique({IDX(mon==1 & (goodDi | goodBi)   & units & (xII{1} | xII{2})).penetration})) ...
%         length(unique({IDX(mon==1 & goodDi  & units & (xII{1} | xII{2})).penetration})) ...
%         length(unique({IDX(mon==1 & goodBi  & units & (xII{1} | xII{2})).penetration})) ...
%         length(unique({IDX(mon==1 & goodAll & units & (xII{1} | xII{2})).penetration})); ...
%         ...
%         length(unique({IDX(mon==1 & (goodDi | goodBi)  & units & xII{1}).penetration})) ...
%         length(unique({IDX(mon==1 & goodDi  & units & xII{1}).penetration})) ...
%         length(unique({IDX(mon==1 & goodBi  & units & xII{1}).penetration})) ...
%         length(unique({IDX(mon==1 & goodAll & units & xII{1}).penetration})); ...
%         ...
%         length(unique({IDX(mon==1 & (goodDi | goodBi)  & units & xII{2}).penetration})) ...
%         length(unique({IDX(mon==1 & goodDi  & units & xII{2}).penetration})) ...
%         length(unique({IDX(mon==1 & goodBi  & units & xII{2}).penetration})) ...
%         length(unique({IDX(mon==1 & goodAll & units & xII{2}).penetration}))];
%     P1 = M
%     P2 = P-M
%     
%     
%     fprintf('\nPopulation Overlap - %s - %s',klstype,eyestr)
%     pen = grp2idx({IDX.penetration});
%     ovl = intersect(pen(xII{2}),pen(xII{1}));
%     mem = ismember(pen(xII{2}),ovl);
%     O = [sum(mem) sum(~mem) length(mem)]
    
    
end




return


%% ATTNETION x dCOS

clear at*
atanova = [IDX.atanova];
atstats = [IDX.atastats];
atwin = [.1 .2];
atalpha = 0.1; 

clear newI
newI = kls & [IDX.redun] == 0 & atanova(2,:) < 0.05;
unittype2 = 'kls w/ effect of stim'; %'main effect of attention, kls only';

clear *Mo* *Di* *Bi*
for i = 1:length(IDX);
    MoA(i,:) = IDX(i).(SDF)(13, :);
    MoU(i,:) = IDX(i).(SDF)(14, :);
    BiA(i,:) = IDX(i).(SDF)(16, :);
    BiU(i,:) = IDX(i).(SDF)(17, :);
    DiA(i,:) = IDX(i).(SDF)(19, :);
    DiU(i,:) = IDX(i).(SDF)(20, :);
    dMo(i,:) = IDX(i).(SDF)(22, :);
    dBi(i,:) = IDX(i).(SDF)(23, :);
    dDi(i,:) = IDX(i).(SDF)(24, :);
    
end

clear remove keep tm tmlim
remove = all(isnan(MoA)') | all(isnan(MoU)') | all(isnan(BiA)') | all(isnan(BiU)');
keep   = ~remove ;
tm = mode(TM(newI & keep,:),1);
tmlim = tm >= atwin(1) & tm <= atwin(2);

figure('Position',[0 0 601 874]); clf
for di = 0:1
    clear U A D
    if di == 1
        U = DiU;
        A = DiA;
        D = dDi;
        cond = 'dCOS';
        color = 'r';
    else
        U = BiU;
        A = BiA;
        D = dBi;
        cond = 'BC';
        color = 'b'; 
    end
    
    subplot(4,2,1+di)
    plot(tm,nanmean(MoU(newI & keep,:),1),'k','LineWidth',1);hold on
    plot(tm,nanmean(MoA(newI & keep,:),1),'k','LineWidth',2);
    plot(tm,nanmean(  U(newI & keep,:),1),color,'LineWidth',1);
    plot(tm,nanmean(  A(newI & keep,:),1),color,'LineWidth',2); axis tight
    xlim([tm(1) 0.25]);
    plot([0 0],ylim,'k')
    set(gca,'TickDir','out','Box','off')
    title(sprintf('%s v Monocular\n%s, n = %u / %u\n%s',cond,unittype2, sum(newI & keep),length(unique({IDX(newI & keep).penetration})),eyestr))
    [~, p ~,stat] =ttest2(mean(  MoA(newI & keep,tmlim),2), mean(MoU(newI & keep,tmlim),2) )
    [~, p ~,stat] =ttest2(mean(   A(newI & keep,tmlim),2),  mean(U(newI & keep,tmlim),2) )

    
    
    subplot(4,2,3+di)
    plot(tm,nanmean(dMo(newI & keep,:),1),'k','LineWidth',1.5);hold on
    plot(tm,nanmean(  D(newI & keep,:),1),color,'LineWidth',1.5);axis tight
    xlim([tm(1) 0.25]);
    plot([0 0],ylim,'k')
    plot(xlim,[0 0],'k')
    set(gca,'TickDir','out','Box','off')
    

    subplot(4,2,5+di)
    % delta delta timcourse
    clear ci
    [~, ~, ci] = ttest2( D(newI & keep,:), dMo(newI & keep,:));
    ci(3,:) = nanmean( D(newI & keep,:) - dMo(newI & keep,:));
    lh = plot(tm,ci,color); hold on; axis tight
    set(lh(end),'LineWidth',1.5); 
    xlim([tm(1) 0.25]);
    plot([0 0],ylim,'k')
    plot(xlim,[0 0],'k')
    set(gca,'TickDir','out','Box','off')
    plot([1 1] * atwin(1) ,ylim,':k')
    plot([1 1] * atwin(2) ,ylim,':k')
    % ttest for title
    [~, p ~,stat] =ttest2(mean(  D(newI & keep,tmlim),2), mean(dMo(newI & keep,tmlim),2) )
    title(sprintf('u = %0.2f; t(%u) = %0.2f, p = %0.3f',mean(ci(3,tmlim),2),stat.df,stat.tstat,p))

    % mc scatters
    subplot(4,2,7+di)
    clear x* y*
    x = nanmean(dMo(newI & keep,tmlim),2)  ./ (nanmean(MoA(newI & keep,tmlim),2)  + nanmean(MoU(newI & keep,tmlim),2));
    y = nanmean(  D(newI & keep,tmlim),2)  ./ (nanmean(  A(newI & keep,tmlim),2) + nanmean(  U(newI & keep,tmlim),2));
   
    
    xt = atstats(1+0,newI & keep);
    xp = atstats(1+3,newI & keep);
    
    if di == 1
        yt = atstats(3+0,newI & keep);
        yp = atstats(3+3,newI & keep);
    elseif di == 0
        yt = atstats(2+0,newI & keep);
        yp = atstats(2+3,newI & keep);
    end
    
    clear sig
    sig = 2*(yp<atalpha) + (xp<atalpha); unique(sig)

    if di == 0
        % outline rejection
        x(y<-0.02) = [];
        sig(y<-0.02) = [];
        y(y<-0.02) = [];
    end
    scatter(x,y,[],sig); hold on;
    
    axis([-1 1 -1 1] .* max([max(abs(y)), max(abs(x))])); axis square
    
    xlabel('mc(M)')
    ylabel(['mc(', cond, ')'])
    
    lsline; [r,p] = corrcoef(x,y); 
    title(sprintf('r = %.3f, p = %.3f',r(2),p(2)))
    
  
    
end
    
    
    
    
    



%%
subplot(3,2,4)

remove = all(isnan(MoA)') | all(isnan(MoU)') | all(isnan(DiA)') | all(isnan(DiU)');
keep   = ~remove ;
clear tm; tm = mode(TM(newI & keep,:),1);

plot(tm,nanmean(dMo(newI & keep,:),1),'k','LineWidth',1.5);hold on
plot(tm,nanmean(dBi(newI & keep,:),1),'b','LineWidth',1.5);axis tight
xlim([tm(1) 0.25]);
plot([0 0],ylim,'k')
plot(xlim,[0 0],'k')
set(gca,'TickDir','out','Box','off')


%%
  ahaha
    
    % t scatters
    subplot(5,2,9+di)
    
   
       
    scatter(xt,yt,[],sig,'d','MarkerFaceColor','Flat'); hold on;
       
    axis([-1 1 -1 1] .* max([max(abs(yt)), max(abs(xt))])); axis square

    xlabel('tstat(M)')
    ylabel(['tstat(', cond, ')'])
    
    plot(xlim,[0 0],'k')
    plot(xlim,  nanmean(yt).*[1 1],color)
    plot([0 0],ylim,'k')
    plot(  nanmean(xt).*[1 1],ylim,'--k')
%%

subplot(3,2,6); cla; clear y* sig
yt = atstats(2+0,newI & keep);
yp = atstats(2+3,newI & keep);
sig = 2*(yp<atalpha) + (xp<atalpha); unique(sig)
scatter(xt,yt,[],sig,'d','MarkerFaceColor','Flat'); hold on; 
axis([-2.4 2.4 -2.4 2.4]); axis square

xlabel('tstat(M)')
ylabel('tstat(BC)')

plot(xlim,[0 0],'k')
plot(xlim,  nanmedian(yt).*[1 1],'b')
plot([0 0],ylim,'k')
plot(  nanmedian(xt).*[1 1],ylim,'--k')




% 
% subplot(3,2,5);
% 
% remove = all(isnan(MoA)') | all(isnan(MoU)') | all(isnan(DiA)') | all(isnan(DiU)');
% keep   = ~remove ;
% clear tm; tm = mode(TM(newI & keep,:),1);
% clear tmlim; tmlim = tm >= atwin(1) & tm <= atwin(2);
% clear tm
% 
% clear x y
% x = nanmean(dMo(newI & keep,tmlim),2) ./ (nanmean(MoA(newI & keep,tmlim),2)  + nanmean(MoU(newI & keep,tmlim),2));
% y = nanmean(dDi(newI & keep,tmlim),2)  ./ (nanmean(DiA(newI & keep,tmlim),2) + nanmean(DiU(newI & keep,tmlim),2));
% scatter(x,y); hold on;
% axis([-1 1 -1 1] .* .34); axis square
% 
% plot([0 0],ylim,'k')
% plot(  nanmean(x).*[1 1],ylim,'--k')
% %plot(nanmedian(x).*[1 1],ylim,':k')
% 
% plot(xlim,[0 0],'k')
% plot(xlim,  nanmean(y).*[1 1],'r')
% %plot(xlim,nanmedian(y).*[1 1],'m')
% 
% set(gca,'TickDir','out','Box','off')
% xlabel('Monocular')
% ylabel('dCOS')
% 
% 
% subplot(3,2,6)
% remove = all(isnan(MoA)') | all(isnan(MoU)') | all(isnan(BiA)') | all(isnan(BiU)');
% keep   = ~remove ;
% clear tm; tm = mode(TM(newI & keep,:),1);
% 
% clear x y
% x = nanmean(dMo(newI & keep,tmlim),2)  ./ (nanmean(MoA(newI & keep,tmlim),2) + nanmean(MoU(newI & keep,tmlim),2));
% y = nanmean(dBi(newI & keep,tmlim),2)  ./ (nanmean(BiA(newI & keep,tmlim),2) + nanmean(BiU(newI & keep,tmlim),2));
% scatter(x,y); hold on;
% axis([-1 1 -1 1] .* .34); axis square
% 
% 
% 
% 
% plot([0 0],ylim,'k')
% plot(  nanmean(x).*[1 1],ylim,'--k')
% %plot(nanmedian(x).*[1 1],ylim,':k')
% 
% plot(xlim,[0 0],'k')
% plot(xlim,  nanmean(y).*[1 1],'b')
% %plot(xlim,nanmedian(y).*[1 1],'c')
% 
% set(gca,'TickDir','out','Box','off')
% xlabel('Monocular')
% ylabel('BI')

%%



%
%
% % overlap between populations
% i = intersect(xP{2},xP{1});
% d = setdiff(xP{2},xP{1});
% dsum = sum(ismember(xP{2},d));
% isum = sum(ismember(xP{2},i));
% disp('overlap between populations')
% isum/length(xP{2})
%
%
% ahaha
% subplot(2,2,porder(u,double(c==0)+1))
% clear tm; tm = mode(TM(:,I & keep),2);
%
% clear x s
% x = nanmean(Mo(I & keep,:),1); s = nanstd(Mo(I & keep,:),[],1) ./ sum(I & keep);
% plot(tm,x,'k','LineWidth',2);hold on
% plot(tm,x+s,'k','LineWidth',0.5);hold on
% plot(tm,x-s,'k','LineWidth',0.5);hold on
%
% clear x s
% x = nanmean(Bi(I & keep,:),1); s = nanstd(Bi(I & keep,:),[],1) ./ sum(I & keep);
% plot(tm,x,'b','LineWidth',2);hold on
% plot(tm,x+s,'b','LineWidth',0.5);hold on
% plot(tm,x-s,'b','LineWidth',0.5);hold on
%
% clear x s
% x = nanmean(Di(I & keep,:),1); s = nanstd(Bi(I & keep,:),[],1) ./ sum(I & keep);
% plot(tm,x,'r','LineWidth',2);hold on
% plot(tm,x+s,'r','LineWidth',0.5);hold on
% plot(tm,x-s,'r','LineWidth',0.5);hold on
%
% axis tight;
% plot([0 0],ylim,'k')
% set(gca,'TickDir','out','Box','off')
% xlabel('Time (s)')
% title(sprintf('%s\nn = %u units over %u sessions\n%s',unittype,sum(I & keep),length(unique({IDX(I & keep).penetration})),eyestr))
%
%
%
% % delta
%
% if u == 1
%     h(3) = figure('Position',[0 0 601 874]);
% else
%     figure(h(3));
% end
% porder = [1 3; 2 4];
%
% for c = 0:2:2
%
%
%     if c == 0
%         mstr = '[full contrast, blank]';
%         dstr = '[full contrast, full contrast]';
%         eyestr = 'DE at full contrast, NDE at full';
%     else
%         mstr = '[1/2 contrast, blank]';
%         dstr = '[1/2 contrast, full contrast]';
%         eyestr = 'DE at 1/2 contrast, NDE at full';
%     end
%
%     clear BI DI
%     for i = 1:length(IDX);
%         Bi(i,:) = IDX(i).(SDF)( 9+c, :);
%         Di(i,:) = IDX(i).(SDF)(10+c, :);
%     end
%     remove = all(isnan(Bi)') | all(isnan(Di)');
%     keep   = ~remove;
%
%     subplot(2,2,porder(u,double(c==0)+1))
%     clear tm; tm = mode(TM(:,I & (~all(isnan(Bi)') | ~all(isnan(Bi)')) ),2);
%
%     x = nanmean(Bi(I&keep,:),1); s = nanstd(Bi(I&keep,:),[],1) ./ sum(I&keep);
%     plot(tm,x,'b','LineWidth',2); hold on
%     plot(tm,x+s,'b','LineWidth',0.5); hold on
%     plot(tm,x-s,'b','LineWidth',0.5); hold on
%
%     x = nanmean(Di(I&keep,:),1); s = nanstd(Di(I&keep,:),[],1) ./ sum(I&keep);
%     plot(tm,x,'r','LineWidth',2); hold on
%     plot(tm,x+s,'r','LineWidth',0.5); hold on
%     plot(tm,x-s,'r','LineWidth',0.5); hold on
%
%     axis tight;
%     plot([0 0],ylim,'k')
%     plot(xlim,[0 0],'k')
%     set(gca,'TickDir','out','Box','off')
%     title(sprintf('Di(ch)optic - Monocular\n%s, n = %u / %u\n%s',unittype, sum(I & keep),length(unique({IDX(I & keep).penetration})),eyestr))
%     xlabel('Time (s)')
%     ylabel('Delta Spks')
% end
%
%
%
%
%
%
%
%
%
%
%
%
%
%
% %% depth histrogram
% if u == 1
%     h(1) = figure('Position',[0 0 601 874]);
%     clear D
% else
%     figure(h(1));
% end
% porder = [4 1 ;5 2];
%
% depths = [IDX.depth];
% for d = 1:2
%     subplot(2,3,porder(u,d))
%     cla
%     depth = depths(d,I);
%     [n,  e]= hist(depth,min(depths(d,:)):max(depths(d,:)));
%     bar(e,n); hold on
%     if d == 1
%         set(gca,'view',[90 90])
%         title(sprintf('units as a function of depth\ndepth from top'))
%     else
%         set(gca,'view',[90 -90])
%         title(sprintf('units as a function of depth\ndepth from sink'))
%     end
%     xlabel(sprintf('%s\n%u units over %u sessons',unittype,sum(I),length(unique({IDX(I).penetration}))))
%
%     axis tight; hold on;
%     plot([0 0],ylim,'k')
%     set(gca,'TickDir','out','Box','off')
%     D{u,d} = n;
% end
%
% if u == 2
%     porder = [6 3];
%     for d = 1:2
%         subplot(2,3,porder(d))
%         bar(min(depths(d,:)):max(depths(d,:)),cell2mat(flipud(D(:,d)))','stacked')
%
%         if d == 1
%             set(gca,'view',[90 90])
%             title(sprintf('units as a function of depth\ndepth from top'))
%         else
%             set(gca,'view',[90 -90])
%             title(sprintf('units as a function of depth\ndepth from sink'))
%         end
%
%         axis tight; hold on;
%         plot([0 0],ylim,'k')
%         set(gca,'TickDir','out','Box','off')
%     end
% end
%
%
% %%
% % evoked
%
% if u == 1
%     h(2) = figure('Position',[0 0 601 874]);
% else
%     figure(h(2));
% end
% porder = [1 3; 2 4];
%
% for c = 0:3:3
%
%
%     if c == 0
%         mstr = '[full contrast, blank]';
%         dstr = '[full contrast, full contrast]';
%         eyestr = 'DE at full contrast, NDE at full';
%     else
%         mstr = '[1/2 contrast, blank]';
%         dstr = '[1/2 contrast, full contrast]';
%         eyestr = 'DE at 1/2 contrast, NDE at full';
%     end
%
%     clear Mo BI DI
%     for i = 1:length(IDX);
%         Mo(i,:) = IDX(i).(SDF)(1+c, :);
%         Bi(i,:) = IDX(i).(SDF)(2+c, :);
%         Di(i,:) = IDX(i).(SDF)(3+c, :);
%     end
%     remove = all(isnan(Mo)') | all(isnan(Bi)') | all(isnan(Di)');
%     keep   = ~remove;
%
%     subplot(2,2,porder(u,double(c==0)+1))
%     clear tm; tm = mode(TM(:,I & keep),2);
%
%     clear x s
%     x = nanmean(Mo(I & keep,:),1); s = nanstd(Mo(I & keep,:),[],1) ./ sum(I & keep);
%     plot(tm,x,'k','LineWidth',2);hold on
%     plot(tm,x+s,'k','LineWidth',0.5);hold on
%     plot(tm,x-s,'k','LineWidth',0.5);hold on
%
%     clear x s
%     x = nanmean(Bi(I & keep,:),1); s = nanstd(Bi(I & keep,:),[],1) ./ sum(I & keep);
%     plot(tm,x,'b','LineWidth',2);hold on
%     plot(tm,x+s,'b','LineWidth',0.5);hold on
%     plot(tm,x-s,'b','LineWidth',0.5);hold on
%
%     clear x s
%     x = nanmean(Di(I & keep,:),1); s = nanstd(Bi(I & keep,:),[],1) ./ sum(I & keep);
%     plot(tm,x,'r','LineWidth',2);hold on
%     plot(tm,x+s,'r','LineWidth',0.5);hold on
%     plot(tm,x-s,'r','LineWidth',0.5);hold on
%
%     axis tight;
%     plot([0 0],ylim,'k')
%     set(gca,'TickDir','out','Box','off')
%     xlabel('Time (s)')
%     title(sprintf('%s\nn = %u units over %u sessions\n%s',unittype,sum(I & keep),length(unique({IDX(I & keep).penetration})),eyestr))
% end
%
%
% % delta
%
% if u == 1
%     h(3) = figure('Position',[0 0 601 874]);
% else
%     figure(h(3));
% end
% porder = [1 3; 2 4];
%
% for c = 0:2:2
%
%
%     if c == 0
%         mstr = '[full contrast, blank]';
%         dstr = '[full contrast, full contrast]';
%         eyestr = 'DE at full contrast, NDE at full';
%     else
%         mstr = '[1/2 contrast, blank]';
%         dstr = '[1/2 contrast, full contrast]';
%         eyestr = 'DE at 1/2 contrast, NDE at full';
%     end
%
%     clear BI DI
%     for i = 1:length(IDX);
%         Bi(i,:) = IDX(i).(SDF)( 9+c, :);
%         Di(i,:) = IDX(i).(SDF)(10+c, :);
%     end
%     remove = all(isnan(Bi)') | all(isnan(Di)');
%     keep   = ~remove;
%
%     subplot(2,2,porder(u,double(c==0)+1))
%     clear tm; tm = mode(TM(:,I & (~all(isnan(Bi)') | ~all(isnan(Bi)')) ),2);
%
%     x = nanmean(Bi(I&keep,:),1); s = nanstd(Bi(I&keep,:),[],1) ./ sum(I&keep);
%     plot(tm,x,'b','LineWidth',2); hold on
%     plot(tm,x+s,'b','LineWidth',0.5); hold on
%     plot(tm,x-s,'b','LineWidth',0.5); hold on
%
%     x = nanmean(Di(I&keep,:),1); s = nanstd(Di(I&keep,:),[],1) ./ sum(I&keep);
%     plot(tm,x,'r','LineWidth',2); hold on
%     plot(tm,x+s,'r','LineWidth',0.5); hold on
%     plot(tm,x-s,'r','LineWidth',0.5); hold on
%
%     axis tight;
%     plot([0 0],ylim,'k')
%     plot(xlim,[0 0],'k')
%     set(gca,'TickDir','out','Box','off')
%     title(sprintf('Di(ch)optic - Monocular\n%s, n = %u / %u\n%s',unittype, sum(I & keep),length(unique({IDX(I & keep).penetration})),eyestr))
%     xlabel('Time (s)')
%     ylabel('Delta Spks')
% end
%
%
%
% % var
% for var = 1:8
%     if u == 1
%         h(3+var) = figure('Position',[0 0 601 874]);
%         clear anp
%     else
%         figure(h(3+var));
%     end
%     porder = [1 3; 2 4];
%
%     for c = 0:2:2
%
%         if c == 0
%             mstr = '[full contrast, blank]';
%             dstr = '[full contrast, full contrast]';
%             eyestr = 'DE at full contrast, NDE at full';
%         else
%             mstr = '[1/2 contrast, blank]';
%             dstr = '[1/2 contrast, full contrast]';
%             eyestr = 'DE at 1/2 contrast, NDE at full';
%         end
%
%         clear BI DI DEPTH
%         for i = 1:length(IDX);
%             clear tm tmlim
%             tm = TM(i,:);
%             tmlim = tm >= diwin(1) & tm <= diwin(2);
%             if mod(var,2) ~= 0
%                 Bi(i,:) = nanmean(IDX(i).(SDF)( 9+c, tmlim)) ./ (nanmean(IDX(i).(SDF)(2+(c~=0)*3, tmlim)) + nanmean(IDX(i).(SDF)(1+(c~=0)*3, tmlim))) ;
%                 Di(i,:) = nanmean(IDX(i).(SDF)(10+c, tmlim)) ./ (nanmean(IDX(i).(SDF)(3+(c~=0)*3, tmlim)) + nanmean(IDX(i).(SDF)(1+(c~=0)*3, tmlim)));
%             else
%                 Bi(i,:) = IDX(i).distats(1+c);
%                 Di(i,:) = IDX(i).distats(2+c);
%             end
%             DEPTH(i,:) =  IDX(i).depth(2);
%         end
%         clear tm
%
%         if mod(var,2) ~= 0
%             Bi(abs(Bi) >1) = NaN;
%             Di(abs(Di) >1) = NaN;
%             measure = 'm.c.';
%             centers = -1.1:0.1:1.1;
%         else
%             Bi(abs(Bi) >5) = NaN;
%             Di(abs(Di) >5) = NaN;
%             measure = 'tstat';
%             centers = -5.5:0.5:5.5;
%         end
%         subplot(2,2,porder(u,double(c==0)+1))
%         if var == 1 || var == 2
%             keep = ~isnan(Bi) ;
%             hist(Bi(I & keep'),centers); hold on
%             xlim([min(centers) max(centers)])
%             plot([0 0],ylim,'k')
%             plot(  mean(Bi(I & keep')).*[1 1],ylim,'b')
%             plot(median(Bi(I & keep')).*[1 1],ylim,'c')
%             xlabel([measure '(BI-M)'])
%
%         elseif var == 3 || var == 4
%             keep = ~isnan(Di);
%             hist(Di(I & keep'),centers); hold on
%             plot(  mean(Di(I & keep')).*[1 1],ylim,'r')
%             plot(median(Di(I & keep')).*[1 1],ylim,'m')
%             xlim([min(centers) max(centers)])
%             plot([0 0],ylim,'k')
%             xlabel([measure '(dCOS-M)'])
%         elseif var == 5 || var == 6
%             keep = ~isnan(Di) & ~isnan(Bi) ;
%             scatter(Bi(I & keep'),Di(I & keep')); hold on
%             axis([min(centers) max(centers) min(centers) max(centers)])
%             axis square
%
%             plot([0 0],ylim,'k')
%             plot(  mean(Bi(I & keep')).*[1 1],ylim,'b')
%             plot(median(Bi(I & keep')).*[1 1],ylim,'c')
%
%             plot(xlim,[0 0],'k')
%             plot(xlim,  mean(Di(I & keep')).*[1 1],'r')
%             plot(xlim,median(Di(I & keep')).*[1 1],'m')
%
%             lsline
%
%             xlabel([measure '(BI-M)'])
%             ylabel([measure '(dCOS-M)'])
%         elseif var == 7 || var == 8
%             %%
%
%             % BF
%             clear keep dat depths
%             keep = ~isnan(Bi) ;
%             dat    = Bi(I & keep');
%             depths = DEPTH(I & keep');
%
%             %                 clear dgroup
%             %                 dgroup = nan(size(depths));
%             %                 dgroup(depths < 0) = -1;
%             %                 dgroup(depths >= 0 & dgroup <= 5) = 0;
%             %                 dgroup(depths > 5) = 1;
%             %                 anovan(dat,{depths},'display','off')
%             %                 anovan(dat,{dgroup},'display','off')
%             %
%
%             %scatter
%             scatter(depths,dat,'x','MarkerEdgeColor',[0.5 0.5 1]); hold on%,'MarkerEdgeColor','none'); hold on
%
%             % measures of layer averages - 1
%             clear uu gname mm
%             [uu,gname]= grpstats(dat,{depths},{'mean','gname'});
%             uu = [uu str2double(gname)];
%             plot(uu(:,2),uu(:,1),'d','LineWidth',1.5,'MarkerFaceColor',[.25 .25 1], 'MarkerEdgeColor',[.25 .25 1]);
%             hold on
%             % measures of layer averages - 2
%             mm=[];
%             for dp = min(depths): max(depths);
%                 ii = depths >= dp-1 & depths <= dp+1;
%                 y =dat( ii');
%                 mm = [mm; nanmean(y) dp];
%             end
%             plot(mm(~any(isnan(mm),2),2),mm(~any(isnan(mm),2),1),'b','LineWidth',1.5);
%             hold on
%
%
%             % dCOS
%             clear keep dat depths
%             keep = ~isnan(Di) ;
%             dat    = Di(I & keep');
%             depths = DEPTH(I & keep');
%
%             %                 clear dgroup
%             %                 depths = DEPTH(I & keep');
%             %                 dgroup = nan(size(depths));
%             %                 dgroup(depths < 0) = -1;
%             %                 dgroup(depths >= 0 & dgroup <= 5) = 0;
%             %                 dgroup(depths > 5) = 1;
%             %                 anovan(dat,{depths},'display','off')
%             %                 anovan(dat,{dgroup},'display','off')
%
%             %scatter
%             scatter(depths,dat,'x','MarkerEdgeColor',[1 0.5 0.5]);%'MarkerEdgeColor','none'); hold on
%
%             % measures of layer averages - 1
%             clear uu gname mm
%             [uu,gname]= grpstats(dat,{depths},{'mean','gname'});
%             uu = [uu str2double(gname)];
%             plot(uu(:,2),uu(:,1),'d','LineWidth',1.5,'MarkerFaceColor',[1 .25 .25], 'MarkerEdgeColor',[1 .25 .25]);
%             hold on
%             % measures of layer averages - 2
%             mm=[];
%             for dp = min(depths): max(depths);
%                 ii = depths >= dp-1 & depths <= dp+1;
%                 y =dat( ii');
%                 mm = [mm; nanmean(y) dp];
%             end
%             plot(mm(~any(isnan(mm),2),2),mm(~any(isnan(mm),2),1),'r','LineWidth',1.5);
%             hold on
%
%
%             set(gca,'view',[90 -90])
%             axis tight;
%             xlim([min(DEPTH) max(DEPTH)])
%             plot([0 0],ylim,'k')
%             plot(xlim,[0 0],'k')
%             ylabel(measure)
%
%         end
%         set(gca,'TickDir','out','Box','off')
%         title(sprintf('Di(ch)optic - Monocular\n%s, n = %u / %u\n%s',unittype, sum(I & keep'),length(unique({IDX(I & keep').penetration})),eyestr))
%
%     end
%
% end
%
%
% %%
%
% if u == 1
%     h(13) = figure('Position',[0 0 601 874]); clf
% else
%     figure(h(13)); colormap(bone)
% end
% porder = [1 3; 2 4];
%
% for c = 0:2:2
%
%     if c == 0
%         mstr = '[full contrast, blank]';
%         dstr = '[full contrast, full contrast]';
%         eyestr = 'DE at full contrast, NDE at full';
%     else
%         mstr = '[1/2 contrast, blank]';
%         dstr = '[1/2 contrast, full contrast]';
%         eyestr = 'DE at 1/2 contrast, NDE at full';
%     end
%
%     clear *T *P  distats
%     distats=[IDX.distats];
%     biT = distats([0+1+c 0+1+c+8],:);
%     biP = distats([0+5+c 0+5+c+8],:);
%     diT = distats([1+1+c 1+1+c+8],:);
%     diP = distats([1+5+c 1+5+c+8],:);
%
%     clear remove keep
%     remove = any(isnan(biT)) | any(isnan(diT));
%     keep   = ~remove;
%
%     clear bi di n
%     bi = sign(biT(:,I & keep)) .* ((biP(:,I & keep) < alpha)+1);
%     di = sign(diT(:,I & keep)) .* ((diP(:,I & keep) < alpha)+1);
%
%     n(:,1) = hist(di(2,:),-2:2);
%     n(:,2) = hist(bi(2,:),-2:2);
%     n(:,3) = hist(di(1,:),-2:2);
%     n(:,4) = hist(bi(1,:),-2:2);
%
%     subplot(2,2,porder(u,double(c==0)+1))
%     bar(n','stacked'); colormap('gray');
%     set(gca,'xticklabel',{'early Di','early Bi','late Di','late Bi'})
%     view([90 90])
%     set(gca,'TickDir','out','Box','off')
%     title(sprintf('supression v. facilitation\n%s, n = %u / %u\n%s',unittype, sum(I & keep),length(unique({IDX(I & keep).penetration})),eyestr))
%
% end

