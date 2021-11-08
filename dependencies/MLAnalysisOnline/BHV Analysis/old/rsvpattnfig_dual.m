% Feb/March 2016

clear

filelist = {...
    %    '/Users/ShellyCox/Dropbox (MLVU)/160309_E/Experiment-E48-03-09-2016(08).bhv',...
    %    '/Users/ShellyCox/Dropbox (MLVU)/160314_E/Experiment-E48-03-14-2016.bhv',...
    %    '/Users/ShellyCox/Dropbox (MLVU)/160314_E/Experiment-E48-03-14-2016(01).bhv',...
    %    '/Users/ShellyCox/Dropbox (MLVU)/160314_E/Experiment-E48-03-14-2016(02).bhv',...
    %    '/Users/ShellyCox/Dropbox (MLVU)/160314_E/Experiment-E48-03-14-2016(03).bhv',...
    %    '/Users/ShellyCox/Dropbox (MLVU)/160315_E/Experiment-E48-03-15-2016.bhv'...
    %    '/Users/ShellyCox/Dropbox (MLVU)/160315_E/Experiment-E48-03-15-2016(02).bhv'...
    %    '/Users/ShellyCox/Dropbox (MLVU)/160316_E/Experiment-E48-03-16-2016(03).bhv'... rsvpln = 4
    %    '/Users/ShellyCox/Dropbox (MLVU)/160317_E/Experiment-E48-03-17-2016(01).bhv'... rsvpln = 3
   %     '/Users/ShellyCox/Dropbox (MLVU)/160318_E/Experiment-E48-03-18-2016.bhv'... rsvpln = 4
   %      '/Users/ShellyCox/Dropbox (MLVU)/160318_E/Experiment-E48-03-18-2016.bhv'... rsvpln = 4
   % '/Users/ShellyCox/Dropbox (MLVU)/160318_E/Experiment-E48-03-18-2016(01).bhv'... rsvpln = 4
   % '/Users/ShellyCox/Dropbox (MLVU)/160318_E/Experiment-E48-03-18-2016(02).bhv'... rsvpln = 4
   % '/Users/ShellyCox/Dropbox (MLVU)/160318_E/Experiment-E48-03-18-2016(03).bhv'... rsvpln = 4
   %  '/Users/ShellyCox/Dropbox (MLVU)/160318_E/Experiment-E48-03-18-2016(04).bhv'... rsvpln = 4
    % '/Users/ShellyCox/Dropbox (MLVU)/160319_E/Experiment-E48-03-19-2016.bhv'... rsvpln = 4
    %'/Users/ShellyCox/Dropbox (MLVU)/160321_E/Experiment-E48-03-21-2016.bhv'... rsvpln = 4
    % '/Users/ShellyCox/Dropbox (MLVU)/160321_E/Experiment-E48-03-21-2016(01).bhv'... rsvpln = 4
   %  '/Users/ShellyCox/Dropbox (MLVU)/160322_E/Experiment-E48-03-22-2016.bhv'... rsvpln = 4
%    '/Users/ShellyCox/Dropbox (MLVU)/160323_E/Experiment-E48-03-23-2016.bhv'... rsvpln = 4
 %      '/Users/ShellyCox/Dropbox (MLVU)/160323_E/Experiment-E48-03-23-2016(01).bhv'... rsvpln = 4
 %     '/Users/ShellyCox/Dropbox (MLVU)/160324_E/Experiment-E48-03-24-2016.bhv'... rsvpln = 4, NEW TASK with target SOA
 %      '/Users/ShellyCox/Dropbox (MLVU)/160324_E/Experiment-E48-03-24-2016(01).bhv'... rsvpln = 4, NEW TASK with target SOA
   %    '/Users/ShellyCox/Dropbox (MLVU)/160324_E/Experiment-E48-03-24-2016(02).bhv'...
      %    '/Users/ShellyCox/Dropbox (MLVU)/160325_E/Experiment-E48-03-25-2016.bhv'... rsvpln = 2, NEW TASK with target SOA
    %      '/Users/ShellyCox/Dropbox (MLVU)/160325_E/Experiment-E48-03-25-2016(01).bhv'... rsvpln = 3, NEW TASK with target SOA
     %     '/Users/ShellyCox/Dropbox (MLVU)/160325_E/Experiment-E48-03-25-2016(02).bhv'...rsvpln = 4, NEW TASK with target SOA
      %    '/Users/ShellyCox/Dropbox (MLVU)/160327_E/Experiment-E48-03-27-2016.bhv'... rsvpln = 2,  NEW TASK with target SOA, rand small red target
       %   '/Users/ShellyCox/Dropbox (MLVU)/160327_E/Experiment-E48-03-27-2016(01).bhv'...rsvpln = 3, NEW TASK with target SOA,rand small red target
 %'/Users/ShellyCox/Dropbox (MLVU)/160327_E/Experiment-E48-03-27-2016(02).bhv'...rsvpln = 4, NEW TASK with target SOA, rand small red target
 %'/Users/ShellyCox/Dropbox (MLVU)/160328_E/Experiment-E48-03-28-2016.bhv'...rsvpln = 4, NEW TASK with target SOA, rand small red target
%'/Users/ShellyCox/Dropbox (MLVU)/160328_E/Experiment-E48-03-28-2016(01).bhv'...rsvpln = 4, NEW TASK with target SOA, rand small red target
%'/Users/ShellyCox/Dropbox (MLVU)/160328_E/Experiment-E48-03-28-2016(02).bhv'...rsvpln = 4, NEW TASK with target SOA, rand small red target
%'/Users/ShellyCox/Dropbox (MLVU)/160328_E/Experiment-E48-03-28-2016(03).bhv'...rsvpln = 4, NEW TASK with target SOA, rand small red target
 %'/Users/ShellyCox/Dropbox (MLVU)/160329_E/Experiment-E48-03-29-2016.bhv'...rsvpln = 3, NEW TASK with target SOA, rand small red target
 %'/Users/ShellyCox/Dropbox (MLVU)/160329_E/Experiment-E48-03-29-2016(01).bhv'...rsvpln = 3, NEW TASK with target SOA, rand small red target, edge smoothed! 
 %'/Users/ShellyCox/Dropbox (MLVU)/160330_E/Experiment-E48-03-30-2016.bhv'...rsvpln = 1, NEW TASK with target SOA, rand small red target
% '/Users/ShellyCox/Dropbox (MLVU)/160330_E/Experiment-E48-03-30-2016(01).bhv'...rsvpln = 1, NEW TASK with target SOA, rand small red target
% '/Users/ShellyCox/Dropbox (MLVU)/160331_E/Experiment-E48-03-31-2016.bhv'...rsvpln = 1, NEW TASK with target SOA, rand small red target
% '/Users/ShellyCox/Dropbox (MLVU)/160331_E/Experiment-E48-03-31-2016(01).bhv'...rsvpln = 1, NEW TASK with target SOA, rand small red target
% '/Users/ShellyCox/Dropbox (MLVU)/160331_E/Experiment-E48-03-31-2016(02).bhv'...rsvpln = 1, NEW TASK with target SOA, rand small red target
% '/Users/ShellyCox/Dropbox (MLVU)/160401_E/Experiment-E48-04-01-2016.bhv'...rsvpln = 1, NEW TASK with target SOA, rand small red target
% '/Users/ShellyCox/Dropbox (MLVU)/160401_E/Experiment-E48-04-01-2016(01).bhv'...rsvpln = 1, NEW TASK with target SOA, rand small red target
% '/Users/ShellyCox/Dropbox (MLVU)/160402_E/Experiment-E48-04-02-2016.bhv'...rsvpln = 1, NEW TASK with target SOA, rand small red target
'Y:\160418_E\160418_E_rsvp001.bhv'... recording day
'Y:\160418_E\160418_E_rsvp002.bhv'...
'Y:\160418_E\160418_E_rsvp003.bhv'...
};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
session =  cellfun(@fileparts, filelist,'UniformOutput',0);
session =  cellfun(@(x) x(end-7:end), session,'UniformOutput',0);
session =  unique(session);

