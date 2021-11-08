clear

varsavepath  = sprintf('/Volumes/Drobo2/USERS/Michele/Dichoptic/DiStim_AutoNev_Aug09/')
flag_checkforexisting = true

alignvar = '/Volumes/Drobo2/USERS/Michele/Dichoptic/V1Limits_Aug10/ALIGN.mat';

autodir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';
sortdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';

paradigm = {... %evp
    'rfori','rfsf',...'rfsize',...
    'drfori','rfsfdrft',...
    'cosinteroc','mcosinteroc','brfs'}; % dev:RSVP

alpha = 0.05;
delta_tilt = 20;

Fs = 30000;
k = jnm_kernel( 'psp', (20/1000) * Fs );
win       = [75 125]; %ms

TuneList = importTuneList(1);
load(alignvar,'ALIGN');

if ~exist(varsavepath,'dir')
    mkdir(varsavepath);
end

skipct = 0; SKIPPED ={};
uct = 0; clear IDX
for s = length(TuneList.Penetration):-1:0 %length(TuneList.Penetration)-1
    
    
    % check for correct di tasks
    if isempty(TuneList.('brfs'){s}) && ...
            isempty(TuneList.('mcosinteroc'){s}) && ...
            isempty(TuneList.('cosinteroc'){s});% && ... isempty(TuneList.('rsvp'){s});
        continue
    end
    
    s
    clear penetration  header el sortdirection V1
    penetration = TuneList.Penetration{s}
    header = TuneList.Penetration{s}(1:end-3);
    el     = TuneList.Penetration{s}(end-1:end);
    sortdirection = TuneList.SortDirection{s};
    V1 = TuneList.Structure{s};
    
    if strcmp(header,'161005_E')
        disp('skipping 161005_E b/c of BHV issues')
        continue
    elseif strcmp(header,'170724_I')
        disp('skipping b/c of NEV v NS6 issue');
        continue
    elseif strcmp(header,'160204_I')
        disp('skipping b/c issue with phototrgger');
        continue
    end
    
    % check for var on disk
    if  flag_checkforexisting && exist([varsavepath penetration '.mat'],'file')
        % found on disk
        loadedfromsaved = 1;
        fprintf('\nfound on disk, loading...')
        load([varsavepath penetration '.mat'],...
            'STIM','rparadigm','rwin','RESP',...
            'PSTH','bintm','bin_sp','SDF','sdftm','depths')
        if ~isequal(rwin,win)
            disp('loaded from disk, but rwin is diffrent from win')
        elseif ~isequal(rparadigm,paradigm)
            disp('loaded from disk, but rparadigm is diffrent from paradigm')
        end
        ninside = size(RESP,1);
        diori = nanunique(STIM.tilt(STIM.ditask==1,:));
        fprintf('done!\n')
        
    else
        % run triggering analysis
        loadedfromsaved = 0;
        clear drobo
        switch TuneList.Drobo(s)
            case 1
                drobo = 'Drobo';
            otherwise
                drobo = sprintf('Drobo%u',TuneList.Drobo(s));
        end
        
        % build session filelist
        ct = 0; filelist = {};
        for p = 1:length(paradigm)
            if strcmp(paradigm{p},'rsvp')
                tf =     strcmp('color', getRSVPTaskType(TuneList.Datestr{s}));
                if ~tf
                    continue
                end
            end
            clear experiment
            experiment = TuneList.(paradigm{p}){s};
            for d = 1:length(experiment)
                ct = ct + 1;
                filelist{ct,1} = sprintf('/Volumes/%s/Data/NEUROPHYS/rig%03u/%s_%s/%s_%s_%s%03u',...
                    drobo,TuneList.Rig(s),TuneList.Datestr{s},TuneList.Monkey{s},TuneList.Datestr{s},TuneList.Monkey{s},paradigm{p},experiment(d));
            end
        end
        
        clear STIM diori
        STIM = getDiTPs(filelist,V1);
        diori = nanunique(STIM.tilt(STIM.ditask==1,:));
        
    end
    
    % file checks (for both loaded and created STIM files)
    % 1: check for correct tasks / params
    if ~any(STIM.ditask==1)
        skipct = skipct+1
        SKIPPED{skipct,1} = STIM.header;
        SKIPPED{skipct,2} = 'no STIM.ditask==1';
        continue
    elseif length(diori) ~= 2
        skipct = skipct+1
        SKIPPED{skipct,1} = STIM.header;
        SKIPPED{skipct,2} = 'length(diori) ~= 2';
        continue
    end
    % 2: check for monocular conditions in dioptic tasks
    % (will cause early sessions to fail)
    clear M
    for eye = 2:3
        for ori = 1:2
            M(eye-1,ori) = sum(...
                STIM.eye == eye & ...
                STIM.tilt(:,1) == diori(ori) & ...
                STIM.ditask & ~STIM.adapted & STIM.monocular);
        end
    end
    if any(M < 5)
        skipct = skipct+1
        SKIPPED{skipct,1} = STIM.header;
        SKIPPED{skipct,2} = 'di tasks does not contain monocular trials';
        continue
    end
    % 3: check that TPs can be retriggered w/ photodiode
    if ~isfield(STIM,'tp_pt')
        % re-trigger TPs
        photoTP  = nan(size(STIM.tp_sp));
        didskip  = 0;
        for filen = 1:length(filelist)
            
            clear filename BRdatafile
            filename  = STIM.filelist{filen};
            
            clear I newTP trigger
            I = STIM.filen == filen;
            [newTP,trigger] = photoReTrigger(...
                STIM.tp_sp(I,:),...
                filename,...
                STIM.ypos(I,:));
            if isempty(newTP)
                didskip = 1;
                continue
            else
                photoTP(I,:) = newTP;
            end
        end
        if didskip
            skipct = skipct+1
            SKIPPED{skipct,1} = STIM.header;
            SKIPPED{skipct,2} = 'fail of photodiode trigger';
            continue
        end
        STIM.tp_pt = photoTP; clear photoTP
    end
    
    
    % return to interation if file was not on disk
    if ~loadedfromsaved
        
        
        % setup depth / alignment
        clear  align v1lim l4_idx in_labels l4_labels depths ninside
        align = ALIGN(strcmp({ALIGN.name},penetration));
        rflim = [align.rftop align.rftop] ;
        if any(isnan(rflim)) || diff(rflim) < 10
            v1lim = [align.stimtop align.stimbtm];
        else
            v1lim = [...
                ceil( nanmean([align.rftop align.stimtop]))...
                floor(nanmean([align.rfbtm align.stimbtm]))...
                ];
        end
        if strcmp(header(end),'I') && length(align.elabel)==32
            v1lim(v1lim>31) = 31;
        end
        in_labels = align.elabel(v1lim(1):v1lim(2));
        l4_labels = align.elabel(align.l4i-5:align.l4i);
        l4_idx    = [-5 0]+find(strcmp(in_labels,align.l4l));
        ninside   = length(in_labels);
        depths = [0:ninside-1; -1*((0:ninside-1) - l4_idx(end)); ninside-1:-1:0]';
        
        % prepare to iterate trials - MUA RESP
        RESP      = nan(ninside,length(STIM.trl));
        
        sdftm     = [-0.3*Fs: 0.15*Fs + max(diff(STIM.tp_sp,[],2))];
        SDF       = nan(ninside,length(sdftm),length(STIM.trl));
        
        bin_sp    = 0.01*Fs;
        bintm     = [sdftm(1) : bin_sp : sdftm(end) + bin_sp];
        PSTH      = nan(ninside,length(bintm),length(STIM.trl));
        
        % iterate trials, loading files as you go
        for i = 1:length(STIM.trl)
            
            if i == 1 || STIM.filen(i) ~= filen;
                
                clear filen filename BRdatafile
                filen = STIM.filen(i);
                filename  = STIM.filelist{filen};
                [~,BRdatafile,~] = fileparts(filename);
                
                % get SPK from auto file
                clear autofile NEV nev_labels nix SPK
                autofile = [autodir BRdatafile '.ppnev'];
                load(autofile,'-MAT','ppNEV');
                NEV = ppNEV; clear ppNEV;
                nev_labels  = cellfun(@(x) x(1:4)',{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0);
                [~,~,nix]=intersect(in_labels,nev_labels,'stable');
                SPK = cell(length(nix),1);
                for e=1:length(nix)
                    SPK{e,1} = NEV.Data.Spikes.TimeStamp(NEV.Data.Spikes.Electrode == nix(e));
                end
                
            end
            
            % back to interating trials
            clear tp
            tp = STIM.tp_pt(i,:) ;
            if any(isnan(tp))
                continue
            end
            
            % single value over pre-set window
            clear spk rwin
            rwin = tp(1) + (win/1000*Fs);
            spk = cellfun(@(x) sum(x>=rwin(1) & x<=rwin(2)),SPK) ;
            RESP(:,i) = spk ./ (diff(rwin) / Fs);
            
            for e = 1:length(SPK);
                clear spk sua psth sdf;
                [spk,idx,~] = intersect(sdftm,SPK{e} - tp(1),'stable') ;
                if ~isempty(spk)
                    psth = histc(spk,bintm) .* (Fs/bin_sp);
                    PSTH(e,bintm<=diff(tp),i) = psth(bintm<=diff(tp));
                    
                    sua = zeros(size(sdftm));
                    sua(idx) = 1;
                    sdf = conv(sua,k,'same') * Fs;
                else
                    sdf = zeros(diff(tp),1);
                end
                sdf(sdftm > diff(tp)) = [];
                SDF(e,1:length(sdf),i) = sdf;
            end
        end % done iterating trials
        
        % remove last bin (inf) and center time vector
        PSTH(:,end,:) = [];
        bintm(end) = [];
        bintm = bintm + bin_sp/2;
        
        % convert time vectors to seconds
        sdftm = sdftm./Fs;
        bintm = bintm./Fs;
        
        % trim SDF of convolution extreams %MAY NEED DEV
        trim = sdftm < -0.15 | sdftm > sdftm(end) -0.15;
        sdftm(trim) = [];
        SDF(:,trim,:) = [];
        
        % trim PSTH to match
        trim = bintm < -0.15 | bintm > bintm(end) -0.15;
        bintm(trim) = [];
        PSTH(:,trim,:) = [];
        
        %SAVE!
        fprintf('\nsaving...')
        clear rwin rparadigm
        rwin = win; rparadigm = paradigm;
        save([varsavepath penetration '.mat'],...
            'STIM','rparadigm','rwin','RESP',...
            'PSTH','bintm','bin_sp','SDF','sdftm','k',...
            'align', 'v1lim','l4_idx', 'in_labels', 'depths',...
            '-v7.3')
        fprintf('done!\n')
    end
    %%
    
    % ORI tuning
    clear I gname group  remove  result
    I = (strcmp(STIM.task,'rfori') | strcmp(STIM.task,'rfsf'))...
        & ~STIM.blank;
    varnames = {...
        'tilt';'eye';'sf';'phase';'contrast';...
        'xpos';'ypos';'diameter';'gabor'};
    gname = varnames;
    group = cell(1,length(gname));
    for g = 1:length(gname)
        x = STIM.(gname{g})(I,1);
        if all(isnan(x)) || length(nanunique(x))==1
            continue
        end
        group{g} = STIM.(gname{g})(I,1);
    end
    remove = cellfun(@isempty,group);
    gname(remove) = [];
    group(remove) = [];
    if ~any(strcmp(gname,'tilt'))
        error('no tilts?')
    end
    
    clear gauss  result
    result = nan(ninside,length(varnames));
    gauss  = nan(ninside,6);
    for e = 1:size(RESP,1)
        
        clear dat anp p *sig_* u theta g gparam
        dat  = RESP(e,I);
        anp = anovan(dat,group,'varnames',gname,'display','off');
        gauss(e,6)= anp(strcmp(gname,'tilt'));
        sig_vars = gname(anp<alpha);
        
        [~,iidx]=intersect(varnames,gname,'stable');
        result(e,iidx) = anp;
        
        if isempty(sig_vars) || all(strcmp(sig_vars,'tilt'))
            [u, theta] = grpstats(dat,STIM.tilt(I,1),{'mean','gname'});
            theta = str2double(theta);
        else
            sig_grp       = group(anp<alpha);
            tilt          = strcmp(sig_vars,'tilt');
            othr_sig_grp  = sig_grp(~tilt);
            [sd,num,g] = grpstats(dat,othr_sig_grp,{'std','numel','gname'});
            [~,midx]=max(sd);
            g = str2double(g(midx,:));
            clear gI;
            for v = 1:length(othr_sig_grp)
                gI(:,v) = othr_sig_grp{v} == g(v);
            end
            gI = any(gI,2);
            if ~tilt
                % add tilt back in if it did not survive sig test
                sig_grp = cat(2,STIM.tilt(I,1),sig_grp);
                tilt=1;
            end
            sig_grp = cellfun(@(x) x(gI),sig_grp,'UniformOutput',0);
            if length(unique(sig_grp{tilt})) < 3
                [u, theta] = grpstats(dat,STIM.tilt(I,1),{'mean','gname'});
                theta = str2double(theta);
            else
                [u, theta] = grpstats(dat(gI),sig_grp,{'mean','gname'});
                theta = str2double(theta(:,tilt));
            end
        end
        
        % find peak theta,
        clear mi peak
        [~,mi]=max(u);
        peak = theta(mi);
        
        % reshape data so that peak is in middle
        clear x y grange
        x = wrapTo180([theta-peak theta-peak+180]);
        y = [u u];
        grange = find(x >= -90  & x <= 90) ;
        x = x(grange); y = y(grange);
        [x,idx] = sort(x); y = y(idx);
        
        % fit x and y with gauss, save gauss params
        clear gparam
        [gparam,~] = gaussianFit(x,y,false); % gparam = mu sigma A
        gauss(e,1:4) = [peak real(gparam')]; %xf = [-80:1:80];yf = p(3).*exp(-((xf-p(1)).^2)./(2*p(2)^2));
        
        % check ori tunining against orientations used during task
        clear fpeak delta
        fpeak = gauss(e,1) + gauss(e,2);
        delta = abs(fpeak - [diori(1) diori(1)+180 diori(2) diori(2)+180]);
        if any(delta < delta_tilt)
            gauss(e,5) = 1;
        else
            gauss(e,5) = 0;
        end
        
    end
    
    % EYE Tuning
    clear ipsi contra
    ipsi = STIM.eye == 2 & ...
        STIM.contrast(:,1) >= 0.8 & ...
        ~STIM.adapted & STIM.monocular & STIM.motion == 0;
    contra = STIM.eye == 3 & ...
        STIM.contrast(:,1) >= 0.8 & ...
        ~STIM.adapted & STIM.monocular & STIM.motion == 0;
    clear occ
    for e = 1:size(RESP,1)
        
        % generic, colapsed across all other params
        clear dat_* mc stats
        dat_i = RESP(e,ipsi);
        dat_c = RESP(e,contra);
        mc = (nanmean(dat_c) - nanmean(dat_i)) / (nanmean(dat_c) + nanmean(dat_i));
        [~,~,~,stats]=ttest2(dat_c,dat_i);
        occ(e,1:2) = [mc stats.tstat];
        
        % occ using best ori
        clear uTilt fpeak dTilt oidx bestori
        uTilt = unique(STIM.tilt(ipsi,1));
        uTilt = [uTilt, uTilt+180];
        fpeak = gauss(e,1) + gauss(e,2);
        dTilt = abs(uTilt - fpeak);
        dTilt = min(dTilt,[],2);
        [~,oidx] = min(dTilt);
        bestori = uTilt(oidx,1);
        clear dat_* mc stats
        dat_i = RESP(e,ipsi   & STIM.tilt(:,1) == bestori);
        dat_c = RESP(e,contra & STIM.tilt(:,1) == bestori);
        mc = (nanmean(dat_c) - nanmean(dat_i)) / (nanmean(dat_c) + nanmean(dat_i));
        [~,~,~,stats]=ttest2(dat_c,dat_i);
        occ(e,3:4) = [mc stats.tstat];
    end
    
    % DRFT tuning
    clear I gname group  remove
    f0 = nan(ninside,1); fnot = nan(ninside,1);
    I = (strcmp(STIM.task,'drfori') | strcmp(STIM.task,'rfsfdrft'))...
        & ~STIM.blank;
    if any(I)
        tf = unique(STIM.tf(I));
        if length(tf)>1
            tf = max(tf);
            I = I & STIM.tf == tf;
        end
        
        drftwin = [0.2 min(diff(STIM.tp_sp(I,:),[],2))/Fs];
        
        for e = 1:size(RESP,1)
            tmidx = bintm >= drftwin(1) &  bintm < drftwin(2);
            
            clear dat p *sig_* u theta g psth
            dat  = squeeze(nanmean(PSTH(e,tmidx,I),2));
            psth = squeeze(PSTH(e,tmidx,I));
            q80  = quantile(dat,[.8]);
            psth = psth(:,dat>=q80);
            psth(isnan(psth)) = 0;
            
            [f0(e,:)  ,~, ~] = ratio_ftf_f0(psth,Fs / bin_sp,tf);
            [fnot(e,:),~, ~] = ratio_ftf_fnot(psth,Fs / bin_sp,tf);
        end
    end
    
    %%
    % dCOS w/o adaptation
    % using monocular data form di tasks only (DEV: get more data w/o this restriciton)
    
    clear I gname group
    I = STIM.monocular & STIM.ditask & ~STIM.adapted;
    gname = {'eye','tilt','contrast'};
    group = cell(1,length(gname));
    for g = 1:length(gname)
        group{g} = STIM.(gname{g})(I,1);
    end
    
    % determin main contrasts levels
    clear uContrast contrast_*
    uContrast = unique(STIM.contrast(I));
    contrast_max = max(uContrast);
    [~,idx] = min(abs(uContrast - contrast_max/2));
    contrast_half   = uContrast(idx);
    
    for e = 1:size(RESP,1)
        
        % determin best monocular condition
        clear dat anp u ci sd n vars
        dat  = RESP(e,I);
        anp = anovan(dat,group,'varnames',gname,'display','off');
        [u,sd,n,ci,vars] = grpstats(dat,group,{'mean','std','numel','meanci','gname'});
        vars = str2double(vars);
        clear M
        for eye = 2:3
            for ori = 1:2
                M(eye-1,ori,:) = u(vars(:,1) == eye & vars(:,2) == diori(ori) & vars(:,3) == contrast_max);
            end
        end
        clear eidx oidx prefeye nulleye prefori nullori
        [eidx, oidx] = find(M(:,:,end) == max(max((M))));
        prefeye = eidx(1)+1;
        if prefeye == 2
            nulleye = 3;
        else
            nulleye = 2;
        end
        prefori = diori(oidx(1));
        nullori = diori(diori~=prefori);
        
        % get monocualr trials for ttest later;
        clear mI mdat msdf
        mI = STIM.eye == prefeye & ...
            STIM.tilt(:,1) == prefori & ...
            STIM.contrast(:,1) == contrast_max & ...
            STIM.ditask & ~STIM.adapted & STIM.monocular;
        mdat  = RESP(e,mI);
        % get monocular SDF
        msdf  = squeeze(SDF(e,:,mI));
        
        
        % get CRFs for relavant Monocular Conditions
        clear CRF II eyes contrasts tilts dat
        CRF = NaN(5,length(uContrast));
        CRF(1,:)  = u(vars(:,1) == prefeye & vars(:,2) == prefori)';
        CRF(2,:)  = u(vars(:,1) == nulleye & vars(:,2) == prefori)';
        CRF(3,:)  = u(vars(:,1) == nulleye & vars(:,2) == nullori)';
        % get CRFs for matching and nonmatching di conditions
        II = STIM.ditask & ~STIM.adapted & STIM.botheyes;
        eyes      = STIM.eyes(II,:);
        contrasts = STIM.contrast(II,:);
        tilts     = STIM.tilt(II,:);
        dat       = RESP(e,II);
        sdf       = squeeze(SDF(e,:,II));
        % sort data so that they are [prefeye nulleye]
        if prefeye == 2
            [eyes,sortidx] = sort(eyes,2,'ascend');
        else
            [eyes,sortidx] = sort(eyes,2,'descend');
        end
        for w = 1:length(eyes)
            contrasts(w,:) = contrasts(w,sortidx(w,:));
            tilts(w,:)     = tilts(w,sortidx(w,:));
        end
        % bi CRF
        clear bI bu bs bci bcontrast
        bI = tilts(:,1) == prefori & tilts(:,2) == prefori & contrasts(:,2) == contrast_max;
        [bu,bs,bn,bci,bcontrast] = grpstats(dat(bI),{contrasts(bI,1)},{'mean','std','numel','meanci','gname'});
        bcontrast = str2double(bcontrast);
        [~,iidx]=intersect(uContrast,bcontrast,'stable');
        CRF(4,iidx) = bu;
        % di CRF
        clear dI du ds dci dcontrast
        dI = tilts(:,1) == prefori & tilts(:,2) == nullori & contrasts(:,2) == contrast_max;
        [du,ds,dn,dci,dcontrast] = grpstats(dat(dI),{contrasts(dI,1)},{'mean','std','numel','meanci','gname'});
        dcontrast = str2double(dcontrast);
        [~,iidx]=intersect(uContrast,dcontrast,'stable');
        CRF(5,iidx) = du;
        
        clear STATS; STATS = NaN(5,5);
        STATS(1,:)  =[...
            u(vars(:,1) == prefeye & vars(:,2) == prefori & vars(:,3) == contrast_max),...
            sd(vars(:,1) == prefeye & vars(:,2) == prefori & vars(:,3) == contrast_max),...
            n(vars(:,1) == prefeye & vars(:,2) == prefori & vars(:,3) == contrast_max),...
            ci(vars(:,1) == prefeye & vars(:,2) == prefori & vars(:,3) == contrast_max,:),...
            ];
        STATS(2,:)  =[...
            u(vars(:,1) == nulleye & vars(:,2) == prefori & vars(:,3) == contrast_max),...
            sd(vars(:,1) == nulleye & vars(:,2) == prefori & vars(:,3) == contrast_max),...
            n(vars(:,1) == nulleye & vars(:,2) == prefori & vars(:,3) == contrast_max),...
            ci(vars(:,1) == nulleye & vars(:,2) == prefori & vars(:,3) == contrast_max,:),...
            ];
        STATS(3,:)  =[...
            u(vars(:,1) == nulleye & vars(:,2) == nullori & vars(:,3) == contrast_max),...
            sd(vars(:,1) == nulleye & vars(:,2) == nullori & vars(:,3) == contrast_max),...
            n(vars(:,1) == nulleye & vars(:,2) == nullori & vars(:,3) == contrast_max),...
            ci(vars(:,1) == nulleye & vars(:,2) == nullori & vars(:,3) == contrast_max,:),...
            ];
        if ~isempty(bu)
            STATS(4,:)  =[...
                bu(bcontrast == contrast_max),...
                bs(bcontrast == contrast_max),...
                bn(bcontrast == contrast_max),...
                bci(bcontrast == contrast_max,:),...
                ];
        end
        if ~isempty(du)
            STATS(5,:)  =[...
                du(dcontrast == contrast_max),...
                ds(dcontrast == contrast_max),...
                dn(dcontrast == contrast_max),...
                dci(dcontrast == contrast_max,:),...
                ];
        end
        
        % TTEST / MC
        clear bdat  ddat bstat dstat
        bdat = dat(bI & contrasts(:,1) == contrast_max);
        ddat = dat(dI & contrasts(:,1) == contrast_max);
        [~,~,~,bstat]=ttest2(bdat,mdat);
        [~,~,~,dstat]=ttest2(ddat,mdat);
        bstat.mc = (STATS(4,1) - STATS(1,1)) / (STATS(4,1) + STATS(1,1));
        dstat.mc = (STATS(5,1) - STATS(1,1)) / (STATS(5,1) + STATS(1,1));
        
        % add contrasts to CRF
        CRF = cat(1,CRF,uContrast');
        
        % di and bi SDF
        clear bsdf dsdf
        bsdf  = sdf(:,bI & contrasts(:,1) == contrast_max);
        dsdf  = sdf(:,dI & contrasts(:,1) == contrast_max);
        clear unitsdf
        unitsdf(1,:) = mean(msdf,2);
        unitsdf(2,:) = mean(bsdf,2);
        unitsdf(3,:) = mean(dsdf,2);
        unitsdf(4,:) = mean(bsdf,2) - mean(msdf,2);
        unitsdf(5,:) = mean(dsdf,2) - mean(msdf,2);
        %remv=all(isnan(unitsdf));
        
        % SAVE UNIT INFO!
        uct = uct + 1;
        IDX(uct).s = s;
        IDX(uct).penetration = penetration;
        IDX(uct).header = header;
        IDX(uct).monkey = header(end);
        IDX(uct).V1 = V1;
        
        IDX(uct).win   = win';
        IDX(uct).depth = depths(e,:)';
        
        IDX(uct).varnames = varnames;
        IDX(uct).varvary = result(e,:)';
        
        IDX(uct).gauss = gauss(e,:)'; %peakTh, gauss s, gauss sigma, gauss amplitude, does peak TH == diori, anaova p value for tilt
        IDX(uct).occ   = occ(e,:)';  % all_mc all_tstat bestori_mc bestori_tstat
        IDX(uct).dfft  = [f0(e) fnot(e)]';
        
        IDX(uct).prefeye   = prefeye;
        IDX(uct).prefori   = prefori;
        IDX(uct).dianov    = anp; % p for main effect of each 'eye' 'tilt' 'contrast'
        IDX(uct).di        = [bstat.mc bstat.tstat dstat.mc dstat.tstat]';
        IDX(uct).CRF       = CRF; %rows = Mpp,Mnp,Mnn,BI,dCOS; columns = contrast levels
        IDX(uct).STATS     = STATS; %rows = Mpp,Mnp,Mnn,BI,dCOS; columns = [mean std n ci]
        IDX(uct).SDF       = unitsdf; %rows = Mpp,BI,dCOS,BI-Mpp,dCOS-Mpp; columns = time;
        IDX(uct).tm        = sdftm;
        
        
    end
    
end


%
%
% vars = {...
%     'tilt';'eye';'sf';'phase';...
%     'contrast';'soa';'motion';'tf';'rns';'blank';...
%     'monocular';'ditask';'dioptic';'tiltmatch';'adapted';'cued';'evp';...
%     'xpos';'ypos';'diameter';'gabor'}; %'filen';'trl';'prez';
%
%
%     % setup groups for anova
%     gname = vars;
%     I = STIM.adapted == 0 & STIM.motion == 0;
%     group = cell(1,length(gname));
%     for g = 1:length(gname)
%         x = STIM.(gname{g})(I,1);
%         if all(isnan(x)) || length(nanunique(x))==1
%             continue
%         end
%         group{g} = STIM.(gname{g})(I,1);
%     end
%     remove = cellfun(@isempty,group);
%     gname(remove) = [];
%     group(remove) = [];
%     doesvary = ~remove;
%
%     % run anova and count channels with main effect of eye and ori
%     P = NaN(size(RESP,1),length(gname)); clear H
%     for e = 1:size(RESP,1)
%         dat = RESP(e,I);
%         P(e,:)=anovan(dat,group,'varnames',gname,'display','off');
%     end
%     H = P < alpha;
%     N(s,:) = [...
%         sum(H(:,strcmp(gname,'eye'))),...
%         sum(H(:,strcmp(gname,'tilt'))),...
%         sum(H(:,strcmp(gname,'eye')) & H(:,strcmp(gname,'tilt'))),...
%         size(RESP,1)];
%
%      for e = 1:size(RESP,1)
%          dat = RESP(e,I);
%
%
%
%
%      end


