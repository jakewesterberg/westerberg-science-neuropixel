clear

fullfilelist = {...
% %     '/Volumes/Drobo/DATA/NEUROPHYS/rig022/160330_E/Experiment-E48-03-30-2016.bhv'...rsvpln = 1, NEW TASK with target SOA, rand small red target, edge smoothed
% %     '/Volumes/Drobo/DATA/NEUROPHYS/rig022/160330_E/Experiment-E48-03-30-2016(01).bhv'...rsvpln = 1, NEW TASK with target SOA, rand small red target, edge smoothed
% %     '/Volumes/Drobo/DATA/NEUROPHYS/rig022/160331_E/Experiment-E48-03-31-2016.bhv'...rsvpln = 1, NEW TASK with target SOA, rand small red target, edge smoothed
% %     '/Volumes/Drobo/DATA/NEUROPHYS/rig022/160331_E/Experiment-E48-03-31-2016(01).bhv'...rsvpln = 1, NEW TASK with target SOA, rand small red target, edge smoothed
% %     'Experiment-E48-03-31-2016(02).bhv';...rsvpln = 1, NEW TASK with target SOA, rand small red target, edge smoothed
%     'Experiment-E48-04-01-2016';...rsvpln = 1, NEW TASK with target SOA, rand small red target, edge smoothed
%     'Experiment-E48-04-01-2016(01)';...rsvpln = 1, NEW TASK with target SOA, rand small red target, edge smoothed
%     'Experiment-E48-04-02-2016';...rsvpln = 1, NEW TASK with target SOA, rand small red target, edge smoothed
%     'Experiment-E48-04-03-2016';...rsvpln = 1, NEW TASK with target SOA, rand small red target, edge smoothed
%     '160416_E_rsvp003';...rsvpln = 1, NEW TASK with target SOA, rand small red target, edge smoothed
%     '160416_E_rsvp004';...rsvpln = 1, NEW TASK with target SOA, rand small red target, edge smoothed
    '160418_E_rsvp001';... RECORDINGS START -- rsvpln = 1, NEW TASK with target SOA, rand small red target, edge smoothed
    '160418_E_rsvp002';...
    '160418_E_rsvp003';...
    '160420_E_rsvp001';...
    '160420_E_rsvp002';...
    '160421_E_rsvp001';...
    '160421_E_rsvp002';...
    '160421_E_rsvp003';...
    '160422_E_rsvp001';...
    '160422_E_rsvp002';...
    '160423_E_rsvp001';...
    '160425_E_rsvp001';...
    '160425_E_rsvp002';...
    '160425_E_rsvp003';...
    '160427_E_rsvp001';...
    '160427_E_rsvp002';...
    '160429_E_rsvp001';... comment from here for 7 session figure
    '160429_E_rsvp002';...
    '160502_E_rsvp001';...
    '160502_E_rsvp002';...
    '160502_E_rsvp003';...
    '160505_E_rsvp001';...
    '160505_E_rsvp002';...
    '160505_E_rsvp003';...
    '160512_E_rsvp001';...
    '160512_E_rsvp002';...
     };

% 
% fullfilelist = {... all the sessions where I collected the redundant cue data
%     '160418_E_rsvp002';...
%     '160418_E_rsvp003';...
%     '160420_E_rsvp001';...
%     '160420_E_rsvp002';...
%     '160421_E_rsvp001';...
%     '160421_E_rsvp002';...
%     '160421_E_rsvp003';...
%     '160422_E_rsvp001';...
%     '160422_E_rsvp002';...
%     '160423_E_rsvp001';...
%     '160425_E_rsvp001';...
%     '160425_E_rsvp002';...
%     '160425_E_rsvp003';...
%     '160427_E_rsvp001';...
%     '160427_E_rsvp002';...
%     '160429_E_rsvp001';...
%     '160429_E_rsvp002';...
%     '160502_E_rsvp001';...
%     '160502_E_rsvp002';...
%     '160502_E_rsvp003';...
%     '160505_E_rsvp001';...
%     '160505_E_rsvp002';...
%     '160505_E_rsvp003';...
%     '160512_E_rsvp001';...
%     '160512_E_rsvp002';...
%     };


atypicalnamestyle =  cellfun(@(x) strcmp(x(1),'E'),fullfilelist);
Headers1 =  cellfun(@(x) x(1:8), fullfilelist(~atypicalnamestyle),'UniformOutput',0);
Headers2 =  cellfun(@(x) [datestr(datenum(x(16:strfind(x,'2016')+3)),'yymmdd') '_' x(12)],...
    fullfilelist(atypicalnamestyle),'UniformOutput',0);
