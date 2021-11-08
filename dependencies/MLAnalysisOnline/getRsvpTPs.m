function Obs = getRsvpTPs(filelist,minStimulusTm,BRtime)

%clear
%filelist = '160420_E_rsvp001';
%minStimulusTm = 200;
%BRtime = 'samples';

% April 2016
% Trigger new RSVP attention task
% Key Event Codes:
%   102 = target onset (red patch inside stimulus)
%   37  = "redundent cue" for V1 attention dip paper control
%   each of these event marker is then followed by a "task object on" event marker during the actual flip
%   44/54 = 'Start/End eye 1', mark aprox. begin and end of saccade

if ~iscell(filelist)
    filelist = {filelist};
end

ct = 0; clear Obs
for i = 1:length(filelist)
    clearvars -except i ct Obs filelist minStimulusTm BRtime
    
    BRdatafile = filelist{i};
    
    if  datenum(BRdatafile(1:6),'yymmdd') < datenum('18-Apr-2016')
        error('cannot use this analysis code')
    end
    
    if ispc
        brdrname = sprintf('Z:\\%s',BRdatafile(1:8));
        mldrname = sprintf('Y:\\%s',BRdatafile(1:8));
    else
        brdrname = sprintf('/Volumes/Drobo2/DATA/NEUROPHYS/rig022/%s',BRdatafile(1:8));
        mldrname = brdrname;
    end
    
    % parameters that are set on the ML side, manually put here for use
    targetposbycond = [NaN NaN 1 1 2 2 3 3 4 4];
    rfcuedbycond    = [1 0 1 0 1 0 1 0 1 0]; %1 = RF
    stim_name = {...
        'mCOS';... MASK STIM, ADDED HERE, NOT CODED IN TASK FILEs
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
    
    % load behavoral data and stimulus info
    [cue, cuedD, ~, uncuedD, uncuedS, targetD, ~, rsvp_ln] = loadRSVPdata(mldrname,BRdatafile);
    bhv = concatBHV([mldrname filesep BRdatafile '.bhv']);
    isCueValid = (cue.grating_theta(1:2:end) == targetD.grating_theta);
    
    % load digital codes and neural data:
    filename = fullfile(brdrname,BRdatafile);
    NEV = openNEV(strcat(filename,'.nev'),'noread','nosave');
    
    % get event codes from NEV
    EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
    EventTimes = floor(NEV.Data.SerialDigitalIO.TimeStampSec .* 1000); %ms, to match 1kHz
    EventSampels = NEV.Data.SerialDigitalIO.TimeStamp;
    switch BRtime
        case 'samples'
            [pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);
        case 'ms'
            [pEvC, pEvT] = parsEventCodesML(EventCodes,EventTimes);
    end
    
    
    % check for aggreement
    [allpass, message] =  checkTrMatch(cuedD,NEV);
    if ~allpass
        message
        error('issue with NEV and stimulus txt file');
    end
    
    for tr = 1:length(pEvC)
        
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
        
        for p = 0:rsvp_ln
            EM = 25 + p*2;
            % get START event for this presentation
            st_event = find(CodeNumbers == EM,1,'first');
            if isempty(st_event)
                continue
            end
            % get END event for this presentation
            em = 0; en_event = [];
            em_array = [EM+1, 44, 97, 96, 18]; % stim off, saccade, break fixation, reward, end trial
            while isempty(en_event)
                em = em + 1;
                en_event = find(CodeNumbers == em_array(em),1,'first');
                if em > length(em_array)
                    break
                end
            end
            
            % exclude presentations with an early target appearence INSIDE RF
            if p == TargetPos && TargetTm <= minStimulusTm;
                if RfCued && CueValid
                    % target appeared in RF fewer than 'minStimulusTm' ms from stimulus onset, do not count
                    continue
                elseif ~RfCued && ~CueValid
                    % target appeared in RF fewer than 'minStimulusTm' ms from stimulus onset, do not count
                    continue
                end
            elseif p == 0
                tmidx = [...
                    st_event,...
                    en_event ...
                    ];
                MaskTm = diff(CodeTimes(tmidx));
                if MaskTm <= minStimulusTm
                    continue
                end
            end
                
            
            % exclude presentations with an early saccade [false alarms, or saccades to early targets outside RF]
            if any(CodeNumbers(st_event:en_event) == 44)
                tmidx = [...
                    st_event,...
                    find(CodeNumbers == 44) ...
                    ];
                EyeTm = diff(CodeTimes(tmidx));
                if EyeTm <= minStimulusTm
                    continue
                end
            end
            
            % all checks passed, meaning this is a presentaion to examin
            idx = cuedD.trial==tr & cuedD.pres==p;
            ct  = ct + 1;
            
            % get trigger point, attention status, stimulus info!
            Obs.fl(ct,1)  = i;
            Obs.tr(ct,1)   = tr;
            Obs.pres(ct,1) = p;
            Obs.tp(ct,1)   = double(pEvT{tr}(find(pEvC{tr} == EM,1,'first')));
            Obs.err(ct,1)  = TrialError;
            Obs.attn(ct,1) = RfCued;
            if p == 0 % mask stimulus
                Obs.stim(ct,1) = 1;
            else      % rsvp stimulus, function of RF being cued or uncued
                if RfCued
                    Obs.stim(ct,1) = cuedD.cued_cond(idx) + 1;
                else
                    Obs.stim(ct,1) = uncuedD.uncued_cond(idx) + 1;
                end
            end
            
        end
    end
    
    
    Obs.contrast(i,:) = double([unique(uncuedD.grating_contrast) unique(uncuedS.grating_contrast)]);
    Obs.grating(i,:)  = nanunique(uncuedD.grating_tilt);
    Obs.fname{i,:}    = BRdatafile;
    
    
end

Obs.sXa = (Obs.attn*max(Obs.stim))+Obs.stim;
Obs.stim_name = stim_name;
Obs.sXa_name  = stimXattn_name;