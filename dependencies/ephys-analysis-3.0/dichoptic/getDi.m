function STIM  = getDi(filelist,el,sortdirection,datatype)

% filelist must include path to dir with NEV, stimulus text files, NS6

if nargin < 4
    datatype = 'all';
end

flag_RewardedTrialsOnly   = false;
flag_usePhotodiodeTrigger = false;

obs = 0; clear TN mua nev evp kls ato

fpath              = fileparts(filelist{1});
STIM.name          = [fpath(end-7:end) '_' el];
STIM.header        = fpath(end-7:end);
STIM.filelist      = filelist;
STIM.el            = el;
STIM.elabel        = {};

STIM.muadat        = NaN(1,length(filelist));
STIM.nevdat        = NaN(1,length(filelist));
STIM.klsdat        = NaN(1,length(filelist));
STIM.atodat        = NaN(1,length(filelist));
STIM.evpdat        = NaN(1,length(filelist));

for j = 1:length(filelist)
    filename = filelist{j};
    [~,BRdatafile,~] = fileparts(filename);
    
    %% load digital codes and neural data:
    if exist(strcat(filename,'.nev'),'file') == 2;
        NEV = openNEV(strcat(filename,'.nev'),'noread','nomat','nosave');
    else
        error('the NEV file does not exist\n%s.nev',filename);
    end
    % get event codes from NEV
    EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
    EventSampels = double(NEV.Data.SerialDigitalIO.TimeStamp);
    if isempty(EventSampels) || isempty(EventCodes)
        continue
    end
    [pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);
    evtFs = double(NEV.MetaTags.SampleRes);
    
    %% get NSx Header for nel
    
    % Read in NS Header
    NS6_header = openNSx([filename '.ns6'],'noread');
    NS2_header = openNSx([filename '.ns2'],'noread');
    
    % arrange channels as needed
    elb = cellfun(@(x) (x(1:4)),{NS6_header.ElectrodesInfo.Label},'UniformOutput',0);
    prb = find(~cellfun('isempty',strfind({NS6_header.ElectrodesInfo.Label},el)));
    idx = zeros(1,length(prb));
    for e = 1:length(prb)
        elable = [el num2str(e,'%02u')];
        idx(e) = find(strcmp(elb,elable));
    end
    % most superficial channel on top, regardless of number
    switch sortdirection
        case 'descending'
            idx = fliplr(idx);
    end
    
    %% get stimunuls info
    clear grating ext
    if ~isempty(strfind(filename,'ori'))
        ext = '.gRFORIGrating_di';
    elseif ~isempty(strfind(filename,'sf'))
        ext = '.gRFSFGrating_di';
    end
    grating = readgGrating([filename ext]);
    
    % check that all is good between NEV and grating text file;
    [allpass, message] =  checkTrMatch(grating,NEV);
    if ~allpass
        %continue
        error('%s Failed checkTrMatch, Message as follows:\n\t%s\n\t%s\n\t%s',filename,message{:})
    end
    
    % load NEV Spikes and kilosort if availible / requested
    if any(strcmp({'nev','all','spiking'},datatype))
        NEV            = openNEV(strcat(filename,'.nev'),'overwrite');
        STIM.nevdat(j) = any(NEV.Data.Spikes.TimeStamp);
    end
    
    if any(strcmp({'ppnev','all','spiking','autosort','auto'},datatype))
        autosortdir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';
        if exist([autosortdir BRdatafile '.ppnev'],'file')
            STIM.atodat(j) = 0;
            load([autosortdir BRdatafile '.ppnev'],'-mat')
        else
            STIM.atodat(j) = 0;
        end
    end
    
    if any(strcmp({'kilosort','all','spiking'},datatype))
        % NOT CONCATENATED DATA
        kilodirname = sprintf('/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/%s/',BRdatafile);
        if exist([kilodirname 'rez.mat'],'file')
            STIM.klsdat(j) = 1;
            % load ss structure
            if exist([kilodirname 'ss.mat'],'file')
                load([kilodirname 'ss.mat'],'-mat');
            else
                ss = KiloSort2SpikeStruct(BRdatafile,1);
            end
        else
            STIM.klsdat(j) = 0;
        end
    end
    
    
    %% photodiode trigger (needed stim info 1st)
    if flag_usePhotodiodeTrigger
        [pEvT_photo,tf] = pEvtPhoto(filename,pEvC,pEvT,mode(grating.ypos),[],'ainp1',0);
        if ischar(tf)
            flag_usePhotodiodeTrigger = false;
            fprintf('\nNot Using pEvT_photo: %s\n%s\n','ainp1',tf)
        elseif tf
            disp('Triggered to Photodiode + Constant Offset')
        else
            disp('Triggered to EventCode + Constant Offset')
        end
    end
    
    %% Find trigger poitns
    trls = find(cellfun(@(x) sum(x == 23) == sum(x == 24),pEvC));
    for tr = 1:length(trls)
        t = trls(tr);
        
        if flag_RewardedTrialsOnly && ~any(pEvC{t} == 96)
            % skip if not rewarded (event code 96)
            continue
        end
        
        stimon  =  pEvC{t} == 23 | pEvC{t} == 25  | pEvC{t} == 27   | pEvC{t} == 29  | pEvC{t} == 31;
        stimoff =  pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32;
        
        if flag_usePhotodiodeTrigger
            start = pEvT_photo{t}(stimon);
        else
            start = pEvT{t}(stimon);
        end
        finish = pEvT{t}(stimoff);
        stim =  find(grating.trial == t);
        
        maxpres = min([length(start) length(finish) length(stim)]);
        
        for p = 1:maxpres
            
            % get correct row in text file
            pidx = find(grating.trial == t & grating.pres == p);
            if isempty(pidx)
                continue
            end
            
            % stimulus data
            obs = obs + 1;
            
            STIM.xpos(1,obs)       = grating.xpos(pidx);
            STIM.ypos(1,obs)       = grating.ypos(pidx);
            STIM.eye(1,obs)        = grating.eye(pidx);
            
            STIM.tilt(1,obs)       = grating.tilt(pidx);
            STIM.sf(1,obs)         = grating.sf(pidx);
            
            STIM.contrast(1,obs)   = grating.contrast(pidx);
            STIM.diameter(1,obs)   = grating.diameter(pidx);
            STIM.gabor(1,obs)      = grating.gabor(pidx);
            
            STIM.pres(1,obs)       = p;
            STIM.filen(1,obs)      = j;
            STIM.st(1,obs)         = start(p);
            STIM.en(1,obs)         = finish(p);
            if obs == 1
                STIM.evtFs         = evtFs;
            end
            
            
            if any(strcmp({'mua','all','spiking'},datatype))
                
                % store logical
                STIM.muadat(j) = 1;
                
                % convert NEV Event Times to FS as needed
                clear Fs conv st en pre
                Fs = double(NS6_header.MetaTags.SamplingFreq);
                conv = Fs/evtFs;
                st   = round(start(p) * conv);
                en   = round(finish(p) * conv);
                pre  = round(50/1000 * Fs);
                
                % MUA data (DEV: clean up timing with photodiode?)
                clear timeperiod NS DAT response
                timeperiod = sprintf('t:%u:%u', st,en);
                NS = openNSx(strcat(filename,'.ns6'),timeperiod,'read');
                DAT = double(NS.Data)' ./ 4;
                nyq = Fs/2;
                hpc = 750;  %high pass cutoff
                hWn = hpc/nyq;
                [bwb,bwa] = butter(4,hWn,'high');
                response = mean(...
                    abs(filtfilt(bwb,bwa,DAT)));
                
                % baseline data
                clear timeperiod NS DAT baseline
                timeperiod = sprintf('t:%u:%u', st-pre,st);
                NS = openNSx(strcat(filename,'.ns6'),timeperiod,'read');
                DAT = double(NS.Data)' ./ 4;
                nyq = Fs/2;
                hpc = 750;  %high pass cutoff
                hWn = hpc/nyq;
                [bwb,bwa] = butter(4,hWn,'high');
                baseline = mean(...
                    abs(filtfilt(bwb,bwa,DAT)));
                
                mua.r_raw(:,obs) = response;
                mua.r_dif(:,obs) = response - baseline;
                mua.r_pc(:,obs) = (response - baseline) ./ baseline .* 100;
            end
            
            if any(strcmp({'nev','all','spiking'},datatype))
                
                clear response baseline
                response = nan(length(idx),1);
                baseline = nan(length(idx),1);
                
                if STIM.nevdat(j) == 1
                    clear st en dur pre
                    
                    % nev evt times
                    st   = start(p);
                    en   = finish(p);
                    dur  = (en - st) / evtFs; % seconds
                    pre  = 50/1000; %s
                    
                    for e =1:length(idx)
                        
                        eid = NS6_header.ElectrodesInfo(idx(e)).ElectrodeID;
                        I   =  NEV.Data.Spikes.Electrode == eid;
                        if ~any(I)
                            continue
                        end
                        SPK = double(NEV.Data.Spikes.TimeStamp(I));
                        
                        response(e) = sum(SPK > st & SPK < en) / dur;
                        baseline(e) = sum(SPK > st-round(pre*evtFs) & SPK < st) / pre;
                        
                        
                    end
                end
                
                nev.r_raw(:,obs) = response;
                nev.r_dif(:,obs) = response - baseline;
                nev.r_pc(:,obs) = (response - baseline) ./ baseline .* 100;
                
                
            end
            
            
            if any(strcmp({'ppnev','all','spiking','autosort','auto'},datatype))
                
                clear response baseline
                response = nan(length(idx),1);
                baseline = nan(length(idx),1);
                
                if STIM.atodat(j) == 1
                    clear st en dur pre
                    
                    % nev evt times
                    st   = start(p);
                    en   = finish(p);
                    dur  = (en - st) / evtFs; % seconds
                    pre  = 50/1000; %s
                    
                    for e =1:length(idx)
                        
                        eid = NS6_header.ElectrodesInfo(idx(e)).ElectrodeID;
                        I   =  NEV.Data.Spikes.Electrode == eid;
                        if ~any(I)
                            continue
                        end
                        SPK = double(ppNEV.Data.Spikes.TimeStamp(I));
                        
                        response(e) = sum(SPK > st & SPK < en) / dur;
                        baseline(e) = sum(SPK > st-round(pre*evtFs) & SPK < st) / pre;
                        
                    end
                end
                
                ato.r_raw(:,obs) = response;
                ato.r_dif(:,obs) = response - baseline;
                ato.r_pc(:,obs) = (response - baseline) ./ baseline .* 100;
                
                
            end
            
            
            if any(strcmp({'kilosort','all','spiking'},datatype))
                
                clear response baseline
                response = nan(length(idx),1);
                baseline = nan(length(idx),1);
                
                
                if STIM.klsdat(j) == 1
                    clear Fs conv st en dur pre
                    
                    % ks evt times
                    Fs = ss.Fs;
                    conv = Fs/evtFs;
                    st   = round(start(p) * conv);
                    en   = round(finish(p) * conv);
                    dur  = (en - st) / Fs; % seconds
                    pre  = round(50/1000 * Fs);
                    
                    for e =1:length(idx)
                        elabel  = elb(idx(e));
                        eidx    = find(strcmp(ss.chanIDs,elabel));
                        if isempty(eidx)
                            continue
                        end
                        cidx    = find(ss.clusterMap(:,2) == eidx,1,'first');
                        if isempty(cidx) || ss.clusterMap(cidx,end) == 0
                            continue
                        end
                        clustID = ss.clusterMap(cidx,1);
                        I       = ss.spikeClusters == clustID;
                        if ~any(I)
                            continue
                        end
                        SPK = ss.spikeTimes(I);
                        
                        response(e) = sum(SPK > st & SPK < en) / dur;
                        baseline(e) = sum(SPK > st-round(pre*evtFs) & SPK < st) / pre;
                        
                    end
                end
                
                kls.r_raw(:,obs) = response;
                kls.r_dif(:,obs) = response - baseline;
                kls.r_pc(:,obs) = (response - baseline) ./ baseline .* 100;
                
            end
            
            if any(strcmp({'evp','all'},datatype))
                
                % store logical
                STIM.evpdat(j) = 1;
                
                % convert NEV Event Times to FS as needed
                Fs = double(NS2_header.MetaTags.SamplingFreq);
                conv = Fs/evtFs;
                pre  = 50;
                post = 200;
                st = floor( (start(p) * conv) - (pre/1000*Fs)  );
                en = floor( (start(p) * conv) + (post/1000*Fs) );
                
                % presentation data
                clear timeperiod NS
                timeperiod = sprintf('t:%u:%u', st,en);
                NS = openNSx(strcat(filename,'.ns2'),timeperiod,...
                    'read');
                evp(:,:,obs) = double(NS.Data)' ./ 4;
                
                if obs == 1
                    tm = -pre:post;
                end
            end
            
        end
        
        
        
    end
