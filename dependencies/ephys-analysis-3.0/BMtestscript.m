clear

load('\Users\bmitc\Box Sync\Data_2\160420_E_eD.mat')
matobj = matfile('\Users\bmitc\Box Sync\Data_2\160420_E_eD_AUTO');

clear dMUA
uct = 0;
%% Electrode Loop
for e = 1:length(STIM.depths) 
    win_ms = matobj.win_ms; tic 
    if ~isequal(win_ms,[40 140; 141 450; 50 250; -50 0])
        error('check win')
    end
    
    goodfiles = unique(STIM.filen);
        
    resp  = squeeze(matobj.RESP(e,3,:)); %pulls out matobj RESP
    X = diUnitTuning(resp,STIM,goodfiles);
     prefeye = X.dipref(1);
     nulleye = X.dinull(1);
     prefori = X.dipref(2);
     nullori = X.dinull(2);
   
        
    % sort data so that they are [prefeye nulleye]
    clear eyes sortidx contrasts tilts
    eyes      = STIM.eyes;
    contrasts = STIM.contrast;
    tilts     = STIM.tilt;
    if X.dipref(1) == 2
        [eyes,sortidx] = sort(eyes,2,'ascend');
    else
        [eyes,sortidx] = sort(eyes,2,'descend');
    end
    for w = 1:length(eyes)
        contrasts(w,:) = contrasts(w,sortidx(w,:)); % sort contrasts in dominant eye and non-dominant eye
        tilts(w,:)     = tilts(w,sortidx(w,:));
    end; clear w

    STIM.monocular(find(STIM.adapted)+1) = 1;
    
    % establish constant parameters
    I = STIM.ditask ...
        & STIM.adapted == 0 ... %is not adapted
        & STIM.rns == 0 ... %not random noise stimulus
        & STIM.cued == 0 ... %not cued or uncued
        & STIM.motion == 0 ... %not moving
        & ismember(STIM.filen,goodfiles); % things that should be included.
    
    % pull out the data for single electrode
    clear sdf sdftm resp
    sdf   = squeeze(matobj.SDF(e,:,:)); % load only the channel of interest from matobj
    sdftm =  matobj.sdftm;
    resp = squeeze(matobj.RESP(e,:,:));
    
    % create contrast vectors for different conditions
    stimcontrast = [0 0.225 0.4500 0.9000]; 

%% Pull out data by monocular condition, one contact at a time

    % pre-allocate data matrices
    moncond     = {'DE_PS','DE_NS','NDE_PS','NDE_NS'};
    mon_SDF     = nan(4,length(sdftm),4);
    mon_SDFerror   = nan(4, length(sdftm),4);
    mon_RESP    = nan(4,4,4);
    mon_RESPerror  = nan(4,4,4);
    monTrlNum     = nan(4,4);  
    
    for mon = 1:size(moncond,2)
        for c = 1:length(stimcontrast)
            switch moncond{mon}           % Find the trials you want to look at
                case 'DE_PS'
                    if c == 1
                        trls = STIM.blank;
                    else
                    trls = I & prefeye...
                        & contrasts(:,1) == stimcontrast(c)... % contrast in dom eye
                        & tilts(:,1) == X.dipref(2)... % pref orientation in dom eye
                        & STIM.monocular;
                    end
                case 'DE_NS'
                    if c == 1
                        trls = STIM.blank;
                    else
                    trls = I & prefeye...
                        & contrasts(:,1) == stimcontrast(c)... % contrast in dom eye
                        & tilts(:,1) == X.dinull(2)... % pref orientation in dom eye
                        & STIM.monocular;
                    end
                case 'NDE_PS'
                    if c == 1
                        trls = STIM.blank;
                    else
                    trls = I & nulleye...
                        & contrasts(:,2) == stimcontrast(c) ... % contrast in null eye
                        & tilts(:,2) == X.dipref(2) ... % pref orientation in null eye
                        & STIM.monocular;
                    end
                case 'NDE_NS'
                    if c == 1
                        trls = STIM.blank;
                    else
                    trls = I & nulleye...
                        & contrasts(:,2) == stimcontrast(c)... % contrast in dom eye
                        & tilts(:,2) == X.dinull(2)... % pref orientation in dom eye
                        & STIM.monocular;
                    end
            end
            if sum(trls) >= 5
                mon_SDF(c,:,mon)   = nanmean(sdf(:,trls),2);
                mon_SDFerror(c,:,mon)   = (nanstd(sdf(:,trls),0,2))./(sqrt(sum(trls))-1);
                mon_RESP(c,:,mon)    = nanmean(resp(:,trls),2);
                mon_RESPerror(c,:,mon)   = (nanstd(resp(:,trls),0,2))./(sqrt(sum(trls))-1);
            else
                mon_SDF(c,:,mon)   = nan(size(sdf,1),1);
                mon_SDFerror(c,:,mon)   = nan(size(sdf,1),1);
            end
            monTrlNum(c,mon) = sum(trls);
            
            MON.dMUA.(moncond{mon}).sdf(c,:,e) = nanmean(sdf(:,trls),2);
            MON.dMUA.(moncond{mon}).resp(c,:,e) = nanmean(resp(:,trls),2);
        end
    end
    
    clear trls mon c
        
