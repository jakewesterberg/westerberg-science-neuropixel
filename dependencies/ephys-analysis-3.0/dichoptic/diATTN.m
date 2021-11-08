clear

didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Aug24/';
list  = dir([didir '*_AUTO.mat']);

alpha = 0.05;
delta_tilt = 20;
whichwin = 1;

uct = 0;
for i = 1:length(list)
    i
    
    % load session data
    clear penetration
    penetration = list(i).name(1:11);
    
    clear STIM
    load([didir list(i).name],...
        'STIM')
    if ~any(STIM.cued ~= 0)
        % no attention task
        continue
    end
    
    clear RESP matobj win_ms sdftm 
    load([didir list(i).name],...
        'win_ms','sdftm')
    matobj = matfile([didir list(i).name]);
    RESP   = matobj.RESP(:,whichwin,:);
    RESP   = squeeze(RESP);
    
    clear nel
    nel = length(STIM.el_labels);
    
    clear diori
    diori = nanunique(STIM.tilt(STIM.cued ~= 0,1));
    
    clear diContrast
    diContrast = unique(STIM.contrast(STIM.cued ~= 0 & STIM.monocular,1));
    
    % setup monocular comparisons
    clear I gname group
    I = STIM.monocular & ~STIM.adapted & STIM.cued == 0 & STIM.motion == 0;
    gname = {'eye','tilt','contrast'};
    group = cell(1,length(gname));
    for g = 1:length(gname)
        group{g} = STIM.(gname{g})(I,1);
    end
    if ~any(I)
        continue
    end
    
    for e = 1:nel
        
        clear dat ANP U SD N CI VARS
        dat  = squeeze(RESP(e,I));
        ANP  = anovan(dat,group,'varnames',gname,'display','off');
        [U,SD,N,CI,VARS] = grpstats(dat,group,{'mean','std','numel','meanci','gname'});
        VARS = str2double(VARS);
        
        clear M uContrast
        uContrast = unique(VARS(:,3));
        M = nan(2,2,length(uContrast));
        for eye = 2:3
            for ori = 1:2
                v = VARS(:,1) == eye & VARS(:,2) == diori(ori);
                c = VARS(v,3);
                [~,iidx]=intersect(uContrast,c,'stable');
                M(eye-1,ori,iidx) = U(v);
            end
        end
        
        clear eidx oidx prefeye nulleye prefori nullori
        p = length(uContrast);
        while p > 0
            m = M(:,:,p);
            if ~any(isnan(m))
                p = 0;
                [eidx, oidx] = find(m == max(max((m))));
                prefeye = eidx(1)+1;
                if prefeye == 2
                    nulleye = 3;
                else
                    nulleye = 2;
                end
                prefori = diori(oidx(1));
                nullori = diori(diori~=prefori);
            end
        end
        
        % sort data so that they are [prefeye nulleye]
         clear contrasts tilts eyes
        if prefeye == 2
            [eyes,sortidx] = sort(STIM.eyes,2,'ascend');
        else
            [eyes,sortidx] = sort(STIM.eyes,2,'descend');
        end
        for w = 1:length(eyes)
            contrasts(w,:) = STIM.contrast(w,sortidx(w,:));
            tilts(w,:)     = STIM.tilt(w,sortidx(w,:));
        end; clear w
        
                
        clear mI
        mI = STIM.eye == prefeye & ...
            STIM.tilt(:,1) == prefori & ...
            STIM.monocular & ...
            STIM.cued ~= 0;
        
        clear bI
        bI = all(tilts == prefori,2) & ...
            STIM.cued ~= 0;
        
        clear dI
        dI = STIM.tiltmatch == 0 & ...
            ~any(contrasts == 0,2) & ...
            STIM.cued ~= 0 & ...
            tilts(:,1) == prefori;
        
        if ~any(dI) || ~any(bI) || ~any(mI)
            continue
        elseif ~any(RESP(e,mI|bI|dI))
            continue
        end
            
        clear dat mu msd mn mci mvars mcued
        dat = RESP(e,mI);
        [mu,msd,mn,mci,mvars] = grpstats(dat,{STIM.cued(mI),STIM.contrast(mI,1)},{'mean','std','numel','meanci','gname'});
        mcued = str2double(mvars(:,1));
        
        clear dat bu bsd bn bci bvars bcued
        dat = RESP(e,bI);
        [bu,bsd,bn,bci,bvars] = grpstats(dat,{STIM.cued(bI),contrasts(bI,1),contrasts(bI,2)},{'mean','std','numel','meanci','gname'});
        bcued = str2double(bvars(:,1));
        
        clear dat du dsd dn dci dvars dcued
        dat = RESP(e,dI);
        [du,dsd,dn,dci,dvars] = grpstats(dat,{STIM.cued(dI),contrasts(dI,1) contrasts(dI,2)},{'mean','std','numel','meanci','gname'});
        dcued = str2double(dvars(:,1));
        
        if ~isequal(bvars(:,2:3),dvars(:,2:3))
            error('need dev')
        elseif ~isequal(bvars(:,2),dvars(:,2))
            error('need dev')
        elseif ~isequal(bvars(:,2),mvars(:,2))
            error('need dev')
        elseif length(unique(str2double(mvars(:,2))))>1
            error('need dev')
        end

        % get same stimuli from non-attention task
        clear mmI
        mmI = STIM.eye == prefeye & ...
            STIM.tilt(:,1) == prefori & ...
            STIM.contrast(:,1) == unique(str2double(mvars(:,2))) & ...
            STIM.monocular & ...
            STIM.cued == 0;
        
        clear bbI bctr
        bctr = [unique(str2double(bvars(:,2))) unique(str2double(bvars(:,3)))];
        bbI = all(tilts == prefori,2) & ...
            contrasts(:,1) == bctr(1) & ...
            contrasts(:,2) == bctr(2) & ...
            STIM.cued == 0;
        
        clear ddI dctr
        dctr = [unique(str2double(dvars(:,2))) unique(str2double(dvars(:,3)))];
        ddI = STIM.tiltmatch == 0 & ...
            tilts(:,1) == prefori & ...
            contrasts(:,1) == dctr(1) & ...
            contrasts(:,2) == dctr(2) & ...
            STIM.cued == 0;
        
              
        % monocular attention ttest
        clear mstat attn unattn n
        attn   = RESP(e,STIM.cued ==  1 & mI); n(1) = length(attn); 
        unattn = RESP(e,STIM.cued == -1 & mI); n(2) = length(unattn); 
        [~,p,~,mstat] = ttest2(attn,unattn);
        mstat.p = p;
        mstat.mc = (nanmean(attn) - nanmean(unattn)) / (nanmean(attn) + nanmean(unattn));
        
        % binocualr attention ttest
        clear bstat attn unattn
        attn   = RESP(e,STIM.cued ==  1 & bI); n(3) = length(attn); 
        unattn = RESP(e,STIM.cued == -1 & bI); n(4) = length(unattn); 
        [~,p,~,bstat] = ttest2(attn,unattn);
        bstat.p = p;
        bstat.mc = (nanmean(attn) - nanmean(unattn)) / (nanmean(attn) + nanmean(unattn));
        
        % dCOS attention ttest
        clear dstat attn unattn
        attn   = RESP(e,STIM.cued ==  1 & dI); n(5) = length(attn); 
        unattn = RESP(e,STIM.cued == -1 & dI); n(6) = length(unattn); 
        [~,p,~,dstat] = ttest2(attn,unattn);
        dstat.p = p;
        dstat.mc = (nanmean(attn) - nanmean(unattn)) / (nanmean(attn) + nanmean(unattn));
        
        
        %ANOVA
       dat = [...
           RESP(e,STIM.cued ==  1 & mI),...
           RESP(e,STIM.cued == -1 & mI),...
           RESP(e,STIM.cued ==  1 & bI),...
           RESP(e,STIM.cued == -1 & bI),...
           RESP(e,STIM.cued ==  1 & dI),...
           RESP(e,STIM.cued == -1 & dI)];
       cued = ones(size(dat));
       cued(sum(n(1:1))+1:sum(n(1:1))+n(2)) = -1;
       cued(sum(n(1:3))+1:sum(n(1:3))+n(4)) = -1;
       cued(sum(n(1:5))+1:sum(n(1:5))+n(6)) = -1;
       stim = ones(size(dat));
       stim(sum(n(1:2))+1:sum(n(1:2))+n(3)) = 2;
       stim(sum(n(1:3))+1:sum(n(1:3))+n(4)) = 2;
       stim(sum(n(1:4))+1:sum(n(1:4))+n(5)) = 3;
       stim(sum(n(1:5))+1:sum(n(1:5))+n(6)) = 3;
       anp = anovan(dat,{cued stim},'display','off','model','full');
        
       % delta SDFs 
       clear SDF
       SDF = squeeze(matobj.SDF(e,:,:));
       
       clear msdf
       msdf = nan(3,size(SDF,1)); 
       msdf(1,:) = nanmean(SDF(:,mI & STIM.cued ==  1),2);
       msdf(2,:) = nanmean(SDF(:,mI & STIM.cued == -1),2);
       msdf(3,:) = nanmean(SDF(:,mmI),2);
       
       clear bsdf
       bsdf = nan(3,size(SDF,1)); 
       bsdf(1,:) = nanmean(SDF(:,bI & STIM.cued ==  1),2);
       bsdf(2,:) = nanmean(SDF(:,bI & STIM.cued == -1),2);
       bsdf(3,:) = nanmean(SDF(:,bbI),2);
       
       clear dsdf
       dsdf = nan(3,size(SDF,1)); 
       dsdf(1,:) = nanmean(SDF(:,dI & STIM.cued ==  1),2);
       dsdf(2,:) = nanmean(SDF(:,dI & STIM.cued == -1),2);
       dsdf(3,:) = nanmean(SDF(:,ddI),2);
       
       clear deltasdf
       deltasdf(1,:) = msdf(1,:) - msdf(2,:);
       deltasdf(2,:) = bsdf(1,:) - bsdf(2,:);
       deltasdf(3,:) = dsdf(1,:) - dsdf(2,:);
               
       
        
         % SAVE UNIT INFO!
        uct = uct + 1;
        ATTN(uct).penetration = penetration;
        ATTN(uct).header = penetration(1:8);
        ATTN(uct).monkey = penetration(8);
        
        ATTN(uct).win   = win_ms(whichwin,:)';
        ATTN(uct).depth = STIM.depths(e,:)';
        
        ATTN(uct).prefeye   = prefeye;
        ATTN(uct).prefori   = prefori;
        ATTN(uct).mask      = any(STIM.rsvpmask(STIM.cued ~=0));
        
        ATTN(uct).u         = [mu bu du]; 
        ATTN(uct).sd        = [msd bsd dsd];
        ATTN(uct).n         = [mn bn dn];
        
        ATTN(uct).mc       = [mstat.mc bstat.mc dstat.mc]';
        ATTN(uct).tstat    = [mstat.tstat bstat.tstat dstat.tstat]';
        ATTN(uct).p        = [mstat.p bstat.p dstat.p]';
        
        
        ATTN(uct).dianov    = ANP; % p for main effect of each 'eye' 'tilt' 'contrast'
        ATTN(uct).atanova   = anp; % p for 'cued','stim','cued*stim'; 
        
        ATTN(uct).mCRF      = [squeeze(M(1,1,:)) squeeze(M(1,2,:)) squeeze(M(2,1,:)) squeeze(M(2,2,:)) uContrast]';
        
        ATTN(uct).SDF   = ([msdf;bsdf;dsdf]);
        ATTN(uct).SDFd  = deltasdf;
        ATTN(uct).tm    = sdftm;
        
        ATTN(uct).type  = list(i).name(end-6:end-4);
        
    end
end