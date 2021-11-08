function [LFP,MUA] = getNeuralData(signals,theseelectrodes,filename)

LFP = [];
MUA = []; 
if exist(strcat(filename,'.ns6'),'file') == 2;
    extension = 'ns6';
elseif exist(strcat(filename,'.ns5'),'file') == 2;
    NS = openNSx(strcat(filename,'.ns5'),'noread','precision','double');
    if mode([NS.ElectrodesInfo.HighFreqCorner]) == 300 && mode([NS.ElectrodesInfo.HighFreqCorner]) == 500000
        % N5 is unfiltered
        extension = 'ns5';
    end
elseif exist(strcat(filename,'.ns2'),'file') == 2;
    extension = 'ns2';
else
    error('file does not exist\n');
end


% Read in NS Header
NS_Header = openNSx(strcat(filename,'.',extension),'noread');
neural = ~strcmp('E',{NS_Header.ElectrodesInfo.ConnectorBank}); % bank E is the BNCs on the front of the NSP
N.electrodes = length(neural);
N.neural = sum( neural);
N.analog = sum(~neural);

%get labels 
NeuralLabels = {NS_Header.ElectrodesInfo(neural).Label};
NeuralInfo = NS_Header.ElectrodesInfo(neural);
BNCLabels = {NS_Header.ElectrodesInfo(~neural).Label};
BNCInfo = NS_Header.ElectrodesInfo(~neural);

% get sampeling frequency
Fs = NS_Header.MetaTags.SamplingFreq;
nyq = Fs/2;
r = Fs/1000; % 1000 is the sampling frequency we want after decimation
 
% counters
clear act nct
act = 0;
nct = 0;

% sort electrode contacts in ascending order:
for ch = 1:length(theseelectrodes)
    chname = theseelectrodes{ch}; 
    id = find(~cellfun('isempty',strfind(NeuralLabels,chname)));
    if ~isempty(id)
        ids(ch) = id;
    end
end

if ~exist('ids') 
    ids = find(~cellfun('isempty',strfind(BNCLabels,chname)));
end

% load LFP and/or MUA
if any(strcmp(signals,'LFP')) || any(strcmp(signals,'MUA')) || ...
        any(strcmp(signals,'lfp')) || any(strcmp(signals,'mua'))
    
    for e = ids
        
        electrode = sprintf('c:%u',e);
        NS = openNSx(strcat(filename,'.',extension),electrode,'read');
        DAT = double(NS.Data);
        NS.Data = [];
        
        % data was collected on preamp
        % filter and downsample neural data
        nct = nct+1;
        
        DAT = DAT./4;
        
        if ids == ids(1)
            %preallocation
            N.samples = length(DAT); %samples in header diffrent from actual data length???
           
            if any(strcmp(signals,'LFP')) || any(strcmp(signals,'lfp'))
                LFP = zeros(ceil(N.samples/r),length(ids));
            end
            
            if any(strcmp(signals,'MUA')) || any(strcmp(signals,'mua'))
                MUA = zeros(ceil(N.samples/r),length(ids));
            end
        end
        
        if any(strcmp(signals,'LFP')) || any(strcmp(signals,'lfp'))
            % LFP
            lpc = 200; %low pass cutoff
            lWn = lpc/nyq;
            [bwb,bwa] = butter(4,lWn,'low');
           
            fLFP = filtfilt(bwb,bwa,DAT);  %low pass filter
            
            if Fs > 1000
                LFP(:,nct) = decimate(fLFP,r); % downsample to 1kHz, lowpass filtered previously to avoid aliasing
            else
                LFP(:,nct) = fLFP;
            end
            clear fLFP 
        end
        
         if any(strcmp(signals,'MUA')) || any(strcmp(signals,'mua'))
             %Followng Self et al. 2013 supplement
            
            % high pass at 500 Hz
            hpc = 500;  %cutoff
            hWn = hpc/nyq;
            [bwb,bwa] = butter(4,hWn,'high');
            
            hpMUA = filtfilt(bwb,bwa,DAT); %high pass filter 
            
            % low pass at 5000 Hz and rectifiy
            lpc = 5000;  % cutoff
            lWn = lpc/nyq;
            [bwb,bwa] = butter(4,hWn,'low');
            hpMUA = abs(filtfilt(bwb,bwa,hpMUA)); %low pass filter &rectify
            
            
            % low pass filter at x Hz 
            lpc = 200; %low pass cutoff
            lWn = lpc/nyq;
            [bwb,bwa] = butter(4,lWn,'low');
          
            lpMUA = filtfilt(bwb,bwa,hpMUA);  %low pass filter to smooth
            
            % then downsample:
            if Fs > 1000
                fprintf('\ndownsampling MUA, ch %u of %u \n',nct, N.neural)
                MUA(:,nct) = downsample(lpMUA,r); % downsample to 1kHz, lowpass filtered previously to avoid aliasing
            else
                MUA(:,nct) = lpMUA;
            end
            clear lpMUA hpMUA
             
         end
     
        
    end
end

 