Headers = cell(size(fullfilelist));
Headers(~atypicalnamestyle) = Headers1;
Headers( atypicalnamestyle) = Headers2;
uHeaders =  unique(Headers);

excludeMonocular = true;
flag_rtbar = true;
flag_fitdprime = true;

clear dprime
for j = 1:length(uHeaders)
    header = uHeaders{j};
    filelist = fullfilelist(strcmp(Headers,header));
    
    n =  datenum(header(1:6),'yymmdd');
    if any(n < datenum('18-Mar-2016','dd-mmm-yyyy'))
        targetposbycond = [NaN NaN NaN NaN 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4];
        maxcatchcond = 4;
    else
        targetposbycond = [NaN NaN 1 1 2 2 3 3 4 4];
        maxcatchcond = 2;
    end
    
    ct = 0;
    clear TrialError ConditionNumber BlockNumber ReactionTime TargetPos Saturation CueValid TargetMoncular TargetTm
    for i = 1:length(filelist)
        
        if ispc
            mldrname = sprintf('Y:\\%s\\',header);
        else
            mldrname =  sprintf('/Volumes/Drobo/DATA/NEUROPHYS/rig022/%s/',header);
        end
        bhvfile = [mldrname filelist{i} '.bhv'];
        
        clear bhv cue cuedD uncuedD targetD rsvp_ln fdir fname rgbcolor tColors isCueValid I
        bhv = concatBHV(bhvfile);
        [fdir,fname,~] = fileparts(bhvfile);
        if any(strcmp(bhv.TaskObject(1,:),'gen(gTarg_di)'))
            [cue, cuedD, cuedS, uncuedD, uncuedS, targetD, ~, rsvp_ln] = loadRSVPdata(fdir,fname);
            rgbcolor = hex2rgb(targetD.grating_color2);
            % tColors = round(1 - rgbcolor(:,2),2);
            tColors = 1 - rgbcolor(:,2);
            isCueValid = (cue.grating_theta(1:2:end) == targetD.grating_theta);
        else
            [~, cuedD, cuedS, uncuedD, uncuedS, rsvp_ln] = loadRSVPdata(fdir,fname);
            
            for tr = 1:length(bhv.TrialError)
                clear rgbcolor I
                % check for color in cued stream 1st, assume cue valid
                rgbcolor  = hex2rgb(cuedD.grating_color2(cuedD.trial == tr));
                I = find(rgbcolor ~= 1,1);
                isCueValid(tr) = true;
                if isempty(I);
                    % check for color in UNCUED stream
                    rgbcolor = hex2rgb(uncuedD.grating_color2(uncuedD.trial == tr));
                    I = find(rgbcolor ~= 1,1);
                    if ~isempty(I);
                        isCueValid(tr) = false;
                    end
                end
                if isempty(I);
                    tColors(tr)    = 0;
                else
                    tColors(tr)    = round(1-rgbcolor(I),2);
                end
            end
        end
        
        for tr = 1:length(bhv.TrialError)
            
            ct = ct + 1;
            
            TrialError(ct,1)      = bhv.TrialError(tr);
            ConditionNumber(ct,1) = bhv.ConditionNumber(tr);
            BlockNumber(ct,1)     = bhv.BlockNumber(tr);
            ReactionTime(ct,1)    = bhv.ReactionTime(tr);
            TargetPos(ct,1)       = targetposbycond(bhv.ConditionNumber(tr));
            Saturation(ct,1)      = tColors(tr);
            CueValid(ct,1)        = isCueValid(tr);
            
            if isnan(TargetPos(ct,1))
                TargetMoncular(ct,1) = 0; %no target shown, so don't need to worry about it's occularity
            else
                if isCueValid(tr)
                    idx   = find(cuedS.trial==tr);
                    tilt = cuedS.grating_tilt(idx(TargetPos(ct,1)));
                elseif ~isCueValid(tr)
                    idx = find(uncuedS.trial==tr);
                    tilt = uncuedS.grating_tilt(idx(TargetPos(ct,1)));
                end
                if isnan(tilt)
                    TargetMoncular(ct,1) = 1;
                else
                    TargetMoncular(ct,1) = 0;
                end
            end
            
            % calculate time from stimulus to target
            if any(bhv.CodeNumbers{tr} == 102)
                EM = 25 + 2*targetposbycond(bhv.ConditionNumber(tr));
                clear tmidx
                tmidx = [...
                    find(bhv.CodeNumbers{tr} == EM ,1,'first'),...
                    find(bhv.CodeNumbers{tr} == 102) + 1 ...
                    ];
                tmidx(bhv.CodeNumbers{tr}(tmidx) ~= EM) = [];
                if length(tmidx) > 1
                    TargetTm = diff(bhv.CodeTimes{tr}(tmidx));
                else
                    TargetTm = 0;
                end
            else
                TargetTm = Inf;
            end
            
            
        end
    end
    
    %%% d' %%%
    % hits           = TE 0 on TARGET trls only, saccade to correct matching stim
    % correct reject = TE 0 on CATCH trls only, no sacade
    % false alarm    = TE 6 7, any saccades to wrong targets
    % miss           = TE 8, hold a saccade when they should have made one
    
    uSaturation = [0.15 : 0.05 : 0.9];%unique(Saturation);
    
    c = 0;
    for cue = 1:-1:0
        c =  c + 1;
        
        for s = 1:length(uSaturation)
            sI = (abs(Saturation - uSaturation(s)) < 0.01)...
                & (CueValid == cue);
            if excludeMonocular
                bI = BlockNumber == 1 & TargetMoncular  == 0; % EXCLUD MONOCULAR PRESENTAITONS
                xstr = 'Color Saturation of Binocular Stimuli';
            else
                bI = BlockNumber == 1; % INCLUDE MONOCULAR PRESENTAITONS
                xstr = 'Color Saturation of All Stimuli';
            end
            
            targetTrl = ConditionNumber >  maxcatchcond & TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI & sI;
            catchTrl  = ConditionNumber <= maxcatchcond & TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI;
            alarmTrls = TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI;
            
            saturation(s)    = uSaturation(s);
            
            hits(s)          = sum(TrialError(targetTrl) == 0) / sum(targetTrl);
            miss(s)          = sum(TrialError(targetTrl) == 8) / sum(targetTrl); % should I add error type 2 here
            correctreject(s) = sum(TrialError(catchTrl ) == 0) / sum(catchTrl );
            falsealarm(s)    = sum(TrialError(alarmTrls) == 6 | TrialError(alarmTrls) == 7) / sum(alarmTrls);
            
            % adjust for hit rate == 1 || == 0 and fa rate == 0
            if hits(s)  == 1
                hits(s) = 1 - 1/(2*sum(targetTrl));
            elseif hits(s) == 0
                hits(s) = 1/(2*sum([targetTrl]));
            end
            if falsealarm(s)  == 0
                falsealarm(s) = 1/(2*sum([catchTrl;targetTrl]));
            end
            
            % calculate
            d(s) = norminv(hits(s),0,1)  -  norminv(falsealarm(s),0,1);
            
            % RT, get all measures for given saturation and block (dual cue versus focal)
            I = bI & sI & (TrialError == 0 | TrialError == 2);
            rt(s)            = nanmean(ReactionTime(I));
            rterr(s)         = nanstd(ReactionTime(I)) / sqrt(sum(~isnan(ReactionTime(I))));
            
            % N of choice trials (i.e., no fixational errors)
            n(s)             = sum(bI & sI & TrialError ~=3 & TrialError ~=4 & TrialError ~=5);
            
            % percent of fixational errors
            fixerrors(s)     = sum(TrialError == 3 | TrialError == 4 | TrialError == 5) / length(TrialError);
            
        end
        
        dprime(c).saturation(j,:) = saturation;
        dprime(c).hits(j,:) = hits;
        dprime(c).miss(j,:) = miss;
        dprime(c).correctreject(j,:) = correctreject;
        dprime(c).falsealarm(j,:) = falsealarm;
        dprime(c).d(j,:) = d;
        dprime(c).rt(j,:) = rt;
        dprime(c).rterr(j,:) = rterr;
        dprime(c).n(j,:) = n;
        dprime(c).fixerrors(j,:) = fixerrors;
        
        clear saturation hist miss correctreject falsealarm d rt rterr n fixerrors
        
    end
    
    
