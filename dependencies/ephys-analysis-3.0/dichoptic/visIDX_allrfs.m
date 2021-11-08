clear

savedir = '/Volumes/LaCie/Dichoptic Project/vars/RFs_Oct7_klsmean/'; 
didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Aug24/';
load([didir 'IDX_Oct3b.mat']);

PEN = unique({IDX.penetration});

clear X; uct = 0; 
for i = 1:length(PEN)
    penetration = PEN{i};
    
    % ID all units on this penetration
    clear  matobj units STIM
    matobj       = matfile([didir penetration '_KLS.mat']);
    units = find(...
        strcmp({IDX.penetration},penetration)...
        & [IDX.kls] == 1 );
    STIM = matobj.STIM;
   
   
    for un = 1:length(units)
        % reverse engineer value of "e", see diIDX.m

        clear e
        e = IDX(units(un)).depth(1)+1;
        elabel = STIM.el_labels{e};
       
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
        
        uct = uct +1; 
        X(uct).idx    = units(un);
        X(uct).penetration = penetration; 
        X(uct).elabel = elabel;
        X(uct).depth = IDX(units(un)).depth;
        X(uct).goodfiles = goodfiles;
        X(uct).clusters = STIM.clusters(e,goodfiles);
        X(uct).filelist = STIM.filelist{goodfiles};
            
    end
end

%%

PEN = unique({X.penetration});
TuneList = importTuneList;
for i = 1:length(PEN)
    penetration = PEN{i};
    i
    
    clear s header el
    s = find(strcmp(TuneList.Penetration,penetration));
    header = TuneList.Penetration{s}(1:end-3);
    el     = TuneList.Penetration{s}(end-1:end);
    clear sortdirection
    sortdirection = TuneList.SortDirection{s};
    clear drobo
    switch TuneList.Drobo(s)
        case 1
            drobo = 'Drobo';
        otherwise
            drobo = sprintf('Drobo%u',TuneList.Drobo(s));
    end
    
    paradigm = {'dotmapping'};
    % build filelist
    ct = 0; filelist = {};
    for p = 1:length(paradigm)
        clear exp
        exp = TuneList.(paradigm{p}){s};
        for d = 1:length(exp)
            ct = ct + 1;
            filelist{ct,1} = sprintf('/Volumes/%s/Data/NEUROPHYS/rig%03u/%s_%s/%s_%s_%s%03u',...
                drobo,TuneList.Rig(s),TuneList.Datestr{s},TuneList.Monkey{s},TuneList.Datestr{s},TuneList.Monkey{s},paradigm{p},exp(d));
        end
    end
    
    if ~isempty(filelist)
        
        RF = getRF(filelist,el,sortdirection,{'auto','kilosorted'});
        
        rfdatatype = 'kls_zsr';
        crit0 = 1;
        dthresh = 0.5;
        flag_zcrit = 1;
        I = [];
       
        [uRF, xcord, ycord, elabel]= meanRF(RF,rfdatatype);
        [fRF, dRF, rflim]   = fitRF(uRF,xcord,ycord,I,crit0,dthresh,flag_zcrit);
        
        save([savedir penetration '.mat'],...
            'RF',...
            'rfdatatype','crit0','dthresh','flag_zcrit','I',...
            'uRF','xcord','ycord','elabel',...
            'fRF','dRF','rflim','-v7.3'); 
        
    end
end


%%

list = dir([savedir '*.mat']);
clf; ct = 0; clear ECC AREA PEN

subplot(2,2,1)
for i = 1:length(list)
    load([savedir list(i).name],'fRF')
    load([didir list(i).name],'STIM')
    
    
    for rf = STIM.v1lim(1):STIM.v1lim(end)
        
        centroid = fRF(rf,1:2);
        width    = fRF(rf,3:4);
        
        if width(1)*width(2)*pi < .01
            continue
        end
        
        centroid(1) = abs(centroid(1));
        
        rfboundary = [centroid(1)-width(1)/2,centroid(2)-width(2)/2, width(1), width(2)];
        if ~any(isnan(rfboundary))
            h=rectangle('Position',rfboundary,'Curvature',[1,1]); hold on
            set(h,'EdgeColor','g')
            
            ct = ct + 1;
            
            ECC(ct) = sqrt(sum(centroid .^2)); 
            AREA(ct) = width(1)*width(2)*pi; 
            PEN(ct) = i; 
            
        end
        
    end
end
set(gca,'Box','off','TickDir','out')
axis equal; hold on
plot([0 0],ylim,'m')
plot(xlim,[0 0],'m')

%%
subplot(2,2,2)
scatter(ECC,sqrt(AREA),'o');
set(gca,'Box','off','TickDir','out')
xlabel('Ecc')
ylabel('sqrt(Area)')
title(ct)


