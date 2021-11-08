%addpath(genpath('/Users/ShellyCox/MLAnalysisOnline'));

% for quick daily analysis for post-August 2016 task version
% assumes that the corrent directory contains all stimulus and BHV files

%on mac pro: /Volumes/Drobo2/DATA/NEUROPHYS/rig022/
clear

mldrname = pwd;

listing = dir('*rsvp***.bhv');
filelist = {listing.name};

ct = 0;
for i = 1:length(filelist)
    bhvfile = [mldrname filesep filelist{i}];
    
    clear bhv cue cuedD uncuedD targetD rsvp_ln fdir fname rgbcolor tColors isCueValid I
    bhv = concatBHV(bhvfile);
    [fdir,fname,~] = fileparts(bhvfile);
    
    [cue, cuedD, cuedS, uncuedD, uncuedS, targetD, ~, rsvp_ln] = loadRSVPdata(fdir,fname,listing(i).datenum);
    rgbcolor = hex2rgb(targetD.grating_color2);
    tColors = 1 - rgbcolor(:,2);
    isCueValid = (cue.grating_theta(1:2:end) == targetD.grating_theta);
    targetposbycond = [NaN NaN 1 1 2 2 3 3 4 4];
    maxcatchcond = 2;
    
    if rsvp_ln > 1
        error('this code will not work')
    end
    
    
    for tr = 1:length(bhv.TrialError)
        
        ct = ct + 1;
        
        TrialError(ct,1)      = bhv.TrialError(tr);
        ConditionNumber(ct,1) = bhv.ConditionNumber(tr);
        BlockNumber(ct,1)     = bhv.BlockNumber(tr);
        ReactionTime(ct,1)    = bhv.ReactionTime(tr);
        TargetPos(ct,1)       = targetposbycond(bhv.ConditionNumber(tr)); % in the RSVP sequence, not really used atm
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
            EM = 27; % hard coded to `1st stimulus
            clear tmidx
            tmidx = [...
                find(bhv.CodeNumbers{tr} == EM ,1,'first'),...
                find(bhv.CodeNumbers{tr} == 102) + 1 ...
                ];
            tmidx(bhv.CodeNumbers{tr}(tmidx) ~= EM) = [];
            if length(tmidx) > 1
                TargetTm(ct,1) = diff(bhv.CodeTimes{tr}(tmidx));
            else
                TargetTm(ct,1) = 0; % target turned on w/ stim
            end
        else
            TargetTm(ct,1) = Inf; % target never appeared
        end
        
        % calculate time from stimulus to eyemovement
        eyestevt = bhv.CodeNumbersUsed(strcmp(bhv.CodeNamesUsed,'Start eye1'));
        if any(bhv.CodeNumbers{tr} == eyestevt)
            EM = 27; % hard coded to `1st stimulus
            clear tmidx
            tmidx = [...
                find(bhv.CodeNumbers{tr} == EM ,1,'first'),...
                find(bhv.CodeNumbers{tr} == eyestevt) ...
                ];
            EyeTm(ct,1) = diff(bhv.CodeTimes{tr}(tmidx));
        else
            EyeTm(ct,1) = inf; % no eyemovment
        end
        
    end
end


% only examin trials with good fixation
goodFix = TrialError ~=3 & TrialError ~=4 & TrialError ~=5; % can add target monocular here if needed

% catch trials
catchTrls  = ...
    goodFix & ... no fix errors
    ConditionNumber <= maxcatchcond; % an actual catch trial
hits_catch = sum(TrialError(catchTrls) == 0) / sum(catchTrls);

% target hits by cue validity and saturation and time
uSaturation = unique(Saturation); uSaturation(uSaturation == 0) = [];
bins = min(TargetTm(TargetTm~=Inf)):range(TargetTm(TargetTm~=Inf))/10:max(TargetTm(TargetTm~=Inf));
c = 0; clear hits_target n uRT_target eRT_target
for cue = 1:-1:0
    c =  c + 1;
    
    for w = 1:length(bins)
        for s = 1:length(uSaturation)
            
            clear sI targetTrls
            
            sI = (abs(Saturation - uSaturation(s)) < 0.01)...
                & (CueValid == cue);
            
            targetTrls = ...
                goodFix & ... no fix errors
                ConditionNumber >  maxcatchcond & ... NOT a catch trial (theoretically a target should appear)
                TargetTm ~= Inf & ... target actually appeared
                sI; % target was the saturation and cue validity expected
            
            if w < length(bins)
                targetTrls = targetTrls & ...
                    (TargetTm >= bins(w) & TargetTm <= bins(w+1));
            end
            
            hits_target(c,s,w)   = sum(TrialError(targetTrls) == 0) / sum(targetTrls);
            n{c,s,w}             = num2str(sum(targetTrls));
            
            % RT
            I = targetTrls & (TrialError == 0 | TrialError == 2);
            uRT_target(c,s,w)    = nanmean(ReactionTime(I));
            eRT_target(c,s,w)   = nanstd(ReactionTime(I)) / sqrt(sum(~isnan(ReactionTime(I))));
            
        end
        
    end
