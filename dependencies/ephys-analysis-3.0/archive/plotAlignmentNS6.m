function h = plotAlignmentNS6(BRdatafile,el,sortdirection)

h = figure('Units','Inches','Position',[0 0 11 8.5]); 

pre = 50;
post = 250;

flag_subtractbasline = false;
flag_halfwaverectify = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

locations = {...
    'Drobo2','022';...
    'Drobo','022';...
    'Drobo','021'};
brdrname = [];
for j = 1:size(locations, 1)
    temp = sprintf('/Volumes/%s/DATA/NEUROPHYS/rig%s/%s/',locations{j,1},locations{j,2},BRdatafile(1:8));
    if  exist([temp BRdatafile '.nev'],'file');
        brdrname = temp;
        break
    end
end
if isempty(brdrname)
    fprintf('\ncannot find file on drobo\n')
    return
end
header = openNEV(strcat(brdrname,BRdatafile,'.nev'),'noread','nosave');
st = header.MetaTags.DateTime;
dur = round(header.MetaTags.DataDurationSec / 60);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[DAT, EventCodes, EventTimes]= getLFP(BRdatafile,'ns6',el,sortdirection);

Fs = 30000;
nyq = Fs/2;
r = Fs/1000; % 1000 is the sampeling frequency we want after decimation, allows us to use time info from LFP above
triggerpoints = round(EventTimes(EventCodes == 23)/r);

% MUA
hpc = 750;  %high pass cutoff
hWn = hpc/nyq;
[bwb,bwa] = butter(4,hWn,'high');
hpMUA = abs(filtfilt(bwb,bwa,DAT)); %high pass filter &rectify

lpc = 200; %low pass cutoff
lWn = lpc/nyq;
[bwb,bwa] = butter(4,lWn,'low');
lpMUA = filtfilt(bwb,bwa,hpMUA);  %low pass filter to smooth

MUA = downsample(lpMUA,r); % downsample to 1kHz, lowpass filtered previously to avoid aliasing

[datMUA, TM] = trigData(MUA, triggerpoints , pre, post);
EVM = mean(datMUA,3);

clear *MUA

% LFP
lpc = 500; %low pass cutoff
lWn = lpc/nyq;
[bwb,bwa] = butter(4,lWn,'low');
lpLFP = filtfilt(bwb,bwa,DAT);  %low pass filter to smooth

LFP = downsample(lpLFP,r); % downsample to 1kHz, lowpass filtered previously to avoid aliasing

[datLFPA, ~] = trigData(LFP, triggerpoints , pre, post);
EVP = mean(datLFPA,3);

clear DAT *LFP 

%%


switch sortdirection
    case 'ascending'
        channelsindepth = [1:size(EVP,2)] ;
    case 'descending'
        channelsindepth = fliplr([1:size(EVP,2)]);
end

n = length(triggerpoints);


%%

subplot(1,4,1); cla

f_ShadedLinePlotbyDepth(EVP,channelsindepth,TM,[],1,0)
title(sprintf('%s\nEVP (uV)',[BRdatafile '_' el]),'interpreter','none');


%%
subplot(1,4,2); cla


CSD = calcCSD(EVP) .* 0.4; % conver to nA/mm^3
if flag_subtractbasline
    CSD = bsxfun(@minus,CSD,mean(CSD(:,TM<0),2));
end
if flag_halfwaverectify
    CSD(CSD > 0) = 0;
end
CSD = padarray(CSD,[1 0],0);
f_ShadedLinePlotbyDepth(CSD,channelsindepth,TM,[],1,1)
title(sprintf('n = %u trls\nPad CSD (nA/mm^3)',n))

%%

subplot(1,4,3); cla

CSDf = filterCSD(CSD);
switch sortdirection
    case 'ascending'
        y = [1:size(CSDf,1)]./10;
        ydir = 'reverse';
    case 'descending'
        y = fliplr([1:size(CSDf,1)]./10);
        ydir = 'normal';
end
imagesc(TM,y,CSDf); colormap(flipud(jet));
climit = max(abs(get(gca,'CLim'))*.8);
set(gca,'CLim',[-climit climit],'Ydir',ydir,'Box','off','TickDir','out')
hold on;
plot([0 0], ylim,'k')
title(sprintf('st tm = %s\nFilt CSD (s = 0.1)',st(end-8:end)))
xlabel('Time')

%%

subplot(1,4,4); cla

f_ShadedLinePlotbyDepth(EVM,channelsindepth,TM,[],1)
title(sprintf('dur ~%u min\nAnalog MUA (uV)',dur))
