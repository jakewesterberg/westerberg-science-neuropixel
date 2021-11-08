clear


didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Aug18/';
list  = dir([didir '*_KLS.mat']);

alpha = 0.05;
delta_tilt = 20;
whichwin =1;

uct = 0;
for i = 1:length(list)
    i
    
    % load session data
    clear penetration
    penetration = list(i).name(1:11);
    
    
    clear STIM RESP matobj win_ms sdftm
    load([didir list(i).name],...
        'STIM','win_ms','sdftm','CLUST')
    
    matobj = matfile([didir list(i).name]);
    RESP   = matobj.RESP(:,whichwin,:); 
    RESP   = squeeze(RESP); 
        
    clear nel
    nel = length(STIM.el_labels);
    
    % check for bonocular conditions
    I = ~STIM.adapted & STIM.cued == 0 & STIM.motion == 0;
    mo_tilts = intersect(unique(STIM.tilt(STIM.eye == 2 & I,1)),unique(STIM.tilt(STIM.eye == 3 & I,1)));
    biori = intersect(mo_tilts,unique(STIM.tilt(STIM.dioptic & I,1)));
    if isempty(biori)
        continue
    end
    clear bicontrast
    for ori = 1:length(biori); 
        clear x
        x = intersect(...
            unique(STIM.contrast(STIM.tilt(:,1) == biori(ori) & STIM.monocular & I,1)),...
            unique(STIM.contrast(STIM.tilt(:,1) == biori(ori) & STIM.dioptic & I,1)));
        if isempty(x)
            bicontrast(ori,:) = nan;
        else
            bicontrast(ori,:) = x;
        end
    end
    if all(isnan(bicontrast))
        continue
    end
    biori(isnan(bicontrast)) = []; 
    bicontrast(isnan(bicontrast)) = []; 
    
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
    result = nan(nel,length(varnames));
    gauss  = nan(nel,6);
    for e = 1:nel
        
        clear dat anp p *sig_* u theta g gparam
        dat  = squeeze(RESP(e,I));
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
        
        gauss(e,5) = NaN; % n/a : check ori tunining against orientations used during di task
        
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
    for e = 1:nel
        
        % generic, colapsed across all other params
        clear dat_* mc stats
        dat_i = squeeze(RESP(e,ipsi));
        dat_c = squeeze(RESP(e,contra));
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
    f0 = nan(nel,1); fnot = nan(nel,1);
    I = STIM.motion ~= 0;
    if any(I)
        I = find(I);
        
        clear PSTH psthtm ;
        PSTH = matobj.PSTH(:,:,I);
        psthtm = matobj.psthtm;
        
        clear drftwin Fs
        Fs=30000;
        drftwin = [0.2 min(diff(STIM.tp_sp(I,:),[],2))/Fs];
        
        clear tf tI
        tf = unique(STIM.tf(I));
        if length(tf)>1
            tf = max(tf);
            tI = STIM.tf(I) == tf;
        else
            tI = true(size(I));
        end
        
        for e = 1:nel
            tmidx = psthtm >= drftwin(1) &  psthtm < drftwin(2);
            
            clear dat p *sig_* u theta g psth
            dat  = squeeze(nanmean(PSTH(e,tmidx,tI),2));
            psth = squeeze(PSTH(e,tmidx,tI));
            q80  = quantile(dat,[.8]);
            psth = psth(:,dat>=q80);
            psth(isnan(psth)) = 0;
            
            [f0(e,:)  ,~, ~] = ratio_ftf_f0(psth,1/diff(psthtm(1:2)),tf);
            [fnot(e,:),~, ~] = ratio_ftf_fnot(psth,1/diff(psthtm(1:2)),tf);
        end
    end
    
    %%
        
    % bonocular facilitation
    % look at oris that are present for each monocular and dioptic
    clear I gname group
    I = STIM.monocular & ~STIM.adapted & STIM.cued == 0 & STIM.motion == 0 ...
        & ismember(STIM.tilt(:,1),biori);
    gname = {'eye','tilt','contrast'};
    group = cell(1,length(gname));
    for g = 1:length(gname)
        group{g} = STIM.(gname{g})(I,1);
    end
    
    if ~any(I)
        continue
    end
    
    % determin main contrasts levels
    clear uContrast contrast_*
    uContrast = unique(STIM.contrast(I));
    contrast_max = max(uContrast);
    [~,idx] = min(abs(uContrast - contrast_max/2));
    contrast_half   = uContrast(idx);
    
    for e = 1:nel
        % load SDF for this channel
        clear SDF; 
        SDF = squeeze(matobj.SDF(e,:,:)); 
        
        % grp stats for monocular condition
        clear dat anp u sd n vars
        dat  = squeeze(RESP(e,I));
        anp = anovan(dat,group,'varnames',gname,'display','off');
        vars = cellfun(@(x) transpose(unique(x)),group,'UniformOutput',0); 
        vars = combvec(vars{:})';  
        for v = 1:size(vars,1)
            clear x
            x = dat(group{1} == vars(v,1) & group{2} == vars(v,2) & group{3} == vars(v,3) );
            if isempty(x)
                u(v,1)  = NaN;
                sd(v,1) = NaN;
                n(v,1)  = 0;
            else
                u(v,1)  = nanmean(x);
                sd(v,1) = nanstd(x);
                n(v,1)  = sum(~isnan(x));
            end
        end
        
        if all(u == 0)
            continue
        end
        
        % determin best monocular cond
        [~,maxidx] = max(u); 
      
        prefeye = vars(maxidx,1);
        if prefeye == 2
            nulleye = 3;
        else
            nulleye = 2;
        end
        prefori = vars(maxidx,2);

                
         % sort data so that they are [prefeye nulleye]
         clear contrasts tilts eyes
         eyes      = STIM.eyes;
        contrasts = STIM.contrast;
        tilts     = STIM.tilt;
        if prefeye == 2
            [eyes,sortidx] = sort(eyes,2,'ascend');
        else
            [eyes,sortidx] = sort(eyes,2,'descend');
        end
        for w = 1:length(eyes)
            contrasts(w,:) = contrasts(w,sortidx(w,:));
            tilts(w,:)     = tilts(w,sortidx(w,:));
        end; clear w
        I = eyes(:,1) == prefeye &  tilts(:,1) == prefori &...
             ~STIM.adapted & STIM.cued == 0 & STIM.motion == 0 ...
             & ~STIM.blank;
    
        
        eyes(:,1)
        
        % get monocualr trials 
        clear mI mdat msdf
        mI = STIM.eye == prefeye & ...
            STIM.tilt(:,1) == prefori & ...
            STIM.contrast(:,1) == contrast_max & ...
            STIM.monocular & ...
            STIM.ditask & ~STIM.adapted & STIM.cued == 0 & STIM.motion == 0;
        mdat  = RESP(e,mI);
        % get monocular SDF
        msdf = SDF(:,mI);
       
        
        % get CRFs for relavant Monocular Conditions
        clear CRF II eyes contrasts tilts dat
        CRF = NaN(7,length(uContrast));
        for c = 1:length(uContrast)
            CRF(1,c)  = u(vars(:,1) == prefeye & vars(:,2) == prefori & vars(:,3) == uContrast(c));
            CRF(2,c)  = u(vars(:,1) == nulleye & vars(:,2) == prefori & vars(:,3) == uContrast(c));
            CRF(3,c)  = u(vars(:,1) == nulleye & vars(:,2) == nullori & vars(:,3) == uContrast(c));
        end
        % get CRFs for matching and nonmatching di conditions
        II = STIM.botheyes & STIM.ditask & ~STIM.adapted & STIM.cued == 0 & STIM.motion == 0;
        eyes      = STIM.eyes(II,:);
        contrasts = STIM.contrast(II,:);
        tilts     = STIM.tilt(II,:);
        dat       = RESP(e,II);
        % sort data so that they are [prefeye nulleye]
        if prefeye == 2
            [eyes,sortidx] = sort(eyes,2,'ascend');
        else
            [eyes,sortidx] = sort(eyes,2,'descend');
        end
        for w = 1:length(eyes)
            contrasts(w,:) = contrasts(w,sortidx(w,:));
            tilts(w,:)     = tilts(w,sortidx(w,:));
        end; clear w
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
        
        clear STATS; STATS = NaN(7,3);
        STATS(1,:)  =[...
            u(vars(:,1) == prefeye & vars(:,2) == prefori & vars(:,3) == contrast_max),...
            sd(vars(:,1) == prefeye & vars(:,2) == prefori & vars(:,3) == contrast_max),...
            n(vars(:,1) == prefeye & vars(:,2) == prefori & vars(:,3) == contrast_max),...
            ];
        STATS(2,:)  =[...
            u(vars(:,1) == nulleye & vars(:,2) == prefori & vars(:,3) == contrast_max),...
            sd(vars(:,1) == nulleye & vars(:,2) == prefori & vars(:,3) == contrast_max),...
            n(vars(:,1) == nulleye & vars(:,2) == prefori & vars(:,3) == contrast_max),...
            ];
        STATS(3,:)  =[...
            u(vars(:,1) == nulleye & vars(:,2) == nullori & vars(:,3) == contrast_max),...
            sd(vars(:,1) == nulleye & vars(:,2) == nullori & vars(:,3) == contrast_max),...
            n(vars(:,1) == nulleye & vars(:,2) == nullori & vars(:,3) == contrast_max),...
            ];
        if ~isempty(bu) && any(bcontrast == contrast_max)
            STATS(4,:)  =[...
                bu(bcontrast == contrast_max),...
                bs(bcontrast == contrast_max),...
                bn(bcontrast == contrast_max),...
                ];
        end
        if ~isempty(du)  && any(dcontrast == contrast_max)
            STATS(5,:)  =[...
                du(dcontrast == contrast_max),...
                ds(dcontrast == contrast_max),...
                dn(dcontrast == contrast_max),...
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
        II = find(II); 
        btrl = II(bI & contrasts(:,1) == contrast_max);
        bsdf = SDF(:,btrl); 
        dtrl = II(dI & contrasts(:,1) == contrast_max); 
        dsdf = SDF(:,dtrl); 
       
        clear unitsdf
        unitsdf = nan(9,length(msdf));
        unitsdf(1,:) = nanmean(msdf,2);
        if ~isempty(bsdf)
            unitsdf(2,:) = nanmean(bsdf,2);
            unitsdf(4,:) = nanmean(bsdf,2) - nanmean(msdf,2);
        end
        if ~isempty(dsdf)
            unitsdf(3,:) = nanmean(dsdf,2);
            unitsdf(5,:) = nanmean(dsdf,2) - nanmean(msdf,2);
        end
        
        % append ADAPTED contdition if abaialibe
        if any(STIM.adapted == 1)
            II = STIM.adapted & STIM.soa == max(STIM.soa) &...
                 STIM.botheyes & STIM.ditask & STIM.cued == 0 & STIM.motion == 0;
            eyes      = STIM.eyes(II,:);
            contrasts = STIM.contrast(II,:);
            tilts     = STIM.tilt(II,:);
            dat       = RESP(e,II);
            
            % find trails where the 2ns stim is preffered
            clear sI
            sI = contrasts(:,2) > 0 & eyes(:,2) == prefeye &  tilts(:,2) == prefori;
            if any(sI)
                
                % bi CRF
                clear bI bu bs bci bcontrast iidx
                bI = tilts(:,1) == prefori & contrasts(:,1) == contrast_max & sI;
                [bu,bs,bn,bci,bcontrast] = grpstats(dat(bI),{contrasts(bI,2)},{'mean','std','numel','meanci','gname'});
                bcontrast = str2double(bcontrast);
                [~,iidx]=intersect(uContrast,bcontrast,'stable');
                CRF(6,iidx) = bu;
                % di CRF
                clear dI du ds dci dcontrast iidx
                dI = tilts(:,1) == nullori & contrasts(:,1) == contrast_max & sI;
                [du,ds,dn,dci,dcontrast] = grpstats(dat(dI),{contrasts(dI,2)},{'mean','std','numel','meanci','gname'});
                dcontrast = str2double(dcontrast);
                [~,iidx]=intersect(uContrast,dcontrast,'stable');
                CRF(7,iidx) = du;
                
                % STATS
                if ~isempty(bu) && any(bcontrast == contrast_max)
                    STATS(6,:)  =[...
                        bu(bcontrast == contrast_max),...
                        bs(bcontrast == contrast_max),...
                        bn(bcontrast == contrast_max),...
                        ];
                end
                if ~isempty(du)  && any(dcontrast == contrast_max)
                    STATS(7,:)  =[...
                        du(dcontrast == contrast_max),...
                        ds(dcontrast == contrast_max),...
                        dn(dcontrast == contrast_max),...
                        ];
                end
                
                % di and bi SDF
                clear bsdf dsdf
                II = find(II);
                btrl = II(bI & contrasts(:,1) == contrast_max);
                bsdf = SDF(:,btrl);
                dtrl = II(dI & contrasts(:,1) == contrast_max);
                dsdf = SDF(:,dtrl);
                if ~isempty(bsdf)
                    unitsdf(6,:) = nanmean(bsdf,2);
                    unitsdf(8,:) = nanmean(bsdf,2) - nanmean(msdf,2);
                end
                if ~isempty(dsdf)
                    unitsdf(7,:) = nanmean(dsdf,2);
                    unitsdf(9,:) = nanmean(dsdf,2) - nanmean(msdf,2);
                end
       
                
            end
        end
   
        
        % SAVE UNIT INFO!
        uct = uct + 1;
        IDX(uct).penetration = penetration;
        IDX(uct).header = penetration(1:8);
        IDX(uct).monkey = penetration(8);
        
        IDX(uct).win   = win_ms(whichwin,:)';
        IDX(uct).depth = STIM.depths(e,:)';
        
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
        
        
        % DEV: figure out how to add clusters
        
        
        
    end
    
end









