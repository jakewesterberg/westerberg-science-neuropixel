% June 15, 2017
% Oct 5, 2017


clear; %close all

filename  = '160108_E_dotmapping003';
elabel    = 'eD10';
pre       = 0.35; % s
crit0      = 1; % z-score
dthresh = 0.5;


nevdir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';
klsdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';
rfdir = '/Volumes/LaCie/Dichoptic Project/vars/V1Limits_Aug18/';

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

clear brfile nevfile klsfile dotfile rffile ns6file
dotfile = sprintf('/Volumes/%s/Data/NEUROPHYS/rig%03u/%s_%s/%s.gDotsXY_di',...
    drobo,TuneList.Rig(s),TuneList.Datestr{s},TuneList.Monkey{s},filename);
nevfile = [nevdir filename '.ppnev'];
klsfile = [klsdir filename filesep 'ss.mat'];
rffile  = [rfdir filename(1:8) '_' elabel(1:2) '.mat'];
ns6file  = sprintf('/Volumes/%s/Data/NEUROPHYS/rig%03u/%s_%s/%s.ns6',...
    drobo,TuneList.Rig(s),TuneList.Datestr{s},TuneList.Monkey{s},filename);

clear dots*
dots  = readgDotsXY(dotfile); % read in text file with stim parameters
dotsXrng = [min(dots.dot_x) max(dots.dot_x)];
dotsYrng = [min(dots.dot_y) max(dots.dot_y)];

clear NS_Header ss ppNEV NEV
NS_Header = openNSx(ns6file,'noread');
load(klsfile,'ss');
load(nevfile,'-mat'); NEV = ppNEV; clear ppNEV

clear EventSampels EventCodes pEvC pEvT
EventSampels = NEV.Data.SerialDigitalIO.TimeStamp;
EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
[pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);

% NS6
clear e electrode Fs NS DAT
e = find(strcmp(cellfun(@(x) x(1:4), {NS_Header.ElectrodesInfo.Label},'UniformOutput',0),elabel));
electrode = sprintf('c:%u',e);
NS = openNSx(ns6file,electrode,'read');
DAT = double(NS.Data)'; clear NS
% filter
nsFs = double(NS_Header.MetaTags.SamplingFreq);
nyq = nsFs/2;
hpc = 750;  %high pass cutoff
hWn = hpc/nyq;
[bwb,bwa] = butter(4,hWn,'high');
DAT = abs(filtfilt(bwb,bwa,DAT));
DAT = DAT ./ 4;


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


%%
t = randi(length(pEvC),1);
while ~any(pEvC{t} == 96)
    t = randi(length(pEvC),1);
end
t


figure


% clear dot_*
dot_x = dots.dot_x(dots.trial == t);
dot_y = dots.dot_y(dots.trial == t);
dot_d = dots.diameter(dots.trial == t);

clear stimon stimoff start finish
stimon  =  pEvC{t} == 23 | pEvC{t} == 25  | pEvC{t} == 27   | pEvC{t} == 29  | pEvC{t} == 31;
stimoff =  pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32;
start = pEvT{t}(stimon);
finish = pEvT{t}(stimoff);

% photodiode triggering
TP = [start finish];
[newTP,trigger] = photoReTrigger(TP,dotfile(1:end-11),mean(dot_y),'default');
start = newTP(:,1);
finish =  newTP(:,2);

% spatial plots
for p = 1:length(start)
    subplot(5,7,p+1)
    center = [dot_x(p), dot_y(p)];
    width  = [dot_d(p),dot_d(p)];
    rec    = [center - width./2 width];
    rectangle('Position',rec,'Curvature',[1 1]);
    xlim(dotsXrng); ylim(dotsYrng); axis equal
    set(gca,'Box','off','TickDir','out')
    
    if p == 3
        title(sprintf('%s_%s\ntrl = %u',filename,elabel,t),'interpreter','none')
    end
end