end
%% plot
figure
for c = 1:2
    if j > 1
        goodobs = ~isnan(nanmean(dprime(c).d));
    else
        goodobs = ~isnan(dprime(c).d);
    end
    x       = dprime(c).saturation(1,goodobs);
    
    h(1) = subplot(1,2,1);
    if j > 1
        u    = nanmean(dprime(c).d(:,goodobs),1);
        err  = nanstd(dprime(c).d(:,goodobs),[],1) ./ sqrt(sum(~isnan(dprime(c).d(:,goodobs))));
        ph=errorbar(x, u, err,'o'); hold all
    else
        u = dprime(c).d(:,goodobs);
        ph=plot(x, u,'o'); hold all
    end
    axis tight
    xlim([0 1])
    
    if flag_fitdprime
        % add logisitic fit
        g = fittype('c / (1 + exp(-b*(x-a)))',...
            'coefficients',{'a','b','c'}); % a = threshold [-inf inf], b = slope [0 inf], c = max performance [0 max(u)]
        f = fit([0 x]',[0 u]',g,...
            'Lower',[-Inf,0,0],'Upper',[Inf,Inf,max(u)],'StartPoint',[0 0 0]);
        fh = plot(f); hold on;
        set(fh,'color',get(ph,'color'));
    end
    
    % label d-prime plot
    xlabel(xstr)
    ylabel('Perfomance (d-prime)')
    if j > 1
        title(sprintf('E48, n = %u sessions',length(uHeaders)))
    else
        title(sprintf('E48 -- %s',header(1:6)))
    end
    
    
    
    h(2) = subplot(1,2,2);
    if flag_rtbar
        idx = find(dprime(c).saturation(1,:) == max(x));
        if j > 1
            u    = nanmean(dprime(c).rt(:,idx),1);
            err  = nanstd(dprime(c).rt(:,idx),[],1) ./ sqrt(sum(~isnan(dprime(c).d(:,idx))));
        else
            u      = dprime(c).rt(:,idx);
            err    =  dprime(c).rterr(:,idx);
        end
        bar(c,u); hold on;
        errorbar(c, u, err,'r'); hold on
        if c == 2
            set(gca,'XTick',[1 2],'XTickLabel',{'Valid Cue','Invalid Cue'})
            xlabel(sprintf('Saturation = %0.1f',max(x)))
        end
    else
        if j > 1
            u    = nanmean(dprime(c).rt(:,goodobs),1);
            err  = nanstd(dprime(c).rt(:,goodobs),[],1) ./ sqrt(sum(~isnan(dprime(c).d(:,goodobs))));
        else
            u      = dprime(c).rt(:,goodobs);
            err    =  dprime(c).rterr(:,goodobs);
        end
        errorbar(x, u, err,'-o'); hold all
        xlim([0 1])
        xlabel(xstr)
    end
    ylabel('Hit RT (ms)')
    
