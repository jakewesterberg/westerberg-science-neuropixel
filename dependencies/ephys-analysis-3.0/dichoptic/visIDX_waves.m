clear

didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Aug24/';
load([didir 'IDX_Oct7a.mat']);
klsdir   = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';
PEN = unique({IDX.penetration});

clear X; uct = 0;
for i = 1:length(PEN)
    figure
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
        goodfiles = goodfiles(strcmp(STIM.paradigm(goodfiles),'rfori')); 
        if isempty(goodfiles)
            continue
        end
        clear  clusters filelist
        clusters = STIM.clusters(e,goodfiles);
        filelist = STIM.filelist(goodfiles);
        
        
        for c = 1:length(clusters)
            [~,filename,~] = fileparts( filelist{c});
            
            clear ss
            klsfile  = [klsdir filename filesep 'ss.mat'];
            load(klsfile,'ss');
            
            if isempty(ss.spikeWaves)
                load(klsfile,'WAVE','tmW');
                ss.spikeWaves = WAVE; clear WAVE
                ss.spikeWavesTM = tmW; clear tmW
            end
            
            clear cI kI wave err
            cI   =  ss.spikeClusters == clusters(c);
            kI   = strcmp(ss.chanIDs,elabel);
            wave = squeeze(nanmean(ss.spikeWaves(kI,:,cI),3));
            err  = squeeze(nanstd(ss.spikeWaves(kI,:,cI),[],3)) ./ sqrt(sum(cI));
            
            subplot(length(units),...
                sum(strcmp(STIM.paradigm,'rfori')),...
                c + (un-1)*sum(strcmp(STIM.paradigm,'rfori')))
            
            ph = plot(ss.spikeWavesTM,wave-wave(1)); hold on
            plot(ss.spikeWavesTM,wave-err-wave(1),':','color',get(ph,'color')); hold on
            plot(ss.spikeWavesTM,wave+err-wave(1),':','color',get(ph,'color')); hold on
            axis tight;
            set(gca,'Box','off','TickDir','out')
            
            title(sprintf('%s_%s',filename,elabel),'interpreter','none')
        end
    end
    
end