end


figure('Units','Inches','Position',[0 0 8.5 11])

subplot(3,2,1)
% target trials hit rate:
plot(uSaturation,hits_target(:,:,end),'.-','LineWidth',2); hold on
text(uSaturation,hits_target(1,:,end),n(1,:,end),'HorizontalAlignment','Center','VerticalAlignment','Bottom'); hold on
text(uSaturation,hits_target(2,:,end),n(2,:,end),'HorizontalAlignment','Center','VerticalAlignment','Top'); hold on
% catch trials hit rate:
plot(0,hits_catch,'kd'); hold on
text(0,hits_catch,num2str(sum(catchTrls)),'HorizontalAlignment','Center','VerticalAlignment','Bottom'); hold on
% estimated FA rate:
alarmTrls = ...
    goodFix & ... no fix errors
    EyeTm < TargetTm; % AND eye moved before target onset -- does NOT matter where it moved
FA = sum(alarmTrls) / sum(goodFix);
plot([0 1], [FA FA],'k:','LineWidth',1.5); hold on
% label:
xlim([-0.05 1])
ylim([0 1.1])
legend('Cue Valid','Cue Invalid','Catch Trials','False Alarm Rate','Location','Best');
set(gca,'box','off','tickdir','out')
ylabel(sprintf('Hit Rate (# = condition trial number)'))
xlabel(sprintf('Saturation\nfixational errors on %u%% of trials',100-round(sum(goodFix) / length(goodFix) * 100)))
title(filelist{1},'interpreter','none')


subplot(3,2,2)
% target trials RT:
errorbar(uSaturation,uRT_target(1,:,end),eRT_target(1,:,end),'LineWidth',2); hold on;
errorbar(uSaturation,uRT_target(2,:,end),eRT_target(2,:,end),'LineWidth',2); hold on;
% label:
xlim([-0.05 1])
legend('Cue Valid','Cue Invalid','Location','Best');
set(gca,'box','off','tickdir','out')
ylabel('Reaction Time (ms)')
xlabel('Saturation')

