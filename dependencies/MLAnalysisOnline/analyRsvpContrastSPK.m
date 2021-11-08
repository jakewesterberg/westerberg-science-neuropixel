
clear

datum = '151204'; % session to analyze;
detailedfilelist = {...
    '151125_E_rsvp002', 0, [0.8 1.0], [12 13];...
    '151125_E_rsvp003', 0, [0.8 0.6], [12 13];...
    '151125_E_rsvp004', 0, [0.8 0.8], [12 13];...
    '151203_E_rsvp002', 0, [], 'NN probe, not sure about mapping';...... % DIFF ORI THAN NEXT 2 FILES, need to figure out how to deal with that
    '151203_E_rsvp003', 0, [], 'NN probe, not sure about mapping';...... 
    '151203_E_rsvp004', 0, [], 'NN probe, not sure about mapping';...... 
    '151204_E_rsvp002', 0, [0.8 1.0], [13 14];...
    '151204_E_rsvp003', 0, [0.8 0.8], [13 14];...
    '151204_E_rsvp004', 0, [0.8 0.2], [13 14];...
    };

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% prepare to iterate
SESSIONS = cellfun(@(x) x(1:6), detailedfilelist(:,1),'UniformOutput',0);
idx = find(strcmp(SESSIONS,datum));
if isempty(idx)
    error('bad session')
end

files = detailedfilelist(idx,1);
contrasts = cell2mat(detailedfilelist(idx,3));

R = nan(24, 10, length(idx)); % 3rd demenstion of R is CONTRAST
S = nan(24, 10, length(idx)); % 3rd demenstion of S is CONTRAST

for f = 1:length(idx)
    
    BRdatafile = files{f};
    badobs = getBadObs(BRdatafile);
    if ispc
        brdrname = sprintf('Z:\\%s',BRdatafile(1:8));
        if  any(strcmp({'151120','151121','151125'},BRdatafile(1:6)));
            mldrname = 'Y:\Early RSVP Data';
        else
            mldrname = sprintf('Y:\\%s',BRdatafile(1:8));
        end
    else
        brdrname = sprintf('/Volumes/Drobo/DATA/NEUROPHYS/rig022/%s',BRdatafile(1:8));
        mldrname = brdrname;
    end
    
    
    % behavoral data and stimulus info
    [~, cuedD, cuedS, uncuedD, uncuedS, rsvp_ln] = loadRSVPdata(mldrname,BRdatafile);
    badtrls = [setdiff(uncuedD.trial,uncuedS.trial); setdiff(uncuedS.trial,uncuedD.trial)];
    BHV = concatBHV([mldrname filesep BRdatafile '.bhv']);
    
    
    %% load digital codes and neural data:
    filename = fullfile(brdrname,BRdatafile);
    
    % check if file exist and load NEV
    if exist(strcat(filename,'.nev'),'file') == 2;
        NEV = openNEV(strcat(filename,'.nev'),'read','overwrite','uV');
    else
        error('the following file does not exist\n%s.nev',filename);
    end
    % get event codes from NEV
    EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
    EventTimes = floor(NEV.Data.SerialDigitalIO.TimeStampSec .* 1000); %ms, to match 1kHz
    EventSampels = NEV.Data.SerialDigitalIO.TimeStamp;
    [pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);
    
    for e = 24:-1:1
        
        % get electrrode index
        elabel = sprintf('eD%02u',e);
        eidx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x',elabel)),{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0)));
        I =  NEV.Data.Spikes.Electrode == eidx;
        
        % get SPK and WAVE
        clear SPK Fs
        SPK = double(NEV.Data.Spikes.TimeStamp(I)); % in samples
        WAVE = double(NEV.Data.Spikes.Waveform(:,I));
        Fs = double(NEV.MetaTags.SampleRes);
        
        ct = 0; clear attn stim r sXa
        maxtr = length(pEvC);
        for tr = 1:maxtr
            if BHV.trialerror(tr) > 0 || any(tr == badtrls)
                % skip if not correct trial
                continue
            end
            
            target = rsvp_loc(BHV.conditionnumber(tr));
            rfcued =  logical(cue_loc(BHV.conditionnumber(tr)));
            if rfcued
                stimuli = double(cuedD.stimcond(cuedD.trial == tr));
            else
                stimuli = uncuedD.stimcond(uncuedD.trial == tr);
            end
            if isempty(stimuli)
                continue
            end
            
             p = 0;
            while p < rsvp_ln
                p = p + 1;
                
                if p == target || stimuli(p) == 99
                    % want to exclude presnetations with a potential saccade, and all
                    % subsequent presnetations
                    p = rsvp_ln;
                    continue
                end
                
                ct = ct +1;
                
                st = pEvT{tr}( pEvC{tr}== (27 + (p-1)*2) );
                en = st + (500/1000) * Fs;
                
                attn(ct) = rfcued;
                stim(ct) = stimuli(p);
                if any(ct == badobs)
                    r(ct) = NaN;
                else
                    r(ct) = sum(SPK > st & SPK < en);
                end
                
            end
            
        end
        if ct == 0 || sum(r~=0) < 5 || max(r) < 5
            continue
        end
        sXa = (attn*5)+stim;
        missingcond = setdiff([1:10],unique(sXa));
        sXa = [sXa missingcond];
        r = [r nan(size(missingcond))];
        
        % group stats
        clear uR mR sR gstim N
        [uR mR sR gstim N] = grpstats(r,  sXa, {'mean','median','sem','gname','numel'});
        gstim = str2double(gstim);
        R(e,gstim,f) = uR;
        S(e,gstim,f) = sR;
        
    end
end


%% for sesssion, plot rough CRF
for e = 24:-1:1
    elabel = sprintf('eD%02u',e);
    
    if all(all(isnan(squeeze((R(e,:,:))))))
        continue
    end
    
    figure('position', [670   554   592   424])
    
    
    stim = [1 2 6 7];
    for s = 1:length(stim)
        
        x = diff(contrasts,[],2);
        y = squeeze(R(e,stim(s),:));
        er = squeeze(S(e,stim(s),:));
        [x sI] = sort(x); y = y(sI); er = er(sI);
        
        stimname = stimXattn_name{stim(s)};
        switch stimname(1)
            case 'C'
                color = [0 0 0];
            case 'U'
                color = [.6 .6 .6];
        end
        switch stimname(3:end)
            case 'MC1'
                style = '-';
            case 'dCOS'
                style = '--';
        end
        
        h = errorbar(x,y,er,'o-','LineWidth',2,'LineStyle',style,'Color',color); hold all
    end
    legend(stimXattn_name(stim),'Location','BestOutside')
    xlabel('dom eye contrast - nondom eye contrast')
    ylabel('mean response +/- sem')
    title(sprintf('%s: %s',BRdatafile(1:8), elabel),'interpreter','none')
    box off; set(gca,'TickDir','out');
    
end




