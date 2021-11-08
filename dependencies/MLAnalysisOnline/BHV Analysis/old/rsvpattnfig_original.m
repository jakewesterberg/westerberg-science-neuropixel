% Feb/March 2016

clear
flag_checkforerr7color = 1;

% filelist = {...
%     '/Users/ShellyCox/Dropbox (MLVU)/160301_E/Experiment-E48-03-01-2016(06).bhv',...
%     '/Users/ShellyCox/Dropbox (MLVU)/160301_E/Experiment-E48-03-01-2016(07).bhv',...
%     '/Users/ShellyCox/Dropbox (MLVU)/160301_E/Experiment-E48-03-01-2016(08).bhv',...
%     };

% filelist = {...
%     '/Users/ShellyCox/Dropbox (MLVU)/160303_E/Experiment-E48-03-03-2016(05).bhv',...
%     };

% filelist = {...
%     '/Users/ShellyCox/Dropbox (MLVU)/160304_E/Experiment-E48-03-04-2016.bhv',...
%     '/Users/ShellyCox/Dropbox (MLVU)/160304_E/Experiment-E48-03-04-2016(01).bhv',...
%     };
% 
filelist = {...
    '/Users/ShellyCox/Dropbox (MLVU)/160305_E/Experiment-E48-03-05-2016.bhv',... 
    '/Users/ShellyCox/Dropbox (MLVU)/160305_E/Experiment-E48-03-05-2016(02).bhv',...
    };
% filelist = {...
%     '/Users/ShellyCox/Dropbox (MLVU)/160305_E/Experiment-E48-03-05-2016(01).bhv'}; ln = 2



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
session =  cellfun(@fileparts, filelist,'UniformOutput',0);
session =  cellfun(@(x) x(end-7:end), session,'UniformOutput',0);
session =  unique(session);
if length(session) > 1
    session = 'Across Session';
else
    session = session{1};
end

% Overall Percent Correct / Errors %%%
BHV = concatBHV(filelist);

[~, ConditionsFile, ~] = fileparts(BHV.ConditionsFile{1});
rsvp_ln = str2double(ConditionsFile(end));  

clear resp I n
TE = [0 6 7 8];
TE_str = {'Correct','Err: Non-Target','Err: Uncued','Err: No Saccade'};
for j = 1:2
    if j == 1
        I = BHV.ConditionNumber > 4; % target trials
    elseif j == 2
        I = BHV.ConditionNumber <= 4; % catch trails
    end
    if ~any(I)
        continue
    end
    n(j) = sum(BHV.TrialError(I) ~=3 & BHV.TrialError(I) ~=4 & BHV.TrialError(I) ~=5);
    
    resp(:,j) = [...
        sum(BHV.TrialError(I) == TE(1))...
        sum(BHV.TrialError(I) == TE(2))...
        sum(BHV.TrialError(I) == TE(3))...
        sum(BHV.TrialError(I) == TE(4))] ./ n(j) * 100;
    
end

if flag_checkforerr7color
    ct = 0; clear ERR COLOR CATCH
    for i = 1:length(filelist)
        clear bhv cuedD uncuedD rsvp_ln
        
        bhv = concatBHV(filelist{i});
        [fdir,fname,~] = fileparts(filelist{i});
        [~, cuedD, ~, uncuedD, ~, rsvp_ln] = loadRSVPdata(fdir,fname);
        
        if rsvp_ln > 1
            error('this section only works for rsvp_ln = 1')
        end
        
        for tr = 1:length(bhv.TrialError)
            
            TrialError = bhv.TrialError(tr);
            if TrialError == 7
                ct = ct + 1;
                ERR(ct,1) = TrialError;
                rgbcolor = hex2rgb(uncuedD.grating_color2(uncuedD.trial == tr));
                if isequal(rgbcolor,[1 1 1])
                    COLOR(ct,1) = 0;
                else
                    COLOR(ct,1) = 1;
                end
                if bhv.ConditionNumber(tr) <= 4
                    CATCH(ct,1) = 1;
                else
                    CATCH(ct,1) = 0;
                end
                
            end
        end
    end
    err7resp = [...
        sum(~COLOR(~CATCH == 1)) ./ n(1) * 100, sum(COLOR(~CATCH == 1)) ./ n(1) * 100;...
        sum(~COLOR( CATCH == 1)) ./ n(2) * 100, sum(COLOR( CATCH == 1)) ./ n(2) * 100;...
        ];
    
    TE_str{TE==7} = '';
