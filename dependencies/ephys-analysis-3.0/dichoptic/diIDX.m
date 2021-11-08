clear


didir   = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Nov22/';
list    = dir([didir '*_AUTO.mat']);
sdfwin  = [-0.05 0.5]; %s
Fs      = 1000;

alpha_ori    = 0.05; 
assumedwin   = [50 100; 150 250; 50 250]; 

% set di conditions
dicontrast   = [0.050,0.150,0.200,0.225,0.300,0.400,0.450,0.500,0.600,0.800,0.900,1.000];
disoa        = [0 800]; 
dicond = {'Binocular','dCOS'};
% group contrasts 
dicgrp = nan(size(dicontrast));
dicgrp(dicontrast < 0.2) = 1;
dicgrp(dicontrast >= 0.2 & dicontrast <= 0.3) = 2;
dicgrp(dicontrast >= 0.4 & dicontrast <= 0.6) = 3;
dicgrp(dicontrast >= 0.8 & dicontrast <= 1.0) = 4;
diclevel = [0.1 0.2 0.5 0.9];


clear IDX
uct = 0;
for i = 1:length(list)
    i
    % load session data
    clear penetration
    penetration = list(i).name(1:11);
    
    clear STIM nel difiles
    load([didir penetration '.mat'],'STIM')
    nel = length(STIM.el_labels);
    difiles = unique(STIM.filen(STIM.ditask));
    
    signaltype = {'kls1','kls2'};
    for slt = 1:length(signaltype)
        
        clear matobj win_ms clusterstr ksl
        switch signaltype{slt}
            case 'kls1'
                kls = 1;
                clusterstr = 'clusters';
                wavestr = 'waves';
                matobj = matfile([didir penetration '_KLS.mat']);
            case 'kls2'
                if isempty(STIM.('rclusters'))
                    continue
                end
                kls = 1;
                clusterstr = 'rclusters';
                wavestr = 'rwaves';
                matobj = matfile([didir penetration '_KLS.mat']);
            case 'nev'
                kls = 0;
                matobj = matfile([didir penetration '_AUTO.mat']);
            case 'csd'
                kls = 0;
                matobj = matfile([didir penetration '_CSD.mat']);
        end
        
        win_ms = matobj.win_ms;
        if ~isequal(win_ms,assumedwin)
            error('check window assumptions')
        end
        
        for e = 1:nel
            
            clear *RESP* *SDF* sdf sdftm X M TRLS SUB CRF
            fRESP = squeeze(matobj.RESP(e,3,:)); % f = full,  50-250 ms
            eRESP = squeeze(matobj.RESP(e,1,:)); % e = early, 50-100 ms
            lRESP = squeeze(matobj.RESP(e,2,:)); % l = late,  150-250 ms
            
            if all(isnan(fRESP))
                continue
            end
            
            % get "goodfiles" for each cluster
            % i.e., the files over which the cluster is present
            % pref for ditasks if there are more than 1 set of clusters at depth
            clear goodfiles allfiles unitid wave
            allfiles = 1:length(STIM.filelist);
            if ~kls
                goodfiles = allfiles;
                unitID = nan;
                wave = nan(61,1); 
            else
                goodfiles = find(~isnan(STIM.(clusterstr)(e,:)));
                if isempty(goodfiles)
                    continue
                elseif ~isequal(goodfiles,allfiles)...
                        && length(goodfiles)>1 ...
                        && any(diff(goodfiles) > 1)
                    goodfiles = unique(STIM.filen(ismember(STIM.filen, goodfiles) & STIM.ditask));
                end
                cnum   = STIM.(clusterstr)(e,goodfiles);
                cfile  = STIM.filelist(goodfiles);
                unitID = cell(length(cnum),1);
                for cu = 1:length(cnum); 
                    [~,q] = fileparts(cfile{cu});
                    unitID{cu} = sprintf('%s_c%03u',q,cnum(cu));
                end
                wave = squeeze(nanmean(STIM.(wavestr)(e,goodfiles,:),2));
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
            X.ori(1,1:14) = NaN;
            X.oriana = false;
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
                    TRLS{c,3} = nanvar(fRESP(trls));
                end
                TRLS = TRLS(cellfun(@(x) x>=5,TRLS(:,2)),:);
                if ~isempty(TRLS)
                    if size(TRLS,1) > 1
                        [~,mI]=max([TRLS{:,3}]);
                        TRLS = TRLS(mI,:);
                    end
                    % test for a significant main effect of tilt, also find theta
                    tilt_p = anovan(fRESP(TRLS{1}),STIM.tilt(TRLS{1})','display','off');
                    [u,theta] = grpstats(fRESP(TRLS{1}),STIM.tilt(TRLS{1}),{'mean','gname'});
                    theta = str2double(theta);
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
                    
                    % remove nan (helps with fitting)
                    x(isnan(y)) = []; y(isnan(y)) = [];
                    
                    if ~isempty(y) && length(y) > 5
                        % fit x and y with gauss, save gauss params
                        clear gparam
                        [gparam,gerror] = gaussianFit(x,y,false); % gparam = mu sigma A
                        X.ori(1,1:8) = [tilt_p peak real(gparam') real(gerror')];
                        % fit x and y with gauss2:
                        %   f(x) =  a1*exp(-((x-b1)/c1)^2) + a2*exp(-((x-b2)/c2)^2)
                        if length(y) > 6
                            f = fit(x,y,'gauss2');
                            X.ori(1,9:end) = [f.b1 f.c1 f.a1 f.b2 f.c2 f.a2]; %  mu sigma A
                        end
                    end
                    
                    % signal that oriana happened
                    X.oriana = true;
                    
                end
            end
                        
            % get occularity (2v3), looking across all files but
            % balance all non-relevant conditions
            clear I varnames
            I = STIM.monocular ...
                & STIM.adapted == 0 ...
                & ~STIM.blank ...
                & STIM.rns == 0 ...
                & STIM.cued == 0 ...
                & STIM.motion == 0 ...
                & ismember(STIM.filen,goodfiles);
            varnames = {'tilt';'contrast';'sf';'phase';'xpos';'ypos';'diameter';'gabor'};
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
            values   = values(doesvary);
            temp     = temp(:,doesvary);
            clear combinations TRLS
            combinations = combvec(values{:})';
            TRLS = cell(3,size(combinations,1));
            for c = 1:size(combinations,1)
                for eye = 2:3
                    TRLS{eye,c} = find(...
                        I & STIM.eye == eye ...
                        & ismember(temp,combinations(c,:),'rows'))';
                end
            end
            TRLS = TRLS(:,~all(cellfun(@isempty,TRLS)));
            n = min(cellfun(@length,TRLS(2:3,:)));
            if all(n==0)
                X.occ(1,1:9) = NaN;
                X.occana = 0;
            else
                SUB = cell(size(TRLS));
                for c = 1:size(n,2)
                    if n(c) > 0
                        SUB{2,c} = randsample(TRLS{2,c},n(c));
                        SUB{3,c} = randsample(TRLS{3,c},n(c));
                    else
                        SUB{2,c} = [];
                        SUB{3,c} = [];
                    end
                end
                clear occ
                % occ(1:3) sub selected AND balanced
                occ(3) =  (nanmean(fRESP(cell2mat(SUB(2,:)))) - nanmean(fRESP(cell2mat(SUB(3,:)))) )...
                    ./ (nanmean(fRESP(cell2mat(SUB(2,:)))) + nanmean(fRESP(cell2mat(SUB(3,:)))) ) ;
                [~,p,~,stats]=ttest2(fRESP(cell2mat(SUB(2,:))),fRESP(cell2mat(SUB(3,:))));
                occ(2) = stats.tstat;
                occ(1) = p;
                % occ(4:6) sub selected, NOT balanced
                occ(6) =  (nanmean(fRESP(cell2mat(TRLS(2,:)))) - nanmean(fRESP(cell2mat(TRLS(3,:)))) )...
                    ./ (nanmean(fRESP(cell2mat(TRLS(2,:)))) + nanmean(fRESP(cell2mat(TRLS(3,:)))) ) ;
                [~,p,~,stats]=ttest2(fRESP(cell2mat(TRLS(2,:))),fRESP(cell2mat(TRLS(3,:))));
                occ(5) = stats.tstat;
                occ(4) = p;
                % occ(7:9) NOT sub selected
                occ(9) =  (nanmean(fRESP(I & STIM.eye == 2)) - nanmean(fRESP(I & STIM.eye == 3)) )...
                    ./ (nanmean(fRESP(I & STIM.eye == 2)) + nanmean(fRESP(I & STIM.eye == 3)) ) ;
                [~,p,~,stats]=ttest2(fRESP(I & STIM.eye == 2),fRESP(I & STIM.eye == 3));
                occ(8) = stats.tstat;
                occ(7) = p;
                X.occ = occ;
                X.occana = 1;
                
                % Note, eye = 2 signifies IPSI , 3 signifies CONTRA
                % so contrasts are IPSI - contra; (contra dom = negative nubmer)
            end
            
            
            % get BINOCULARITY, looking across all files but
            % balance all non-relevant conditions
            clear I varnames
            I = (STIM.monocular | STIM.dioptic) ...
                & STIM.adapted == 0 ...
                & ~STIM.blank ...
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
            if ~any(strcmp(varnames(doesvary),'eye')) ...
                    || ~isequal(values{strcmp(varnames,'eye')},[1 2 3])
                X.bio(1,1:6) = NaN;
            else
                values   = values(doesvary);
                temp     = temp(:,doesvary);
                varnames = varnames(doesvary);
                clear combinations TRLS TILTS
                combinations = combvec(values{:})';
                TRLS  = cell(3,size(combinations,1));
                TILTS = cell(1,size(combinations,1));
                for c = 1:3:size(combinations,1)
                    % only want BI if there are coresponding monocular conditions
                    clear n
                    n = [...
                        sum(ismember(temp,combinations(c+0,:),'rows'))
                        sum(ismember(temp,combinations(c+1,:),'rows'))
                        sum(ismember(temp,combinations(c+2,:),'rows'))];
                    if ~any(n==0)
                        for eye = 1:3
                            TRLS{eye,c} = find(ismember(temp,combinations(c+eye-1,:),'rows'))';
                        end
                        TILTS{1,c} = combinations(c+eye-1,strcmp(varnames,'tilt'));
                    end
                end
                TRLS  = TRLS(:,~all(cellfun(@isempty,TRLS)));
                TILTS = TILTS(:,~all(cellfun(@isempty,TRLS)));
                if isempty(TRLS)
                    X.bio(1,1:6) = NaN;
                else
                    n = min(cellfun(@length,TRLS(1:3,:)));
                    SUB = cell(size(TRLS));
                    for c = 1:size(n,2)
                        SUB{1,c} = randsample(TRLS{1,c},n(c));
                        SUB{2,c} = randsample(TRLS{2,c},n(c));
                        SUB{3,c} = randsample(TRLS{3,c},n(c));
                    end
                    % determin preffered eye
                    clear d PE
                    d = diff([nanmean(fRESP(cell2mat(SUB(2,:))))  nanmean(fRESP(cell2mat(SUB(3,:))))]);
                    if d > 0
                        PE = 3;
                    else
                        PE = 2;
                    end
                    clear bio
                    % bio(1:3) sub selected AND balanced
                    bio(3) =  (nanmean(fRESP(cell2mat(SUB(1,:)))) - nanmean(fRESP(cell2mat(SUB(PE,:)))) )...
                        ./ (nanmean(fRESP(cell2mat(SUB(1,:)))) + nanmean(fRESP(cell2mat(SUB(PE,:)))) ) ;
                    [~,p,~,stats]=ttest2(fRESP(cell2mat(SUB(1,:))),fRESP(cell2mat(SUB(PE,:))));
                    bio(2) = stats.tstat;
                    bio(1) = p;
                    % bio(4:6) sub selected, NOT balanced
                    bio(6) =  (nanmean(fRESP(cell2mat(TRLS(1,:)))) - nanmean(fRESP(cell2mat(TRLS(PE,:)))) )...
                        ./ (nanmean(fRESP(cell2mat(TRLS(1,:)))) + nanmean(fRESP(cell2mat(TRLS(PE,:)))) ) ;
                    [~,p,~,stats]=ttest2(fRESP(cell2mat(TRLS(1,:))),fRESP(cell2mat(TRLS(PE,:))));
                    bio(5) = stats.tstat;
                    bio(4) = p;
                    X.bio = bio;
                    % quick check if a "full" bonocularity analysis can be done
                    if length(unique(cell2mat(TILTS))) > 5
                        X.occana = 2;
                    end
                end
            end
            
            
            % DRFT tuning
            clear I gname group remove
            X.f0 = nan(1,1); X.fnot = nan(1,1);
            I = STIM.motion ~= 0;
            if any(I)
                I = find(I);
                
                clear PSTH psthtm ;
                PSTH = squeeze(matobj.PSTH(e,:,I));
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
                
                tmidx = psthtm >= drftwin(1) &  psthtm < drftwin(2);
                
                clear dat p *sig_* u theta g psth
                dat  = squeeze(nanmean(PSTH(tmidx,tI),2));
                if ~all(dat == 0) && ~all(isnan(dat))
                    psth = (PSTH(tmidx,tI));
                    q80  = quantile(dat,[.8]);
                    psth = psth(:,dat>=q80);
                    psth(isnan(psth)) = 0;
                    [X.f0(1,:)  ,~, ~] = ratio_ftf_f0(psth,1/diff(psthtm(1:2)),tf);
                    [X.fnot(1,:),~, ~] = ratio_ftf_fnot(psth,1/diff(psthtm(1:2)),tf);
                end
            end
            
            %%
            % DI TASK ANALYSIS,
            
            clear prefeye prefori
            prefeye = NaN;
            prefori = NaN;
            
            clear diSDF diKEY diRESP diTM
            sdftm    =  matobj.sdftm;
            diSDF    = nan(52,length(sdftm));
            diKEY    = nan(52,6);
            diRESP   = cell(52,3);
            diTM     = nan(1,diff(sdfwin)*1000);
            
            clear anp distats diana CRF
            anp     = nan(3,1);
            diana   = 0;
            CRF    = [];
            
            clear I
            I =  STIM.ditask...
                & STIM.adapted == 0 ...
                & ~STIM.blank ...
                & STIM.rns == 0 ...
                & STIM.cued == 0 ...
                & STIM.motion == 0 ...
                & ismember(STIM.filen,goodfiles);
            
            if any(I)
                
                % determin main contrasts levels 
                clear uContrast contrast_*
                uContrast = unique(STIM.contrast(I,:));
                uContrast(uContrast==0) = [];
                % for SDF, max & half contrast only
                contrast_max = max(uContrast);
                [~,idx] = min(abs(uContrast - contrast_max/2));
                contrast_half   = uContrast(idx);
                sdfcnt = [contrast_max contrast_half];
                % for CRF, group contrasts
                [~,x]=intersect(dicontrast,uContrast,'stable');
                uCntGroup = dicgrp(x);
                
                % determin dioptic tilts
                clear diori
                diori = nanunique(STIM.tilt(I,:));
                
                % determin best monocular condition
                clear M
                M = nan(2,2,length(uContrast));
                clear I gname group
                I = STIM.monocular...
                    & STIM.ditask...
                    & STIM.adapted == 0 ...
                    & ~STIM.blank ...
                    & STIM.rns == 0 ...
                    & STIM.cued == 0 ...
                    & STIM.motion == 0 ...
                    & ismember(STIM.filen,goodfiles);
                if any(I)
                    % look for monocular conditions in task
                    for eye = 2:3
                        for ori = 1:2
                            for cnt = 1:length(uContrast)
                                M(eye-1,ori,cnt) = nanmean(fRESP(I & STIM.eye == eye & STIM.tilt(:,1) == diori(ori) & STIM.contrast(:,1) == uContrast(cnt)));
                            end
                        end
                    end
                    M(:,:,any(squeeze(any(isnan(M),2)) | squeeze(any(isnan(M),1)))) = [];
                end
                M = nanmean(M,3);
                
                % determin pref eye and ori
                clear prefeye nulleye prefori prefori
                if isempty(M) || any(any(isnan(M)))
                    % monocular data from ditask is *INcomplete*
                    if X.oriana && X.occana > 0 && X.ori(1) < alpha_ori
                        % can recover pref from tuning data
                        if X.occ(2) > 0
                            prefeye = 2;
                            nulleye = 3;
                        else
                            prefeye = 3;
                            nulleye = 2;
                        end
                        deltaori = abs([diori,diori+180] - X.ori(2));
                        [a,~]=find(deltaori == min(min(deltaori)));
                        if length(a)>1 && diff(a) ~= 0
                            prefeye = NaN;
                            prefori = NaN;
                        else
                            prefori = diori(a(1));
                            nullori = diori(diori~=prefori);
                        end
                                                
                    else
                        prefeye = NaN;
                    end
                    
                else
                    % monocular data from ditask is complete
                    % so, check for significant main effects of EYE and ORI
                    gname = {'eye','tilt','contrast'};
                    group = cell(1,length(gname));
                    for g = 1:length(gname)
                        group{g} = STIM.(gname{g})(I,1);
                    end
                    clear anp
                    anp = anovan(fRESP(I),group,'varnames',gname,'display','off');

                    % check for orientation tuning
                    if anp(2) < alpha_ori
                    % find pref eye and ori
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
                    else
                        prefeye = NaN; 
                    end
                end
                
                % DIOPTIC AND SOA ANALYSIS
                % if you have pref sim info,
                % AND the unit is orientation tuned
                if ~isnan(prefeye)
                    
                    % sort data so that they are [prefeye nulleye]
                    clear eyes sortidx contrasts tilts
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
                    % organize data for SOA ana where temporal order matters
                    clear adaptor supresor
                    adaptor   = [STIM.eyes(:,1) STIM.tilt(:,1) STIM.contrast(:,1)];
                    supresor  = [STIM.eyes(:,2) STIM.tilt(:,2) STIM.contrast(:,2)];
                    
                    % analyze by DI condition
                    clear sdftm sdf stimcontrast
                    sdf   = squeeze(matobj.SDF(e,:,:));
                    sdftm =  matobj.sdftm;
                    sdfct = 0;
                    
                    % MASTER I
                    clear I
                    I = STIM.ditask...
                        & ~STIM.blank ...
                        & STIM.rns == 0 ...
                        & STIM.cued == 0 ...
                        & STIM.motion == 0 ...
                        & ismember(STIM.filen,goodfiles);
                    
                    % Monocular Conditons
                    for ori = 0:1
                        for c = 1:2
                            for eye =  0:1
                                
                                sdfct = sdfct +1;
                                
                                clear tempeye tempori
                                if ori == 1
                                    tempori = prefori;
                                else
                                    tempori = nulleye;
                                end
                                if eye == 1
                                    tempeye = prefeye;
                                    diKEY(sdfct,:) = [...
                                        ori-1 ...
                                        dicontrast(c) ...
                                        0 ...
                                        0 NaN NaN];
                                else
                                    tempeye = nulleye;
                                    diKEY(sdfct,:) = [...
                                        ori-1 ...
                                        0 ...
                                        dicontrast(c) ...
                                        0 NaN NaN];
                                end
                                
                                
                                trls = I & STIM.soa == 0 &...
                                    STIM.eye == tempeye & ...
                                    STIM.tilt(:,1) == tempori & ...
                                    STIM.contrast(:,1) == dicontrast(c) & ...
                                    STIM.monocular;
                                
                                % save data and key
                                diKEY(sdfct,end) = sum(trls);
                                
                                if any(trls)
                                    diSDF(sdfct,:)   = nanmean(sdf(:,trls),2);
                                    diRESP{sdfct,1}  = eRESP(trls); 
                                    diRESP{sdfct,2}  = lRESP(trls); 
                                    diRESP{sdfct,3}  = fRESP(trls); 
                                    %diRESP{sdfct,1} = nanmean(sdf(sdftm >= statwin(1,1) & sdftm <= statwin(1,2),trls),1);
                                    %diRESP{sdfct,2} = nanmean(sdf(sdftm >= statwin(2,1) & sdftm <= statwin(2,2),trls),1);
                                else
                                    diSDF(sdfct,:)  = nan(size(sdf,1),1);
                                    diRESP{sdfct,1} = nan;
                                    diRESP{sdfct,2} = nan;
                                    diRESP{sdfct,3} = nan;
                                end
                                
                            end
                        end
                    end
                    
                    % Dioptic Conditions
                    for brfs = 1:length(disoa)
                        for di = 1:length(dicond)
                            for adaptnull = 1:-1:0;
                                for de = 1:2
                                    for nde = 1:2
                                        
                                        clear soa trls
                                        soa = disoa(brfs);
                                        
                                        switch dicond{di}
                                            
                                            case 'Binocular'
                                                if soa == 0
                                                    trls = I & STIM.soa == soa &...
                                                        tilts(:,1) == prefori & ...
                                                        tilts(:,2) == prefori & ...
                                                        contrasts(:,1) == dicontrast(de) & ...
                                                        contrasts(:,2) == dicontrast(nde);
                                                elseif soa == 0 && adaptnull == 0
                                                    continue
                                                else
                                                    trls = I & STIM.soa == soa &...
                                                        tilts(:,1) == prefori & ...
                                                        tilts(:,2) == prefori & ...
                                                        contrasts(:,1) == dicontrast(de) & ...
                                                        contrasts(:,2) == dicontrast(nde);
                                                    if adaptnull
                                                        trls = trls & ...
                                                            adaptor(:,1) == nulleye & ...
                                                            supresor(:,1) == prefeye;
                                                    else
                                                        trls = trls & ...
                                                            adaptor(:,1) == prefeye & ...
                                                            supresor(:,1) == nulleye;
                                                    end
                                                end
                                            case 'dCOS'
                                                if soa == 1
                                                    trls = I & STIM.soa == soa &...
                                                        tilts(:,1) == prefori & ...
                                                        tilts(:,2) == nullori & ...
                                                        contrasts(:,1) == dicontrast(de) & ...
                                                        contrasts(:,2) == dicontrast(nde);
                                                elseif soa == 0 && adaptnull == 0
                                                    continue
                                                else
                                                    trls = I & STIM.soa == soa &...
                                                        contrasts(:,1) == dicontrast(de) & ...
                                                        contrasts(:,2) == dicontrast(nde);
                                                    if adaptnull
                                                        trls = trls & ...
                                                            adaptor(:,1) == nulleye & ...
                                                            adaptor(:,2) == nullori & ...
                                                            supresor(:,1) == prefeye & ...
                                                            supresor(:,2) == prefori;
                                                    else
                                                        trls = trls & ...
                                                            adaptor(:,1) == prefeye & ...
                                                            adaptor(:,2) == prefori & ...
                                                            supresor(:,1) == nulleye & ...
                                                            supresor(:,2) == nullori;
                                                    end
                                                end
                                        end
                                        
                                        % save data and key
                                        sdfct = sdfct +1;
                                        if soa == 0
                                            diKEY(sdfct,:) = [...
                                                di...
                                                dicontrast(de) ...
                                                dicontrast(nde)...
                                                soa  NaN sum(trls)];
                                        else
                                            diKEY(sdfct,:) = [...
                                                di...
                                                dicontrast(de) ...
                                                dicontrast(nde)...
                                                soa adaptnull sum(trls)];
                                        end
                                        
                                        if any(trls)
                                            diSDF(sdfct,:)   = nanmean(sdf(:,trls),2);
                                            diRESP{sdfct,1}  = eRESP(trls);
                                            diRESP{sdfct,2}  = lRESP(trls);
                                            diRESP{sdfct,3}  = fRESP(trls);
                                            %diRESP{sdfct,1} = nanmean(sdf(sdftm >= statwin(1,1) & sdftm <= statwin(1,2),trls),1);
                                            %diRESP{sdfct,2} = nanmean(sdf(sdftm >= statwin(2,1) & sdftm <= statwin(2,2),trls),1);
                                        else
                                            diSDF(sdfct,:)   = nan(size(sdf,1),1);
                                            diRESP{sdfct,1} = nan;
                                            diRESP{sdfct,2} = nan;
                                            diRESP{sdfct,3} = nan;
                                        end
                                        
                                    end
                                end
                            end
                        end
                    end
                    
                    
                    for w = 1:3
                        clear RESP
                        if w == 1; 
                            RESP = eRESP;
                            crfstr = 'early';
                        elseif w == 2
                            RESP = lRESP;
                            crfstr = 'late';
                        elseif w == 3
                            RESP = fRESP;
                            crfstr = 'full';
                        end
                           
                        
                    % CRF Analysis - added Oct 3, dCOS added Oct 18
                    rCRF = nan(5+length(uContrast)*2,length(uContrast));
                    rCRF(1,:) = uContrast;
                    eCRF = rCRF; nCRF = rCRF;
                    
                    % monocular
                    clear iI uu* nn ee gname
                    iI = I & STIM.monocular & STIM.soa == 0;
                    [uu, nn, ee, gname] = grpstats(RESP(iI),{STIM.eye(iI),STIM.tilt(iI,1),STIM.contrast(iI,1)},{'mean','numel','std','gname'});
                    uueye = str2double(gname(:,1));
                    uutilt = str2double(gname(:,2));
                    uucon = str2double(gname(:,3));
                    mct = 1;
                    for ori = 0:1
                        for eye =  0:1
                            mct = mct + 1;
                            for c = 1:length(uContrast)
                                
                                clear tempeye tempori
                                if ori == 1
                                    tempori = prefori;
                                else
                                    tempori = nulleye;
                                end
                                if eye == 1
                                    tempeye = prefeye;
                                else
                                    tempeye = nulleye;
                                end
                                
                                idx = ...
                                    uueye == tempeye & ...
                                    uutilt == tempori & ...
                                    uucon == uContrast(c);
                                if any(idx)
                                    rCRF(mct,c) = uu(idx);
                                    eCRF(mct,c) = ee(idx);
                                    nCRF(mct,c) = nn(idx);
                                else
                                    rCRF(mct,c) = NaN;
                                    eCRF(mct,c) = NaN;
                                    nCRF(mct,c) = 0;
                                end
                            end
                        end
                    end
                    
                    
                    %binocular
                    cidx = 5;
                    for de = 1:length(uContrast)
                        for nde = 1:length(uContrast)
                            clear trls
                            trls = I & STIM.soa == 0 & ...
                                tilts(:,1) == prefori & ...
                                tilts(:,2) == prefori & ...
                                contrasts(:,1) == uContrast(de) & ...
                                contrasts(:,2) == uContrast(nde);
                            
                            rCRF(cidx+nde,de) = nanmean(RESP(trls));
                            eCRF(cidx+nde,de) = nanstd(RESP(trls));
                            nCRF(cidx+nde,de) = sum(trls);
                            
                        end
                    end
                    
                    %dCOS
                    cidx = cidx + length(uContrast);
                    for de = 1:length(uContrast)
                        for nde = 1:length(uContrast)
                            clear trls
                            trls = I & STIM.soa == 0 & ...
                                tilts(:,1) == prefori & ...
                                tilts(:,2) == nullori & ...
                                contrasts(:,1) == uContrast(de) & ...
                                contrasts(:,2) == uContrast(nde);
                            
                            rCRF(cidx+nde,de) = nanmean(RESP(trls));
                            eCRF(cidx+nde,de) = nanstd(RESP(trls));
                            nCRF(cidx+nde,de) = sum(trls);
                        end
                    end
                    
                    CRF.(crfstr) = cat(3,rCRF,eCRF,nCRF);
                    
                    end
                    if any(any(diSDF))
                        diana = 1;
                    end
                end
            end
         
            
            if ~diana
                continue
            end
                   ffffddffdfdf     
            % SAVE UNIT INFO!
            uct = uct + 1;
            IDX(uct).penetration = penetration;
            IDX(uct).header  = penetration(1:8);
            IDX(uct).monkey  = penetration(8);
            IDX(uct).unitID  = unitID; 
            IDX(uct).wave    = wave; 
            IDX(uct).runtime = now;
            
            IDX(uct).depth = STIM.depths(e,:)';
            IDX(uct).kls   = logical(kls);
            IDX(uct).nev   = strcmp(signaltype{slt},'nev');
            IDX(uct).csd   = strcmp(signaltype{slt},'csd');
            
            IDX(uct).occana       = X.occana;
            IDX(uct).oriana       = X.oriana;
            IDX(uct).diana        = diana;
            IDX(uct).dicontrast   = dicontrast';
            
            IDX(uct).ori   = X.ori';
            IDX(uct).occ   = X.occ';
            IDX(uct).bio   = X.bio';
            IDX(uct).dfft  = [X.f0 X.fnot]';
            
            IDX(uct).prefeye    = prefeye;
            IDX(uct).prefori    = prefori;
            IDX(uct).dianov     = anp; % p for main effect of each 'eye' 'tilt' 'contrast'
            
            IDX(uct).diSDF       = diSDF; % no subtractions, no stats
            IDX(uct).tm          = diTM;
            IDX(uct).diKEY       = diKEY;
            IDX(uct).diRESP      = diRESP;
            
            IDX(uct).CRF       = CRF;
            
            
        end
    end
end




% normalized SDF
%             clear x
%             x = cat(1,nSDF,aSDF);
%             if ~diana && ~attnana
%                 % SAVE to IDX
%                 IDX(uct).nSDF = x;
%             else
%                 % remove subtractions
%                 sub = logical([0 0 0 0 0 0 0 0 1 1 1 1, 0 0 0 0 0 0 0 0 0 1 1 1]);
%                 x(sub,:) = nan;
%                 % normalize relative to best monocular condition
%                 % note, will fail for redun cue sessions
%                 % b/c there is no data in x(1,:)
%                 x = bsxfun(@minus,x, mean(x(:,diTM>-0.05 & diTM<0),2));
%                 x = x ./ max(x(1,diTM>0.05 & diTM<0.11));
%                 % fill in subtractions
%                 x( 9,:) = x( 2,:) - x( 1,:);
%                 x(10,:) = x( 3,:) - x( 1,:);
%                 x(11,:) = x( 5,:) - x( 4,:);
%                 x(12,:) = x( 6,:) - x( 4,:);
%                 x(22,:) = x(13,:) - x(14,:);
%                 x(23,:) = x(16,:) - x(17,:);
%                 x(24,:) = x(19,:) - x(20,:);
%                 % SAVE to IDX
%                 IDX(uct).nSDF = x;
%             end