n = cellfun(@(x) datenum(x(1:6),'yymmdd'),session);
if any(n < datenum('18-Mar-2016','dd-mmm-yyyy'))
    targetposbycond = [NaN NaN NaN NaN 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4];
    maxcatchcond = 4;
else
    targetposbycond = [NaN NaN 1 1 2 2 3 3 4 4];
    maxcatchcond = 2;
end

mFactor = 1; %not using this at the moment, but looks like it should be ~0.3 based on behavior. 

if length(session) > 1
    session = 'Across Session';
else
    session = session{1};
end



ct = 0; clear TrialError ConditionNumber BlockNumber ReactionTime TargetPos *Saturation TargetTm CueValid MonocularCorrection isMoncular
for i = 1:length(filelist)
    
    clear bhv cue cuedD uncuedD targetD rsvp_ln fdir fname rgbcolor tColors isCueValid I
    bhv = concatBHV(filelist{i});
    [fdir,fname,~] = fileparts(filelist{i});
    if any(strcmp(bhv.TaskObject(1,:),'gen(gTarg_di)'))
        [cue, cuedD, cuedS, uncuedD, uncuedS, targetD, ~, rsvp_ln] = loadRSVPdata(fdir,fname);
        rgbcolor = hex2rgb(targetD.grating_color2);
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
        
        if isCueValid(tr)
            ValidSaturation(ct,1)   = tColors(tr);
            inValidSaturation(ct,1) = 0;
            CueValid(ct,1)        = true;
            idx = find(cuedS.trial==tr);
            
            if isnan(TargetPos(ct,1))
                MonocularCorrection(ct,1) = NaN;
                isMoncular(ct,1) = NaN;
            else
                if isnan(cuedS.grating_tilt(idx(TargetPos(ct,1))))
                    MonocularCorrection(ct,1) = mFactor;
                    isMoncular(ct,1) = 1;
                else
                    MonocularCorrection(ct,1) = 1;
                    isMoncular(ct,1) = 0;
                end
            end
            
        else
            ValidSaturation(ct,1)   = 0;
            inValidSaturation(ct,1) = tColors(tr);
            CueValid(ct,1)        = false;
            idx = find(uncuedS.trial==tr);
            if isnan(TargetPos(ct,1))
                MonocularCorrection(ct,1) = NaN;
                isMoncular(ct,1) = NaN;
            else
                if isnan(uncuedS.grating_tilt(idx(TargetPos(ct,1))))
                    MonocularCorrection(ct,1) = mFactor;
                    isMoncular(ct,1) = 1;
                else
                    MonocularCorrection(ct,1) = 1;
                    isMoncular(ct,1) = 0;
                end
            end
            
        end
        
        CodeNumbers = bhv.CodeNumbers{tr};
        CodeTimes   = bhv.CodeTimes{tr};
        if any(CodeNumbers == 102)
            EM = 25 + 2*targetposbycond(bhv.ConditionNumber(tr));
            clear tmidx
            tmidx = [...
                find(CodeNumbers == EM ,1,'first'),...
                find(CodeNumbers == 102) + 1 ...
                ];
            tmidx(CodeNumbers(tmidx) ~= EM) = [];
            if length(tmidx) > 1
                TargetTm(ct,1) = diff(CodeTimes(tmidx));
            else
                TargetTm(ct,1) = 0;
            end
        else
            TargetTm(ct,1) = NaN;
        end
      
    end
