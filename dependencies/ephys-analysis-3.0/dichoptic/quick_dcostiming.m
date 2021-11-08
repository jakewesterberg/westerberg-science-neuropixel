clear

paradigm = {... %evp
    'cosinteroc','mcosinteroc','brfs',...
    'rsvp'};

TuneList = importTuneList(1);    
load(alignvar,'ALIGN');

for s = length(TuneList.Penetration)
    
    clear penetration header el sortdirection V1
    penetration = TuneList.Penetration{s};
    header = TuneList.Penetration{s}(1:end-3);
    el     = TuneList.Penetration{s}(end-1:end);
    sortdirection = TuneList.SortDirection{s};
    V1 = TuneList.Structure{s};
    
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
        clear exp
        exp = TuneList.(paradigm{p}){s};
        for d = 1:length(exp)
            ct = ct + 1;
            filelist{ct,1} = sprintf('/Volumes/%s/Data/NEUROPHYS/rig%03u/%s_%s/%s_%s_%s%03u',...
                drobo,TuneList.Rig(s),TuneList.Datestr{s},TuneList.Monkey{s},TuneList.Datestr{s},TuneList.Monkey{s},paradigm{p},exp(d));
        end
    end
    
    clear STIM diori
    STIM        = getDiTPs(filelist,V1);
    uTilt       = nanunique(STIM.tilt); 
    uContrast   = nanunique(STIM.tilt);
    
    for i = 1:length(STIM.trl)
        
        if i == 1 || STIM.filen(i) ~= filen;

            % file info
            clear filen filename BRdatafile
            filen = STIM.filen(i);
            filename  = STIM.filelist{filen};
            [~,BRdatafile,~] = fileparts(filename); 
            
             % re-trigger TPs
            clear I newTP trigger
            I = STIM.filen == filen;
            [newTP,trigger] = photoReTrigger(...
                STIM.tp_sp(I,:),...
                filename,...
                STIM.ypos(I,:));
            if isempty(newTP) %DEV
                filename
                trigger
                continue
            else
                photoTP(I,:) = newTP;
            end 
            
            % get SPK from auto file
            clear autofile NEV nev_labels nix SPK
            autofile = [autodir BRdatafile '.ppnev'];
            load(autofile,'-MAT','ppNEV');
            NEV = ppNEV; clear ppNEV; 
            Fs = double(NEV.MetaTags.TimeRes); 
            nev_labels  = cellfun(@(x) x(1:4)',{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0);
            [~,~,nix]=intersect(in_labels,nev_labels,'stable');
            SPK = cell(length(nix),1);
            for e=1:length(nix)
                SPK{e,1} = NEV.Data.Spikes.TimeStamp(NEV.Data.Spikes.Electrode == nix(e));
            end
                      
        end
        
        % back to interating trials
        clear tp 
        tp = photoTP(i,:); 
        if any(isnan(tp))
            continue
        end
        
        clear spk
        spk = cellfun(@(x) sum(x>=tp(1) & x<=tp(2)),SPK) ; 
        RESP(:,i) = spk ./ (diff(tp) / Fs);
    end
    
    
    dddd
end