%% Binocular conditions
        clear binSDF binSDFerror binRESP binRESPerror binTrlNum
        bincond     = {'BIN_PS','BIN_NS'};
        binSDF     = nan(4,length(sdftm),2);
        binSDFerror   = nan(4, length(sdftm),2);
        binRESP    = nan(4,4,2);
        binRESPerror  = nan(4,4,2);
        binTrlNum     = nan(4,2);
        
    for bin = 1:size(bincond,2)
        for c = 1:length(stimcontrast)
            switch bincond{bin}           % Find the trials you want to look at
                case 'BIN_PS'
                    if c == 1
                        trls = STIM.blank;
                    else
                        trls = I & STIM.botheyes...
                            & contrasts(:,1) == stimcontrast(c)... % contrast in dom eye
                            & contrasts(:,2) == stimcontrast(c)... % contrast in null eye
                            & tilts(:,1) == X.dipref(2)... % pref orientation in dom eye
                            & tilts(:,2) == X.dipref(2); % pref orientation in null eye
                    end
                case 'BIN_NS'
                    if c == 1
                        trls = STIM.blank;
                    else
                        trls = I & STIM.botheyes...
                            & contrasts(:,1) == stimcontrast(c)... % contrast in dom eye
                            & contrasts(:,2) == stimcontrast(c)... % contrast in null eye
                            & tilts(:,1) == X.dinull(2)... % null orientation in dom eye
                            & tilts(:,2) == X.dinull(2); % null orientation in null eye
                    end
            end

            if sum(trls) >= 5
                binSDF(c,:,bin)   = nanmean(sdf(:,trls),2);
                binSDFerror(c,:,bin)   = (nanstd(sdf(:,trls),0,2))./(sqrt(sum(trls))-1);
                binRESP(c,:,bin)    = nanmean(resp(:,trls),2);
                binRESPerror(c,:,bin)   = (nanstd(resp(:,trls),0,2))./(sqrt(sum(trls))-1);
            else
                binSDF(c,:,bin)   = nan(size(sdf,1),1);
                binSDFerror(c,:,bin)   = nan(size(sdf,1),1);
            end
            binTrlNum(c,bin) = sum(trls);

            BIN.dMUA.(bincond{bin}).sdf(c,:,e) = nanmean(sdf(:,trls),2);
            BIN.dMUA.(bincond{bin}).resp(c,:,e) = nanmean(resp(:,trls),2);
        end
    end
    
    clear bin trls c
    
