function output = fftdriftana(filename,datatype)

if nargin < 2
    datatype = {'kls','auto'};
end
[~,fname,~] = fileparts(filename);

% check for ppNEV
autodir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';
if any(strcmp(datatype,'auto')) && exist([ autodir fname '.ppnev'],'file')
    load([ autodir fname '.ppnev'] ,'ppNEV','-MAT')
    NEV = ppNEV; clear ppNEV;
else
    NEV = openNEV([filename,'.nev'],'noread','nosave','nomat');
    datatype(strcmp(datatype,'auto')) = [];
end
if isempty(NEV)
     output = [];
     return
end

if any(strcmp(datatype,'kls'))
    % find kilosort
    sortdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';
    klsfile = [sortdir '/' fname '/ss.mat'];
    if exist(klsfile,'file')
        x = load(klsfile,'ss');
        ss = x.ss; clear x;
    else
        datatype(strcmp(datatype,'kls')) = []; 
    end
end
if isempty(datatype)
      output = [];
     return
end

%%
EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
EventSampels = double(NEV.Data.SerialDigitalIO.TimeStamp);
[pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);

Fs = double(NEV.MetaTags.SampleRes);

ext = {'.gRFORIDRFTGrating_di','.gRFSFDRFTGrating_di'};
for ex = 1:length(ext)
    if exist([filename ext{ex}],'file')
        grating = readgDRFTGrating([filename ext{ex}]);
        break
    end
end
%%

stimfeatures = {...
    'trial'...
    'tilt'...
    'sf'...
    'contrast'...
    'eye'...
    'temporal_freq'...
    'motion'...
    'pres'}; 


obs = 0; clear STIM
for t = 1: length(pEvC)
    % examin presentations ONLY if there is a off event marker (not a break fixation)
    stim =  find(grating.trial == t); if any(diff(stim) ~= 1); error('check stim file'); end
    nstim = sum(pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32); if nstim == 0; continue; end
    for p = 1:nstim %\
        obs = obs + 1;
        STIM.('trl')(obs,:) = t;
        STIM.('prez')(obs,:) = p;
        STIM.('reward')(obs,:) = any(pEvC{t} == 96);
        stimon  =  pEvC{t} == 21 + p*2;
        stimoff =  pEvC{t} == 22 + p*2;
        st = double(pEvT{t}(stimon));
        en = double(pEvT{t}(stimoff));
        STIM.tp_sp(obs,:) = [st(end) en];
        STIM.tp_ms(obs,:) = round([st(end) en] ./ Fs * 1000);
        % write STIM features
        for f = 1:length(stimfeatures)
            STIM.(stimfeatures{f})(obs,:) = grating.(stimfeatures{f})(stim(p));
        end
    end
end

%%

bin_sp = 10/1000 * Fs;
ct = zeros(1,length(datatype)); 
for d = 1:length(datatype)
    
    switch datatype{d}
        case 'kls'
            emax = size(ss.clusterMap,1);
        case 'auto'
            nevel =unique(NEV.Data.Spikes.Electrode);
            emax = length(nevel); 
    end
    
    for e = 1:emax
         clear I SPK elabel
        
         switch datatype{d}
            case 'kls'
                I = ss.spikeClusters == ss.clusterMap(e,1);
                SPK = ss.spikeTimes(I);
                elabel = ss.chanIDs{ss.clusterMap(e,2)};
                
            case 'auto' 
                I   =  NEV.Data.Spikes.Electrode == nevel(e);
                elabel = NEV.ElectrodesInfo(nevel(e)).ElectrodeLabel';
                SPK = unique(double(NEV.Data.Spikes.TimeStamp(I)));
        end
        
                clear PSTH RESP
        RESP = nan(1,length(STIM.tp_sp));
        for t = 1:length(STIM.tp_sp)
            % trigger points
            tp      = STIM.tp_sp(t,1);
            st        = tp + (200/1000*Fs);
            en        = tp + (1000/1000*Fs);
            
            edges  = st: bin_sp : en-1;
            
            spk = SPK(SPK >= st & SPK < en);
            
            if ~isempty(spk)
                
                PSTH(:,t) = histc(spk,edges) .* (Fs/bin_sp); %  bin/s  = (Fs/bin_sp) ?????
                RESP(1,t) = length(unique((spk)));
                
            end
        end
        
        % remove last bin (inf)
        PSTH(end,:) = [];
        
        % seperate out best conditions
        group = {STIM.eye,STIM.tilt,STIM.motion,STIM.temporal_freq};
        p = anovan(RESP,group,'display','off');
        if any(p < 0.05)
            group = group(p < 0.05);
            [u, n, gname] = grpstats(RESP,group,{'mean','numel','gname'});
            u(n<2) = [];
            gname(n<2,:) = [];
            [~,mI] = max(u);
            var = cellfun(@str2num,gname(mI,:));
            clear I
            for g = 1:length(group)
                I(:,g) = group{g} == var(g);
            end
            I = all(I,2);
        else
            I = true(t,1);
        end
        
        clear TF psth dpsth
        TF = unique(STIM.temporal_freq(I));
        if length(TF) > 1
            TF = max(TF);
        end
        
        psth = PSTH(:,I & STIM.temporal_freq == TF);
        dpsth = bsxfun(@minus, psth, mean(psth,1));
        
        clear f0 fnot
        [f0,~, ~] = ratio_ftf_f0(psth,Fs / bin_sp,TF);
        [fnot,~, ~] = ratio_ftf_fnot(dpsth,Fs / bin_sp,TF);
        
        ct(d) = ct(d) + 1; 
        output.(datatype{d}).f0(ct(d),:)     = f0;
        output.(datatype{d}).fnot(ct(d),:)   = fnot;
        output.(datatype{d}).elabel{ct(d),:} = elabel;
        
    end
end


%%