end


figure('Units','Inches','Position',[0 0 10 7.5])
colormap(fliplr(jet))

subplot(4,4,[1:8])
bar([1 2 3 4],resp); hold all;
plot(xlim,[100 100] ./ (rsvp_ln*2+1),'k:');
legend({sprintf('Target Trials, n = %u', n(1)), sprintf('Catch Trials, n = %u', n(2)),'Chance Level'})
title(sprintf('%s Performance',session),'interpreter','none')
ylabel(sprintf('Percent Response\nExcluding Fixational Errors'))
set(gca,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial',...
    'Xtick',[1 2 3 4],'XtickLabel',TE_str)
ylimits = ylim;
if flag_checkforerr7color
    subplot(4,4,[11 15])
    bar([1 3],err7resp,'stacked'); hold on
    plot(xlim,[100 100] ./ (rsvp_ln*2+1),'k:');
    legend({'B/W Stim', 'Color Stim'},'Location','NorthWest')
    title('Err: Uncued')
    xlabel('Trial Type')
    set(gca,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial',...
        'Xtick',[1 3],'XtickLabel',{'Target','Catch'},'Ylim',ylimits,'YAxisLocation','left')
    ylabel(sprintf('Percent Response'))
end

%%
[fdir,fname,~] = fileparts(filelist{1});
if strcmp(fname(1:10),'Experiment')
    n = datenum(fname(16:25),'mm-dd-yyyy');
else
    n = datenum(fname(1:6),'yymmdd');
end

if n < datenum('03/03/2016','mm/dd/yyyy');

ct = 0; clear RT ERR CODE
for tr = 1:length(BHV.TrialError)
    
    TrialError = BHV.TrialError(tr);
    if TrialError == 3 || TrialError == 4 || TrialError == 5
        continue
    elseif BHV.ConditionNumber(tr) <= 4 && TrialError == 0
        continue
    end
    
    ct = ct + 1;
    
    if TrialError == 0
        ERR(ct,1) = 0;
    else
        ERR(ct,1) = 1;
    end
    
    CodeTimes = BHV.CodeTimes{tr};
    CodeNumbers = BHV.CodeNumbers{tr};
    
    % get eye signal from "fixation occures" to end
    clear eyesignal eyeidx
    if any(CodeNumbers == 96)
        eyesignal = BHV.AnalogData{tr}.EyeSignal(CodeTimes(CodeNumbers == 27):CodeTimes(CodeNumbers == 96), 1);
    elseif any(CodeNumbers == 97)
        eyesignal = BHV.AnalogData{tr}.EyeSignal(CodeTimes(CodeNumbers == 27):CodeTimes(CodeNumbers == 97), 1);
    else
        eyesignal = BHV.AnalogData{tr}.EyeSignal(CodeTimes(CodeNumbers == 27):end, 1);
    end
    
    eyevelocity = diff(eyesignal);
    I = abs(eyevelocity) > 2;
    
    if ~any(I)
        RT(ct,1) = NaN;
        CODE(ct,1) = NaN;
    else
        absrt = find(I,1,'first') + CodeTimes(CodeNumbers == 27);
        relrt = absrt;
        
        while ~any(CodeTimes == relrt) && relrt > 0;
            relrt = relrt - 1;
            
            if CodeNumbers(CodeTimes == relrt) == 97
                relrt = relrt - 1;
            elseif mod(CodeNumbers(CodeTimes == relrt),2) == 0
                relrt = relrt - 1;
            end
            
        end
        if relrt == 0
            RT(ct,1) = NaN;
            CODE(ct,1) = NaN;
        else
            RT(ct,1) = absrt - relrt;
            CODE(ct,1) = CodeNumbers(CodeTimes == relrt);
        end
    end
