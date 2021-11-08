filename  = '160108_E_rfori002';
elabel    = 'eD13';
dur       = 5; %s

nevdir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';
klsdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';

TuneList = importTuneList; clear s
s = strcmp(TuneList.Datestr,filename(1:6)) & strcmp(TuneList.Bank,elabel(2));

clear sortdirection
sortdirection = TuneList.SortDirection{s};

clear drobo
switch TuneList.Drobo(s)
    case 1
        drobo = 'Drobo';
    otherwise
        drobo = sprintf('Drobo%u',TuneList.Drobo(s));
end

clear brfile nevfile klsfile stimfile rffile
ns6file = sprintf('/Volumes/%s/Data/NEUROPHYS/rig%03u/%s_%s/%s.ns6',...
    drobo,TuneList.Rig(s),TuneList.Datestr{s},TuneList.Monkey{s},filename);
nevfile = [nevdir filename '.ppnev'];
klsfile = [klsdir filename filesep 'ss.mat'];



clear NS_Header ss ppNEV NEV Fs
NS_Header = openNSx(ns6file,'noread');
Fs = double(NS_Header.MetaTags.SamplingFreq);
load(klsfile);
load(nevfile,'-mat'); NEV = ppNEV; clear ppNEV


clear EventSampels EventCodes pEvC pEvT
EventSampels = NEV.Data.SerialDigitalIO.TimeStamp;
EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
[pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);
ypos = 0; 
[pEvT_photo,phototrigger] = pEvtPhoto(ns6file,pEvC,pEvT,ypos,[],[],0,'constant');




% NS6
clear e electrode NS DAT
e = find(strcmp(cellfun(@(x) x(1:4), {NS_Header.ElectrodesInfo.Label},'UniformOutput',0),elabel));
electrode = sprintf('c:%u',e);
NS = openNSx(ns6file,electrode,'read');
DAT = double(NS.Data)'; clear NS

%NEV
clear nI
nI = find(strcmp(cellfun(@(x) x(1:4), {NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0),elabel));

%KLS
clear kI cluster
kI = find(strcmp(ss.chanIDs,elabel));
cluster = ss.clusterMap((ss.clusterMap(:,2) == kI & ss.clusterMap(:,3) == 1),1);
if length(cluster) > 1
    N = zeros(size(cluster));
    for c = 1:length(cluster)
        N(c) = sum(ss.spikeClusters == cluster(c));
    end
    [~,mI]=max(N);
    cluster = cluster(mI);
end

% st, en, tm, k
st = randi(length(DAT),1); 
en = st + dur*Fs - 1; 
tm_spl = ([st:en] - st); 
tm_sec = ([st:en] - st) ./ Fs; 
k = jnm_kernel( 'psp', (20/1000) * Fs );
kln = tm_sec(find(k>0,1,'last') - find(k>0,1,'first'));

%%
figure
datatype = {'RAW','aMUA','dMUA','SUA','STIM'};
for d = 1:length(datatype);
    clear y tm ystr
    flag_conv = true;

    switch datatype{d}
        case 'RAW'
           
            tm = tm_sec;
            y = (DAT(st:en)) ./ 4 ;
            ystr = 'uV';
           
            flag_conv = false; 
           
        case 'aMUA'
            tm = tm_sec;
            
            % filter
            nyq = Fs/2;
            hpc = 750;  %high pass cutoff
            hWn = hpc/nyq;
            [bwb,bwa] = butter(4,hWn,'high');
            y = abs(filtfilt(bwb,bwa,DAT));
            %y = y - mean(y); 
            y = y(st:en) ./ 4 ;

            ystr = 'uV';
            
            
        case 'dMUA'
            tm = tm_sec;
            y   = zeros(size(tm));
            I   =  NEV.Data.Spikes.Electrode == nI;
            SPK = double(NEV.Data.Spikes.TimeStamp(I));
            x   = ((SPK(SPK > st & SPK < en)) - st)/Fs;
            [~,ii]=intersect(tm,x,'stable');
            y(ii) = 1;
            
            ystr = 'imp/s';
            
            
        case 'SUA'
            tm = tm_sec;
            y   = zeros(size(tm));
            I   =  ss.spikeClusters == cluster;
            SPK = ss.spikeTimes(I);
            x   = ((SPK(SPK > st & SPK < en)) - st)/Fs;
            [~,ii]=intersect(tm,x,'stable');
            y(ii) = 1;
            
            ystr = 'imp/s';
            
            
        case 'STIM'
            
            y   = zeros(size(tm_spl));
            for t = 1:length(pEvT)
                evtI = pEvT{t} >= st & pEvT{t} <= en;
                if any(evtI)
                    codes = pEvC{t};
                    
                    times = pEvT_photo{t};
                    xtimes = pEvT{t};
                    times(isnan(times)) = xtimes(isnan(times));
                    times = times - st + 1;
                    
                     for evt=23:2:31
                            evtst = times( codes == evt) ;
                            if evtst > length(y)
                                continue
                            end

                            if any(codes == evt+1)
                                evten = times( codes == evt+1) ;
                            else
                                evten = times( find(codes == evt) + 1);
                            end
                            if evten > length(y)
                                evten = length(y);
                            end
                            
                            y(evtst:evten) = ones(1,evten - evtst + 1); 
                            
                     end
                     
                end
            end
            
            ystr = 'on/off';
            flag_conv = false;
            tm = tm_sec;
%          
%         
    end
    
            
            
            
            
    
    
    % convolve
    sy = nan(size(y)); 
    if flag_conv
        sy    = doConv(y,k);
    end
    
    subplot(5,1,d)
    if any(strcmp({'dMUA','SUA'},datatype{d}))
        plot(tm(y==1),zeros(1,sum(y)),'+'); 
        sy = sy  * Fs; 
    else
        plot(tm,y);
        sy = sy  * (Fs / 1000);
        sy = sy - min(sy); 
%         sy(2,:) = sy(1,:)  * 30;
%         sy(2,:) = sy(2,:) - min(sy(2,:));
    end

    hold on;
    plot(tm,sy); 
        
    axis tight;
    set(gca,'Box','off','TickDir','out')
    
    ystr = sprintf('%s\n%s',datatype{d},ystr);
    ylabel(ystr)
    
    if d == 1
        title(filename,'interpreter','none')
    end
    
end

figure; cI   =  ss.spikeClusters == cluster;
wave = squeeze(nanmean(ss.spikeWaves(kI,:,cI),3));
plot(ss.spikeWavesTM,wave)
title('kls')
axis tight;
box off;