end

%%

figure

%%% d' %%%
% hits           = TE 0 on TARGET trls only, saccade to correct matching stim
% correct reject = TE 0 on CATCH trls only, no sacade
% false alarm    = TE 6 7, any saccades to wrong targets
% miss           = TE 8, hold a saccade when they should have made one

clear dprime
uSaturation = nanunique([ValidSaturation; inValidSaturation]);
uSaturation(uSaturation == 0) = [];

flag_ShowMonocular = false; 

for c = 1:3
    if c == 2
        block = 4;
    else
        block = 1;
    end
    for s = 1:length(uSaturation)
        
        if c < 3
            sI = (ValidSaturation) == uSaturation(s);
        else
            sI = (inValidSaturation)  == uSaturation(s);
        end
        if flag_ShowMonocular
            bI = BlockNumber == block & isMoncular  == 1; % INCLUDE MONOCULAR PRESENTAITONS
            xstr = 'Color Saturation of Monocular Stimuli';
        else
            bI = BlockNumber == block & isMoncular  == 0; % EXCLUDE MONOCULAR PRESENTAITONS
            xstr = 'Color Saturation of Binocular Stimuli';
        end
        
        targetTrl = ConditionNumber >  maxcatchcond & TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI & sI;
        catchTrl  = ConditionNumber <= maxcatchcond & TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI;
        alarmTrls = TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI;
        
        dprime(c).saturation(s)    = uSaturation(s);
        
        dprime(c).hits(s)          = sum(TrialError(targetTrl) == 0) / sum(targetTrl);
        dprime(c).miss(s)          = sum(TrialError(targetTrl) == 8) / sum(targetTrl); % should I add error type 2 here
        dprime(c).correctreject(s) = sum(TrialError(catchTrl ) == 0) / sum(catchTrl );
        dprime(c).falsealarm(s)    = sum(TrialError(alarmTrls) == 6 | TrialError(alarmTrls) == 7) / sum(alarmTrls);
        
        % adjust for hit rate == 1 || == 0 and fa rate == 0
        if dprime(c).hits(s)  == 1
            dprime(c).hits(s) = 1 - 1/(2*sum(targetTrl));
        elseif dprime(c).hits(s) == 0
            dprime(c).hits(s) = 1/(2*sum([targetTrl]));
        end
        if dprime(c).falsealarm(s)  == 0
            dprime(c).falsealarm(s) = 1/(2*sum([catchTrl;targetTrl]));
        end
        
        % calculate
        dprime(c).d(s) = norminv(dprime(c).hits(s),0,1)  -  norminv(dprime(c).falsealarm(s),0,1);
        
        % RT, get all measures for given saturation and block (dual cue versus focal)
        I = bI & sI & (TrialError == 0 | TrialError == 2);
        dprime(c).rt(s)            = nanmean(ReactionTime(I));
        dprime(c).rterr(s)         = nanstd(ReactionTime(I)) / sqrt(sum(~isnan(ReactionTime(I))));
        
        % N of choice trials (i.e., no fixational errors)
        dprime(c).n(s)             = sum(bI & sI & TrialError ~=3 & TrialError ~=4 & TrialError ~=5);
        
        
    end
    h(1) = subplot(2,2,1);
    plot(dprime(c).saturation,dprime(c).d,'-o'); hold on
    xlabel(xstr)
    ylabel('Perfomance (d-prime)')
    title(session,'interpreter','none')
    
    h(2) = subplot(2,2,2);
    errorbar(dprime(c).saturation,dprime(c).rt,dprime(c).rterr,'-o'); hold on
    xlabel(xstr)
    ylabel('Hit RT (ms)')
    title(session,'interpreter','none')
    
