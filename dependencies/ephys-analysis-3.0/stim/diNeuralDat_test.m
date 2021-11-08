function [RESP, win_ms, SDF, sdftm, PSTH, psthtm]= diNeuralDat(STIM,datatype,flag_1kHz,win_ms)


if nargin < 4 || isempty(win_ms)
    win_ms    = [50 100; 150 250; 50 250; -50 0]; % ms;
    % note, when win_ms exceeds stimulus duration, data will be trunkated
end
if nargin < 3 || isempty(flag_1kHz)
    flag_1kHz = true;
end
%%%%%%%%%%%%%%%%%%%%%


    
if ~any(strcmp({'auto','nev','kls','csd','mua','lfp'},datatype))
    % auto = discreat mua, stolen from blackrock
    % mua  = analong mua, a la super
    error('bad datatype')
end


global AUTODIR
if ~isempty(AUTODIR)
    autodir = AUTODIR;
else
    autodir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';
end
global SORTDIR
if ~isempty(SORTDIR)
    sortdir = SORTDIR;
else
    sortdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';
end

bin_ms    = 10;
nwin      = size(win_ms,1);

switch datatype
    case 'kls'
        el_labels = STIM.el_labels;
        nel       = length(STIM.units);
    otherwise
        el_labels = STIM.el_labels; % Changed by BMC 4/7/20
        nel       = length(el_labels);
end


switch datatype
    case {'nev','kls','auto','mua'}
       
        Fs = 30000;
        TP = STIM.tp_pt;
        
        RESP      = nan(nel,nwin,length(STIM.tp_pt));
        
        bin_sp    = bin_ms/1000*Fs;
        psthtm    = [-0.3*Fs : bin_sp : 0.15*Fs + max(diff(TP,[],2)) + bin_sp];
        PSTH      = nan(nel,length(psthtm),length(STIM.tp_pt));
        
        if ~flag_1kHz
            r = 1;
        else
            r = 30;
        end
        sdftm     = [-0.3*Fs/r: 0.15*Fs/r + max(diff(TP,[],2)/r)];
        SDF       = nan(nel,length(sdftm),length(STIM.tp_pt));
        k         = jnm_kernel( 'psp', (20/1000) * (Fs/r) );

        
    case {'csd','lfp'}
        Fs = 1000;
        TP = round(STIM.tp_pt ./ 30); %DEV: make TP/r relationship clearer, it's handeled diffrently for spk data
        r = 1; 
        
        RESP      = nan(nel,nwin,length(STIM.trl));
        
        sdftm     = [-0.3*Fs: 0.15*Fs + max(diff(TP,[],2))]; 
        SDF       = nan(nel,length(sdftm),length(STIM.trl));
        
        psthtm     = [];
        PSTH      = [];
        
%     case {'mua'}
%         Fs = 30000;
%         TP = STIM.tp_pt;
%         
%         RESP      = nan(nel,nwin,length(STIM.tp_pt));
%         sdftm_raw = [-0.3*Fs/1: 0.15*Fs/1 + max(diff(TP,[],2)/1)];
%         
%         
%         if ~flag_1kHz
%             r         = 1;
%             sdftm = sdftm_raw;
%         else
%             r         = 30;
%             sdftm     = downsample(sdftm_raw,r);
%         end
%         SDF       = nan(nel,length(sdftm),length(STIM.tp_pt));
%         
%         psthtm     = [];
%         PSTH       = [];
 
end

