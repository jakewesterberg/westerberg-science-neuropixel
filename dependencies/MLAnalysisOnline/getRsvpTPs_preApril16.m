function Obs = getRsvpTPs(BRdatafile,time)

if ispc
    brdrname = sprintf('Z:\\%s',BRdatafile(1:8));
    mldrname = sprintf('Y:\\%s',BRdatafile(1:8));
else
    brdrname = sprintf('/Volumes/Drobo/DATA/NEUROPHYS/rig022/%s',BRdatafile(1:8));
    mldrname = brdrname;
end

% parameters that are set on the ML side, manually put here for use
rsvp_loc = [0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4];
cue_loc  = [1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0]; %1 = RF
stim_name = {...
    'dCOS',...
    'MC1',...
    'MC2',...
    'BC1',...
    'BC2'};
stimXattn_name = {...
    'U-dCOS',...
    'U-MC1',...
    'U-MC2',...
    'U-BC1',...
    'U-BC2',...
    'C-dCOS',...
    'C-MC1',...
    'C-MC2',...
    'C-BC1',...
    'C-BC2'};

% load behavoral data and stimulus info
[~, cuedD, ~, uncuedD, uncuedS, rsvp_ln] = loadRSVPdata(mldrname,BRdatafile);
BHV = concatBHV([mldrname filesep BRdatafile '.bhv']);
badtrls = [setdiff(uncuedD.trial,uncuedS.trial); setdiff(uncuedS.trial,uncuedD.trial)];

% load digital codes and neural data:
filename = fullfile(brdrname,BRdatafile);
NEV = openNEV(strcat(filename,'.nev'));

% get event codes from NEV
EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
EventTimes = floor(NEV.Data.SerialDigitalIO.TimeStampSec .* 1000); %ms, to match 1kHz
EventSampels = NEV.Data.SerialDigitalIO.TimeStamp;
switch time
    case 'samples'
        [pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);
    case 'ms'
        [pEvC, pEvT] = parsEventCodesML(EventCodes,EventTimes);
end


% check for aggreement
if length(pEvC) ~=  max(cuedD.trial)
    error('problem with BR and ML trials')
end

% itterate stimulus presentations
maxtr = length(pEvC); 
ct = 0; clear attn stim r sXa err saccade
for tr = 1:maxtr
    
    % get presentation info for trial
    target = rsvp_loc(BHV.conditionnumber(tr));
    rfcued =  logical(cue_loc(BHV.conditionnumber(tr)));
    if rfcued
        stimuli = double(cuedD.stimcond(cuedD.trial == tr));
    else
        stimuli = double(uncuedD.stimcond(uncuedD.trial == tr));
    end
    trialerror =  BHV.trialerror(tr);

    
    if isempty(stimuli) || any(tr == badtrls) || rsvp_ln ~= length(stimuli) 
        % skip entire trial if there were no stimulus presentations
        % saved in the text file or if the record is bad ("badtrls")
        continue
    end
    
    % interate presntations
    p = 0;
    while p < rsvp_ln
        p = p + 1;
        st = pEvT{tr}( pEvC{tr}== (27 + (p-1)*2) );
       
        if isempty(st) || p == target || stimuli(p) == 99
            % want to exclude target presentations
            continue
        end
        
        % get trigger point! 
        ct = ct +1;
        tp(ct) = st;
        attn(ct) = rfcued;
        stim(ct) = stimuli(p);
        err(ct)  = trialerror;
        
        % get eye status
        clear eyesignal eyeidx
        eyeidx = BHV.codetimes{tr}(BHV.codenumbers{tr} == (27 + (p-1)*2));
        eyesignal = BHV.analogdata{tr}.eyesignal;
        if eyeidx+450 > length(eyesignal)
            eyesignal = eyesignal(eyeidx:end,:);
        else
            eyesignal = eyesignal(eyeidx:eyeidx+450,:);
        end
        if any( abs(diff(eyesignal)) > 5 )
            saccade(ct) = true;
        else
            saccade(ct) = false;
        end
        
    end
    
end

Obs.tp = tp;
Obs.stim = stim; 
Obs.attn = attn;
Obs.sXa = (attn*5)+stim;
Obs.err = err;
Obs.saccade = saccade;
Obs.stim_name = stim_name;
Obs.sXa_name = stimXattn_name;
Obs.contrast = [unique(uncuedD.contrast) unique(uncuedS.contrast)];
Obs.grating = unique(uncuedD.tilt);
