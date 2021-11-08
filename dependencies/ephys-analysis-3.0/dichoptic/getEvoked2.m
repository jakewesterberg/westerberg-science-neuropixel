function EV = getEvoked2(filelist,el,sortdirection,datatypes,flag_skiptrls)

% July 2017

% filelist must include path to dir with NEV, stimulus text files, NS6
% don't use on dots
% only uses auto NEV

% revided Oct 2017 to make it work again

flag_RewardedTrialsOnly        = false;
flag_10kHz                     = true;  % downsample spk
autodir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';

if nargin < 4
    datatypes = {'nev','lfp'};
elseif ~iscell(datatypes)
    datatypes = {datatypes};
end
if nargin < 5
    flag_skiptrls = false;
end

obs  = 0;
pre  = 100/1000; % 100ms
post = 250/1000; % 250ms
% will crop time to [-50 200] before output, extra tm is for convolution

clear EV
fpath            = fileparts(filelist{1});
EV.header        = fpath(end-7:end);
EV.datatypes     = datatypes;
EV.filelist      =filelist;
EV.el            = el;
EV.elabel        = {};

% sort filelist
clear T I
for j = 1:length(filelist)
    clear NS_header filename
    filename = filelist{j};
    NS_header = openNSx([filename '.ns2'],'noread');
    T(j) = datenum(NS_header.MetaTags.DateTime,'dd-mmm-yyyy HH:MM:SS');
end
[~,I]=sort(T);
filelist = filelist(I);
clear T I NS_header filename r R

for j = 1:length(filelist)
    filename = filelist{j};
    [~,BRdatafile,~] = fileparts(filename);
    
    isevp = 0;
    if ~isempty(strfind(BRdatafile,'evp'))
        isevp = 1;
    end
    
    % Read in NS Header
    clear NS_header
    NS_header = openNSx([filename '.ns2'],'noread');
    lfpFs     = double(NS_header.MetaTags.SamplingFreq);
    
    % arrange channels as needed
    elb = cellfun(@(x) (x(1:4)),{NS_header.ElectrodesInfo.Label},'UniformOutput',0);
    prb = sum(~cellfun('isempty',strfind({NS_header.ElectrodesInfo.Label},el)));
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
    
    % load  NEV
    clear NEV
    if any(strcmp(datatypes,'nev'))
        if exist([autodir BRdatafile '.ppnev'],'file')
            load([autodir BRdatafile '.ppnev'],'-mat')
            NEV = ppNEV; clear ppNEV;
        else
            error('no offline sorted NEV')
        end
    else
        NEV = openNEV([filename '.nev'],'noread','nosave','nomat');
    end
    filetm = datenum(NEV.MetaTags.DateTime,'dd-mmm-yyyy HH:MM:SS');
    filetm = datetime(filetm,'ConvertFrom','datenum');
    
    
    % get event codes from NEV
    EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
    EventSampels = double(NEV.Data.SerialDigitalIO.TimeStamp);
    if isempty(EventSampels) || isempty(EventCodes)
        fprintf('\nskipping %s\nbecause no data\n',filename)
        continue
    end
    [pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);
    evtFs = double(NEV.MetaTags.SampleRes);
    
    %% Find trigger poitns
    trls = find(cellfun(@(x) sum(x == 23) == sum(x == 24),pEvC));
    for tr = 1:length(trls)
        t = trls(tr);
        
        if flag_RewardedTrialsOnly && ~any(pEvC{t} == 96)
            % skip if not rewarded (event code 96)
            continue
        end
        
        if flag_skiptrls && rem(tr,3) ~= 0
            continue
        end
        
        stimon   =  pEvC{t} == 23 | pEvC{t} == 25  | pEvC{t} == 27   | pEvC{t} == 29  | pEvC{t} == 31;
        stimoff  =  pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32;
        
        start   =  pEvT{t}(stimon);
        stop    =  pEvT{t}(stimoff);
        
        maxpres = length(stop);
        
        for p = 1:maxpres
            
            % trigger point
            obs = obs + 1;
            
            % file info
            EV.ec(obs,:)     = [stimon(p) stimoff(p)];
            EV.tp(obs,:)     = [start(p)  stop(p)];
            EV.filen(obs,1)  = j;
            EV.isevp(obs,1)  = isevp;
            EV.abstm(obs,1)  = datenum(filetm + seconds(start(p)/evtFs));
            
        end
    end
    % photodiode triggering
    TP = EV.tp(EV.filen == j,:);
    [newTP,~] = photoReTrigger(TP,filename,0,'default');
    if isempty(newTP)
        newTP = nan(size(TP));
    end
    EV.tp(EV.filen == j,:) = newTP;
    EV.evtFs = evtFs;
    
    for p = find(EV.filen(:,1) == j,1,'first'):find(EV.filen(:,1) == j,1,'last')
        clear tp
        tp = EV.tp(p,1);
        
        if any(strcmp(datatypes,'nev'))
            
            % setup time
            if p == 1
                clear R Fs sdftm k
                if ~flag_10kHz
                    R  = 1;
                else
                    R = 10;
                end
                Fs        = evtFs / R;
                sdftm     = -pre:1/Fs:post;
                k         = jnm_kernel( 'psp', (20/1000) * Fs );
                EV.nevFs  = Fs;
                EV.nevtm  = sdftm';
            end
            
            % setup SUA matrix
            if any(isnan(tp))
                sua = nan(length(sdftm),length(idx));
                sdf = nan(length(sdftm),length(idx));
            else
                sua = zeros(length(sdftm),length(idx));
                sdf = zeros(length(sdftm),length(idx));
                
                % iterate MUA/NEV
                for e =1:length(idx)
                    
                    eid = NS_header.ElectrodesInfo(idx(e)).ElectrodeID;
                    I   =  NEV.Data.Spikes.Electrode == eid;
                    if ~any(I)
                        continue
                    end
                    SPK = double(NEV.Data.Spikes.TimeStamp(I));
                    
                    clear x
                    if ~flag_10kHz
                        x = SPK - tp;
                    else
                        x = unique(round((SPK - tp) ./ R ));
                    end
                    
                    clear spk spktm
                    [spk,spktm,~] = intersect(sdftm*Fs,x,'stable') ;
                    
                    if ~isempty(spk)
                        sua(spktm,e) = 1;
                        sdf(:,e)     = conv(sua(:,e),k,'same') * Fs;
                    end
                    
                end
            end
            EV.nev_raw(:,:,p) = sua;
            EV.nev_sdf(:,:,p) = sdf;
        end
        
        if any(strcmp(datatypes,'lfp'))
            
            %setup time
            if p == 1
                clear r 
                EV.lfpFs  = lfpFs;
                EV.lfptm  = [-pre:1/lfpFs:post]';
                r = lfpFs/evtFs;
            end
            
            % setup lfp matrix
            clear y
            if any(isnan(tp))
                y = nan(length(EV.lfptm),length(idx));
            else
                % need to convert lfp event times
                st = round(r * (tp - pre*evtFs)) ;
                en = round(r * (tp + post*evtFs)) ;
                % load lfp data direct from NS6
                clear timeperiod NS
                respperiod = sprintf('t:%u:%u', st,en);
                NS = openNSx([filename '.ns2'],respperiod, 'read');
                y = (double(NS.Data)./4)';
                y = y(:,idx); 
            end
            EV.lfp_uV(:,:,p) = y ;
            
        end
    end
    
