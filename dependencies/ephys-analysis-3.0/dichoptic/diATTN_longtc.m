clear

cd('/Volumes/LaCie/Dichoptic Project/plots/diATTN_longtc_nonpref/')

didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Aug18/';
list  = dir([didir '*_AUTO.mat']);

alpha = 0.05;
delta_tilt = 20;
whichwin = 1;
r = 30;

autodir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';
uct = 0;
for i = length(list):-1:1
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
    
    clear RESP matobj win_ms sdftm CLUST
    load([didir list(i).name],...
        'win_ms','sdftm','CLUST')
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
        ahahaha
        continue
    end
    bhvevt = []; 
    for e = 1:nel
        
        
        clear dat ANP U SD N CI VARS
        dat  = squeeze(RESP(e,I));
        ANP  = anovan(dat,group,'varnames',gname,'display','off');
        [U,SD,N,CI,VARS] = grpstats(dat,group,{'mean','std','numel','meanci','gname'});
        VARS = str2double(VARS);
        
        if all(U==0)
            continue
        end
        
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
        
        clear mI
        mI = STIM.eye == nulleye & ...
            STIM.tilt(:,1) == nullori & ...
            STIM.monocular & ...
            STIM.contrast(:,1) == diContrast(end);
        if all(STIM.cued(mI) == 0)
            continue
        end
        %%
        clf; clear SDF; 
        filen = 0; colors = [.7 1 1; .7 .7 .7; 1 .7 1];
        for cue = -1:1:1
            ct = 0;
            trls = find(mI & STIM.cued == cue);
            if isempty(trls)
                continue
            end
            
            for t = 1:length(trls)
                tr = trls(t);
                
                if  filen ~= STIM.filen(tr,:)
                    
                    clear filen filename BRdatafile
                    filen = STIM.filen(tr);
                    filename  = STIM.filelist{filen};
                    [~,BRdatafile,~] = fileparts(filename);
                    
                    clear autofile NEV
                    autofile = [autodir BRdatafile '.ppnev'];
                    load(autofile,'-MAT','ppNEV');
                    NEV = ppNEV; clear ppNEV;
                    
                    clear nev_labels nidx SPK Fs k
                    nev_labels  = cellfun(@(x) x(1:4)',{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0);
                    nidx = find(strcmp(nev_labels,STIM.el_labels(e)));
                    SPK = NEV.Data.Spikes.TimeStamp(NEV.Data.Spikes.Electrode == nidx);
                    SPK = unique(round(SPK/r));
                    Fs = double(NEV.MetaTags.SampleRes);
                    k  = jnm_kernel( 'psp', (20/1000) * (Fs/r) );
                    
                    clear bhv
                    if strcmp(STIM.task{tr}(1:4),'rsvp'); 
                        bhvfile = [STIM.filelist{filen} '.bhv']; 
                        if exist(bhvfile,'file') && isempty(bhvevt)
                            bhv=concatBHV([STIM.filelist{filen} '.bhv']);
                            
                            bI = cellfun(@(x) any(x == 27), bhv.CodeNumbers,'UniformOutput',1);
                            bhvevt(1)  = median(cellfun(@(x,y) y(find(x == 23,1)) - y(find(x == 27,1)),bhv.CodeNumbers(bI),bhv.CodeTimes(bI),'UniformOutput',1));

                            if any(cellfun(@(x) any(x == 25), bhv.CodeNumbers,'UniformOutput',1));
                                % mask
                                bhvevt(2) = median(cellfun(@(x,y) y(find(x == 25,1)) - y(find(x == 27,1)),bhv.CodeNumbers(bI),bhv.CodeTimes(bI),'UniformOutput',1));
                            end
                        end
                    end
                end
                
                clear tp;
                tp = round(STIM.tp_sp(tr,:) ./ r);
                tm = -1.5*Fs/r : 1*Fs/r;
                tm = tm';
                
                clear spk  spktm
                [spk,spktm,~] = intersect(tm,SPK - tp(1),'stable') ;
                sua = zeros(size(tm));
                if any(spk)
                    sua(spktm) = 1;
                    sdf = conv(sua,k,'same') * Fs/r;
                else
                    sdf = sua;
                end
                
                plot(tm,sdf,'color',colors(cue+2,:),'LineWidth',0.3); hold on;
                ct = ct +1;
                SDF{cue+2}(:,ct) = sdf;
                
            end
            
        end
        
        colors = 2*(colors - 0.7);lw=[2 1 2];
        for cue = 1:length(SDF);
            plot(tm,mean(SDF{cue},2),'Color',colors(cue,:),'LineWidth',lw(cue)); hold on
        end
        axis tight
        set(gca,'box','off','tickdir','out')
        plot([0 0],ylim,'k')
        plot([bhvevt(1) bhvevt(1)],ylim,':k')
        
        if ~any(STIM.rsvpmask)
            xlabel(sprintf('Time (ms)\n%s - NO MASK',STIM.task{tr}),'interpreter','none')
        else
            xlabel(sprintf('Time (ms)\n%s - MASK Present',STIM.task{tr}),'interpreter','none')
            plot([bhvevt(2) bhvevt(2)],ylim,':k')
        end
        ylabel(sprintf('Null Eye & Null Ori\nMUA (imp./s)'))
        title(sprintf('%s %s',STIM.header,NEV.ElectrodesInfo(nidx).ElectrodeLabel'),'interpreter','none')
        saveas(gcf,sprintf('%s-attntc-mua-%s',STIM.header,NEV.ElectrodesInfo(nidx).ElectrodeLabel'),'png')
   
    end
end