end

set(h,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial')
if j == 1
    if flag_fitdprime
        legend(h(1),{...
            sprintf('Valid Cue, n = [%s]',num2str(dprime(1).n(:,dprime(1).n>1))),...
            'logisitic fit',...
            sprintf('Invalid Cue, n = [%s]',num2str(dprime(2).n(:,dprime(2).n>1)))...
            'logisitic fit',...
            },'Location','Best');
    else
        legend(h(1),{...
            sprintf('Valid Cue, n = [%s]',num2str(dprime(1).n(:,dprime(1).n>1))),...
            sprintf('Invalid Cue, n = [%s]',num2str(dprime(2).n(:,dprime(2).n>1)))...
            },'Location','Best');
    end
else
    if flag_fitdprime
        legend(h(1),{'Valid Cue','logisitic fit','Invalid Cue','logisitic fit'},'Location','Best');
    else
        legend(h(1),{'Valid Cue','Invalid Cue'},'Location','Best');
    end
end

%% TABLE for PNAS Paper
clear TABLE

for c = 1:2
    
    if c == 1
        goodobs = ~isnan(nanmean(dprime(c).d));
        x    = dprime(c).saturation(1,goodobs);
        TABLE(1,:) = x;
    end
    
    % hit rate, 2-3
    TABLE(1+c,:) = nanmean(dprime(c).hits(:,goodobs),1);
    
    % dprime, 4-5
    TABLE(3+c,:) = nanmean(dprime(c).d(:,goodobs),1);
    
    if c ==2
        x1 = dprime(1).d(:,goodobs);
        x2 = dprime(2).d(:,goodobs);
        for s = 1:length(x)
            [~, p, ~, stats] = ttest(x1(:,s),x2(:,s),'tail','right');
            TABLE(6,s) = stats.tstat;
            TABLE(7,s) = p;
            TABLE(12,s) = stats.df;
        end
        
    end
    
    % rt, 8,9
    TABLE(7+c,:) = nanmean(dprime(c).rt(:,goodobs),1);
  
    if c ==2
        x1 = dprime(1).rt(:,goodobs);
        x2 = dprime(2).rt(:,goodobs);
        for s = 1:length(x)
            [~, p, ~, stats] = ttest(x1(:,s),x2(:,s),'tail','left');
            TABLE(10,s) = stats.tstat;
            TABLE(11,s) = p;
            TABLE(12,s) = stats.df;
        end
        
    end
    
end



TABLE



