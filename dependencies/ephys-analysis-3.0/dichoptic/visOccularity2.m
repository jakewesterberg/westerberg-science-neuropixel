clear

respdir  = '/Volumes/Drobo2/USERS/Michele/Layer Tuning/stimevoked/April23/';
rfdir    = '/Volumes/Drobo2/USERS/Michele/Layer Tuning/getRF/April21_muazsr/';
tunedir  = '/Volumes/Drobo2/USERS/Michele/Layer Tuning/getTune/Apr24/';

figdir   = '/Users/coxm/Dropbox (MLVU)/_SCRUM/';

% params for v1 limits
rfcrit0 = 1; % z-score
dthresh = 0.5; % dva
stimcrit0 = 0.25;

% params for tuning calculation
datatype = 'kls_raw';
flag_sigonly = 2;  % 1 = ttest across eye, 2 = ttest from baseline (not for CSD), 3 = no selection
alphacrit = 0.05; %
flag_norm = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TuneList = importTuneList;

clear DIST;
zeropt = {'top','sink','btm'};
for z = 1:length(zeropt);
    DIST.(zeropt{z}) = nan(length(TuneList.Penetration),3);
end

clear RESULT Y
Y = [-25:25] ./10;
Y = flipud(Y');
RESULT.tstat = nan(length(Y),length(zeropt),length(TuneList.Penetration));
RESULT.mc = nan(length(Y),length(zeropt),length(TuneList.Penetration));


figure('Position',[0 0 601 874]);

for s = 1:length(TuneList.Penetration)
    
    clear name sortdirection L4
    name = TuneList.Penetration{s};
    sortdirection = TuneList.SortDirection{s};
    L4 = TuneList.SinkBtm(s);
    
    % load tuning
    clear STIM
    load([tunedir filesep name '.mat']);
    % check trls per eye
    [n, eye]=hist(STIM.eye,1:3);
    if any([n(2) n(3)] < 10)
        continue
    end
    
    % V1 limits based on RF
    load([rfdir filesep name '.mat'],'uRF','xcord','ycord')
    [fRF, dRF, rflim]   = fitRF(uRF,xcord,ycord,rfcrit0,dthresh);
    
    % V1 limits based on SNR
    load([respdir filesep name '.mat'],'uR');
    idx = find(uR > stimcrit0);
    if isempty(idx)
        stimlim    = [NaN NaN];
    else
        stimlim    = [min(idx) max(idx)];
    end
    
    % organize vertical demension of data relative to markers
    clear y elnum top btm
    elnum = cellfun(@(x) str2double(x(3:4)),STIM.elabel);
    switch sortdirection
        case 'ascending'
            y.sink = L4 - elnum;
        case 'descending'
            y.sink = elnum - L4;
    end
    L4 = find(y.sink==0);
    y.sink = (y.sink ./ 10)';
    
    top = min([rflim(1) stimlim(1)]);
    btm = max([rflim(2) stimlim(2)]);
    
    y.top = (top - [1:max(elnum)]') ./ 10;
    y.btm = (btm - [1:max(elnum)]') ./ 10;
    y.lim = zeros(size(y.sink)); y.lim(top:btm) = 1; y.lim = logical(y.lim);
    y.idx = false(size(y.sink)); y.idx([top L4 btm]) = true;
    
    % exctact CSD, check for sig responses from baseline.
    clear H
    if strcmp(datatype,'csd')
        tl = STIM.evp_tm > 30 & STIM.evp_tm < 80;
        STIM = csdTune(STIM,top:btm,'tl','sink');
        H = ones(length(STIM.elabel),1);
    else
        units = find(~all(isnan(STIM.([datatype(1:4) 'dif'])),2));
        H = zeros(length(STIM.elabel),1);
        for u = 1:length(units)
            x = STIM.([datatype(1:4) 'dif'])(units(u),:);
            H(units(u)) = ttest(x,0,'tail','right');
        end
    end
    H(isnan(H)) = 0; 
    H = logical(H);
    
    % normalize data if requested
    if flag_norm
        STIM = normTune(STIM,datatype,'within');
        ndatatype = ['nrm_' datatype];
    else
        ndatatype = datatype;
    end
    
    
    % MC and t-test across eyes
    % (DEV: make sure eye conditions are blanced)
    M = nan(length(STIM.elabel),1);
    P = nan(length(STIM.elabel),1);
    T = nan(length(STIM.elabel),1);
    for j = 1:length(STIM.elabel)
        eye2 = mean(STIM.(ndatatype)(j,STIM.eye == 2));
        eye3 =  mean(STIM.(ndatatype)(j,STIM.eye == 3));
        M(j) = (eye2-eye3) / (eye2+eye3);
        [~,p,~,stats]= ttest2(...
            STIM.(ndatatype)(j,STIM.eye == 2),...
            STIM.(ndatatype)(j,STIM.eye == 3));
        P(j) = p;
        T(j) = stats.tstat;
    end
    P = P < alphacrit;
    
    
    clear I
    if flag_sigonly == 1
        I = y.lim & P;
        sigstr = 'units = sig diff across eyes';
    elseif flag_sigonly == 2
        I = y.lim & H;
        sigstr = 'units = sig resp from baseline';
    else
        I = y.lim;
        sigstr = 'units = all';
    end
    I = I & ~(isnan(M) | isnan(T));
    if ~any(I)
        continue
    end
    
    
    
    clear xx tt
    xx = (M(I));
    tt = (T(I));
    for z = 1:length(zeropt);
        
        clear yy  idx
        yy = y.(zeropt{z})(I) ;
        [~,idx] = sort(yy);
        
        subplot(2,3,z); hold on
        h1 = plot(yy(idx),xx(idx),'LineStyle','none');
        
        subplot(2,3,z+3); hold on
        h2 = plot(yy(idx),tt(idx),'LineStyle','none');
        
        if strcmp(TuneList.Monkey{s},'E')
            set([h1 h2],'Marker','x')
        else
            set([h1 h2],'Marker','d')
        end

        
        % save for across-session
        DIST.(zeropt{z})(s,:) = y.(zeropt{z})(y.idx);
        [~,overlap]=intersect(Y,yy,'stable');
        RESULT.mc(overlap,z,s) = (xx);
        RESULT.tstat(overlap,z,s) = (tt);
        
    end
    
end

for z = 1:3;
    for w = 0:3:3
        subplot(2,3,z+w)
        axis tight; box off
        if w == 0
            ylabel('|M.C|')
            ylim([-1 1])
        else
            ylabel('|T-Stat|')
            ylim([-25 25])
        end
        
        plot([nanmean(DIST.(zeropt{z}));nanmean(DIST.(zeropt{z}))],ylim,'r','LineWidth',2)
        plot(xlim,[0 0],'k')
        view(90,-90)
        xlabel(sprintf('Distance from %s',upper(zeropt{z})))
       
         if z == 2 && w == 0
            n_units    = sum(sum(~isnan(RESULT.mc(:,z,:)),3));
            n_sessions = size(RESULT.mc(:,:,:),3);
            
            titlestr = sprintf('%s\n%u units over %u sessions\n(%s)',upper(datatype),n_units,n_sessions,sigstr);
            title(titlestr,'interpreter','none')
            
        end
        
    end
end

%%

MONK = {'E','I'}';

for m=1:2
    clear mI
    if any(m == [1 2])
        mI =  strcmp(TuneList.Monkey,MONK{m});
        monkstr = ['Monkey ' MONK{m}]; 
    else
        mI = true(size(TuneList.Monkey));
        monkstr = ['BothM']; 
    end

figure('Position',[0 0 601 874]);
for z = 1:3;
    for w = 0:3:3
        subplot(2,3,z+w)
        
        if w == 0
            u = squeeze(nanmean(abs(RESULT.mc(:,z,mI)),3));
            s = squeeze(nanstd(abs(RESULT.mc(:,z,mI)),[],3));
            n = squeeze(sum(~isnan(RESULT.mc(:,z,mI)),3));
            ylabelstr = ('|M.C|');
        else
            u = squeeze(nanmean(abs(RESULT.tstat(:,z,mI)),3));
            s = squeeze(nanstd(abs(RESULT.tstat(:,z,mI)),[],3));
            n = squeeze(sum(~isnan(RESULT.tstat(:,z,mI)),3));
            ylabelstr = ('|T-Stat|');
        end
        
        e = s ./ sqrt(n);
        keep = ~isnan(u) ; %& n > 3 ;
        
        %bar(Y(keep),u(keep)); hold on
        ul = e; %ul(u<=0)=0;
        ll = e; %ll(u>=0)=0;
        errorbar(Y(keep),u(keep),ll(keep),ul(keep),'b','LineStyle','-','Marker','o'); hold on
                axis tight; box off

        plot([nanmean(DIST.(zeropt{z})(mI,:));nanmean(DIST.(zeropt{z})(mI,:))],ylim,'r','LineWidth',2)
        
        
        view(90,-90)
        xlabel(sprintf('Distance from %s',upper(zeropt{z})))
        ylabel(ylabelstr)
        
        
        if z == 2 && w == 0
            n_units    = sum(sum(~isnan(RESULT.mc(:,z,mI)),3));
            n_sessions = size(RESULT.mc(:,:,mI),3);
            
            titlestr = sprintf('%s - %s\n%u units over %u sessions\n(%s)',upper(datatype),monkstr,n_units,n_sessions,sigstr);
            title(titlestr,'interpreter','none')
            
        end
        
    end
end

saveas(gcf,sprintf('%s/%s-sig%u-m%u.png',figdir,datatype,flag_sigonly,m))

end
