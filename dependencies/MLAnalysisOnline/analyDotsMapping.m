% analyze grid mapping data
clear all;
% load corresponding neural data: 
% load(''); 

%drname = 'C:\Users\Maier  Lab\Documents\MLAnalysis';
drname = 'z:/151125_E'; 
cd(drname);

BRdatafile = '151125_E_dotmapping003'; 
cd('y:/151125_E'); 
fkey = '151125_E_dotmapping003.gDotsXY_di'; % key elements in file name
fname = dir(sprintf('%s',fkey));
filename = fname.name; 
theseelectrodes = {'eD11';'eD15'}; 
signals = {'spikes'; 'mua'; 'lfp'}; 

dots = readgDotsXY(filename); % read in text file with stim parameters
dots.trial(1) = 1; 

cd(drname); 
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % plot positions of presented stimuli:
% figure,
% set(gcf,'Color','w');
% plot(dots.dot_x,dots.dot_y,'bo','MarkerFaceColor','b');
% set(gca,'box','off','LineWidth',2,'TickDir','out');
% title('Positions of presented stimuli');
% xlabel('horizontal position (dva)');
% ylabel('vertical position (dva)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot positions of presented stimuli color-coded by other stimulus parameter:
% 
% coord = cat(2,round(dots.dot_x*10)./10,round(dots.dot_y*10)/10);
% unqvals  = unique(coord,'rows');
% possible = length(unique(dots.dot_x));

% poscolor   = [1 0]; % black or white
% 
% emp_color = nan(length(unqvals),length(poscolor));
% 
% % sort trials by position
% for i = 1:length(unqvals)
%     % trials at these coords
%     thesetrs = find(coord(:,1) == unqvals(i,1) & coord(:,2) == unqvals(i,2));
%     ntrsatpos(i) = length(thesetrs);
%     
% end
% 
% figure,
% set(gcf,'Color','w');
% bar([1:length(unqvals)],ntrsatpos);
% xlabel('position number');
% ylabel('n total trials');
% box off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%analyze analog data in response to stimulus presentations:

% load digital codes and neural data: 
filename = fullfile(drname,BRdatafile);
savepath = drname; 

% check if file exist and load NEV
if exist(strcat(filename,'.nev'),'file') == 2;
    NEV = openNEV(strcat(filename,'.nev'),'nomat','nosave');
else
    error('the following file does not exist\n%s.nev',filename);
end
% get event codes from NEV, then clear
EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
EventTimes = floor(NEV.Data.SerialDigitalIO.TimeStampSec .* 1000); %ms, to match 1kHz

queryuser = 0; 

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
% %check that D2A range is same for all files (to convert appropriately)
% rnge = ((length(NS_Header.ElectrodesInfo(1).MinAnalogValue:NS_Header.ElectrodesInfo(1).MaxAnalogValue))./...
%     (length(NS_Header.ElectrodesInfo(1).MinDigiValue:NS_Header.ElectrodesInfo(1).MaxDigiValue)));
% if abs(rnge - 0.25) > .001
%     error('check D2A range\n'); 
% end

% % analyze NEV data
% for ch = 1:size(NEV.ElectrodesInfo,2)
%     nevlabel{ch} = NEV.ElectrodesInfo(ch).ElectrodeLabel';
% end
% 
% for ch = 1:length(theseelectrodes)
%     
%     clear chname; 
%     chname = theseelectrodes{ch};
%     nevid = find(~cellfun('isempty',strfind(nevlabel,chname)));
%     if ~isempty(nevid)
%     spkid = find(NEV.Data.Spikes.Electrode == nevid(ch)); 
%     h_spkt  = NEV.Data.Spikes.TimeStamp(spkid); 
%     spkt{ch} = unique(h_spkt./NEV.MetaTags.SampleRes.*1000); 
%     end
%     
% end


% get sampeling frequnecy
Fs = NS_Header.MetaTags.SamplingFreq;
nyq = Fs/2;
r = Fs/1000; % 1000 is the sampling frequency we want after decimation
 
% counters
clear act nct
act = 0;
nct = 0;

% process data electrode by electrode

% sort electrode contacts in ascending order:
for ch = 1:length(theseelectrodes)
    chname = theseelectrodes{ch}; 
    id = find(~cellfun('isempty',strfind(NeuralLabels,chname)));
    if ~isempty(id)
        ids(ch) = id;
    end
end

for e = ids
    fprintf('\nreading electrode %u of %u\n',e,N.electrodes); 
    
    clear NS DAT
%     if ~strcmp(NeuralLabels{e}(1:4),thiselectrode)
%         continue
%     else
%     
    electrode = sprintf('c:%u',e);
    NS = openNSx(strcat(filename,'.',extension),electrode,'read');
    DAT = double(NS.Data);
    NS.Data = [];

    if e == 1
        %preallocation
        N.samples = length(DAT); %samples in header diffrent from actual data length???
        clear BNC LFP MUA
        BNC = zeros(ceil(N.samples/r),N.analog);
        LFP = zeros(ceil(N.samples/r),N.neural);
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
            lpc = 50; %low pass cutoff
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

    clear DAT NEV
%%
% % sort trials by position of stimulus presentation:
% test code with photodiode signal 
load(sprintf('%s.mua',BRdatafile),'-MAT');
neuraldata = selfMUA;

[codesbtw tcodesbtw trackcond nine eighteen succtr] = evalCodes(EventCodes,EventTimes,0);
onsets     = [23:2:31];
presOnsets = [];
rempres = [1:length(dots.trial)];
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
post = 140; % t (ms) post stimulus pres

coord = cat(2,dots.dot_x,dots.dot_y);
unqvals  = unique(coord,'rows');

data = nan(length(pre:post),size(neuraldata,2),size(unqvals,1),length(presOnsets));
for i = 1:length(unqvals)
    
    % trials at these coords
    thesetrs = intersect(find(dots.dot_x == unqvals(i,1)),find(dots.dot_y == unqvals(i,2)));
    thesetrs = thesetrs(ismember(thesetrs,rempres));
    valtrs{i} = thesetrs; 
    for tr = 1:length(thesetrs)
       
            stimON = presOnsets(thesetrs(tr)); %find way to trigger data
            tref = stimON + pre : stimON + post;
            data(:,:,i,thesetrs(tr)) = abs(neuraldata(tref,:)); % collect snippets of signal for these trs at this pos
            clear tref
  
    end
    
end


resp = squeeze(nanmean(nanmean(nanmean(data,1),4),2)); 
%resp = squeeze(nanmean(nanmean(data(:,2,:,:),1),4)); 
figure, 
scatter(unqvals(:,1),unqvals(:,2),50,resp,'filled'); 
colorbar, 
ylabel('vertical (dva)'); xlabel('horizontal (dva)'); 
title('avg across channels RF dot mapping'); 

%%
unqx = unique(dots.dot_x); 
unqy = unique(dots.dot_y); 
data = nan(length(pre:post),size(neuraldata,2),size(unqx,1),size(unqy,1),length(presOnsets));
for i = 1:length(unqx)
    for ii = 1:length(unqy)
        
    % trials at these coords
    thesetrs = intersect(find(dots.dot_x == unqx(i)),find(dots.dot_y == unqy(ii)));
    thesetrs = thesetrs(ismember(thesetrs,rempres));
    valtrs{i} = thesetrs; 
    for tr = 1:length(thesetrs)
       
            stimON = presOnsets(thesetrs(tr)); %find way to trigger data
            tref = stimON + pre : stimON + post;
            data(:,:,i,ii,thesetrs(tr)) = abs(neuraldata(tref,:)); % collect snippets of signal for these trs at this pos
            clear tref
  
    end
    
end
end
resp = squeeze(nanmean(nanmean(nanmean(data,1),5),2)); 

figure, 
imagesc(unqx,unqy,resp); colorbar
colorbar, 
ylabel('vertical (dva)'); xlabel('horizontal (dva)'); 
title('avg across channels RF dot mapping'); 






% %%
% 
% %color_map = @(resp) ([mod((rand*resp), 1), mod((rand*resp), 1), mod((rand*resp), 1)]);
% 
% ch = 1;
% resp = squeeze(nanmean(nanmean(data(:,ch,:,:),1),4));
% figure, set(gcf,'Position',[1 1 1000 1000]);
% for i = 1:length(unqvals)
%     diameter = dots.diameter(valtrs{i}(1));
%     h = rectangle('Position',[unqvals(i,1) unqvals(i,2) diameter diameter],'Curvature',[1 1]);
%     hold on;
%     clr = slide_map(cid(i),:);
%     set(h,'EdgeColor',clr,'LineWidth',3); clear h;
%     hold on;
% end
% axis equal
% 
% colormap(slide_map); colorbar
% ylabel('vertical (dva)'); xlabel('horizontal (dva)');
% title(sprintf('ch %s RF dot mapping',theseelectrodes{ch}));



