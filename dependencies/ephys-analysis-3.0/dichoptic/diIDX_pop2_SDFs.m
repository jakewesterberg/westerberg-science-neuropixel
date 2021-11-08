clear

%KLS only

didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Mar14/'
list    = dir([didir '*_KLS*.mat']);
sdfwin  = [-0.050 0.250]; %s
blwin   = [-0.050 0    ]; %s
Fs = 1000;
alpha = 0.05;
mintrls = 5; 

clear IDX
uct = 0; skip.noinfo = 0; skip.nottuned = 0;
for i = 1:length(list)
    %i
    % load session data
    clear penetration klsnum
    penetration = list(i).name(1:11);
    klsnum      = str2double(list(i).name(end-4));
    
    clear matobj win_ms
    matobj = matfile([didir list(i).name]);
    win_ms = matobj.win_ms;
    if ~isequal(win_ms,[50 100; 150 250; 50 250; -50 0])
        error('check win')
    end
    
    clear STIM nel clusters difiles
    STIM = matobj.STIM;
    nel = length(STIM.el_labels);
    clusters = STIM.clusters(:,:,klsnum);
    difiles = unique(STIM.filen(STIM.ditask & STIM.cued == 0));
    if ~any(difiles)
        continue
    end
    
    for e = 1:nel
        
        clear fileclust
        fileclust = clusters(e,:);
        if all(isnan(fileclust))
            continue
        end
        
        clear goodfiles allfiles
        allfiles = 1:length(STIM.filelist);
        goodfiles = find(~isnan(fileclust));
        
        % extract relavant info about tuning
        clear X X0 X1
        % (A) do not subtract baseline
        resp = squeeze(matobj.RESP(e,3,:)); % 3 = full,  50-250 ms;
        X1 = diUnitTuning(resp,STIM,e,goodfiles); clear resp
        % (B) subtract baseline
        resp = squeeze(matobj.RESP(e,3,:) - matobj.RESP(e,4,:)) ; %4 = baseline -50 0
        X0 = diUnitTuning(resp,STIM,e,goodfiles); clear resp
        %quickly check X1 v X0
        if  ~isequal(X1.dicontrasts,X0.dicontrasts) ...
                || ~isequal(X1.diori,X0.diori) ...
                ||  ~(X1.oriana == X0.oriana) ...
                ||  ~(X1.occana == X0.occana) ...
                ||  ~(X1.diana  == X0.diana)
            error('look into X0 vs. X1')
        end
        
        clear orieffect
        orieffect = [X1.ori(1) X0.ori(1) ...
            X1.dianp(strcmp(X1.diang,'tilt')) ...
            X0.dianp(strcmp(X1.diang,'tilt'))];
        % exclustion critera
        if all(isnan(X1.dipref))
            fprintf('cannot determin dipref, skipping unit\n')
            continue
        elseif ~isequal(X1.dipref,X0.dipref) 
            fprintf('X1 and X0 have diffrent dipref, skipping unit\n')
            continue
        elseif ~any(orieffect < alpha)
            fprintf('no signifcant ori effect, skipping unit\n')
            continue
        end
        
        clear prefeye prefori nulleye nullori
        prefeye = X1.dipref(1);
        nulleye = X1.dinull(1);
        prefori = X1.dipref(2);
        nullori = X1.dinull(2);
        
        % static DITASK analysis
        clear I
        I =  STIM.ditask...
            & STIM.adapted == 0 ...
            & ~STIM.blank ...
            & STIM.rns == 0 ...
            & STIM.cued == 0 ...
            & STIM.motion == 0 ...
            & ismember(STIM.filen,goodfiles);
        
        % get main contrast levels
        contrast_half = intersect(X1.dicontrasts,0.40:0.05:0.5);
        if length(contrast_half) > 1
            aksakssk      %       ctemp = [contrast_half contrast_half.*2] ;
        elseif isempty(contrast_half)
            continue
        end
        contrast_max  = contrast_half*2;
        
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
        
        % analyze by DI condition
        clear sdftm dicond sdf stimcontrast
        sdf   = squeeze(matobj.SDF(e,:,:));
        sdftm =  matobj.sdftm;
        dicond = {'Monocular','Binocular','dCOS'};
        stimcontrast = [contrast_max contrast_half];
        
        clear SDF UV MV 
        sdfct = 0; 
        SDF = nan(9,length(sdftm),2); 
        UV  = nan(9,4);
        MV  = nan(9,4); 
        
        clear MC* TS*
        MC1 = nan([6 2]);
        TS1 = nan([6 2]);
        MC0 = nan([6 2]);
        TS0 = nan([6 2]);
        
        for c = 1:2
            clear TRLS
            TRLS = false(3,length(I));
            
            for di = 1:3
                sdfct = sdfct +1;
                clear trls
                switch dicond{di}
                    case 'Monocular'
                        trls = I &...
                            STIM.eye == prefeye & ...
                            STIM.tilt(:,1) == prefori & ...
                            STIM.contrast(:,1) == stimcontrast(c) & ...
                            STIM.monocular;
                    case 'Binocular'
                        trls = I &...
                            tilts(:,1) == prefori & ...
                            tilts(:,2) == prefori & ...
                            contrasts(:,1) == stimcontrast(c) & ...
                            contrasts(:,2) == contrast_max;
                    case 'dCOS'
                        trls = I &...
                            tilts(:,1) == prefori & ...
                            tilts(:,2) == nullori & ...
                            contrasts(:,1) == stimcontrast(c) & ...
                            contrasts(:,2) == contrast_max;
                end
                if sum(trls) >= mintrls
                    clear rdat ndat bl
                    rdat  = sdf(:,trls); 
                    bl   = mean(rdat(sdftm > blwin(1) & sdftm < blwin(2),:),1);
                    ndat = bsxfun(@minus,rdat,bl);
                    
                    SDF(sdfct,:,1)   = nanmean(rdat,2);
                    SDF(sdfct,:,2)   = nanmean(ndat,2);
                    TRLS(di,:)   = trls;
                    
                    for w = 1:4
                        clear resp
                        resp = squeeze(matobj.RESP(e,w,:));
                        UV(sdfct,w) = nanmean(resp(trls));
                        MV(sdfct,w) = nanmedian(resp(trls));
                    end   
                end
            end
            
            clear base 
            base = squeeze(matobj.RESP(e,4,:)); % 4 = -50 0
                for w = 1:2
                    clear resp
                    resp = squeeze(matobj.RESP(e,w,:));
                   
                    clear Mo Bi Di 
                    Mo = resp(TRLS(strcmp('Monocular',dicond),:));
                    Bi = resp(TRLS(strcmp('Binocular',dicond),:));
                    Di = resp(TRLS(strcmp('dCOS',dicond),:));
                    
                    clear dMo dBi dDi
                    dMo = Mo - base(TRLS(strcmp('Monocular',dicond),:));
                    dBi = Bi - base(TRLS(strcmp('Binocular',dicond),:));
                    dDi = Di - base(TRLS(strcmp('dCOS',dicond),:));
                    
                    MC1(1+(c-1)*3,w) = (mean(Bi) - mean(Mo)) /  (mean(Bi) + mean(Mo));
                    MC1(2+(c-1)*3,w) = (mean(Di) - mean(Mo)) /  (mean(Di) + mean(Mo));
                    MC1(3+(c-1)*3,w) = (mean(Bi) - mean(Di)) /  (mean(Bi) + mean(Di));

                    MC0(1+(c-1)*3,w) = (mean(dBi) - mean(dMo)) /  (mean(dBi) + mean(dMo));
                    MC0(2+(c-1)*3,w) = (mean(dDi) - mean(dMo)) /  (mean(dDi) + mean(dMo));
                    MC0(3+(c-1)*3,w) = (mean(dBi) - mean(dDi)) /  (mean(dBi) + mean(dDi));
                    
                    [~,~,~,stat]= ttest2(Bi,Mo);
                    TS1(1+(c-1)*3,w)     = stat.tstat;
                    [~,~,~,stat]= ttest2(Di,Mo);
                    TS1(2+(c-1)*3,w)     = stat.tstat;
                    [~,~,~,stat]= ttest2(Bi,Di);
                    TS1(3+(c-1)*3,w)     = stat.tstat;
                    
                    [~,~,~,stat]= ttest2(dBi,dMo);
                    TS0(1+(c-1)*3,w)     = stat.tstat;
                    [~,~,~,stat]= ttest2(dDi,dMo);
                    TS0(2+(c-1)*3,w)     = stat.tstat;
                    [~,~,~,stat]= ttest2(dBi,dDi);
                    TS0(3+(c-1)*3,w)     = stat.tstat;
                    
                end
        
        end
        
        % Add ND monocular conditions
        clear nde_prefori
        nde_prefori = I &...
            STIM.eye == nulleye & ...
            STIM.tilt(:,1) == prefori & ...
            STIM.contrast(:,1) == contrast_max & ...
            STIM.monocular;
        if sum(nde_prefori) >= mintrls
            clear rdat ndat bl
            rdat  = sdf(:,nde_prefori);
            bl   = mean(rdat(sdftm > -0.025 & sdftm < 0,:),1);
            ndat = bsxfun(@minus,rdat,bl);
            
            SDF(7,:,1)   = nanmean(rdat,2);
            SDF(7,:,2)   = nanmean(ndat,2);
        end
        
        clear nde_nullori
        nde_nullori = I &...
            STIM.eye == nulleye & ...
            STIM.tilt(:,1) == nullori & ...
            STIM.contrast(:,1) == contrast_max & ...
            STIM.monocular;
        if sum(nde_nullori) >= mintrls
            clear rdat ndat bl
            rdat  = sdf(:,nde_nullori);
            bl   = mean(rdat(sdftm > -0.025 & sdftm < 0,:),1);
            ndat = bsxfun(@minus,rdat,bl);
            
            SDF(8,:,1)   = nanmean(rdat,2);
            SDF(8,:,2)   = nanmean(ndat,2);
        end
        
        % Add BLANK
        clear blanktrls
        blanktrls = STIM.blank & STIM.ditask & ismember(STIM.filen,goodfiles);
        if sum(blanktrls) >= mintrls
            clear rdat ndat bl
            rdat  = sdf(:,blanktrls);
            bl   = mean(rdat(sdftm > -0.025 & sdftm < 0,:),1);
            ndat = bsxfun(@minus,rdat,bl);
            
            SDF(9,:,1)   = nanmean(rdat,2);
            SDF(9,:,2)   = nanmean(ndat,2);
        end
       
        % crop / pad SDF
        clear tm pad st en
        tm = sdftm;
        if tm(end) < sdfwin(2)
            pad = [tm(end):diff(tm(1:2)):sdfwin(2)];
            pad(1) = [];
            en = length(tm);
            st = find(tm> sdfwin(1),1);
            tm = [tm pad];
            tm = tm(st : end);
            pad(:) = NaN;
            pad = repmat(pad,size(SDF,1),1);
            pad(:,:,2) = pad;
        else
            pad = [];
            en = find(tm > sdfwin(2),1)-1;
            st = find(tm > sdfwin(1),1);
            tm = tm(st : en);
        end
        clear pSDF TM 
        pSDF = cat(2,SDF(:, st : en ,:),pad); 
        if size(pSDF,2) ~= length(tm)
            error('check tm')
        end
        TM = tm;
        SDF = pSDF; clear pSDF sdftm 
        
        
        
        
        
        
        % SAVE UNIT INFO!
        uct = uct + 1;
        IDX(uct).penetration = penetration;
        IDX(uct).header = penetration(1:8);
        IDX(uct).monkey = penetration(8);
        IDX(uct).runtime = now;
        
        IDX(uct).depth = STIM.depths(e,:)';
        IDX(uct).kls   = 1;
        
        IDX(uct).occana       = X1.occana;
        IDX(uct).oriana       = X1.oriana;
        IDX(uct).diana        = X1.diana;
        IDX(uct).dicontrast   = stimcontrast';
        
        IDX(uct).prefeye    = prefeye;
        IDX(uct).prefori    = prefori;
        
        IDX(uct).ori        = X1.ori';
        IDX(uct).occ        = X1.occ';
        IDX(uct).bio        = X1.bio';
        IDX(uct).dianov     = X1.dianp'; % p for main effect of each 'eye' 'tilt' 'contrast'
        
        IDX(uct).ori0       = X0.ori';
        IDX(uct).occ0       = X0.occ';
        IDX(uct).bio0       = X0.bio';
        IDX(uct).dianov0    = X0.dianp'; % p for main effect of each 'eye' 'tilt' 'contrast'
       
        IDX(uct).SDF       = SDF(:,:,1); %rows = Mpp,BI,dCOS,BI-Mpp,dCOS-Mpp; columns = time;
        IDX(uct).SDF0      = SDF(:,:,2);
        IDX(uct).tm        = TM';
        
        IDX(uct).UV        = UV;
        IDX(uct).MV        = MV;
        IDX(uct).win       = win_ms;
        
        IDX(uct).mc        = MC1; 
        IDX(uct).ts        = TS1; 
        
        IDX(uct).mc0       = MC0;
        IDX(uct).ts0       = TS0;
                
    end
end










