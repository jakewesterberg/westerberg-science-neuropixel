clear
BRdatafile = {'160523_E_mcosinteroc001','160523_E_mcosinteroc002'};%,'160211_I_brfs002'};
el = 'eD';
el_array = [18];  

tmwin = [50 150];
Fs = 30000;

badobs = [];
flag_RewardedTrialsOnly = true;
flag_MonocularOnly = true;
flag_ploterrorbars = true;
flag_plottimecourse = false;

flag_SaveFigs = false;
figsavepath = sprintf('/Volumes/Drobo/USERS/Michele/Analysis Projects/dCOS/analyBrfsSPK/');
if flag_SaveFigs
    close all
end

obs = 0; clear spkTP spkFL STIM spk
for i = 1:length(BRdatafile)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % set data directories
    if ispc
        brdrname = sprintf('Z:\\%s',BRdatafile{i}(1:8));
        mldrname = sprintf('Y:\\%s',BRdatafile{i}(1:8));
    else
        if ~isempty(strfind(BRdatafile{i},'_I_'))
            rignum = '021';
        else
            rignum = '022';
        end
        brdrname = sprintf('/Volumes/Drobo/DATA/NEUROPHYS/rig%s/%s',rignum,BRdatafile{i}(1:8));
        mldrname = brdrname;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % load stim info
    clear brfs grating
    if ~isempty(strfind(BRdatafile{i},'brfs'))
        task = 'brfs';
        brfs        = readBRFS([mldrname filesep BRdatafile{i} '.gBrfsGratings']);
        
    elseif  ~isempty(strfind(BRdatafile{i},'cosinteroc'))
        task = 'cosinteroc';
        if isempty(strfind(BRdatafile{i},'m'))
            ext = '.gCOSINTEROCGrating_di';
        else
            ext = '.gMCOSINTEROCGrating_di';
        end
        grating        = readgGrating([mldrname filesep BRdatafile{i} ext]);
        
        % extract params for brfs-like analysis
        s1_eye = grating.eye;
        s2_eye = zeros(size(s1_eye));
        s2_eye(s1_eye == 2) = 3; s2_eye(s1_eye == 3) = 2;
        
        oridist = grating.oridist;
        s1_tilt = grating.tilt;
        s2_tilt = uCalcTilts0to179(s1_tilt, oridist);
        
        s1_contrast  = grating.contrast;
        s2_contrast  = grating.fixedc;
        
        brfs.trial       = grating.trial;
        brfs.pres        = grating.pres;
        brfs.s1_eye      = s1_eye;
        brfs.s2_eye      = s2_eye;
        brfs.s1_tilt     = s1_tilt;
        brfs.s2_tilt     = s2_tilt;
        brfs.s1_contrast = s1_contrast;
        brfs.s2_contrast = s2_contrast;
        brfs.soa         = zeros(size(grating.trial));
        
        stim = cell(size(grating.trial));
        stim(oridist == 90) = {'dCOS'};
        stim(oridist == 0 ) = {'Binocular'};
        stim(s1_contrast == 0) = {'Monocular'};
        stim(s2_contrast == 0) = {'Monocular'};
        
        brfs.stim = stim;
        clear s1_* s2_* stim
        
        if any(strcmp(fieldnames(grating),'timestamp'))
            brfs.timestamp = grating.timestamp;
        end
        
    else
        error('BRdatafile: %s not recognized',BRdatafile{i})
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % load digital codes and neural data:
    filename = fullfile(brdrname,BRdatafile{i});
    
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
    
    % check that all is good between NEV and grating text file;
    [allpass, message] =  checkTrMatch(brfs,NEV);
    if ~allpass
        error('not all pass')
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % sort/pick trials [before iterating units]
    stimfeatures = {...
        'stim',...
        's1_eye'...
        's2_eye'...
        's1_tilt'...
        's2_tilt'...
        's1_contrast'...
        's2_contrast'...
        'soa'...'grating_phase'...
        };
    clear(stimfeatures{:})
    
    for t = 1: length(pEvC)
        
        stim =  find(brfs.trial == t); if any(diff(stim) ~= 1); error('check stim file'); end
        nstim = sum(pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32); if nstim == 0; continue; end
        
        for p = 0:nstim
            
            obs = obs + 1;
            
            if p > 0
                stimon  =  pEvC{t} == 21 + p*2;
                stimoff =  pEvC{t} == 22 + p*2;
                if isempty(tmwin)
                    st = double(pEvT{t}(stimon));
                    en = double(pEvT{t}(stimoff));
                else
                    st = double(pEvT{t}(stimon));
                    en = st + tmwin(2) / 1000 * Fs;
                    st = st + tmwin(1) / 1000 * Fs;
                end
            else
                % BLANK
                en = double(pEvT{t}(pEvC{t} == 23));
                en = en(1);
                if isempty(tmwin)
                    st = en - 0.25*Fs;
                else
                    st = en - abs(diff(tmwin))/1000*Fs;
                end
            end
            
            spkFL(obs,:) = i;
            if (flag_RewardedTrialsOnly && ~any(pEvC{t} == 96))
                % skip obs, so make it "empty"
                spkTP(obs,:) = [0 0];
                for f = 1:length(stimfeatures)
                    if strcmp('stim',(stimfeatures{f}))
                        STIM.(stimfeatures{f}){obs,:} = NaN;
                    else
                        STIM.(stimfeatures{f})(obs,:) = NaN;
                    end
                end
            else
                % goodobs, save trigger pts
                spkTP(obs,:) = [st(end) en];
                for f = 1:length(stimfeatures)
                    if p > 0
                        STIM.(stimfeatures{f})(obs,:) = brfs.(stimfeatures{f})(stim(p));
                    else
                        if strcmp('stim',(stimfeatures{f}))
                            STIM.(stimfeatures{f}){obs,:} = 'Blank';
                        elseif strcmp('s1_contrast',(stimfeatures{f})) || strcmp('s2_contrast',(stimfeatures{f}))
                            STIM.(stimfeatures{f})(obs,:) = 0;
                        else
                            STIM.(stimfeatures{f})(obs,:) = NaN;
                        end
                    end
                end
            end
        end
    end % looked at all trials
    
    % save NEV data across files
    if i == 1
        spk.ElectrodeLabel = {NEV.ElectrodesInfo.ElectrodeLabel};
        spk.Electrode = [];
        spk.Unit = [];
        spk.TimeStamp = [];
        spk.Electrode = [];
        spk.Waveform  = [];
        spk.FileNum   = [];
    end
    spk.Electrode = [spk.Electrode (NEV.Data.Spikes.Electrode)];
    spk.Unit      = [spk.Unit (NEV.Data.Spikes.Unit)];
    spk.TimeStamp = [spk.TimeStamp (NEV.Data.Spikes.TimeStamp)];
    spk.Waveform  = [spk.Waveform NEV.Data.Spikes.Waveform];
    spk.FileNum   = [spk.FileNum repmat(i,size(NEV.Data.Spikes.Electrode))];
