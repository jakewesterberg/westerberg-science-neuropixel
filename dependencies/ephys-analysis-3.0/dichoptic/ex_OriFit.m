% June 26, 2017


clear;
didir    = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Aug24/';
load([didir 'IDX_Oct7a.mat'],'IDX');
PEN = unique({IDX.penetration});

for ip = find(strcmp(PEN,'170724_I_eD'))% 1:length(PEN)
    clearvars -except PEN ip IDX didir
    
    
    penetration  = PEN{ip};
    pre          = 0.35; % s
    
    nevdir   = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';
    klsdir   = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';
    
    % extrack all units with significant ori tuning on this penetration
    clear  matobj
    matobj       = matfile([didir penetration '_KLS.mat']);
    ori = [IDX.ori];
    units = find(...
        strcmp({IDX.penetration},penetration)...
        & [IDX.kls] == 1 & [IDX.oriana] == 1 ...
        & ori(1,:) < 0.05);
    
    clear STIM; X = [];
    STIM = matobj.STIM;
    for un = 1:length(units)
        
        % reverse engineer value of "e" so that you can loook at response
        % see diIDX.m
        
        clear e
        e = IDX(units(un)).depth(1)+1;
        elabel = STIM.el_labels{e};
        
        clear *RESP*
        RESP = squeeze(matobj.RESP(e,4,:));
        
        kls = 1;
        clear goodfiles allfiles
        allfiles = 1:length(STIM.filelist);
        if ~kls
            goodfiles = allfiles;
        else
            goodfiles = find(~isnan(STIM.clusters(e,:)));
            if isempty(goodfiles)
                continue
            elseif ~isequal(goodfiles,allfiles)...
                    && length(goodfiles)>1 ...
                    && any(diff(goodfiles) > 1)
                goodfiles = unique(STIM.filen(ismember(STIM.filen, goodfiles) & STIM.ditask));
            end
        end
        if any(diff(goodfiles) > 1)
            %error('check goodfiles')
            continue %DEV: need to figure out a way to slavage
        end
        
        % Determin Neuron's Orientation Tuning
        clear I varnames
        I = (STIM.monocular | STIM.dioptic) ...
            & STIM.adapted == 0 ...
            & STIM.blank == 0 ...
            & STIM.rns == 0 ...
            & STIM.cued == 0 ...
            & STIM.motion == 0 ...
            & ismember(STIM.filen,goodfiles);
        varnames = {'eye';'tilt';'contrast';'sf';'phase';'xpos';'ypos';'diameter';'gabor'};
        clear doesvary values temp
        doesvary = true(size(varnames));
        values = cell(size(varnames));
        temp = nan(length(I),length(varnames));
        for v = 1:length(varnames)
            x = STIM.(varnames{v})(I,1);
            if all(isnan(x)) || length(nanunique(x))==1
                doesvary(v) = false;
            else
                temp(:,v) = STIM.(varnames{v})(:,1);
                values{v} = (nanunique(x))';
            end
        end
        
        twoeyes = true;
        if any(strcmp(varnames(doesvary),'tilt'))
            values   = values(doesvary & ~strcmp(varnames,'tilt'));
            temp     = temp(:,doesvary & ~strcmp(varnames,'tilt'));
            clear combinations TRLS
            combinations = combvec(values{:})';
            TRLS = cell(size(combinations,1),3);
            for c = 1:size(combinations,1)
                trls = find(ismember(temp,combinations(c,:),'rows')');
                TRLS{c,1} = trls;
                TRLS{c,2} = length(unique(STIM.tilt( trls,1)));
                TRLS{c,3} = nanvar(RESP(trls));
            end
            keep = cellfun(@(x) x>=5,TRLS(:,2));
            combinations = combinations(keep,:);
            TRLS = TRLS(keep,:);
            if ~isempty(TRLS)
                if size(TRLS,1) == 1
                    twoeyes = false;
                else
                    [~,mI]=max([TRLS{:,3}]);
                    val = combinations(mI,:);
                    if val(1) == 1
                        twoeyes = false;
                    elseif val(1) == 2
                        val(1) = 3;
                    elseif val(1) == 3
                        val(1) = 2;
                    end
                    trlidx = find(ismember(combinations,val,'rows')');
                    if isempty(trlidx)
                        twoeyes = false;
                    else
                        eTRLS = TRLS(trlidx,:);
                    end
                    TRLS = TRLS(mI,:);
                end
                
                for eyr = 1:twoeyes+1
                    if eyr == 1
                        TRLS = TRLS;
                    else
                        TRLS = eTRLS;
                    end
                    % test for a significant main effect of tilt, also find theta
                    tilt_p = anovan(RESP(TRLS{1}),STIM.tilt(TRLS{1})','display','off');
                    [u,s,theta] = grpstats(RESP(TRLS{1}),STIM.tilt(TRLS{1}),{'mean','sem','gname'});
                    theta = str2double(theta);
                    % find peak theta,
                    clear mi peak
                    [~,mi]=max(u);
                    peak = theta(mi);
                    % reshape data so that peak is in middle
                    clear x y grange
                    x = wrapTo180([theta-peak theta-peak+180]);
                    y = [u u];
                    z = [s s];
                    grange = find(x >= -90  & x <= 90) ;
                    x = x(grange); y = y(grange); z = z(grange);
                    [x,idx] = sort(x); y = y(idx); z = z(idx);
                    % get rid of NaN
                    x(isnan(y)) = []; z(isnan(y)) = []; y(isnan(y)) = []; 
                    % fit x and y with gauss, save gauss params
                    clear gparam
                    [gparam,~] = gaussianFit(x,y,false); % gparam = mu sigma A
                    xf = min(x):max(x);
                    yf = gparam(3,1).*exp(-((xf-gparam(1,1)).^2)./(2*gparam(2,1)^2));
                    
                    
                    % save for later
                    if eyr == 1
                        X(un).x = x;
                        X(un).y = y;
                        X(un).e = z;
                        X(un).xf = xf;
                        X(un).yf = yf;
                        X(un).gparam  = gparam;
                        X(un).peak    = peak;
                        X(un).eye    = combinations(mI,1);
                        X(un).tilt_p  = round(tilt_p,3);
                        X(un).twoeyes  = twoeyes;
                        
                        % bookkeeping
                        X(un).idx    = units(un);
                        X(un).elabel = elabel;
                        X(un).depth = IDX(units(un)).depth;
                        X(un).goodfiles = goodfiles;
                        X(un).clusters = STIM.clusters(e,goodfiles);
                        X(un).filelist = STIM.filelist{goodfiles};
                        X(un).bestfile = STIM.filelist{mode(STIM.filen(TRLS{1}))};
                        X(un).bestclust = STIM.clusters(e,mode(STIM.filen(TRLS{1})));
                        
%                         obs = find(STIM.filen == mode(STIM.filen(TRLS{1})));
%                         X(un).besttrls  = unique(STIM.trl(intersect(TRLS{1},obs)));
%                         
                    else
                        X(un).x2 = x;
                        X(un).y2 = y;
                        X(un).e2 = z;
                        X(un).xf2 = xf;
                        X(un).yf2 = yf;
                        X(un).gparam2  = gparam;
                        X(un).peak2    = peak;
                        X(un).tilt_p2  = round(tilt_p,3);
                    end
                    if ~twoeyes
                        X(un).x2 = NaN;
                        X(un).y2 = NaN;
                        X(un).e2 = NaN;
                        X(un).xf2 = NaN;
                        X(un).yf2 = NaN;
                        X(un).gparam2  = NaN;
                        X(un).peak2    = NaN;
                        X(un).tilt_p2  = NaN;
                    end
                    
                end
            end
        end
    end
    if isempty(X) || ~any([X.twoeyes])
        continue
    end
    X =  X([X.twoeyes]);
    
    
    %%
    
    
    
    TuneList = importTuneList; clear s
    s = strcmp(TuneList.Penetration,penetration);
    
    clear sortdirection penetraton
    sortdirection = TuneList.SortDirection{s};
    
    clear drobo
    switch TuneList.Drobo(s)
        case 1
            drobo = 'Drobo';
        otherwise
            drobo = sprintf('Drobo%u',TuneList.Drobo(s));
    end
    %%
    for un = 2%1:length(X)
        if isempty(X(un))
            continue
        end
        
        clear filename cluster
        [~,filename,~] = fileparts(X(un).bestfile);
        cluster = X(un).bestclust;
        
        clear brfile nevfile klsfile dotfile rffile
        ns6file  = sprintf('/Volumes/%s/Data/NEUROPHYS/rig%03u/%s_%s/%s.ns6',...
            drobo,TuneList.Rig(s),TuneList.Datestr{s},TuneList.Monkey{s},filename);
        nevfile  = [nevdir filename '.ppnev'];
        klsfile  = [klsdir filename filesep 'ss.mat'];
        
        clear grating*
        if ~isempty(strfind(filename,'ori'))
            ext = '.gRFORIGrating_di';
        elseif ~isempty(strfind(filename,'sf'))
            ext = '.gRFSFGrating_di';
        elseif  ~isempty(strfind(filename,'size'))
            ext = '.gRFSIZEGrating_di';
        else
            continue
        end
        gratingfile = sprintf('/Volumes/%s/Data/NEUROPHYS/rig%03u/%s_%s/%s%s',...
            drobo,TuneList.Rig(s),TuneList.Datestr{s},TuneList.Monkey{s},filename,ext);
        grating = readgGrating(gratingfile);
        ypos = mode(grating.ypos);
        
        clear NS_Header ss ppNEV NEV
        NS_Header = openNSx(ns6file,'noread');
        load(klsfile,'ss');
        load(nevfile,'-mat'); NEV = ppNEV; clear ppNEV
        
        clear EventSampels EventCodes pEvC pEvT
        EventSampels = NEV.Data.SerialDigitalIO.TimeStamp;
        EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
        [pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);
        [pEvT_photo,phototrigger] = pEvtPhoto(ns6file,pEvC,pEvT,ypos,[],[],0,'constant');
        
        % NS6
        clear e electrode Fs NS DAT
        e = find(strcmp(cellfun(@(x) x(1:4), {NS_Header.ElectrodesInfo.Label},'UniformOutput',0),elabel));
        electrode = sprintf('c:%u',e);
        NS = openNSx(ns6file,electrode,'read');
        DAT = double(NS.Data)'; clear NS
        % filter
        nsFs = double(NS_Header.MetaTags.SamplingFreq);
        nyq = nsFs/2;
        hpc = 750;  %high pass cutoff
        hWn = hpc/nyq;
        [bwb,bwa] = butter(4,hWn,'high');
        DAT = abs(filtfilt(bwb,bwa,DAT));
        DAT = DAT ./ 4;
        
        %NEV
        clear nI
        nI = find(strcmp(cellfun(@(x) x(1:4), {NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0),elabel));
        
        %KLS
        % - cluster set above
        
        
        %% get example tial
        
        trlopt = grating.trial(...
              grating.tilt == X(un).peak...
            & grating.eye  == X(un).eye);
        if isempty(trlopt)
            continue
        end
        trlopt = randsample(trlopt,length(trlopt));
        for o = 1:length(trlopt)
            t = trlopt(o);
            rewarded = any(pEvC{t}==96);
            if rewarded
                break
            end
        end
        if ~rewarded
            continue
        end
        
        
        
        clear eye tilt sf dot_*
        dot_x = grating.xpos(grating.trial == t);
        dot_y = grating.ypos(grating.trial == t);
        dot_d = grating.diameter(grating.trial == t);
        eye = grating.eye(grating.trial == t);
        tilt = grating.tilt(grating.trial == t);
        sf = grating.sf(grating.trial == t);
        
        clear stimon stimoff start finish
        stimon  =  pEvC{t} == 23 | pEvC{t} == 25  | pEvC{t} == 27   | pEvC{t} == 29  | pEvC{t} == 31;
        stimoff =  pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32;
        start  = pEvT_photo{t}(stimon);
        finish = pEvT_photo{t}(stimoff);
        
        % photodiode triggering
        TP = [start finish];
        [newTP,trigger] = photoReTrigger(TP,gratingfile(1:end-17),nanmean(grating.ypos),'default');
        start = newTP(:,1);
        finish =  newTP(:,2);
        
        clear st en
        st = start(1)    - pre*nsFs;
        en = finish(end) + pre*nsFs;
        
        
        figure('Unit','Inches','Position',[0 0 8.5 11]);
        for p = 1:length(start)
            subplot(7,5,p+10)
            center = [dot_x(p), dot_y(p)];
            width  = [dot_d(p),dot_d(p)];
            rec    = [center - width./2 width];
            rectangle('Position',rec,'Curvature',[1 1]);
            text(center(1),center(2),sprintf('%u\n%0.2f^o\n%0.2f',eye(p),tilt(p),sf(p)),...
                'HorizontalAlignment','center');
            axis equal
            set(gca,'Box','off','TickDir','out')
            
        end
        
        
        datatype = {'SUA','dMUA','aMUA'};
        for d = 1:3
            clear y sy tm k R Fs x
            
            switch datatype{d}
                case 'aMUA'
                    % NS6
                    
                    tm = (-pre*nsFs:en-start(1)) ;  %samples
                    k = jnm_kernel( 'psp', (20/1000) * nsFs );
                    
                    y     = (DAT(st:en) - mean(DAT(st:start(1)))) ./ 1000;
                    ystr = ('Delta mV');
                    
                    Fs   = nsFs;
                    
                case 'dMUA'
                    
                    R = 30;
                    
                    tm = (-pre*nsFs:R:en-start(1)) ./ R;  %samples
                    k = jnm_kernel( 'psp', (20/1000) * nsFs/R );
                    
                    y   = zeros(size(tm));
                    I   =  NEV.Data.Spikes.Electrode == nI;
                    SPK = double(NEV.Data.Spikes.TimeStamp(I));
                    x   = SPK - start(1);
                    x   = unique(round( x ./R ));
                    [~,ii]=intersect(tm,x,'stable');
                    y(ii) = 1;
                    
                    ystr = 'imp/s';
                    Fs   = nsFs/R;
                    
                case 'SUA'
                    
                    R = 1;
                    
                    tm = (-pre*nsFs:R:en-start(1)) ./ R;  %samples
                    k = jnm_kernel( 'psp', (20/1000) * nsFs/R );
                    
                    y   = zeros(size(tm));
                    I   =  ss.spikeClusters == cluster;
                    SPK = ss.spikeTimes(I);
                    x   = SPK - start(1);
                    x   = unique(round( x ./R ));
                    [~,ii]=intersect(tm,x,'stable');
                    y(ii) = 1;
                    
                    ystr = 'imp/s';
                    Fs   = nsFs/R;
            end
            
            % convert tm to seconds
            tm = tm ./ Fs; % seconds
            
            
            % convolve
            clear sy
            sy    = doConv(y,k) * Fs;
            
            subplot(7,1,d+3)
            plot(tm,sy); hold on; axis tight;
            set(gca,'Box','off','TickDir','out')
            
            if any(strcmp({'dMUA','SUA'},datatype{d})) && any(y)
                plot(tm(y==1),min(ylim),'+','color',[0 .4 0])
            end
            
            ystr = sprintf('%s\n%s',datatype{d},ystr);
            ylabel(ystr)
            
        end
        
        subplot(7,1,d+3+1)
        clear stimon stimoff stimulus tm
        tm = (-pre*nsFs:en-start(1)) / nsFs;  %s
        stimon  = (start  - start(1)) / nsFs;
        stimoff = (finish - start(1)) / nsFs;
        stimulus = zeros(size(tm));
        for p = 1:length(stimoff)
            clear ii
            ii = tm >= stimon(p) & tm <= stimoff(p);
            stimulus(ii) = 1;
        end
        plot(tm,stimulus); axis tight; ylim([0 1.3])
        set(gca,'Box','off','TickDir','out')
        xlabel('t(s)')
        ylabel(sprintf('Stimulus\non/off'))
        
        
        if isempty(ss.spikeWaves)
            load(klsfile,'WAVE','tmW');
            ss.spikeWaves = WAVE; clear WAVE
            ss.spikeWavesTM = tmW; clear tmW
        end
        cI   =  ss.spikeClusters == cluster;
        kI   = strcmp(ss.chanIDs,X(un).elabel);
        wave = squeeze(nanmean(ss.spikeWaves(kI,:,cI),3));
        err  = squeeze(nanstd(ss.spikeWaves(kI,:,cI),[],3)) ./ sqrt(sum(cI));
        subplot(7,5,[1 6]); cla
        ph = plot(ss.spikeWavesTM,wave-wave(1)); hold on
        plot(ss.spikeWavesTM,wave-err-wave(1),':','color',get(ph,'color')); hold on
        plot(ss.spikeWavesTM,wave+err-wave(1),':','color',get(ph,'color')); hold on
        axis tight;
        set(gca,'Box','off','TickDir','out')
        
        title(sprintf('%s_u%02u\ntrl = %u, l4d = %d',filename,un,t,X(un).depth(2)),'interpreter','none')
        
        
        if ~X(un).twoeyes
            subplot(7,5,[2:5 7:9]); cla
            eh = errorbar(X(un).x,X(un).y,X(un).e,'o');
            hold on;
            plot(X(un).xf,X(un).yf,'color','g');%get(ph,'color'))
            axis tight;
            set(gca,'Box','off','TickDir','out')
           try
                f = fit(X(un).x,X(un).y,'gauss2');
                plot(f);
                legend off; ylabel(''); xlabel('')
                 title(sprintf('Ori Max = %0.2f (p = %0.3f)\nGauss1 = [%0.1f %0.1f %0.1f]\nGauss2 = [%0.1f %0.1f %0.1f] + [%0.1f %0.1f %0.1f]',...
                X(un).peak,X(un).tilt_p,...
                X(un).gparam(3),X(un).gparam(1),X(un).gparam(2),...
                f.a1,f.b1,f.c1,f.a2,f.b2,f.c2));
            
            catch
                 title(sprintf('Ori Max = %0.2f (p = %0.3f)\nGauss1 = [%0.1f %0.1f %0.1f]\nGauss2 = [%0.1f %0.1f %0.1f] + [%0.1f %0.1f %0.1f]',...
                X(un).peak,X(un).tilt_p,...
                X(un).gparam(3),X(un).gparam(1),X(un).gparam(2),...
                0, 0, 0, 0, 0, 0));
            end
        else
            
            subplot(7,5,[2:3 7:8]); cla
            eh = errorbar(X(un).x,X(un).y,X(un).e,'o');
            hold on;
            plot(X(un).xf,X(un).yf,'color','g');%get(ph,'color'))
            axis tight;
            set(gca,'Box','off','TickDir','out')
            try
                f = fit(X(un).x,X(un).y,'gauss2');
                plot(f);
                legend off; ylabel(''); xlabel('')
                 title(sprintf('Ori Max = %0.2f (p = %0.3f)\nGauss1 = [%0.1f %0.1f %0.1f]\nGauss2 = [%0.1f %0.1f %0.1f] + [%0.1f %0.1f %0.1f]',...
                X(un).peak,X(un).tilt_p,...
                X(un).gparam(3),X(un).gparam(1),X(un).gparam(2),...
                f.a1,f.b1,f.c1,f.a2,f.b2,f.c2));
            
            catch
                 title(sprintf('Ori Max = %0.2f (p = %0.3f)\nGauss1 = [%0.1f %0.1f %0.1f]\nGauss2 = [%0.1f %0.1f %0.1f] + [%0.1f %0.1f %0.1f]',...
                X(un).peak,X(un).tilt_p,...
                X(un).gparam(3),X(un).gparam(1),X(un).gparam(2),...
                0, 0, 0, 0, 0, 0));
            end
            alim = axis; 
            
           
            
            subplot(7,5,[4:5 9:10]); cla
            eh = errorbar(X(un).x2,X(un).y2,X(un).e2,'o');
            hold on;
            plot(X(un).xf2,X(un).yf2,'color','g');%get(ph,'color'))
            axis(alim);
            set(gca,'Box','off','TickDir','out')
            try
                f = fit(X(un).x2,X(un).y2,'gauss2');
                plot(f);
                legend off; ylabel(''); xlabel('')
                 title(sprintf('Ori Max = %0.2f (p = %0.3f)\nGauss1 = [%0.1f %0.1f %0.1f]\nGauss2 = [%0.1f %0.1f %0.1f] + [%0.1f %0.1f %0.1f]',...
                X(un).peak,X(un).tilt_p,...
                X(un).gparam(3),X(un).gparam(1),X(un).gparam(2),...
                f.a1,f.b1,f.c1,f.a2,f.b2,f.c2));
            
            catch
                 title(sprintf('Ori Max = %0.2f (p = %0.3f)\nGauss1 = [%0.1f %0.1f %0.1f]\nGauss2 = [%0.1f %0.1f %0.1f] + [%0.1f %0.1f %0.1f]',...
                X(un).peak,X(un).tilt_p,...
                X(un).gparam(3),X(un).gparam(1),X(un).gparam(2),...
                0, 0, 0, 0, 0, 0));
            end
            
            
        end
        
    end
end


%%

%
%
% load(tunefile);
% datatype = {'mua_raw','nev_raw','kls_raw'};
%
% % find max N eye
% E = 1:3;
% n = hist(STIM.eye,E);
% [~,mi]=max(n);
% E = E(mi);
%
% figure
%
% eI = STIM.eye == E;
% trln = length(STIM.xpos);
% clear STIM2
%
% fields = fieldnames(STIM);
% for f = 1:length(fields);
%     if ~isempty(strfind(fields{f},'evp'))
%         continue
%     elseif any(size(STIM.(fields{f})) == trln)
%         STIM2.(fields{f}) = STIM.(fields{f})(:,eI);
%     else
%         STIM2.(fields{f}) = STIM.(fields{f});
%     end
% end
%
% I = strcmp(STIM.elabel,elabel);
% for flag_norm = 0:1
%     for d = 1:3
%
%         if flag_norm
%             STIM2 = normTune(STIM2,datatype{d},'within');
%             ndatatype = ['nrm_' datatype{d}];
%         else
%             ndatatype = datatype{d};
%         end
%
%         clear uSTIM PEAKS GAUSS
%         [uSTIM,PEAKS]= meanTune(STIM2,ndatatype,{elabel});
%         GAUSS = fitTune(uSTIM);
%
%         x = uSTIM.t(1,:);
%         y = uSTIM.u(I,:);
%         e = uSTIM.e(I,:);
%
%         xf = min(x):0.1:max(x);
%         p = GAUSS(I,2:4);
%         yf = p(3).*exp(-((xf-p(1)).^2)./(2*p(2)^2));
%
%         subplot(2,3,d + 3*flag_norm)
%
%         plot(x,y,'d'); hold on
%         plot(xf,yf)
%
%         title(sprintf('%s\n0 = %0.1f deg',ndatatype,uSTIM.peakT),'interpreter','none')
%         set(gca,'Box','off','TickDir','out')
%         h=text(mean(xlim),min(ylim),sprintf('[%0.2f %0.2f %0.2f]',p),...
%             'VerticalAlignment','bottom',...
%             'HorizontalAlignment','center');
%
%     end
% end
