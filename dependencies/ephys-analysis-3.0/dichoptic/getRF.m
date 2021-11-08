function RF  = getRF(filelist,el,sortdirection,datatypes)

% filelist must include path to dir with NEV, stimulus text files, NS6
%   - if only using 'datatypes' MUA and NEV, no other data needed
% major revision on May 30 and 31:
%     - 'datatypes' can contain NEV or Auto, not both
%     - 'kilosort' combines all clusters on a given contact
% another revision on July 13
%     - updated AutoSort path
%     - modifyed z-score calculation
%     - added default photodiode triggering
% July 18
%      - shifted TC for resp + 50ms


if nargin < 4
    datatypes = {'mua','auto','kilosorted'};
end
if ~iscell(datatypes)
    datatypes = {datatypes};
end

flag_RewardedTrialsOnly        = false;
flag_TriggerWithConstantOffset = false; 
flag_Add50msToStart            = true; 

obs = 0; clear RF mua nev kls

fpath            = fileparts(filelist{1});
RF.header        = fpath(end-7:end);
RF.filelist      =filelist;
RF.el            = el;
RF.elabel        = {};

autodir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';
sortdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';


% sort filelist in time
clear T I
for j = 1:length(filelist)
    clear NS_header filename
        filename = filelist{j};
    NS6_header = openNSx([filename '.ns2'],'noread');
   T(j) = datenum(NS6_header.MetaTags.DateTime,'dd-mmm-yyyy HH:MM:SS');
end
[~,I]=sort(T); 
filelist = filelist(I);
clear T I NS_header filename



for j = 1:length(filelist)
    filename = filelist{j};
    [~,BRdatafile,~] = fileparts(filename);
    
     %% get stimunuls info
    dots = readgDotsXY([filename '.gDotsXY_di']); % read in text file with stim parameters