end



if any(strcmp(datatypes,'nev'))
    
    % crop nev time (was longer for convolution's sake)
    nevI = EV.nevtm >= -50/1000 & EV.nevtm <= 200/1000;
    EV.('nev_raw')(~nevI,:,:) = [];
    EV.('nev_sdf')(~nevI,:,:) = [];
    EV.('nevtm')(~nevI) = [];
    
    % sdf to delta
    bl = EV.nevtm > -50/1000 & EV.nevtm < 0/1000;
    u  = mean(EV.nev_sdf(bl,:,:),1);
    EV.nev_dif = bsxfun(@minus,EV.nev_sdf,u);
%     
%     % sdf to zscore
%     s  = std(EV.nev_sdf(bl,:,:),[],1);
%     if any(any(s>0))
%         s(s==0) = min(s(s>0));
%         EV.nev_zsr = bsxfun(@rdivide, EV.nev_dif,s);
%     else
%         EV.nev_zsr = [];
%     end
%     
    % sig resp from baseline for gratings only (no evp)
    clear bl re b r p h fwalpha
    bl = EV.nevtm > -50/1000 & EV.nevtm < 0/1000;
    re = EV.nevtm >  50/1000 & EV.nevtm < 100/1000;
    b  = squeeze(sum(EV.nev_raw(bl,:,EV.isevp==0),1));
    r  = squeeze(sum(EV.nev_raw(re,:,EV.isevp==0),1));
    p = nan(size(r,1),1);
    for e = 1:size(r,1)
        [~,p(e)] = ttest(b(e,:),r(e,:));
    end
    fwalpha = 0.05 / e;
    h = p < fwalpha;
    EV.nev_sig = [h p];
end

% LFP AND CSD
if any(strcmp(datatypes,'lfp'))
    
    
    % ctop time to match NEV
    lfpI = EV.lfptm >= -50/1000 & EV.lfptm <= 200/1000;
    EV.('lfp_uV')(~lfpI,:,:) = [];
    EV.('lfptm')(~lfpI) = [];
    
%     % CSD
%     EV.csd_nA  = nan(size(EV.lfp_uV));
%     csd = calcCSD(EV.lfp_uV) .* 0.4; % uV to nA/mm^3;
%     csd = permute(csd,[2 1 3]);
%     EV.csd_nA(:,2:end-1,:) = csd;
    
end


% other info
EV.elabel        = elb(idx);
EV.timesorted    = issorted(EV.abstm);
EV.flag_skiptrls = flag_skiptrls;
EV.timestamp     = now;



% %sort in time if needed (should not be needed)
% if ~issorted(EV.time)
%     clear I
%
%     [~,I] = sort(EV.time);
%     fields = {'filen','isevp','time'};
%     for f = 1:length(fields)
%         EV.(fields{f}) = EV.(fields{f})(I);
%     end
%
%     EV.('nev_raw') = EV.('nev_raw')(:,:,I);
%     EV.('lfp_raw') = EV.('lfp_raw')(:,:,I);
% end