end

else
    I = BHV.TrialError == 3 | BHV.TrialError == 4 | BHV.TrialError == 5;

    RT = BHV.ReactionTime(~I);
    ERR = BHV.TrialError(~I) > 1;
    
end
    

for err = 0:1
    subplot(4,4,[9 10] + err*4)
    hist(RT(ERR==err),[min(RT):range(RT)/50:max(RT)]);
    h = get(gca,'Children'); set(h,'FaceColor','k');
    set(gca,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial')
    if err == 0
        ylabel('Correct Trials')
    else
        ylabel('Error Trials')
    end
    axis tight
    xlim([min(RT) max(RT)])
    ymax(err+1) = max(ylim);
end
xlabel('Reaction Time (ms)');
for err = 0:1
    subplot(4,4,[9 10] + err*4)
    ylim([0 max(ymax)+1]);
end



%%




%%

if rsvp_ln == 1
    if flag_checkforerr7color
        ct = 0; clear TrialError ConditionNumber Saturation
        for i = 1:length(filelist)
            clear bhv cuedD uncuedD rsvp_ln
            
            bhv = concatBHV(filelist{i});
            [fdir,fname,~] = fileparts(filelist{i});
            [~, cuedD, ~, ~, ~, rsvp_ln] = loadRSVPdata(fdir,fname);
            
            for tr = 1:length(bhv.TrialError)
                ct = ct+1;
                TrialError(ct,1)      = bhv.TrialError(tr);
                ConditionNumber(ct,1) = bhv.ConditionNumber(tr);
                clear rgbcolor
                rgbcolor              = hex2rgb(cuedD.grating_color2(cuedD.trial == tr));
                Saturation(ct,1)      = 1-rgbcolor(2);
            end
        end
        
    else
        TrialError      = BHV.TrialError;
        ConditionNumber = BHV.ConditionNumber;
        Saturation      = ones(size(ConditionNumber))
    end
    
    %%% d' %%%
    % hits           = TE 0 on TARGET trls only, saccade to correct matching stim
    % correct reject = TE 0 on CATCH trls only, no sacade
    % false alarm    = TE 6 7, any saccades to wrong targets
    % miss           = TE 8, hold a saccade when they should have made one
  
    clear dprime
    uSaturation = unique(Saturation); 
    uSaturation(uSaturation == 0) = [];
    for s = 1:length(uSaturation) 
        
    I = Saturation == uSaturation(s);
    
    targetTrl = ConditionNumber >  4 & TrialError ~=3 & TrialError ~=4 & TrialError ~=5 & I;
    catchTrl  = ConditionNumber <= 4 & TrialError ~=3 & TrialError ~=4 & TrialError ~=5;
    
    dprime(s).hits          = sum(TrialError(targetTrl) == 0) / sum(targetTrl);
    dprime(s).correctreject = sum(TrialError(catchTrl ) == 0) / sum(catchTrl );
    
    dprime(s).falsealarm    = sum(TrialError == 6 | TrialError == 7) / sum([catchTrl;targetTrl]);
    dprime(s).miss          = sum(TrialError == 8) / sum(targetTrl);
    
    dprime(s).d             = norminv(dprime(s).hits,0,1)  -  norminv(dprime(s).falsealarm,0,1);
    end
    
    subplot(4,4,[12 16])
    plot(uSaturation,[dprime.d],'-o','color',[0 0 .5])
    xlabel('Color Saturation')
    ylabel('d-prime')
    set(gca,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial')
    legend({'Focal Cue'},'Location','NorthOutside');
    
    
end
%
%
%
%
%
%
%
%
% % parameters that are set on the ML side, manually put here for use
% rsvp_loc = [0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4];
% cue_loc  = [1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0]; %1 = RF
% stim_name = {...
%     'dCOS',...
%     'MC1',...
%     'MC2',...
%     'BC1',...
%     'BC2',...
%     'Cue',...
%     'Mask'...
%     'Target'};
%
% % load stimulus info
% [~, cuedD, ~, uncuedD, uncuedS, rsvp_ln] = loadRSVPdata(fdir,fname);
%
%
% % itterate stimulus presentations
% maxtr = length(BHV.ConditionNumber);
% ct = 0; clear attn stim r sXa err saccade
% for tr = 1:maxtr
%
%     % get presentation info for trial
%     cued_stream = double(cuedD.stimcond(cuedD.trial == tr));
%     uncued_stream = double(uncuedD.stimcond(uncuedD.trial == tr));
%     [x_cue, ~] = pol2cart(deg2rad(cuedD.theta(find(cuedD.trial == tr,1))),cuedD.eccentricity(find(cuedD.trial == tr,1)));
%     x_cue = sign(x_cue);
%
%     % get trial error
%     trialerror =  BHV.TrialError(tr);
%
%     if isempty(cued_stream) || isempty(uncued_stream) || rsvp_ln ~= length(cued_stream)
%         % skip entire trial if there were no stimulus presentations
%         % saved in the text file or if the record is bad ("badtrls")
%         continue
%     end
%
%     % interate within trial presntations, including cue and mask
%     p = 0;
%     while p < rsvp_ln + 2
%         p = p + 1;
%         sp0  = 21 + p*2; sp1 =  22 + p*2;
%         if ~any(BHV.CodeNumbers{tr} == sp0)
%             continue
%         end
%         ct = ct +1;
%
%         % presentation stimulus
%         if p == 1 % cue
%             cued_stim(ct,1)   = find(strcmp(stim_name,'Cue'));
%             uncued_stim(ct,1) = find(strcmp(stim_name,'Cue'));
%         elseif p == 2 % mask
%             cued_stim(ct,1)   = find(strcmp(stim_name,'Mask'));
%             uncued_stim(ct,1) = find(strcmp(stim_name,'Mask'));
%         else
%             cued_stim(ct,1)   = cued_stream(p-2);
%             uncued_stim(ct,1) = uncued_stream(p-2);
%         end
%
%         % presentation error
%         err(ct,1)  = trialerror;
%
%         % get eye status
%         clear eyesignal eyeidx
%         eyest = BHV.CodeTimes{tr}(BHV.CodeNumbers{tr} == sp0);
%         eyeen = BHV.CodeTimes{tr}(BHV.CodeNumbers{tr} == sp1);
%         if isempty(eyeen)
%             eyeen = eyest + 800;
%         end
%         eyesignal = BHV.AnalogData{tr}.EyeSignal;
%         if eyeen > length(eyesignal)
%             eyevelocity = diff(eyesignal(eyest:end,1));
%         else
%             eyevelocity = diff(eyesignal(eyest:eyeen,1));
%         end
%         I = abs(eyevelocity) > 5;
%         if ~any(I)
%             saccade(ct,1) = 0;
%         else
%             % figure out direction of saccade
%             x_saccade =  sign(mean(eyevelocity(I)));
%             if x_cue == x_saccade
%                 % saccade was to cued stream
%                 saccade(ct,1) = 1;
%             else
%                 % saccade was to UNcued stream
%                 saccade(ct,1) = -1;
%             end
%         end
%
%     end
%
% end
% cued_stim(cued_stim==99) = find(strcmp(stim_name,'Target'));
%
%
%
% %% Saccades
% figure;
% X = [1:length(stim_name)]; clear F
% for cond = 1:2
%     if cond == 1
%         [sN,~] = hist(cued_stim(saccade == 1),X);
%         [aN,~] = hist(cued_stim,X);
%     elseif cond == 2
%         [sN,~] = hist(uncued_stim(saccade == -1),X);
%         [aN,~] = hist(uncued_stim,X);
%     end
%     F(:,cond) = sN ./ aN .* 100;
% end
% figure
% bar(X,F)
% title('Saccade as a Function of Stimulus')
% xlabel('Stim Name')
% ylabel('% of Presentations "Evoking" a Saccade')
% legend({'Cued Side', 'Uncued Side'},'Location','Best')
% set(gca,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial',...
%     'Xtick', X,'XtickLabel',stim_name)