%     if isfield(dots,'fix_x') ...
%             && any(any([dots.fix_y dots.fix_x] > 0))
%         fprintf('\nskipping %s\nbecause of unusual fixation location\n',filename)
%         continue
%     end
    
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
        fprintf('\nskipping %s\nbecause no data\n',filename)
        continue
    end
    [pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);
    evtFs = double(NEV.MetaTags.SampleRes);
    if flag_TriggerWithConstantOffset
        ypos = median(dots.dot_y);
        [pEvT_photo,pt] = pEvtPhoto(...
            [filename '.ns6'],pEvC,pEvT,ypos,[],[],0,'constant');
    else 
        pt = 'n/a'; 
    end
    
    %% get NSx Header for nel
    
    % Read in NS Header
    NS6_header = openNSx([filename '.ns6'],'noread');
    NS2_header = openNSx([filename '.ns2'],'noread');
    
    
    % arrange channels as needed
    elb = cellfun(@(x) (x(1:4)),{NS6_header.ElectrodesInfo.Label},'UniformOutput',0);
    prb = sum(~cellfun('isempty',strfind({NS6_header.ElectrodesInfo.Label},el)));
    idx = zeros(1,prb);
    for e = 1:prb
        elable = [el num2str(e,'%02u')];
        idx(e) = find(strcmp(elb,elable));
    end
    % most superficial channel on top, regardless of number
    switch sortdirection
        case 'descending'
            idx = fliplr(idx);
    end
    
   % check that all is good between NEV and grating text file;
    [allpass, message] =  checkTrMatch(dots,NEV);
    if ~allpass
        fprintf('\nskipping %s\nbecause not allpass\n',filename)
        message
        continue
        %error('%s Failed checkTrMatch, Message as follows:\n\t%s\n\t%s\n\t%s',filename,message{:})
    end
    
    
    % load NEV Spikes OR AutoSorted Offline NEV
    NEV = [];
    if any(strcmp(datatypes,'auto'))
        if exist([autodir BRdatafile '.ppnev'],'file')
            load([autodir BRdatafile '.ppnev'],'-mat')
            NEV = ppNEV; clear ppNEV;
        end
    elseif any(strcmp(datatypes,'nev'))
        NEV          = openNEV(strcat(filename,'.nev'),'overwrite');
    end
    
    % load KS data, not concatenated
    ss = [];
    if any(strcmp(datatypes,'kilosorted'))
        if exist([sortdir BRdatafile '/rez.mat'],'file')
            % load ss structure
            if exist([sortdir BRdatafile '/ss.mat'],'file')
                load([sortdir BRdatafile '/ss.mat'],'-mat');
            else
                ss = KiloSort2SpikeStruct([sortdir BRdatafile],1);
            end
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
        if flag_TriggerWithConstantOffset
            start = pEvT_photo{t}(stimon);
        else
            start = pEvT{t}(stimon);
        end
        finish = pEvT{t}(stimoff);
        stim =  find(dots.trial == t);
        
        if flag_Add50msToStart
            newstart  = start  + (50/1000 * evtFs);
        else
            newstart  = start; 
        end
        
        
        maxpres = min([length(start) length(finish) length(stim)]);
        
        for p = 1:maxpres
            obs = obs + 1;
            
            % stim info
            RF.x(1,obs)     = dots.dot_x(stim(p));
            RF.y(1,obs)     = dots.dot_y(stim(p));
            RF.d(1,obs)     = dots.diameter(stim(p));
            RF.eye(1,obs)   = dots.dot_eye(stim(p));
            RF.filen(1,obs) = j;
            
            % timing info
            RF.st(1,obs)         = start(p);
            RF.en(1,obs)         = finish(p);
            if obs == 1
                RF.evtFs         = evtFs;
            end
            
            
            if any(strcmp(datatypes,'mua'))
                ahahahah need to account for ofset in ns6 load
                % convert spkTPs from NEV Event Times to FS as needed
                Fs = double(NS6_header.MetaTags.SamplingFreq);
                conv = Fs/evtFs;
                
                st   = round(newstart(p) * conv);
                en   = round(finish(p) * conv);
                
                blst = round(start(p) * conv) - round(50/1000 * Fs);
                blen = round(start(p) * conv);
                
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
                timeperiod = sprintf('t:%u:%u', blst,blen);
                NS = openNSx(strcat(filename,'.ns6'),timeperiod,'read');
                DAT = double(NS.Data)' ./ 4;
                nyq = Fs/2;
                hpc = 750;  %high pass cutoff
                hWn = hpc/nyq;
                [bwb,bwa] = butter(4,hWn,'high');
                baseline = mean(...
                    abs(filtfilt(bwb,bwa,DAT)));
                
               mua.r_resp(:,obs) = response;
               mua.r_base(:,obs) = baseline;
                
                clear response baseline
            end
            
             if any(strcmp(datatypes,'csd'))
                
                % convert spkTPs from NEV Event Times to FS as needed
                Fs = double(NS2_header.MetaTags.SamplingFreq);
                conv = Fs/evtFs;
                
                st   = round(newstart(p) * conv);
                en   = round(finish(p) * conv);
                
                blst = round(start(p) * conv) - round(50/1000 * Fs);
                blen = round(start(p) * conv);
                
                % EVP data (DEV: clean up timing with photodiode?)
                clear timeperiod NS DAT response
                timeperiod = sprintf('t:%u:%u', st,en);
                NS = openNSx(strcat(filename,'.ns2'),timeperiod,'read');
                DAT = double(NS.Data)' ./ 4;
                clear rCSD
                rCSD = calcCSD(DAT(:,idx)); 
                
                 % baseline data
                clear timeperiod NS DAT baseline
                timeperiod = sprintf('t:%u:%u', blst,blen);
                NS = openNSx(strcat(filename,'.ns6'),timeperiod,'read');
                DAT = double(NS.Data)' ./ 4;
                clear bCSD
                bCSD = calcCSD(DAT(:,idx)) .* 0.4; 
                
                csd.r_resp(:,obs) = [NaN; mean(rCSD,2); NaN];
                csd.r_diff(:,obs) = [NaN; mean(bsxfun(@minus,rCSD,mean(bCSD,2)),2); NaN];
                
                clear response baseline rCSD bCSD
            end
            
            
            if any(strcmp(datatypes,'nev')) || any(strcmp(datatypes,'auto'))
                
                % nev evt times, always the same as the event times
                st        = newstart(p);
                en        = finish(p);
                stim_sec  = (en - st) / evtFs; % seconds
                
                pre_sec   = 50/1000;
                blst      = start(p) - (pre_sec * evtFs); 
                blen      = start(p);
                
                clear response baseline
                response = nan(length(idx),1);
                baseline = nan(length(idx),1);
                
                if ~isempty(NEV)
                    for e =1:length(idx)
                        
                        eid = NS6_header.ElectrodesInfo(idx(e)).ElectrodeID;
                        I   =  NEV.Data.Spikes.Electrode == eid;
                        if ~any(I)
                            continue
                        end
                        SPK = double(NEV.Data.Spikes.TimeStamp(I));
                        
                        response(e) = sum(SPK > st & SPK < en) / stim_sec;
                        baseline(e) = sum(SPK > blst & SPK < blen) / pre_sec;
                        
                    end
                end
                
                nev.r_resp(:,obs) = response;
                nev.r_base(:,obs) = baseline;
                
            end
            
            
            
            if any(strcmp(datatypes,'kilosorted'))
                
                
                % ks evt times, always the same as the event times
                st        = newstart(p);
                en        = finish(p);
                stim_sec  = (en - st) / evtFs; % seconds
                
                pre_sec   = 50/1000;
                blst      = start(p) - (pre_sec * evtFs); 
                blen      = start(p);
                
                
                clear response baseline
                response = nan(length(idx),1);
                baseline = nan(length(idx),1);
                
                if ~isempty(ss)
                    for e =1:length(idx)
                        elabel  = elb(idx(e));
                        eidx    = find(strcmp(ss.chanIDs,elabel));
                        if isempty(eidx)
                            continue
                        end
                        cidx    = find(ss.clusterMap(:,2) == eidx);
                        % combine all clusters from a given channel
                        I       = false(size(ss.spikeClusters));
                       
                        for c = 1:length(cidx)
                            if ss.clusterMap(cidx(c),end) == 1
                                clustID = ss.clusterMap(cidx(c),1);
                                ii = ss.spikeClusters == clustID;
                                I(ii) = true;
                            end
                        end
                        if ~any(I)
                            continue
                        end
                        SPK = ss.spikeTimes(I);
                        
                        response(e) = sum(SPK > st & SPK < en) / stim_sec;
                        baseline(e) = sum(SPK > blst & SPK < blen) / pre_sec;
                    end
                end
                
                kls.r_resp(:,obs) = response;
                kls.r_base(:,obs) = baseline;
                
            end
        end
    end
