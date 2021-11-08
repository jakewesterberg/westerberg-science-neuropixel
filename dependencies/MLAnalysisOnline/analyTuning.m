% analyze grid mapping data
clear all;
% load corresponding neural data: 
% load(''); 
addpath('C:\Users\Maier  Lab\Documents\MLAnalysisOnline\'); 
drname = 'z:\mocktests';
cd(drname);

BRdatafile = '151124_photodiode_rfori001'; 
fkey = '151124_photodiode_rfori001.gRFORIGrating_di'; % key elements in file name
fname = dir(sprintf('%s',fkey));
filename = fname.name; 
grating = readgGrating(filename); % read in text file with stim parameters
theseelectrodes = {'ainp1'}; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%does the first trial in the text file match first trial in GRATINGRECORD?
load(sprintf('%s_GRATINGRECORD1',fkey(1:strfind(fkey,'.')-1))); 
mat = []; 
for i = 1:length(GRATINGRECORD)
    mat = [mat GRATINGRECORD(i).grating_tilt]; 
end

load(sprintf('%s_GRATINGRECORD12',fkey(1:strfind(fkey,'.')-1))); 
for i = 1:length(GRATINGRECORD)
    mat = [mat GRATINGRECORD(i).grating_tilt]; 
end
match = grating.tilt == mat(1:length(grating.trial))'; 


if match == 1
    fprintf('\nfiles match\n');
else
   error('\nfiles DO NOT match\n'); 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%analyze analog data in response to stimulus presentations:

% load digital codes and neural data: 
filename = fullfile(drname,BRdatafile);
savepath = drname; 

% check if file exists and load NEV 
if exist(strcat(filename,'.nev'),'file') == 2;
    NEV = openNEV(strcat(filename,'.nev'),'nomat','nosave');
else
    error('the following file does not exist\n%s.nev',filename);
end

% get event codes from NEV
EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
EventTimes = floor(NEV.Data.SerialDigitalIO.TimeStampSec .* 1000); %ms, to match 1kHz


if exist(strcat(filename,'.ns6'),'file') == 2;
    extension = 'ns6';
elseif exist(strcat(filename,'.ns5'),'file') == 2;
    % read in header info and see if data was filtered at collection
    NS = openNSx(strcat(filename,'.ns5'),'noread','precision','double');
    if mode([NS.ElectrodesInfo.HighFreqCorner]) == 300 && mode([NS.ElectrodesInfo.HighFreqCorner]) == 500000
        % N5 is unfiltered
        extension = 'ns5';
    else
        % NS is filtered
        queryuser = 1;
    end
    clear NS
elseif exist(strcat(filename,'.ns2'),'file') == 2;
    extension = 'ns2';
else
    queryuser = 1;
end

% if the continous data was not NS6 or unfiltered NS5, ask user if they want to proceede
if queryuser
    prompt = 'We typically run this code on an unfilkopotered 30kHz signal (.ns6 or .ns5 file).\nProvide file extension (ns#, no ".") to continue or any other value to abort:\n';
    answer = input(prompt,'s');
    answer = lower(answer);
    if  strfind(answer,'ns')
        extension = answer;
    else
        return
    end
end

% Read in NS Header
NS_Header = openNSx(strcat(filename,'.',extension),'noread');
% get basic info about recorded data
neural = ~strcmp('E',{NS_Header.ElectrodesInfo.ConnectorBank}); % bank E is the BNCs on the front of the NSP
N.electrodes = length(neural);
N.neural = sum( neural);
N.analog = sum(~neural);


%get labels 
NeuralLabels = {NS_Header.ElectrodesInfo(neural).Label};
NeuralInfo = NS_Header.ElectrodesInfo(neural);
BNCLabels = {NS_Header.ElectrodesInfo(~neural).Label};
BNCInfo = NS_Header.ElectrodesInfo(~neural);
%check that D2A range is same for all files (to convert appropriately)
rnge = ((length(NS_Header.ElectrodesInfo(1).MinAnalogValue:NS_Header.ElectrodesInfo(1).MaxAnalogValue))./...
    (length(NS_Header.ElectrodesInfo(1).MinDigiValue:NS_Header.ElectrodesInfo(1).MaxDigiValue)));
if abs(rnge - 0.25) > .001
    error('check D2A range\n'); 
end

% get sampeling frequnecy
Fs = NS_Header.MetaTags.SamplingFreq;
nyq = Fs/2;
r = Fs/1000; % 1000 is the sampling frequency we want after decimation
 
% counters
clear act nct
act = 0;
nct = 0;


% analyze NEV data
for ch = 1:size(NEV.ElectrodesInfo,2)
    nevlabel{ch} = NEV.ElectrodesInfo(ch).ElectrodeLabel';
end

for ch = 1:length(theseelectrodes)
    
    clear chname; 
    chname = theseelectrodes{ch};
    nevid = find(~cellfun('isempty',strfind(nevlabel,chname)));
    if ~isempty(nevid)
    spkid = find(NEV.Data.Spikes.Electrode == nevid(ch)); 
    h_spkt  = NEV.Data.Spikes.TimeStamp(spkid); 
    spkt{ch} = unique(h_spkt./NEV.MetaTags.SampleRes.*1000); 
    end
end

% sort electrode contacts in ascending order:
for ch = 1:length(theseelectrodes)
    chname = theseelectrodes{ch}; 
    %id = find(~cellfun('isempty',strfind(NeuralLabels,chname)));
    id = find(~cellfun('isempty',strfind(BNCLabels,chname)));
    if ~isempty(id)
        ids(ch) = id;
    end
end

%%
% process data electrode by electrode
for e = 1
    fprintf('\nreading electrode %u of %u\n',e,N.electrodes); 
    
    clear NS DAT
    
    electrode = sprintf('c:%u',e);
    NS = openNSx(strcat(filename,'.',extension),electrode,'read');
    DAT = double(NS.Data);
    NS.Data = [];

    if e == 1
        %preallocation
        N.samples = length(DAT); %samples in header diffrent from actual data length???
        clear BNC LFP MUA
        BNC = zeros(ceil(N.samples/r),N.analog);
        MUA = zeros(ceil(N.samples/r),N.neural);
    end
    
    if strcmp('E',NS.ElectrodesInfo(e).ConnectorBank)
        datatype = 'BNC';
    else
        datatype = 'neural';
  
    end
    
    switch datatype
        
        case 'BNC'
            % analog input to NSP breakout board (BNC connectros on front)
            act = act+1;
            
            if Fs > 1000
                fprintf('\n decimating BNC, ch %u of %u \n',act, N.analog)
                BNC(:,act) = decimate(DAT,r); % downsample to 1kHz, lowpass filtered previously to avoid aliasing
            else
                BNC(:,act) = DAT;
            end
            clear DAT
            
            % save and clear when all channels have been read in
            if act == N.analog
                fprintf('\nsaving BNC...\n')
                savefile = sprintf('%s/%s.bnc',savepath,BRdatafile);
                save(savefile,'BNC','BNCLabels','BNCInfo','EventCodes','EventTimes','-mat')
                clear BNC 
            end
                
            
        case 'neural'
            
            % data was collected on preamp
            % filter and downsample neural data
            nct = nct+1;
            
            DAT = DAT./4; 
            
            % LFP
            lpc = 200; %low pass cutoff
            lWn = lpc/nyq;
            [bwb,bwa] = butter(4,lWn,'low');
            fprintf('\nfiltering LFP, ch %u of %u \n',nct, N.neural)
            fLFP = filtfilt(bwb,bwa,DAT);  %low pass filter
            
            if Fs > 1000
                fprintf('\n decimating LFP, ch %u of %u \n',nct, N.neural)
                LFP(:,nct) = decimate(fLFP,r); % downsample to 1kHz, lowpass filtered previously to avoid aliasing
            else
                LFP(:,nct) = fLFP;
            end
            clear fLFP 
            
            % save and clear when all channels have been read in
            if e == ids(end)
                fprintf('\nsaving LFP...\n')
                savefile = sprintf('%s/%s.lfp',savepath,BRdatafile);
                save(savefile,'LFP','NeuralLabels','NeuralInfo','EventCodes','EventTimes','-mat')
                clear LFP
            end

            %Followng Self et al. 2013 supplement
            % MUA, analog
            % high pass at 500 Hz
            hpc = 500;  %high pass cutoff
            hWn = hpc/nyq;
            [bwb,bwa] = butter(4,hWn,'high');
            fprintf('\nhp filtering MUA, ch %u of %u \n',nct, N.neural)
            hpMUA = filtfilt(bwb,bwa,DAT); %high pass filter &rectify
            
            % low pass at 5000 Hz and rectifiy
            lpc = 5000;  %low pass cutoff
            lWn = lpc/nyq;
            [bwb,bwa] = butter(4,hWn,'low');
            hpMUA = abs(filtfilt(bwb,bwa,hpMUA)); %low pass filter &rectify
            
            
            % low pass filter at 200 Hz (as in Self et al. 2013)
            lpc = 50; %200; %low pass cutoff
            lWn = lpc/nyq;
            [bwb,bwa] = butter(4,lWn,'low');
            fprintf('\nlp filtering MUA, ch %u of %u \n',nct, N.neural)
            lpMUA = filtfilt(bwb,bwa,hpMUA);  %low pass filter to smooth
            
            % then downsample:
            if Fs > 1000
                fprintf('\ndownsampling MUA, ch %u of %u \n',nct, N.neural)
                selfMUA(:,nct) = downsample(lpMUA,r); % downsample to 1kHz, lowpass filtered previously to avoid aliasing
            else
                selfMUA(:,nct) = lpMUA;
            end
            clear lpMUA hpMUA

            % save and clear when all channels have been read in
            if e == ids(end)
                fprintf('\nsaving MUA...\n')
                savefile = sprintf('%s/%s.mua',savepath,BRdatafile);
                save(savefile,'selfMUA','NeuralLabels','NeuralInfo','EventCodes','EventTimes','-mat')
                clear MUA selfMUA
            end

    end
   
end

%%
% % sort trials by position of stimulus presentation:
% test code with photodiode signal 
load(sprintf('%s',savefile),'-MAT');
neuraldata = selfMUA; 

[codesbtw tcodesbtw trackcond nine eighteen] = evalCodes(EventCodes,EventTimes,0); % 0 says don't exclude error trials
onsets  = [23:2:31]; % onset codes for up to 5 stimulus presentations
allev   =  unique(EventCodes); 
onsets(~ismember(onsets,allev)) = []; %find onset codes actually used
presOnsets = []; 

%%
header = grating.header(1);

if strcmp(header, 'rfsf')
    
    eyes = unique(grating.eye);
    
    unqcond = unique(grating.sf);
    
    for tr = 1:max(grating.trial)
        [codeids] = ismember(codesbtw{tr},onsets);
        presOnsets = [presOnsets tcodesbtw{tr}(find(codeids))]; % stim onset times
    end
    
    pre  = 0;  % t (ms) pre stimulus pres (positive values indicate later in time)
    post = 200; % t (ms) post stimulus pres
    
    % SAMPLES x CHANNELS x  PRESENTATIONS x SF CONDITIONS x EYES
    data = nan(length(pre:post),size(neuraldata,2),size(grating,1),length(unique(grating.sf)),3);
    
    for y = 1:length(eyes)
        
        for i = 1:length(unqcond)
            
            % trials at these coords
            thesepres = intersect(find(grating.sf == unqcond(i)),find(grating.eye == eyes(y)));
            
            for tr = 1:length(thesepres)
                stimON = presOnsets(thesepres(tr)); %find way to trigger data
                tref = stimON + pre : stimON + post;
                data(:,:,thesepres(tr),i,eyes(y)) = abs(neuraldata(tref,:)); % collect snippets of signal for these trs at this pos
                clear tref
            end
        end
    end
    
    
    if ismember(eyes,2)
        figure,
        set(gcf,'Color','w','Position',[1 1 800 600]);
        
        for i = 1:length(unqcond)
            plot(squeeze(data(:,:,:,i,2)),'Color',getColor(i));
            Legend{i} = sprintf('%0.2f cyc/deg',unqcond(i));
            hold on
        end
        hold off
        set(gca,'box','off','fontsize',12,'TickDir','out');
        axis tight
        xlabel('t (ms)'); ylabel('|microVolts|');
        legend(Legend,'location','northeastoutside');
        [p fname] = fileparts(filename);
        title(gca,sprintf('%s',fname));
    end
    
end

if strcmp(header,'rfori')
    
    eyes = unique(grating.eye);
    
    unqcond = unique(grating.tilt);
    
    % find presentations to remove (trial not finished)
    rempres = [1:length(grating.trial)];
    npres = 5; st = 1;
    for tr = 1:length(codesbtw)
        [codeids] = ismember(codesbtw{tr},onsets);
        presOnsets = [presOnsets tcodesbtw{tr}(find(codeids))]; % stim onset times
        
        ctp = st:st + npres -1;
        del =   npres - length(find(codeids));
        if del > 0
            rempres(end-del+1:end) = [];
        end
        
        st = ctp(end) + 1;
    end
    
    pre  = 40;  % t (ms) pre stimulus pres (positive values indicate later in time)
    post = 80;  % t (ms) post stimulus pres
    
    % SAMPLES x CHANNELS x  PRESENTATIONS x SF CONDITIONS x EYES
    data = nan(length(pre:post),size(neuraldata,2),length(presOnsets),length(unique(grating.tilt)),3);
    for y = 1:length(eyes)
        for i = 1:length(unqcond)
            
            % trials at these coords
            thesepres = intersect(find(grating.tilt == unqcond(i)),find(grating.eye == eyes(y)));
            thesepres = thesepres(ismember(thesepres,rempres));
            ntrs(i) = length(thesepres);
            for tr = 1:length(thesepres)
                stimON = presOnsets(thesepres(tr)); %find way to trigger data
                tref = stimON + pre : stimON + post;
                data(:,:,thesepres(tr),i,eyes(y)) = abs(neuraldata(tref,:)); % collect snippets of signal for these trs at this pos
                
                clear tref
            end
        end
    end
    
    avgdata = squeeze(squeeze(nanmean(nanmean(data,3),2)));
    
    clear Legend
    figure,
    set(gcf,'Color','w','Position',[1 1 800 600]);
    
    for i = 1:length(unqcond)
        plot(pre:post,squeeze(squeeze(avgdata(:,i,eye))),'Color',getColor(i),'LineWidth',2);
        Legend{i} = sprintf('%0.2d deg, trs %u',unqcond(i),ntrs(i));
        hold on
    end
    hold off
    set(gca,'box','off','fontsize',12,'TickDir','out');
    axis tight
    xlabel('t (ms)'); ylabel('|microVolts|');
    legend(Legend,'location','northeastoutside');
    [p fname] = fileparts(filename);
    title(gca,sprintf('%s',fname),'interpreter','none');
    
    figure,
    set(gcf,'Color','w','Position',[1 1 1200 600]);
    subplot(1,3,1)
    plot(unqcond,squeeze(nanmean(nanmean(nanmean(data(:,:,:,:,eye),2),1),3)),'o','Color',getColor(1),'MarkerFaceColor',getColor(1));
    hold on;
    vardata = nanvar(squeeze(nanmean(nanmean(data(:,:,:,:,eye),2),1)),0,1);
    errorbar(unqcond,squeeze(nanmean(nanmean(nanmean(data(:,:,:,:,eye),2),1),3)),vardata,'LineStyle','none','Color',getColor(1));
    set(gca,'Box','off'); title(gca,'average');
    xlabel('orientation (deg)'); ylabel('|microVolts|');
    
    subplot(1,3,2)
    plot(unqcond,squeeze(nanmedian(mean(nanmean(data(:,:,:,:,eye),2),1))),'o','Color',getColor(1),'MarkerFaceColor',getColor(1));
    set(gca,'Box','off'); title(gca,'median');
    xlabel('orientation (deg)'); ylabel('|microVolts|');
    
    subplot(1,3,3)
    for i = 1:length(unqcond)
        plot(unqcond(i),squeeze(nanmean(nanmean(data(:,:,:,i,eye),1),2)),'o','Color',getColor(i),'MarkerFaceColor',getColor(i));
        hold on;
    end
    set(gca,'Box','off'); title(gca,'all pts');
    xlabel('orientation (deg)'); ylabel('|microVolts|');
    
    
    for ch = 1:size(neuraldata,2)
        figure,
        set(gcf,'Color','w','Position',[1 1 1200 600]);
        subplot(1,3,1)
        plot(unqcond,squeeze(nanmean(nanmean(data(:,ch,:,:,eye),1),3)),'o','Color',getColor(1),'MarkerFaceColor',getColor(1));
        hold on;
        vardata = nanvar(squeeze(nanmean(data(:,ch,:,:,eye),1)),0,1);
        errorbar(unqcond,squeeze(nanmean(nanmean(data(:,ch,:,:,eye),1),3)),vardata,'LineStyle','none','Color',getColor(1));
        set(gca,'Box','off'); title(gca,'average');
        xlabel('orientation (deg)'); ylabel('|microVolts|');
        
        subplot(1,3,2)
        plot(unqcond,squeeze(nanmedian(nanmean(data(:,ch,:,:,eye),1))),'o','Color',getColor(1),'MarkerFaceColor',getColor(1));
        set(gca,'Box','off'); title(gca,'median');
        xlabel('orientation (deg)'); ylabel('|microVolts|');
        
        subplot(1,3,3)
        for i = 1:length(unqcond)
            plot(unqcond(i),squeeze(nanmean(data(:,ch,:,i,eye),1)),'o','Color',getColor(i),'MarkerFaceColor',getColor(i));
            hold on;
        end
        set(gca,'Box','off'); title(gca,'all pts');
        xlabel('orientation (deg)'); ylabel('|microVolts|');
        
    end
    
end

%%
ch = 2;
pre  = -50; 
post = 150;
tvec = pre:post; 
binsize = 4;    % in ms
fs      = 1000; % in Hz
for ch = 3
for y = 1:length(eyes)
    for i = 1:length(unqcond)
        spkvec = [];
        spktr  = [];
        
        % trials at these coords
        thesepres = intersect(find(grating.tilt == unqcond(i)),find(grating.eye == eyes(y)));
        thesepres = thesepres(ismember(thesepres,rempres));
        ntrs(i) = length(thesepres);
        
        for tr = 1:length(thesepres)
            stimON = presOnsets(thesepres(tr)); %find way to trigger data
            tref = stimON + pre : stimON + post;
            these = find(spkt{ch} >= tref(1) & spkt{ch} <= tref(end));
            if any(these)
                [~,id] =find(ismember(tref, spkt{ch}(these)));
                spkvec = [spkvec tvec(id)]; % collect snippets of signal for these trs at this pos
                spktr  = [spktr repmat(tr,length(these),1)'];
            end
            clear tref
        end
        
        if ~isempty(spkvec)
            [edges,r,h] = calcPSTH(binsize,fs,spkvec,spktr,pre,post);
            title(h,sprintf('ori %d',unqcond(i)));
            xlabel('t (ms)'); ylabel('spks/sec'); 
        end
        
    end
end
end