subplot(3,2,3)
[n1, x1]= hist(TrialError(catchTrls),0:9); axis tight; hold on
[n2, ~] = hist(TrialError(alarmTrls),0:9); axis tight; hold on
[n3, ~] = hist(TrialError(alarmTrls & EyeTm<400),0:9); axis tight; hold on
bar(x1,[n1;n2;n3]','hist')
ylabel('Saccades');
legend('catchTrls','alarmTrls','alarmTrls<0.4s','Location','Best');
set(gca,'box','off','tickdir','out',...
    'xtick',[0:9],'xticklabel',{'None','','','','','','Cued Stim','Uncued Stim','',''},...
    'XTickLabelRotation',45)


subplot(3,2,4)
% false alarms as a function of time
hist(EyeTm(alarmTrls));
ylabel('Number of False Alarms')
xlabel('Time from Stimulus Onset (all stimtypes)')
set(gca,'box','off','tickdir','out')


h(1) = subplot(3,2,5);
imagesc(uSaturation,bins(1:end-1)+mode(diff(bins)),squeeze(hits_target(1,:,1:end-1))');
new_x = min(uSaturation):range(uSaturation)/(length(uSaturation)-1):max(uSaturation);
for b = 1:length(bins)-1
    y = repmat(bins(b)+mode(diff(bins)),size(new_x));
    text(new_x,y,squeeze(n(1,:,b)),'HorizontalAlignment','Center','VerticalAlignment','Middle')
end
c = colorbar; ylabel(c,'Hit Rate')
title('Cue Valid')
ylabel('Target Time')
xlabel('Saturation')
set(gca,'box','off','tickdir','out')


h(2) = subplot(3,2,6);
imagesc(uSaturation,bins(1:end-1)+mode(diff(bins)),squeeze(hits_target(2,:,1:end-1))');
new_x = min(uSaturation):range(uSaturation)/(length(uSaturation)-1):max(uSaturation);
for b = 1:length(bins)-1
    y = repmat(bins(b)+mode(diff(bins)),size(new_x));
    text(new_x,y,squeeze(n(2,:,b)),'HorizontalAlignment','Center','VerticalAlignment','Middle')
end
c = colorbar; ylabel(c,'Hit Rate')
title('Cue Invalid')
ylabel('Target Time')
xlabel('Saturation')
set(gca,'box','off','tickdir','out')


colormap([0.5 0.5 0.5;parula])
set(h,'CLim',[-0.02 1],'Ydir','normal')

%
% %%
% figure; hist(TrialError(catchTrls),0:9)
% title('Catch Trials')
% ylabel('Number of Errors')
% xlabel('Error Type')
% set(gca,'box','off','tickdir','out')
%
% %DEV:
% %    - examin performance by target time AND saturatuion AND validity
% %    - measure of false alarms for as a function of trial time,
% %    - false alarms ALL TRIALS and CATCH TRIALS ONLY
%
% % TE2 = late response to correct side
% % TE7 = saccade to distractor side
% %
%
% % false alarms as a function of time
% alarmTrls = ...
%     TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & ... no fix error
%     EyeTm < TargetTm; % AND eye moved before target onset -- does NOT matter where it moved
% figure; hist(EyeTm(alarmTrls));
% ylabel('number of false alarms')
% xlabel('time from stimulus onset (all stimtypes)')
% set(gca,'box','off','tickdir','out')
%
% figure; hist(TrialError(catchTrls),0:9)
%         title('Catch Trials')
%         ylabel('Number of Errors')
%         xlabel('Error Type')
%         set(gca,'box','off','tickdir','out')
%
%
% %%
% uSaturation = [0.15 : 0.05 : 0.9];%unique(Saturation);
%
% c = 0; clear hits
% for cue = 1:-1:0
%     c =  c + 1;
%
%     for s = 1:length(uSaturation)
%         sI = (abs(Saturation - uSaturation(s)) < 0.01)...
%             & (CueValid == cue);
%
%
%         targetTrls = ConditionNumber >  maxcatchcond & TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI & sI;
%         catchTrls  = ConditionNumber <= maxcatchcond & TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI;
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
% % bin target times:
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
% %%
% %%% d' %%%
% % hits           = TE 0 on TARGET trls only, saccade to correct matching stim
% % correct reject = TE 0 on CATCH trls only, no sacade
% % false alarm    = TE 6 7, any saccades to wrong targets
% % miss           = TE 8, hold a saccade when they should have made one
%
% uSaturation = [0.15 : 0.05 : 0.9];%unique(Saturation);
%
% c = 0;
% for cue = 1:-1:0
%     c =  c + 1;
%
%     for s = 1:length(uSaturation)
%         sI = (abs(Saturation - uSaturation(s)) < 0.01)...
%             & (CueValid == cue);
%         if excludeMonocular
%             bI = BlockNumber == 1 & TargetMoncular  == 0; % EXCLUD MONOCULAR PRESENTAITONS
%             xstr = 'Color Saturation of Binocular Stimuli';
%         else
%             bI = BlockNumber == 1; % INCLUDE MONOCULAR PRESENTAITONS
%             xstr = 'Color Saturation of All Stimuli';
%         end
%
%         targetTrls = ConditionNumber >  maxcatchcond & TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI & sI;
%         catchTrls  = ConditionNumber <= maxcatchcond & TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI;
%         alarmTrls = TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI;
%
%         saturation(s)    = uSaturation(s);
%
%         hits_target(s)          = sum(TrialError(targetTrls) == 0) / sum(targetTrls);
%         miss(s)          = sum(TrialError(targetTrls) == 8) / sum(targetTrls); % should I add error type 2 here
%         correctreject(s) = sum(TrialError(catchTrls ) == 0) / sum(catchTrls );
%         falsealarm(s)    = sum(TrialError(alarmTrls) == 6 | TrialError(alarmTrls) == 7) / sum(alarmTrls);
%
%         % adjust for hit rate == 1 || == 0 and fa rate == 0
%         if hits_target(s)  == 1
%             hits_target(s) = 1 - 1/(2*sum(targetTrls));
%         elseif hits_target(s) == 0
%             hits_target(s) = 1/(2*sum([targetTrls]));
%         end
%         if falsealarm(s)  == 0
%             falsealarm(s) = 1/(2*sum([catchTrls;targetTrls]));
%         end
%
%         % calculate
%         d(s) = norminv(hits_target(s),0,1)  -  norminv(falsealarm(s),0,1);
%
%         % RT, get all measures for given saturation and block (dual cue versus focal)
%         I = bI & sI & (TrialError == 0 | TrialError == 2);
%         rt(s)            = nanmean(ReactionTime(I));
%         rterr(s)         = nanstd(ReactionTime(I)) / sqrt(sum(~isnan(ReactionTime(I))));
%
%         % N of choice trials (i.e., no fixational errors)
%         n(s)             = sum(bI & sI & TrialError ~=3 & TrialError ~=4 & TrialError ~=5);
%
%         % percent of fixational errors
%         fixerrors(s)     = sum(TrialError == 3 | TrialError == 4 | TrialError == 5) / length(TrialError);
%
%     end
%
%     dprime(c).saturation(j,:) = saturation;
%     dprime(c).hits(j,:) = hits_target;
%     dprime(c).miss(j,:) = miss;
%     dprime(c).correctreject(j,:) = correctreject;
%     dprime(c).falsealarm(j,:) = falsealarm;
%     dprime(c).d(j,:) = d;
%     dprime(c).rt(j,:) = rt;
%     dprime(c).rterr(j,:) = rterr;
%     dprime(c).n(j,:) = n;
%     dprime(c).fixerrors(j,:) = fixerrors;
%
%     clear saturation hist miss correctreject falsealarm d rt rterr n fixerrors
%
% end
%
% %% plot
% figure
% for c = 1:2
%     if j > 1
%         goodobs = ~isnan(nanmean(dprime(c).d));
%     else
%         goodobs = ~isnan(dprime(c).d);
%     end
%     x       = dprime(c).saturation(1,goodobs);
%
%     h(1) = subplot(1,2,1);
%     if j > 1
%         u    = nanmean(dprime(c).d(:,goodobs),1);
%         err  = nanstd(dprime(c).d(:,goodobs),[],1) ./ sqrt(sum(~isnan(dprime(c).d(:,goodobs))));
%         ph=errorbar(x, u, err,'o'); hold all
%     else
%         u = dprime(c).d(:,goodobs);
%         ph=plot(x, u,'o'); hold all
%     end
%     axis tight
%     xlim([0 1])
%
%     if flag_fitdprime
%         % add logisitic fit
%         g = fittype('c / (1 + exp(-b*(x-a)))',...
%             'coefficients',{'a','b','c'}); % a = threshold [-inf inf], b = slope [0 inf], c = max performance [0 max(u)]
%         f = fit([0 x]',[0 u]',g,...
%             'Lower',[-Inf,0,0],'Upper',[Inf,Inf,max(u)],'StartPoint',[0 0 0]);
%         fh = plot(f); hold on;
%         set(fh,'color',get(ph,'color'));
%     end
%
%     % label d-prime plot
%     xlabel(xstr)
%     ylabel('Perfomance (d-prime)')
% %     if j > 1
% %         title(sprintf('E48, n = %u sessions',length(uHeaders)))
% %     else
% %         title(sprintf('E48 -- %s',header(1:6)))
% %     end
%
%
%
%     h(2) = subplot(1,2,2);
%     if flag_rtbar
%         idx = find(dprime(c).saturation(1,:) == max(x));
%         if j > 1
%             u    = nanmean(dprime(c).rt(:,idx),1);
%             err  = nanstd(dprime(c).rt(:,idx),[],1) ./ sqrt(sum(~isnan(dprime(c).d(:,idx))));
%         else
%             u      = dprime(c).rt(:,idx);
%             err    =  dprime(c).rterr(:,idx);
%         end
%         bar(c,u); hold on;
%         errorbar(c, u, err,'r'); hold on
%         if c == 2
%             set(gca,'XTick',[1 2],'XTickLabel',{'Valid Cue','Invalid Cue'})
%             xlabel(sprintf('Saturation = %0.1f',max(x)))
%         end
%     else
%         if j > 1
%             u    = nanmean(dprime(c).rt(:,goodobs),1);
%             err  = nanstd(dprime(c).rt(:,goodobs),[],1) ./ sqrt(sum(~isnan(dprime(c).d(:,goodobs))));
%         else
%             u      = dprime(c).rt(:,goodobs);
%             err    =  dprime(c).rterr(:,goodobs);
%         end
%         errorbar(x, u, err,'-o'); hold all
%         xlim([0 1])
%         xlabel(xstr)
%     end
%     ylabel('Hit RT (ms)')
%
% end
%
% set(h,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial')
% if j == 1
%     if flag_fitdprime
%         legend(h(1),{...
%             sprintf('Valid Cue, n = [%s]',num2str(dprime(1).n(:,dprime(1).n>1))),...
%             'logisitic fit',...
%             sprintf('Invalid Cue, n = [%s]',num2str(dprime(2).n(:,dprime(2).n>1)))...
%             'logisitic fit',...
%             },'Location','Best');
%     else
%         legend(h(1),{...
%             sprintf('Valid Cue, n = [%s]',num2str(dprime(1).n(:,dprime(1).n>1))),...
%             sprintf('Invalid Cue, n = [%s]',num2str(dprime(2).n(:,dprime(2).n>1)))...
%             },'Location','Best');
%     end
% else
%     if flag_fitdprime
%         legend(h(1),{'Valid Cue','logisitic fit','Invalid Cue','logisitic fit'},'Location','Best');
%     else
%         legend(h(1),{'Valid Cue','Invalid Cue'},'Location','Best');
%     end
% end
%
%

%%
%DEV:
%    - examin performance by target time AND saturatuion AND validity
%    - measure of false alarms for ALL TRIALS and CATCH TRIALS ONLY