end
if ~exist('mua','var') && ~exist('nev','var') && ~exist('kls','var')  && ~exist('csd','var')
    RF = [];
    return
end

% MUA
if exist('mua','var')
    clear resp base delta dat
    
    resp        = mua.r_resp(idx,:);
    base        = mua.r_base(idx,:);
    delta       = resp - base;
    
    % raw, diff, pc
    RF.mua_dif = delta;
    RF.mua_pc  = ((resp - base) ./ base) .* 100;
    
    % z-score on RAW 
    clear dat
    dat         = bsxfun(@minus,  resp, nanmean(resp,2));
    dat         = bsxfun(@rdivide,dat, nanstd(resp,[],2));
    RF.mua_zsr  = dat;
    
    % z-score on DIFF 
    clear dat
    dat         = bsxfun(@minus,  delta, nanmean(delta,2));
    dat         = bsxfun(@rdivide,dat, nanstd(delta,[],2));
    RF.nev_dzsr = dat;
    
    clear resp base delta dat mua
end

% CSD
if exist('csd','var')
        
    % raw, diff, pc
    RF.csd_raw  = csd.r_resp;
    RF.csd_dif  = csd.r_diff;
    
end

% NEV
if exist('nev','var')
    clear resp base delta dat
    
    resp        = nev.r_resp;
    base        = nev.r_base;
    delta       = resp - base;
    
    % raw, diff
    RF.nev_raw = resp;
    RF.nev_dif = delta;
    
    % z-score on RAW 
    clear dat
    dat        = bsxfun(@minus,  resp, nanmean(resp,2));
    dat        = bsxfun(@rdivide,dat, nanstd(resp,[],2));
    RF.nev_zsr = dat;    
    
    % z-score on DIFF
    clear dat
    dat        = bsxfun(@minus,  delta, nanmean(delta,2));
    dat        = bsxfun(@rdivide,dat, nanstd(delta,[],2));
    RF.nev_dzsr = dat;
    
    clear resp base delta dat nev
