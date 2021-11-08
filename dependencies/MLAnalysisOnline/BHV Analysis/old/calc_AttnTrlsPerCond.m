% april 2
% only works for newest "rand color change" verison of task

session = '160418_E';
filelist = {'160418_E_rsvp003'};

minStimulusTm = 300;

targetposbycond = [NaN NaN 1 1 2 2 3 3 4 4];
rfcuedbycond    = [1 0 1 0 1 0 1 0 1 0];
stim_name = {...
    'dCOS1';... PREFORI   nullori
    'dCOS2';... nullori   PREFORI
    'BC1';...   PREFORI   PREFORI
    'MC1a';...  PREFORI   nan
    'MC1b';...  nan       PREFORI
    'BC2';...   nullori   nullori
    'MC2a';...  nullori   nan
    'MC2b';...  nan       nullori
    };
stimXattn_name = cat(1,...
    cellfun(@(x) ['U-' x], stim_name,'UniformOutput',0),...
    cellfun(@(x) ['C-' x], stim_name,'UniformOutput',0));
% stim_name = {...
%     'dCOS',...
%     'MC1',...
%     'MC2',...
%     'BC1',...
%     'BC2'};
% stimXattn_name = {...
%     'U-dCOS',...
%     'U-MC1',...
%     'U-MC2',...
%     'U-BC1',...
%     'U-BC2',...
%     'C-dCOS',...
%     'C-MC1',...
%     'C-MC2',...
%     'C-BC1',...
%     'C-BC2'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ispc
    brdrname = sprintf('Z:\\%s\',session);
    mldrname = sprintf('Y:\\%s\',session);
else
    switch session(end)
        case 'I'
            rignum = '021';
        case 'E'
            rignum = '022';
    end
    brdrname = sprintf('/Volumes/Drobo/DATA/NEUROPHYS/rig%s/%s/',rignum,session);
    mldrname = brdrname;
end

ct = 0; clear COND ATTN
for i = 1:length(filelist)
    
    fname = filelist{i};
    bhv = concatBHV([mldrname fname '.bhv']);
    
    [cue, cuedD, cuedS, uncuedD, uncuedS, targetD, ~, rsvp_ln] = loadRSVPdata(mldrname,fname);
    rgbcolor = hex2rgb(targetD.grating_color2);
    tColors = round(1 - rgbcolor(:,2),2);
    isCueValid = (cue.grating_theta(1:2:end) == targetD.grating_theta);
    
    for tr = 1:length(bhv.TrialError)
        
        TrialError = bhv.TrialError(tr);
        if TrialError == 3 || TrialError == 4 || TrialError == 5
            continue
        end
        
        TargetPos = targetposbycond(bhv.ConditionNumber(tr));
        RfCued    = rfcuedbycond(bhv.ConditionNumber(tr));
        CueValid  = isCueValid(tr);
        
        CodeNumbers = bhv.CodeNumbers{tr};
        CodeTimes   = bhv.CodeTimes{tr};
        % calculate time from stimulus to target 
        if any(CodeNumbers == 102)
            EM = 25 + 2*targetposbycond(bhv.ConditionNumber(tr));
            clear tmidx
            tmidx = [...
                find(CodeNumbers == EM ,1,'first'),...
                find(CodeNumbers == 102) + 1 ...
                ];
            tmidx(CodeNumbers(tmidx) ~= EM) = [];
            if length(tmidx) > 1
                TargetTm = diff(CodeTimes(tmidx));
            else
                TargetTm = 0;
            end
        else
            TargetTm = Inf;
        end
       
        
        
        for p = 1:rsvp_ln
            st_event = find(CodeNumbers == 25 + p*2);
            if isempty(st_event) 
                continue
            end
            en_event = find(CodeNumbers == 25 + p*2 + 1);
            if isempty(en_event)
                en_event = find(CodeNumbers == 18,1,'first');
            end
            
            % exclude presentations with an early target appearence INSIDE RF
            if p == TargetPos && TargetTm <= minStimulusTm;
                if RfCued && CueValid
                    % target appeared in RF, do not count
                    continue
                elseif ~RfCued && ~CueValid
                    % target appeared in RF, do notcount
                    continue
                end
            end
            
            % exclude presentations with an early saccade [false alarms, or saccades to early targets outside RF]
            if any(CodeNumbers(st_event:en_event) == 44)
                EM = 25 + p*2;
                tmidx = [...
                    find(CodeNumbers == EM ,1,'first'),...
                    find(CodeNumbers == 102) + 1 ...
                    ];
                EyeTm = diff(CodeTimes(tmidx));
                if EyeTm <= minStimulusTm
                    continue
                end
            end
            
            % all checks passed, meaning this is a presentaion to examin
            idx = cuedD.trial==tr & cuedD.pres==p;
            ct  = ct + 1;
            
            if RfCued
                COND(ct,1) = cuedD.cued_cond(idx);
                ATTN(ct,1) = true;
            else
                COND(ct,1) = uncuedD.uncued_cond(idx);
                ATTN(ct,1) = false;
            end
            
        end
    end
end
%%
sXa = (ATTN .* max(COND)) + COND;
bin = 1:max(sXa); 
n = hist(sXa,bin);
figure
bar(bin,n); hold on
ylim([0 max(n)]);
plot(0.5 + [max(COND) max(COND)],ylim,'r','LineWidth',2)
set(gca,'XTick',bin,'XtickLabel',stimXattn_name)
if i == 1
    title(sprintf('%s\nStimulus Time Limit = %ums',fname,minStimulusTm),'interpreter','none')
else
    title(sprintf('%s\nStimulus Time Limit = %ums',session,minStimulusTm),'interpreter','none')
end
ylabel('Number of Trials')
xlabel('Conditions')
set(gca,'Box','off','YGrid','on')




%%