% iterate trials, loading files as you go
for i = 1:length(STIM.trl)
    
    if i == 1 || STIM.filen(i) ~= filen %% BMC DEV -- dig into this line
        
        clear filen filename BRdatafile
        filen = STIM.filen(i);
        filename  = STIM.filelist{filen};
        [~,BRdatafile,~] = fileparts(filename);
        
        % setup SPK cell array
        SPK   = cell(nel,1);
        empty = false(size(SPK)); 
        
        switch datatype
            case 'auto'
                clear autofile NEV nev_labels nix SPK
                autofile = [autodir BRdatafile '.ppnev'];
                if ~exist(autofile,'file')
                    error('no .ppnev for %s',BRdatafile)
                end
                load(autofile,'-MAT','ppNEV');
                NEV = ppNEV; clear ppNEV;
                nev_labels  = cellfun(@(x) x(1:4)',{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0);
                [~,~,ib]=intersect(el_labels,nev_labels,'stable');
                for e=1:length(ib)
                    SPK{e,1} = NEV.Data.Spikes.TimeStamp(NEV.Data.Spikes.Electrode == ib(e));
                end
            case 'nev'
                clear autofile NEV nev_labels nix SPK
                NEV = openNEV([filename '.nev']);
                nev_labels  = cellfun(@(x) x(1:4)',{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0);
                [~,~,ib]=intersect(el_labels,nev_labels,'stable');
                for e=1:length(ib)
                    SPK{e,1} = NEV.Data.Spikes.TimeStamp(NEV.Data.Spikes.Electrode == ib(e));
                end
            case 'kls'
                % load KS data, never concatenated
                % diClusters already screened and assigned units
                for e=1:nel
                    filematch = STIM.units(e).fileclust(:,2) == filen;
                    if filematch
                        break
                    end
                end
                if filematch
                    load([sortdir BRdatafile '/ss.mat'],'ss');
                    for e=1:nel
                        idx = find(STIM.units(e).fileclust(:,2) == filen);
                        if isempty(idx)
                            empty(e) = true; 
                        else
                            clust = STIM.units(e).fileclust(idx,1);
                            SPK{e,1} = ss.spikeTimes(ismember(ss.spikeClusters,clust));
                        end
                    end
                end
          
                
            case {'csd','lfp'}
                clear ns2file ns_header
                ns2file    = [filename '.ns2'];
                ns_header  = openNSx(ns2file,'noread');
                
                clear elb idx e
                elb = cellfun(@(x) (x(1:4)),{ns_header.ElectrodesInfo.Label},'UniformOutput',0);
                idx = zeros(1,length(el_labels));
                for e = 1:length(el_labels)
                    idx(e) = find(strcmp(elb,el_labels{e}));
                end
                
            case 'mua'
                clear ns6file ns_header
                ns6file    = [filename '.ns6'];
                ns_header  = openNSx(ns6file,'noread');
                
                clear elb idx e
                elb = cellfun(@(x) (x(1:4)),{ns_header.ElectrodesInfo.Label},'UniformOutput',0);
                idx = zeros(1,length(el_labels));
                for e = 1:length(el_labels)
                    idx(e) = find(strcmp(elb,el_labels{e}));
                end
        end
    end
    
    
    % get TP and rwin
    clear tp rwin
    tp = TP(i,:) ;
    if any(isnan(tp))
        continue
    end
    
    rwin = tp(1) + (win_ms/1000*Fs);
    % deal with instnaces where the window exceeds stimulus offset
    stimoff = rwin > tp(2); 
    rwin(stimoff)  = tp(2); 
    
    switch datatype
        case 'csd'           
             for w = 1:nwin
                 if rwin(w,1) == rwin(w,2)
                     continue
                 end
                 timeperiod = sprintf('t:%u:%u', rwin(w,1),rwin(w,2));
                 NS = openNSx(ns2file,timeperiod,...
                     'read','sample');
                 dat = double((NS.Data(idx,:)))' ./ 4;  clear NS; 
                 dat = calcCSD(dat) * 0.4;
                 dat(dat>0) = 0; % half wave rectified, only for RESP
                 dat = mean(abs(dat),2); 
                 RESP(2:end-1,w,i) = dat;
             end
            
             if tp(1) + sdftm(end) > ns_header.MetaTags.DataPoints 
                 continue
             end
             timeperiod = sprintf('t:%u:%u',tp(1) + [sdftm(1) sdftm(end)]);
             NS = openNSx(ns2file,timeperiod,...
                 'read','sample');
             dat = double((NS.Data(idx,:)))' ./ 4; clear NS; %dat is (tp x el)
             dat = calcCSD(dat) * 0.4; %output of calcCSD is transposed. i.e. output is (el x tp)
             dat(:,sdftm > diff(tp)) = [];
             SDF(2:end-1,1:length(dat),i) = dat; % normal continous
             
          case 'lfp'            
             for w = 1:nwin
                 if rwin(w,1) == rwin(w,2)
                     continue
                 end
                 timeperiod = sprintf('t:%u:%u', rwin(w,1),rwin(w,2));
                 NS = openNSx(ns2file,timeperiod,...
                     'read','sample');
                 dat = double((NS.Data(idx,:)))' ./ 4;  clear NS; 
                 RESP(:,w,i) = nanmean(dat,1);
             end
            
             if tp(1) + sdftm(end) > ns_header.MetaTags.DataPoints 
                 continue
             end
             timeperiod = sprintf('t:%u:%u',tp(1) + [sdftm(1) sdftm(end)]);
             NS = openNSx(ns2file,timeperiod,...
                 'read','sample');
             dat = double((NS.Data(idx,:))) ./ 4; clear NS; 
             dat(:,sdftm > diff(tp)) = [];
             SDF(:,1:length(dat),i) = dat;

        case 'mua'
            
            clear samplenum samplevec
            samplenum = tp(1) + r.*[sdftm(1) sdftm(end)];
            samplevec = samplenum(1):samplenum(end);
            
            if samplenum(end) > ns_header.MetaTags.DataPoints
                warning('excluding data you may not have to')
                continue
            end
            
%            % filter settings
%             lpc1 = 500;
%             hpc  = 5000;
%             nyq  = Fs/2;
%             lpc2 = lpc1 / 2;
%             hWn = hpc / nyq;
%             [ bwb1, bwa1 ] = butter( 4, hWn, 'high' );
%             lWn1 = lpc1 / nyq;
%             [ bwb2, bwa2 ] = butter( 4, lWn1, 'low' );
%             lWn2 = lpc2 / nyq;
%             [ bwb3, bwa3 ] = butter( 4, lWn2, 'low' );            
%             
            clear NS dat dat0 dat1 timeperiod hpMUA lpMUA 
            timeperiod = sprintf('t:%u:%u',samplenum);
            NS = openNSx(ns6file,timeperiod,...
                'read','sample');

            dat0 = double((NS.Data(idx,:)))';  clear NS;
            trim = 1 + (length(dat0)-length(samplevec)); 
            dat  = f_calcMUA2D(dat0(trim:end,:),Fs);
            
            if length(dat) ~= length(samplevec)
                error('lengths do not match'); 
            end
            
%             hpMUA = filtfilt(bwb1,bwa1,dat0);
%             lpMUA = abs( filtfilt( bwb2, bwa2, hpMUA ) );
%             dat = filtfilt( bwb3, bwa3, lpMUA ) ./ 4;
%             
            for w = 1:nwin
                if rwin(w,1) == rwin(w,2)
                    continue
                end
                tmlim = samplevec >= rwin(w,1)  & samplevec <= rwin(w,2); 
                RESP(:,w,i) = nanmean(dat(tmlim,:),1);
            end
             
            if r > 1
                mua = downsample(dat,r); clear dat
            else 
                mua = dat; clear dat
            end
            mua(sdftm > diff(tp/r),:) = [];
            SDF(:,1:length(mua),i) = mua';
             
        otherwise
            
            for w = 1:nwin
                % scaler value
                clear spk x
                spk = cellfun(@(x) sum(x>=rwin(w,1) & x<=rwin(w,2)),SPK) ;
                x = spk ./ (diff(rwin(w,:)) / Fs);
                x(empty) = NaN; 
                RESP(:,w,i) = x; 
            end
            
            for e = 1:length(SPK)
                if empty(e)
                    continue
                end
                clear spk sua psth sdf x;
                if ~flag_1kHz
                    x = SPK{e} - tp(1);
                else
                    x = unique(round((SPK{e} - tp(1)) ./r ));
                end
                
                [spk,spktm,~] = intersect(sdftm,x,'stable') ;
                sua = zeros(size(sdftm));
                
                if ~isempty(spk)
                    psth = histc(spk,psthtm) .* (Fs/bin_sp);
                    PSTH(e,psthtm<=diff(tp),i) = psth(psthtm<=diff(tp));
                    
                    sua(spktm) = 1;
                    sdf = conv(sua,k,'same') * Fs/r;
                else
                    sdf = sua;
                end
                sdf(sdftm > diff(tp/r)) = [];
                SDF(e,1:length(sdf),i) = sdf;
            end
    end
end % done iterating trials


% remove last bin (inf) and center time vector
if ~isempty(PSTH)
    PSTH(:,end,:) = [];
    psthtm(end) = [];
    psthtm = psthtm + bin_sp/2;
    % convert time vector to seconds
    psthtm = psthtm./Fs;
end

% convert time vector to seconds
sdftm = sdftm./(Fs/r);

% trim SDF of convolution extreams %MAY NEED DEV
trim = sdftm < -0.15 | sdftm > sdftm(end) -0.15;
sdftm(trim) = [];
SDF(:,trim,:) = [];

% trim PSTH to match
if ~isempty(PSTH)
    trim = psthtm < -0.15 | psthtm > psthtm(end) -0.15;
    psthtm(trim) = [];
    PSTH(:,trim,:) = [];
end