end


if obs == 0
    STIM = [];
    return
end

% MUA
if any(strcmp({'mua','all','spiking'},datatype))
    STIM.mua_raw = mua.r_raw(idx,:);
    STIM.mua_dif = mua.r_dif(idx,:);
    STIM.mua_pc  = mua.r_pc(idx,:);
    %     rawdat     = STIM.mua_raw; % MUA  zscore (z-score for each channel individually, but acorss all OBS regardless of file or stim location)
    %     dat        = bsxfun(@minus,  rawdat, mean(rawdat,2));
    %     dat        = bsxfun(@rdivide,dat, std(rawdat,[],2));
    %     STIM.mua_zsr = dat;
    %     clear rawdat dat mua
end

% NEV
if any(strcmp({'nev','all','spiking'},datatype))
    STIM.nev_raw = nev.r_raw;
    STIM.nev_dif = nev.r_dif;
    STIM.nev_pc  = nev.r_pc;
    %     rawdat     = STIM.nev_raw; % NEV zscore (z-score for each channel individually, but acorss all OBS regardless of file or stim location)
    %     dat        = bsxfun(@minus,  rawdat, nanmean(rawdat,2));
    %     dat        = bsxfun(@rdivide,dat, nanstd(rawdat,[],2));
    %     STIM.nev_zsr = dat;
    %     clear rawdat dat nev