%% Dichoptic conditions

        clear diSDF diRESP diRESPerror diSDFerror diTrlNum
        dicontrast = [0.2250,0.4500;0.2250,0.9000;0.4500,0.2250;0.4500,0.9000;0.9000,0.2250;0.9000,0.4500];
        dicond     = {'DI_PS','DI_NS'};
        diSDF     = nan(6, length(sdftm),2);
        diSDFerror   = nan(6, length(sdftm),2);
        diRESP    = nan(6,4,2);
        diRESPerror  = nan(6,4,2);
        diTrlNum     = nan(6,2);
        
    for di = 1:size(dicond,2)
        for c = 1:length(dicontrast)
            switch dicond{di}           % Find the trials you want to look at
                case 'DI_PS'
                        trls = I & STIM.botheyes...
                            & contrasts(:,1) == dicontrast(c,1)... % contrast in dom eye
                            & contrasts(:,2) == dicontrast(c,2)... % contrast in null eye
                            & tilts(:,1) == X.dipref(2)... % pref orientation in dom eye
                            & tilts(:,2) == X.dipref(2); % pref orientation in null eye
                case 'DI_NS'
                        trls = I & STIM.botheyes...
                            & contrasts(:,1) == dicontrast(c,1)... % contrast in dom eye
                            & contrasts(:,2) == dicontrast(c,2)... % contrast in null eye
                            & tilts(:,1) == X.dinull(2)... % null orientation in dom eye
                            & tilts(:,2) == X.dinull(2); % null orientation in null eye
            end

%              if sum(trls) >= 5
                diSDF(c,:,di)   = nanmean(sdf(:,trls),2);
                diSDFerror(c,:,di)   = (nanstd(sdf(:,trls),0,2))./(sqrt(sum(trls))-1);
                diRESP(c,:,di)    = nanmean(resp(:,trls),2);
                diRESPerror(c,:,di)   = (nanstd(resp(:,trls),0,2))./(sqrt(sum(trls))-1);
%              else
%                 diSDF(c,:,di)   = nan(size(sdf,1),1);
%                 diSDFerror(c,:,di)   = nan(size(sdf,1),1);
%              end
            diTrlNum(c,di) = sum(trls);

            DI.dMUA.(dicond{di}).sdf(c,:,e) = nanmean(sdf(:,trls),2);
            DI.dMUA.(dicond{di}).resp(c,:,e) = nanmean(resp(:,trls),2);
        end
    end
    
    clear trls c di
    
    %% SAVE UNIT in IDX structure!
    
        uct = e;
        dMUA(uct).penetration = STIM.penetration;
        dMUA(uct).v1lim = STIM.v1lim;
        dMUA(uct).depth = STIM.depths(e,:)';

        dMUA(uct).prefeye    = prefeye;
        dMUA(uct).prefori    = prefori;
        dMUA(uct).nulleye    = nulleye;
        dMUA(uct).nullori    = nullori;        
        dMUA(uct).effects     = X.dianp; % p for main effect of each 'eye' 'tilt' 'contrast'
        
        dMUA(uct).X      =   X;
        
        dMUA(uct).occana       = X.occana;
        dMUA(uct).oriana       = X.oriana;
        dMUA(uct).diana        = X.diana;

        dMUA(uct).occ   = X.occ';    % how much it prefers one eye over the other
        dMUA(uct).ori   = X.ori';    % how much it prefers one orientation over the other
        dMUA(uct).bio   = X.bio';    % How much it prefers both eyes over one
        
        dMUA(uct).monContrast      = stimcontrast;
        dMUA(uct).monSDF           = mon_SDF;
        dMUA(uct).monSDF_SEM       = mon_SDFerror;
        dMUA(uct).monRESP          = mon_RESP;
        dMUA(uct).monRESP_SEM      = mon_RESPerror;
        dMUA(uct).monTrlNum        = monTrlNum;
        
        dMUA(uct).binSDF           = binSDF;
        dMUA(uct).binSDF_SEM       = binSDFerror;
        dMUA(uct).binRESP          = binRESP;
        dMUA(uct).binRESP_SEM      = binRESPerror;
        dMUA(uct).binTrlNum        = binTrlNum;
        
        dMUA(uct).dicontrast   = dicontrast';
        dMUA(uct).diSDF           = diSDF;
        dMUA(uct).diSDF_SEM       = diSDFerror;
        dMUA(uct).diRESP          = diRESP;
        dMUA(uct).diRESP_SEM      = diRESPerror;
        dMUA(uct).dinTrlNum        = diTrlNum;
            

toc
end

% Need to save workspace