end


%%
for j = 1:length(el_array)
    e = el_array(j);
    
    % get electrrode index
    elabel = sprintf('%s%02u',el,e);
    eidx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x',elabel)),spk.ElectrodeLabel,'UniformOutput',0)));
    if isempty(eidx)
        fprintf('\nno %s\n',elabel)
        continue
    end
    eI =  spk.Electrode == eidx;
    units = unique(spk.Unit(eI));
    for u = 0:max(units)
        if u > 0
            elabel = sprintf('%s%02u - unit%u',el,e,u);
            I = eI & spk.Unit == u;
        else
            elabel = sprintf('%s%02u - all spikes',el,e);
            I = eI;
        end
        unitID = sprintf('%s%02u-unit%u',el,e,u);
        
        % get SPK and WAVE
        clear SPK WAVE RESP SUA
        SPK  = double(spk.TimeStamp(I)); % in samples
        FIL  = double(spk.FileNum(I));
        WAVE = double(spk.Waveform(:,I));
        RESP = NaN(length(spkTP),1);
        SUA  = cell(length(spkTP),1);
        
        
        for r = 1:length(spkTP)
            st  = spkTP(r,1);
            en  = spkTP(r,2);
            fl  = spkFL(r,1);
            tm  = (en-st) / 30000; % NEV FS = 30,000
            bl =  st - 0.25*30000;
            if st ~= 0 && en ~= 0
                RESP(r,:) = sum(SPK >= st & SPK <= en & FIL == fl) / tm; % units of spk / sec
                SUA{r,:}  = SPK(SPK >= bl & SPK <= en & FIL == fl) - st;
            end
        end
        
        
        if ~any(RESP)
            continue
        end
        
        %figure('Position',[  264   201   902   679])
        figure
        
        subplot(2,3,1)
        plot(RESP); hold on
        axis tight; box off;
        filebreak = find(diff(spkFL) > 0);
        for fb = 1:length(filebreak)
            plot([filebreak(fb) filebreak(fb)], ylim, 'r')
        end
        xlabel('stim prez')
        ylabel('spikes (imp./s)')
        title(elabel)
        axis tight; set(gca,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial');
        
        
        subplot(2,3,4)
        plot(mean(WAVE,2),'-'); hold on
        plot(mean(WAVE,2)+ std(WAVE,[],2),':'); hold on
        plot(mean(WAVE,2)- std(WAVE,[],2),':'); hold on
        xlabel('waveform')
        axis tight; set(gca,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial');
        
        
        
        % get monocular traces for each eye
        clear MONOCULAR STR; strct = 0;
        uTilt     = nanunique([STIM.s1_tilt STIM.s2_tilt]);
        for eye = 1:3
            for ori = 1:2
                clear y err gstim n x
                
                if eye > 1
                    I1 = (STIM.s1_eye == eye & STIM.s1_tilt == uTilt(ori) & STIM.s2_contrast == 0 & STIM.soa == 0);
                    I2 = (STIM.s2_eye == eye & STIM.s2_tilt == uTilt(ori) & STIM.s1_contrast == 0 & STIM.soa == 0); % sum(I2) = 0 for brfs as s1 never has a 0 contrast
                    [y err gstim n] = grpstats([RESP(I1); RESP(I2)], [STIM.s1_contrast(I1);STIM.s2_contrast(I2)], {'mean','sem','gname','numel'});
                    x =  str2double(gstim(:));
                elseif eye == 1
                    I = STIM.s1_contrast == STIM.s2_contrast & STIM.soa == 0 &  STIM.s1_tilt == uTilt(ori) & STIM.s2_tilt == uTilt(ori) ;
                    [y err gstim n] = grpstats(RESP(I), STIM.s1_contrast(I), {'mean','sem','gname','numel'});
                    x =  str2double(gstim(:));
                end
                
                
                if ~isempty(y)
                    %1st, add blank
                    I = strcmp(STIM.stim,'Blank');
                    x = [0; x];
                    y = [nanmean(RESP(I)); y];
                    err = [nanstd(RESP(I))/sqrt(sum(I)); err];
                    
                    %2nd, plot
                    subplot(2,3,[2 3 5 6])
                    strct = strct + 1;
                    STR{strct,1} = [sprintf('eye= %u, ori= %u, n= ',eye,uTilt(ori)) sprintf('%u ',n)];
                    if flag_ploterrorbars
                        h = errorbar(x,y,err,'LineWidth',1); hold all;
                    else
                        h = plot(x,y,'LineWidth',1); hold all;
                    end
                    
                    if eye == 1
                        set(h,'Color',[1 0 0])
                    elseif eye == 2
                        set(h,'Color',[0 1 0])
                    else
                        set(h,'Color',[0 0 1])
                    end
                    if ori == 1
                        set(h,'Marker','^')
                    else
                        set(h,'Marker','o')
                    end
                    
                    
                    if uTilt(ori) == 0
                        MONOCULAR(eye,999).x = x;
                        MONOCULAR(eye,999).y = y;
                        MONOCULAR(eye,999).err = err;
                        MONOCULAR(eye,999).n = n;
                    else
                        MONOCULAR(eye,uTilt(ori)).x = x;
                        MONOCULAR(eye,uTilt(ori)).y = y;
                        MONOCULAR(eye,uTilt(ori)).err = err;
                        MONOCULAR(eye,uTilt(ori)).n = n;
                    end
                end
            end
            
        end
        set(gca,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial');
        xlim([-0.1 1.1])
        legend(STR,'Location','Best')
        if length(BRdatafile) > 1
            title(sprintf('%s: %s',BRdatafile{1}(1:8), elabel),'interpreter','none')
        else
            title(sprintf('%s: %s',BRdatafile{i}, elabel),'interpreter','none')
        end
        ylabel('mean MONOCULAR / BINOCULAR responses (imp./s)')
        if ~isempty(tmwin)
            xlabel(sprintf('contrast in eye (see legend)\n win = %u to %u ms re:StimOn',tmwin(1), tmwin(2)));
        else
            xlabel('contrast in eye (see legend)');
        end

        if flag_MonocularOnly
            continue
        end
        
        % plot stim 2 as a function of stim 1
        uEye = nanunique([STIM.s1_eye STIM.s2_eye]);
        uContrast = nanunique([STIM.s1_contrast STIM.s2_contrast]);uContrast(uContrast == 0) = [];%[0 0.05 0.3 1];%]unique([s1_contrast s2_contrast]); %;
        uSOA     = 0;%nanunique(STIM.soa); uSOA(uSOA == 200) = [];
        uTilt     = nanunique([STIM.s1_tilt STIM.s2_tilt]);
        for eye = 1:2
            for tilt = 1:2
                fh = figure;
                strct = 0; STR =[];
                map = prism(6); map(3,:) = []; map = flipud(map);
                if any(uContrast == 0)
                    map = [0 0 0; map];
                end
                
                % Stim #2 eye and tilt that is on X-Axis
                prefori = uTilt(tilt);
                prefeye  = uEye(eye);
                
                for orthogonal = 0:1
                    for s = 1:length(uSOA)
                        for c = 1:length(uContrast)
                            switch orthogonal
                                case 0
                                    ori = prefori;
                                    stimtype = 'Binocular';
                                case 1
                                    ori = nanmedian(uTilt(uTilt~=prefori));
                                    stimtype = 'dCOS';
                            end
                            
                           switch uSOA(s)
                                case 0
                                    % soa is 0, so don't need to care about which stim may have appeared first 
                                    I1 = STIM.s1_tilt == prefori & STIM.s1_eye == prefeye & ... 
                                         STIM.s2_tilt == ori     & STIM.s2_eye ~= prefeye & ... 
                                         STIM.s2_contrast == uContrast(c) & ...            % 
                                         STIM.soa == uSOA(s);                              % SOA
                                    I2 = STIM.s2_tilt == prefori & STIM.s2_eye == prefeye & ... 
                                         STIM.s1_tilt == ori     & STIM.s1_eye ~= prefeye & ... 
                                         STIM.s1_contrast == uContrast(c) & ...            % 
                                         STIM.soa == uSOA(s);  
                                    
                                    clear y err gstim n x
                                    [y err gstim n] = grpstats([RESP(I1);RESP(I2)], [STIM.s1_contrast(I1);STIM.s2_contrast(I2)], {'mean','sem','gname','numel'});
                                    x =  str2double(gstim(:));
                                    
                               otherwise
                                    % stim 2 is the one that appears second
                                    I = STIM.s2_tilt == prefori & STIM.s2_eye == prefeye & ... %  Stim #2 eye and tilt that is on X-Axis
                                        STIM.s1_tilt == ori     & STIM.s1_eye ~= prefeye & ... % stim 1 params
                                        STIM.s1_contrast == uContrast(c) & ...            % stim 1 contrast
                                        STIM.soa == uSOA(s);                              % SOA
                                    
                                    clear y err gstim n x
                                    [y err gstim n] = grpstats(RESP(I), STIM.s2_contrast(I), {'mean','sem','gname','numel'});
                                    x =  str2double(gstim(:));
                            end
                            
                            if ~isempty(y) && length(x) > 1
                                strct = strct + 1;
                                STR{strct} = [sprintf('%s - %0.2f -- %u, n = ',stimtype,uContrast(c),uSOA(s)) sprintf('%u ',n)];
                                
                                if flag_ploterrorbars
                                    h = errorbar(x,y,err,'Color',map(c,:),'LineWidth',1); hold all
                                else
                                    h = plot(x,y,'Color',map(c,:),'LineWidth',1); hold all
                                end
                                
                                switch stimtype
                                    case 'dCOS'
                                        set(h,'LineStyle','--')
                                    otherwise
                                        set(h,'LineStyle','-')
                                end
                                switch uSOA(s);
                                    case 0
                                        set(h,'Marker','o')
                                    case 200
                                        set(h,'Marker','*')
                                    case 800
                                        set(h,'Marker','s')
                                end
                            end
                            
                        end
                    end
                end
                
                if isempty(get(gca,'Children'))
                    close(fh)
                else
                    
                    if prefori == 0
                        idx = 999;
                    else
                        idx = prefori;
                    end
                    
                    plot(MONOCULAR(prefeye,idx).x,MONOCULAR(prefeye,idx).y,'-','Color',[0 0 0],'LineWidth',1); hold on;
                    
                    set(gca,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial');
                    legend(STR,'Location','Best')
                    if length(BRdatafile) > 1
                        title(sprintf('%s: %s',BRdatafile{1}(1:8), elabel),'interpreter','none')
                    else
                        title(sprintf('%s: %s',BRdatafile{i}, elabel),'interpreter','none')
                    end
                    ylabel('mean response (imp./s)')
                    if isempty(tmwin)
                        xlabel(sprintf('Contrast in EYE = %u for ORI = %u',prefeye, prefori))
                    else
                        xlabel(sprintf('Contrast in EYE = %u for ORI = %u\n win = %u to %u ms re:StimOn',prefeye, prefori,tmwin(1), tmwin(2)));
                    end
                    
                end
                
            end
        end
        
        if flag_plottimecourse
            figure
            % plot TC, PARAMS:
            soa = 0;
            stimcontrast = 1;
            uSTIM   = {'Binocular' 'dCOS' 'Monocular'};
            
            p = 0; clear h_plot
            for eye = 1:2
                for tilt = 1:2
                    p = p + 1;
                    h_plot(p) = subplot(2,2,p);
                    
                    prefori = uTilt(tilt);
                    prefeye  = uEye(eye);
                    
                    STR = []; strct = 0;
                    map = [0 0 1; 1 0 0; 0 0 0];
                    
                    for s = 1:length(uSTIM)
                        
                        stimtype = uSTIM{s};
                        switch stimtype
                            case {'Binocular' 'dCOS'}
                                if strcmp(stimtype,'Binocular')
                                    ori = prefori;
                                else
                                    ori = nanmedian(uTilt(uTilt~=prefori));
                                end
                                
                                I = STIM.s2_tilt == prefori & STIM.s2_eye == prefeye & ...
                                    STIM.s1_tilt == ori & ...
                                    STIM.s1_contrast == stimcontrast   & STIM.s2_contrast == stimcontrast & ...
                                    STIM.soa == soa;
                                
                            case 'Monocular'
                                I = (STIM.s1_tilt == prefori  & STIM.s1_eye == prefeye & ... % stim 1 params
                                    STIM.s1_contrast == stimcontrast  &  STIM.s2_contrast == 0) & ...
                                    STIM.soa == soa;
                        end
                        
                        obs = find(I);
                        if isempty(obs)
                            continue
                        end
                        
                        % get SDF
                        clear SDF TM
                        SDF = zeros(2500,length(obs));
                        TM  = [1:length(SDF)] - 251;
                        for tr = 1:length(obs)
                            uspk = SUA{obs(tr)};
                            if ~isempty(uspk)
                                [sdf, ~, tm] = spk2sdf(uspk,30000,20);
                                if length(sdf) > length(SDF) || ~isempty(setdiff(tm,TM))
                                    error('need to setup larger SDF matrix')
                                end
                                [~,idx,~] = intersect(TM,tm);
                                SDF(idx,tr) = sdf;
                            end
                        end
                        
                        h_line = plot(TM,mean(SDF,2),'Color',map(s,:)); hold on
                        strct = strct + 1;
                        STR{strct} = sprintf('%s, n = %u',stimtype, length(obs));
                        
                        
                        
                    end
                    
                    if p == 1
                        if length(BRdatafile) > 1
                            title(sprintf('%s: %s\nOri = %u, Eye = %u',BRdatafile{i}(1:8), elabel, prefori, prefeye),'interpreter','none')
                        else
                            title(sprintf('%s: %s\nOri = %u, Eye = %u',BRdatafile{i}, elabel, prefori, prefeye),'interpreter','none')
                        end
                    else
                        title(sprintf('Ori = %u, Eye = %u', prefori, prefeye))
                    end
                    legend(STR)
                    xlim([-200 1500])
                    
                end
                
            end
            ylimits = cell2mat(get(h_plot,'Ylim'));
            ylimits = [min(ylimits(:,1)) max(ylimits(:,2))];
            set(h_plot,'Box','off','TickDir','out','YColor',[0 0 0],'XColor',[0 0 0],'FontName','Arial',...
                'Ylim',ylimits);
        end
        
        
        
        if flag_SaveFigs
            if length(BRdatafile) > 1
                fullfigsavepath = sprintf('%s/%s_%s/',figsavepath,BRdatafile{1}(1:8), unitID);
            else
                fullfigsavepath = sprintf('%s/%s_%s/',figsavepath,BRdatafile{i}, unitID);
            end
                        
            if ~exist(fullfigsavepath,'dir')
                mkdir(fullfigsavepath)
            end
            
            figHandles = get(0,'Children');
            
            for f = 1:length(figHandles)
                h = figHandles(f);
                
                export_fig([fullfigsavepath filesep num2str(h.Number)], '-jpg', '-nocrop','-transparent',h)
                saveas(h,[fullfigsavepath filesep num2str(h.Number)],'fig')
                
            end
            close all
        end
        
        
        
        
        
    end
end













%
%                 s2_I = s2_tilt ~= uTilt(tilt) & s2_eye ~= uTilt(eye) ... % dominant eye and tilt
%
%                  I = s1_eye == eye & s1_tilt == uTilt(tilt) & s2_contrast == 0 & soa == 0;
%
%
%                     & s1_contrast == uContrast(c)...  % one line for each "other eye Contrast" so that x-axis can be "eye contrast"
%                     & soa == 800 & strcmp(STIM,uStim{s});
%
%                 [y err gstim] = grpstats(CRF(I), s2_contrast(I), {'mean','sem','gname'});
%
%                 if ~isempty(y)
%                     strct = strct + 1;
%                     str{strct} = sprintf('%s - %0.2f',uStim{s},uContrast(c));
%                     x =  str2double(gstim(:));
%                     %h = errorbar(x,y,err,'Marker','o','Color',map(c,:),'LineWidth',1.5); hold all
%                     h = plot(x,y,'Marker','o','Color',map(c,:),'LineWidth',1.5); hold all
%                     switch uStim{s}
%                         case 'Monocular'
%                             set(h,'LineWidth',2,'Color',[0 0 0])
%                         case 'dCOS'
%                             set(h,'LineStyle','--')
%                     end
%                 end
%             end
%         end
%         box off; set(gca,'TickDir','out');
%         legend(str,'Location','Best')
%         title(sprintf('%s: %s',BRdatafile, elabel),'interpreter','none')
%         ylabel('mean response')
%         %xlabel(sprintf('Contrast in EYE = %u for ORI = %u',uEye(ey), uTilt(t)))
%
%
%
%
%
%         figure
%        uStim     = unique(STIM);
%        uContrast = unique([s1_contrast s2_contrast]);
%
%        strct = 0; clear str
%        map = prism(6); map(3,:) = []; map = [0 0 0; flipud(map)];
%
%        for s = 1:length(uStim)
%            for c = 1:length(uContrast)
%
%                I = s2_tilt == 125 & s2_eye == 2 ... % dominant eye and tilt
%                    & s1_contrast == uContrast(c)...  % one line for each "other eye Contrast" so that x-axis can be "eye contrast"
%                    & soa == 800 & strcmp(STIM,uStim{s});
%
%                 [y err gstim] = grpstats(CRF(I), s2_contrast(I), {'mean','sem','gname'});
%
%                         if ~isempty(y)
%                             strct = strct + 1;
%                             str{strct} = sprintf('%s - %0.2f',uStim{s},uContrast(c));
%                             x =  str2double(gstim(:));
%                             %h = errorbar(x,y,err,'Marker','o','Color',map(c,:),'LineWidth',1.5); hold all
%                             h = plot(x,y,'Marker','o','Color',map(c,:),'LineWidth',1.5); hold all
%                             switch uStim{s}
%                                 case 'Monocular'
%                                     set(h,'LineWidth',2,'Color',[0 0 0])
%                                 case 'dCOS'
%                                     set(h,'LineStyle','--')
%                             end
%                         end
%            end
%        end
%         box off; set(gca,'TickDir','out');
%                 legend(str,'Location','Best')
%                 title(sprintf('%s: %s',BRdatafile, elabel),'interpreter','none')
%                 ylabel('mean response')
%                 %xlabel(sprintf('Contrast in EYE = %u for ORI = %u',uEye(ey), uTilt(t)))
%
%
%
%
%
%         % PLOT CRF for SOA = 0
%         uEye      = [2 3];
%         uTilt     = unique([s1_tilt s2_tilt]);
%         uStim     = unique(STIM);
%         uContrast = unique([s1_contrast s2_contrast]);
%
%         figure; p = 0;
%         for ey = 1:length(uEye)
%             for t = 1:length(uTilt)
%
%                 p = p+1;
%
%
%                 strct = 0; clear str
%                 map = prism(6); map(3,:) = []; map = [0 0 0; flipud(map)];
%
%                 for s = 1:length(uStim)
%                     for c = 1:length(uContrast)
%                         subplot(2,2,p)
%
%                         % one line for each "other eye Contrast" so that x-axis can be "eye contrast"
%                         s1I = s1_eye == uEye(ey) & s1_tilt == uTilt(t) & s1_contrast == uContrast(c) & soa == 0 & strcmp(STIM,uStim{s});
%                         s2I = s2_eye == uEye(ey) & s2_tilt == uTilt(t) & s2_contrast == uContrast(c) & soa == 0 & strcmp(STIM,uStim{s});
%
%                         [y err gstim] = grpstats([CRF(s1I);CRF(s2I)], [s2_contrast(s1I);s1_contrast(s2I)], {'mean','sem','gname'});
%
%                         if ~isempty(y)
%                             strct = strct + 1;
%                             str{strct} = sprintf('%s - %0.2f',uStim{s},uContrast(c));
%                             x =  str2double(gstim(:));
%                             %h = errorbar(x,y,err,'Marker','o','Color',map(c,:),'LineWidth',1.5); hold all
%                             h = plot(x,y,'Marker','o','Color',map(c,:),'LineWidth',1.5); hold all
%                             switch uStim{s}
%                                 case 'Monocular'
%                                     set(h,'LineWidth',2,'Color',[0 0 0])
%                                 case 'dCOS'
%                                     set(h,'LineStyle','--')
%                             end
%                         end
%
%
%                     end
%                 end
%                 box off; set(gca,'TickDir','out');
%                 legend(str,'Location','Best')
%                 title(sprintf('%s: %s',BRdatafile, elabel),'interpreter','none')
%                 ylabel('mean response')
%                 xlabel(sprintf('Contrast in EYE = %u for ORI = %u',uEye(ey), uTilt(t)))
%             end
%         end
%
%     end
%
%     end


%
%     figure
%     map = jet(2);
%     scatter3(prefContrast,nullContrast,CRF,[],map(dCOS+1,:))
%
%
%
% ahahah
%
%
%     figure('Position',[ 11         558        1904         420])
%     subplot(2,3,1)
%     plot(CRF);
%     axis tight; box off;
%     xlabel('stim prez')
%     ylabel('# of spikes')
%     title(elabel)
%
%     subplot(2,3,2)
%     hist(CRF);
%     box off;
%     xlabel('# of spikes')
%     ylabel('frequency')
%
%     subplot(2,3,3)
%     plot(mean(WAVE,2),'-'); hold on
%     plot(mean(WAVE,2)+ std(WAVE,[],2),':'); hold on
%     plot(mean(WAVE,2)- std(WAVE,[],2),':'); hold on
%     xlabel('waveform')
%     axis tight; box off
%
%     subplot(2,3,4)
%     CRF
%
%
%     %     boxplot(r,tilt)
% %     p=anovan(r,tilt','display','off');
%     title(sprintf('p = %0.3f,',p))
%     xlabel(group)
%     ylabel('# of spikes')
%     axis tight; box off;
%
%
%     subplot(2,3,5)
%     theta = deg2rad(tilt(eye==EYE));
%     roh = CRF(eye==EYE);
%
%     polar(theta, roh,'bx'); hold on
%     polar(theta+pi, roh,'bx'); hold on
%     [uRoh mRoh uTheta n] = grpstats(roh, theta, {'mean','median','gname','numel'});
%     uTheta = str2double(uTheta);
%     polar(uTheta, uRoh,'r.'); hold on
%     polar(uTheta+pi, uRoh,'r.'); hold on
%     polar(uTheta, mRoh,'go'); hold on
%     polar(uTheta+pi, mRoh,'go'); hold on
%     title(sprintf('n = [%u %u]',min(n), max(n)))
%     axis tight; axis square; box off;
%
%     subplot(2,3,6)
%     clear x y f
%     [uR sR uTilt n] = grpstats(CRF(eye==EYE), tilt(eye==EYE), {'mean','sem','gname','numel'});
%     y = uR;
%     x = cellfun(@(x) str2num(x),uTilt);
%     y = [y; y];
%     x = [x ; x+180];
%     f = fit(x,y,'smoothingspline');
%     plot(f,x,y); hold on
%     errorbar(x,y,[sR; sR],'linestyle','none'); hold on
%     axis tight; axis square; box off; legend('off')
%     plot([180 180],ylim,'k:');
%
%
%
%



%%
% figure;
% subplot(1,2,1)
% plot(R);
% axis tight; box off;
% subplot(1,2,2)
% hist(R);
% axis tight; box off;
% title(elabel)
%
%
%
%
%