end

if any(strcmp({'nev','all','spiking'},datatype))
    STIM.nev_raw = nev.r_raw;
    STIM.nev_dif = nev.r_dif;
    STIM.nev_pc  = nev.r_pc;
    %     rawdat     = STIM.nev_raw; % NEV zscore (z-score for each channel individually, but acorss all OBS regardless of file or stim location)
    %     dat        = bsxfun(@minus,  rawdat, nanmean(rawdat,2));
    %     dat        = bsxfun(@rdivide,dat, nanstd(rawdat,[],2));
    %     STIM.nev_zsr = dat;
    %     clear rawdat dat nev
end


if any(strcmp({'ppnev','all','spiking','autosort','auto'},datatype))
    STIM.ato_raw = ato.r_raw;
    STIM.ato_dif = ato.r_dif;
    STIM.ato_pc  = ato.r_pc;
    %     rawdat     = STIM.nev_raw; % NEV zscore (z-score for each channel individually, but acorss all OBS regardless of file or stim location)
    %     dat        = bsxfun(@minus,  rawdat, nanmean(rawdat,2));
    %     dat        = bsxfun(@rdivide,dat, nanstd(rawdat,[],2));
    %     STIM.nev_zsr = dat;
    %     clear rawdat dat nev
end

%evp
if any(strcmp({'evp','all'},datatype))
    STIM.evp_raw = evp(:,idx,:);
    STIM.evp_tm  = tm;
end

% bookkeeping
STIM.elabel        = elb(idx);
STIM.photodiode    = flag_usePhotodiodeTrigger;
STIM.rewardedonly  = flag_RewardedTrialsOnly;
STIM.timestamp     = now;



