function h = plotDarkrestPDR(BRdatafile,el,sortdirection)
% December 2016
% Adaped from Jake Westerberg's jnm_pdr_ns2

h = figure('Units','Inches','Position',[0 0 11 8.5]); 

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
[LFP, EventCodes, EventTimes]= getLFP(BRdatafile,'ns2',el,sortdirection);
triggerpoints = EventTimes(EventCodes == 23);%% | EventCodes == 25 | EventCodes == 27 | EventCodes == 29| EventCodes == 31);

[lfpDAT, TM] = trigData(LFP, triggerpoints , pre, post);
EVP = mean(lfpDAT,3);

clear lfpDAT LFP 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[MUA, ~, ~]= getLFP(BRdatafile,'ns6',el,sortdirection);

Fs = 30000;
nyq = Fs/2;
r = Fs/1000; % 1000 is the sampeling frequency we want after decimation, allows us to use time info from LFP above

hpc = 750;  %high pass cutoff
hWn = hpc/nyq;
[bwb,bwa] = butter(4,hWn,'high');
hpMUA = abs(filtfilt(bwb,bwa,MUA)); %high pass filter &rectify

lpc = 200; %low pass cutoff
lWn = lpc/nyq;
[bwb,bwa] = butter(4,lWn,'low');
lpMUA = filtfilt(bwb,bwa,hpMUA);  %low pass filter to smooth

MUA = downsample(lpMUA,r); % downsample to 1kHz, lowpass filtered previously to avoid aliasing

[muaDAT, ~] = trigData(MUA, triggerpoints , pre, post);
EVM = mean(muaDAT,3);

clear muaDAT  *MUA 

%%

 jnm = zeros( pChan, 257 );
    
    for i = k * pChan - pChan + 1  : k * pChan
        
        [ jnm( i - ( ( k - 1 ) * pChan ), : ) ] = jnm_psd( lfp( i, end - valn : end ), ...
            512, 1000, 512, 0);
        
    end
    
    jnm2 = zeros( pChan, 52 );
    
    for i = 1 : 52
        
        for j = 1 : pChan
            
            jnm2( j, i ) = ( jnm( j, i ) - mean( jnm( :, i ) ) ) ...
                / mean( jnm( :, i ) ) * 100;
            
        end
    end
    
    subplot( 1, pNum, k )
    imagesc( jnm2 );
    colormap('hot');
    set(gca,  'XTickLabel', [] );


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