datatype = {'SUA','dMUA','aMUA'};
for d = 1:3
    clear y sy k tm R Fs
    
    switch datatype{d}
        case 'aMUA'
            % NS6
            
            clear R Fs
            R = 1;
            Fs = nsFs;
            k = jnm_kernel( 'psp', (20/1000) * Fs/R );

            tm   = ([st:R:en] - start(1)) ./ R; %ms
            y    = (DAT(st:en) - mean(DAT(st:start(1)))) ./ 1000;
            ystr = ('Delta mV');
        
        case 'dMUA'
            
            clear R Fs
            R = 30;
            Fs = 30000;
            
            clear st en tm k
            st = start(1)    - pre*Fs;
            en = finish(end) + pre*Fs;
            tm = ([st:R:en] - start(1)) ./ R; %ms
            k = jnm_kernel( 'psp', (20/1000) * Fs/R );
            
            y   = zeros(size(tm));
            I   =  NEV.Data.Spikes.Electrode == nI;
            SPK = double(NEV.Data.Spikes.TimeStamp(I));
            x   = SPK - start(1);
            x   = unique(round( x ./R ));
            [~,ii]=intersect(tm,x,'stable');
            y(ii) = 1;
            
            ystr = 'imp/s';
            
        case 'SUA'
            
            clear R Fs
            R  = 1;
            Fs = 30000;
            
            clear st en tm k
            st = start(1)    - pre*Fs;
            en = finish(end) + pre*Fs;
            tm = ([st:R:en] - start(1)) ./ R; %ms
            k = jnm_kernel( 'psp', (20/1000) * Fs/R );
            
            y   = zeros(size(tm));
            I   =  ss.spikeClusters == cluster;
            SPK = ss.spikeTimes(I);
            x   = SPK - start(1);
            x   = unique(round( x ./R ));
            [~,ii]=intersect(tm,x,'stable');
            y(ii) = 1;
            
            ystr = 'imp/s';
    end
    
    % convolve
    clear sy
    sy    = doConv(y,k) * Fs/R;
    
    subplot(5,1,d+1)
    tm = tm ./ Fs/R; 
    plot(tm,sy); hold on; axis tight;
    set(gca,'Box','off','TickDir','out')
    
    ystr = sprintf('%s\n%s',datatype{d},ystr);
    ylabel(ystr)
    
    if ~strcmp(datatype{d},'aMUA')
        plot(tm(y==1),min(ylim),'+','color',[0 .4 0]);
    end
    
end

subplot(5,1,5)
clear stimon stimoff stimulus tm Fs
Fs = 30000;
tm = ((st:en) - start(1)) ./ Fs;
stimon  = (start  - start(1)) / Fs;
stimoff = (finish - start(1)) / Fs;
stimulus = zeros(size(tm));
for p = 1:length(stimoff)
    clear ii
    ii = tm >= stimon(p) & tm <= stimoff(p);
    stimulus(ii) = 1;
end
plot(tm,stimulus); axis tight; ylim([0 1.3])
set(gca,'Box','off','TickDir','out')
xlabel('t(ms)')
ylabel(sprintf('Stimulus\non/off'))


ahahaa

%%
el  = elabel(1:2); filelist = {};
for f = 1:length(TuneList.dotmapping{s})
filelist{f} = sprintf('%s%02u',dotfile(1:end-14),TuneList.dotmapping{s}(f));
end

RF  = getRF({dotfile(1:end-11)},el,sortdirection,{'auto','kilosorted'});
%%

datatype = {'kls_zsr'};
for d = 1
    
    %subplot(2,2,d); cla
    
    [uRF, xcord, ycord, elabels]= meanRF(RF,datatype{d});
    [fRF, dRF, rflim]   = fitRF(uRF,xcord,ycord,[],crit0,dthresh);
    
    for rf = 1:size(uRF,1)
        
    centroid = fRF(rf,1:2);
    width    = fRF(rf,3:4);
    rfboundary = [centroid(1)-width(1)/2,centroid(2)-width(2)/2, width(1), width(2)];
    
    dat = squeeze(uRF(rf,:,:));
    if all(all(isnan(dat)))
        continue
    end
    
    figure
    imagesc(xcord,ycord,dat); hold on
    if ~any(isnan(rfboundary))
    rectangle('Position',rfboundary,'Curvature',[1 1]);
    end
    
    set(gca,...
        'TickDir','out',...
        'Box','off',...
        'Ydir','normal');
    title(sprintf('%s_%s\n%s',RF.header,elabels{rf},datatype{d}),'interpreter','none')
    colorbar
    
    extra = range(get(gca,'Clim')./64);
    set(gca,'Clim', get(gca,'Clim') + [-1 0]*extra)
    colormap( [1 1 1; jet(64)])
    axis tight;
    axis equal;
    
    end
end
%     %%
%     subplot(2,2,d+2)
%     switch datatype{d}(1:3)
%         case 'kls'
%             cI   =  ss.spikeClusters == cluster;
%             wave = squeeze(nanmean(ss.spikeWaves(kI,:,cI),3));
%             plot(ss.spikeWavesTM,wave)
%             title('kls')
%         case 'nev'
%             I   =  NEV.Data.Spikes.Electrode == nI;
%             wave = nanmean(WAVES(:,I),2);
%             plot(wave);
%             title('nev')
%     end
%     box off;
%     
% end