end
set(h,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial',...
    'Xlim',[0 1])
legend(h(1),{...
    sprintf('Focal Cue, n = %u',sum(dprime(1).n)),...
    sprintf('Dual Cue, n = %u',sum(dprime(2).n)),...
    sprintf('Invalid Cue, n = %u',sum(dprime(3).n))...
    },'Location','Best');

%% error distribution by trail type

clear resp I sI bI n
TE = [0 6 7 8 2];
TE_str = {'Correct','Err: Non-Target','Err: Uncued','Err: No Saccade','Err: Late Saccade'};
for j = 1:3
    if j == 1
        I = ConditionNumber  > maxcatchcond ... % target trials
            & BlockNumber == 1 ...    % focal cue
            & CueValid == 1; % valid trial
    elseif j == 2
        I = ConditionNumber <= maxcatchcond ... % catch trials
            & BlockNumber == 1;    % focal cue
    elseif j == 3
        I = ConditionNumber  > maxcatchcond ... % target trials
            & BlockNumber == 1 ...    % focal cue
            & CueValid == 0; % INvalid trial
    end
    if ~any(I)
        n(j) = 0;
        resp(:,j) = [...
            NaN...
            NaN...
            NaN...
            NaN...
            NaN];
    else
        n(j) = sum(TrialError(I) ~=3 & TrialError(I) ~=4 & TrialError(I) ~=5);
        
        resp(:,j) = [...
            sum(TrialError(I) == TE(1))...
            sum(TrialError(I) == TE(2))...
            sum(TrialError(I) == TE(3))...
            sum(TrialError(I) == TE(4))...
            sum(TrialError(I) == TE(5))] ./ n(j) * 100;
    end
    
end

subplot(2,2,[3 4])
bar([1:length(TE)],resp); hold all;
plot(xlim,[100 100] ./ (rsvp_ln*2+1),'k:');
title(sprintf('%s Performance',session),'interpreter','none')
ylabel(sprintf('Percent Response\nExcluding Fixational Errors'))
set(gca,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial',...
    'Xtick',[1:length(TE)],'XtickLabel',TE_str)

legend({...
    sprintf('Target Trials, Focal Cue, n = %u', n(1)),...
    sprintf('Catch Trials, Focal Cue, n = %u', n(2)),...
    sprintf('Target Trials, Invalid Cue, n = %u', n(3)),...
    'Chance Level'},...
    'Location','Best')


