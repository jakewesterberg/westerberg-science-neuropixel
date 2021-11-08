%cd /Users/ShellyCox/MATLAB/attn' bhv data'/
cd /Volumes/Drobo2/DATA/NEUROPHYS/rig022
listing1 = dir('*_E');
filelist = {};
for j = 1:length(listing1)
    cd(listing1(j).name)
    listing = dir('*rsvp***.bhv');
    %listing = dir('*.bhv');
    
    files = cellfun(@(x) [pwd filesep x],{listing.name},'UniformOutput',0);
    
    filelist = cat(2,filelist,files);
cd ..
end
filelist = filelist';
%%
ct = 0;
for i = 1:length(filelist)
    bhvfile =  filelist{i};
    
    clear bhv cue cuedD uncuedD targetD rsvp_ln fdir fname rgbcolor tColors isCueValid I
    bhv = concatBHV(bhvfile);
    if isempty(bhv) || isempty(bhv.CodeNumbersUsed)% DEV: throwing away data here that I should recover later
        continue
    end
    [fdir,fname,~] = fileparts(bhvfile);
    datum = datenum(fdir(end-7:end-2),'yymmdd');
    
    [cue, cuedD, cuedS, uncuedD, uncuedS, targetD, ~, rsvp_ln] = loadRSVPdata(fdir,fname,datum);
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
goodFix = TrialError ~=3 & TrialError ~=4 & TrialError ~=5;

% catch t
catchTrls  = ...
    goodFix & ... no fix errors
    ConditionNumber <= maxcatchcond; % an actual catch trial
hits_catch = sum(TrialError(catchTrls) == 0) / sum(catchTrls);

% target hits by cue validity and saturation and time
uSaturation = unique(Saturation); uSaturation(uSaturation == 0) = [];
bins = min(TargetTm(TargetTm~=Inf)):range(TargetTm(TargetTm~=Inf))/10:max(TargetTm(TargetTm~=Inf));
c = 0; clear hits_target n uRT_target eRT_target rtn
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
            eRT_target(c,s,w)    = nanstd(ReactionTime(I)) / sqrt(sum(~isnan(ReactionTime(I))));
            rtn{c,s,w}           = num2str(sum(I));
            
        end
        
    end
end

%%
figure('Units','Inches','Position',[0 0 8.5 11])

subplot(3,2,1)
% target trials hit rate:
plot(uSaturation,hits_target(:,:,end),'.-','LineWidth',2); hold on
text(uSaturation,hits_target(1,:,end),n(1,:,end),'HorizontalAlignment','Right','VerticalAlignment','Bottom'); hold on
text(uSaturation,hits_target(2,:,end),n(2,:,end),'HorizontalAlignment','Left','VerticalAlignment','Top'); hold on
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


subplot(3,2,2)
% target trials RT:
errorbar(uSaturation,uRT_target(1,:,end),eRT_target(1,:,end),'LineWidth',2); hold on;
errorbar(uSaturation,uRT_target(2,:,end),eRT_target(2,:,end),'LineWidth',2); hold on;
text(uSaturation,uRT_target(1,:,end),rtn(1,:,end),'HorizontalAlignment','Right','VerticalAlignment','Top'); hold on
text(uSaturation,uRT_target(2,:,end),rtn(2,:,end),'HorizontalAlignment','Left','VerticalAlignment','Bottom'); hold on


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