end

% KLS
if exist('kls','var')
    clear resp base delta dat
    
    resp        = kls.r_resp;
    base        = kls.r_base;
    delta       = resp - base;
    
    % raw, diff, pc
    RF.kls_raw = resp;
    RF.kls_dif = delta;
    
    % z-score on RAW
    clear dat
    dat        = bsxfun(@minus,  resp, nanmean(resp,2));
    dat        = bsxfun(@rdivide,dat, nanstd(resp,[],2));
    RF.kls_zsr = dat;
    
    % z-score on DIFF
    clear dat
    dat        = bsxfun(@minus,  delta, nanmean(delta,2));
    dat        = bsxfun(@rdivide,dat, nanstd(delta,[],2));
    RF.kls_zsr = dat;
    
    clear resp base delta dat kls
end

% other info
RF.elabel        = elb(idx);
RF.phototrig     = pt; 
RF.flag_Add50msToStart = flag_Add50msToStart; 
RF.timestamp     = now;

% 
% % check for concatnated KS data
% concatedkls = false;
% kilodirname = sprintf('/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/concatBR_dots/%s/',RF.header);
% if exist(kilodirname,'dir')
%    concatinfofile = sprintf('%s/concatInfo.mat',kilodirname);
%    load(concatinfofile,'fnames')
%    x1 = cellfun(@(x) str2double(x(end-2:end)),filelist);
%    x2 = cellfun(@(x) str2double(x(end-2:end)),fnames); clear fnames
%    if isequal(x1,x2)
%        concatedkls = true;
%    else
%        error('check concatenation')
%    end
% end
% if concatedkls
%     ssplitfile = sprintf('%s/ss_split.mat',kilodirname);
%     if ~exist(ssplitfile,'file')
%         ssfile = sprintf('%s/ss.mat',kilodirname);
%         if ~exist(ssfile)
%             rezfile = sprintf('%s/rez.mat',kilodirname);
%             ss  = KiloSort2SpikeStruct(rezfile,1);
%         else
%             load(ssfile);
%         end
%         concatinfofile = sprintf('%s/concatInfo.mat',kilodirname);
%         load(concatinfofile,'fnames')
%         ss_split = SplitSpikeStruct(ss,fnames,ftps,1);
%     else
%         load(ssplitfile)
%     end
%     % arrange clusters
%     kunits  = find(ss_split.clusterMap(:,3) & ss_split.clusterMap(:,4));
%     klabels = ss_split.chanIDs(ss_split.clusterMap(kunits,2));
%     kprobe  = cellfun(@(x) x(1:2),klabels,'UniformOutput',0);
%     kunits  = kunits(strcmp(kprobe,el));
%     klabels = klabels(strcmp(kprobe,el)); clear kprobe
%     klb     = cellfun(@(x) str2double(x(3:4)),klabels);
%     switch sortdirection
%         case 'ascending'
%             [~,kidx]  = sort(klb,1,'ascend');
%         case 'descending'
%             [~,kidx]  = sort(klb,1,'descend');
%     end
%     kunits  = kunits(kidx);
%     kclusts = ss_split.clusterMap(kunits,1);
%     klabels = klabels(kidx);
%     clear klb kidx
% 
%     RF.klabel = klabels;
%     RF.kclust = kclusts;
% end
% 