%% Perfromnce by Target appearence time
% figure 
% clear dprime2
% allTargetPos = (TargetPos*1000 + TargetTm);
% uTargetPos = nanunique(allTargetPos);
% 
% for c = 1:3
%     if c == 2
%         block = 4;
%     else
%         block = 1;
%     end
%     for s = 1:length(uTargetPos)
%         if c < 3
%             sI = allTargetPos == uTargetPos(s) & CueValid;
%         else
%             sI = allTargetPos == uTargetPos(s) & ~CueValid;
%         end
%         bI = BlockNumber == block;
%         
%         targetTrl = ConditionNumber >  maxcatchcond & TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI & sI;
%         catchTrl  = ConditionNumber <= maxcatchcond & TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI;
%         alarmTrls = TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & bI;
%         
%         dprime2(c).saturation(s)    = uTargetPos(s);
%         
%         dprime2(c).hits(s)          = sum(TrialError(targetTrl) == 0) / sum(targetTrl);
%         dprime2(c).miss(s)          = sum(TrialError(targetTrl) == 8) / sum(targetTrl);
%         dprime2(c).correctreject(s) = sum(TrialError(catchTrl ) == 0) / sum(catchTrl );
%         dprime2(c).falsealarm(s)    = sum(TrialError(alarmTrls) == 6 | TrialError(alarmTrls) == 7) / sum(alarmTrls);
%         
%         % adjust for hit rate == 1 || == 0 and fa rate == 0
%         if dprime2(c).hits(s)  == 1
%             dprime2(c).hits(s) = 1 - 1/(2*sum(targetTrl));
%         elseif dprime2(c).hits(s) == 0
%             dprime2(c).hits(s) = 1/(2*sum([targetTrl]));
%         end
%         if dprime2(c).falsealarm(s)  == 0
%             dprime2(c).falsealarm(s) = 1/(2*sum([catchTrl;targetTrl]));
%         end
%         
%         % calculate
%         dprime2(c).d(s) = norminv(dprime2(c).hits(s),0,1)  -  norminv(dprime2(c).falsealarm(s),0,1);
%         
%         % RT, get all measures for given saturation and block (dual cue versus focal)
%         I = bI & sI & (TrialError == 0 | TrialError == 2);
%         dprime2(c).rt(s)            = nanmean(ReactionTime(I));
%         dprime2(c).rterr(s)         = nanstd(ReactionTime(I)) / sqrt(sum(~isnan(ReactionTime(I))));
%         
%         % N of choice trials (i.e., no fixational errors)
%         dprime2(c).n(s)             = sum(bI & sI & TrialError ~=3 & TrialError ~=4 & TrialError ~=5);
%         
%         
%     end
%     h(1) = subplot(2,2,1);
%     plot(dprime2(c).saturation,dprime2(c).d,'-o'); hold on
%     xlabel('Target Tm')
%     ylabel('Perfomance (d-prime)')
%     title(session,'interpreter','none')
%     
%     h(2) = subplot(2,2,2);
%     errorbar(dprime2(c).saturation,dprime2(c).rt,dprime2(c).rterr,'-o'); hold on
%     xlabel('Target Tm')
%     ylabel('Hit RT (ms)')
%     title(session,'interpreter','none')
%     
% end
% set(h,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial')
% legend(h(1),{...
%     sprintf('Focal Cue, n = %u',sum(dprime(1).n)),...
%     sprintf('Dual Cue, n = %u',sum(dprime(2).n)),...
%     sprintf('Invalid Cue, n = %u',sum(dprime(3).n))...
%     },'Location','Best');

%%
% figure
% clear h
%
%  for c = 1:length(dprime)
% h(1) = subplot(2,2,[1 3]);
%
%     plot(dprime(c).saturation,dprime(c).d,'-o'); hold on
%     xlabel('Color Saturation')
%     ylabel('Perfomance (d-prime)')
%     title(session,'interpreter','none')
%     xlim([0 1])
%  end
%
%  h(2) = subplot(2,2,4);
%     bar([1 2],[mean([dprime(1).rt]) mean([dprime(2).rt])])
%     set(gca, 'Xtick',[1 2],'XtickLabel',{'Focal Cue', 'Dual Cue'})
%     ylabel('Reaction Time (ms)')
%     ylim([300 380])
%
% set(h,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial')
%      legend(h(1),{sprintf('Focal Cue, n = %u',sum(BlockNumber==1)),sprintf('Dual Cue, n = %u',sum(BlockNumber==4))},'Location','SouthEast');

