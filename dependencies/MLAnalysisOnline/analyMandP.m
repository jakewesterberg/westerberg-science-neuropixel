%M or P classification:

BRdatafile = '160205_I_cinteroc001';
el = 'White';

if ispc
    brdrname = sprintf('Z:\\%s',BRdatafile(1:8));
    mldrname = sprintf('Y:\\%s',BRdatafile(1:8));
else
    brdrname = sprintf('/Volumes/Drobo/DATA/NEUROPHYS/rig022/%s',BRdatafile(1:8));
    mldrname = brdrname;
end

if ~isempty(strfind(BRdatafile,'ori'))
    ext = '.gRFORIGrating_di';
elseif ~isempty(strfind(BRdatafile,'sf'))
    ext = '.gRFSFGrating_di';
elseif  ~isempty(strfind(BRdatafile,'size'))
    ext = '.gRFSIZEGrating_di';
elseif  ~isempty(strfind(BRdatafile,'cinteroc'))
    ext = '.gCINTEROCGrating_di';
end

badobs = getBadObs(BRdatafile);

flag_RewardedTrialsOnly = true;
grating = readgGrating([mldrname filesep BRdatafile ext]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% load digital codes and neural data:
filename = fullfile(brdrname,BRdatafile);

% check if file exist and load NEV
if exist(strcat(filename,'.nev'),'file') == 2;
    NEV = openNEV(strcat(filename,'.nev'),'read','overwrite','uV');
else
    error('the following file does not exist\n%s.nev',filename);
end
% get event codes from NEV
EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
EventTimes = floor(NEV.Data.SerialDigitalIO.TimeStampSec .* 1000); %ms, to match 1kHz
EventSampels = NEV.Data.SerialDigitalIO.TimeStamp;
[pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);

% check that all is good between NEV and grating text file;
[allpass, message] =  checkTrMatch(grating,NEV);
if ~allpass
    error('not all pass')
end
%%
%%
% sort/pick trials [before iterating units]
stimfeatures = {...
    'tilt'...
    'sf'...
    'contrast'...
    'fixedc'...
    'diameter'...
    'eye'...
    'varyeye'...
    'oridist'...
    'gabor'...
    'gabor_std'...
    'phase'...
    };
clear(stimfeatures{:})

obs = 0; clear spkTPs STIM
for t = 1: length(pEvC)
    
    stimon  =  pEvC{t} == 23 | pEvC{t} == 25  | pEvC{t} == 27   | pEvC{t} == 29  | pEvC{t} == 31;
    stimoff =  pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32;
    
    st = pEvT{t}(stimon);
    en = pEvT{t}(stimoff);
    
    stim =  find(grating.trial == t); if any(diff(stim) ~= 1); error('check grating file'); end
    
    for p = 1:length(en)
        obs = obs + 1;
        
        if  any(obs == badobs) || ...
                (flag_RewardedTrialsOnly && ~any(pEvC{t} == 96))
            
            spkTPs(obs,:) = [0 0];
            for f = 1:length(stimfeatures)
                STIM.(stimfeatures{f})(obs,:) = NaN;
            end
        else
            
            spkTPs(obs,:) = [st(p) en(p)];
            for f = 1:length(stimfeatures)
                STIM.(stimfeatures{f})(obs,:) = grating.(stimfeatures{f})(stim(p));
            end
        end
    end
end % looked at all trials
%%
% FOR THIS ANALYSIS USE ONLY GRATINGS WITH 80% CONTRAST OR HIGHER
thrc = 0.75;
spkTPs = spkTPs(STIM.contrast >= thrc,:);
%%
% get electrrode index
elabel = el;
eidx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x',elabel)),{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0)));
if isempty(eidx)
    error('no %s',elabel)
end
eI =  NEV.Data.Spikes.Electrode == eidx;
units = unique(NEV.Data.Spikes.Unit(eI));
for u = 0:max(units)
    if u > 0
        elabel = sprintf('%s - unit%u',el,u);
        I = eI &  NEV.Data.Spikes.Unit == u;
    else
        elabel = sprintf('%s - all spikes',el);
        I = eI;
    end
    
    % get SPK and WAVE
    clear SPK WAVE RESP
    SPK = double(NEV.Data.Spikes.TimeStamp(I)); % in samples
    WAVE = double(NEV.Data.Spikes.Waveform(:,I));
    RESP = NaN(length(spkTPs),1);
    pre = -25; post = 200;
    
    for r = 1:length(spkTPs)
        st = spkTPs(r,1);
        en = spkTPs(r,2);
        if st ~= 0 && en ~= 0
            RESP(r,:)   = sum(SPK > st & SPK < en);
        end
    end
    
    % psth:
    binsize = 5; % ms
    triallen = length([pre:post]);
    fs = 1000;
    ntrials = size(RESP,1);
    
    lastBin = binsize * ceil((triallen-1)*(1000/(fs*binsize)));
    edges = 0 : binsize : lastBin;
    tedges = edges +pre;
    x = (mod(SPK./1000-1,triallen)+1)*(1000/fs);
    r = (histc(x,edges)*1000) / (ntrials*binsize);
    faker = r;
    faker(tedges<0) = nan;
    
    
    % neuron latency:
    % threshold: 3*STDs above base firing rate
    
    m_bsl   = nanmean(r(tedges<=0));
    std_bsl = nanstd(r(tedges<=0));
    thr     =(3*m_bsl);
    onlat   = tedges(find(faker>thr,1,'first')); % first bin passing thr;     % Jiang et al. (2015): P (25.2, 2.0) M  (19.6, 2.2)
    peaklat = tedges(find(faker == max(faker))); % bin with max resp    % Jiang et al. (2015): P (72.9, 5.3) M  (43.5, 3.3)
    if isempty(onlat)
        fprintf('\nNote: No data points cross onset threshold\n');
    end
    
    % neuron transiency:
    % Jiang et al. (2015): P (22.95, 5.97) M  (39.53,7.5)
    tridx = 100 - (nanmean((r(tedges>=100 & tedges <=200))) - nanmean(r(tedges<0))) ./ (nanmean((r(tedges>=0 & tedges <=100))) - nanmean(r(tedges<0))).*100;
    
    fprintf('\nonset latency: %d ms\npeak latency: %d ms\ntransiency index %d\n\n',onlat,peaklat,tridx);
    
    %Plot histogram
    figure; h = gca; h_color = [.2 .6 .4];
    axes(h);
    ph=bar(tedges(1:end-1),r(1:end-1),'histc');
    if~isempty(onlat)
        h1 = vline(onlat);
        set(h1,'Color','k');
    end
    h2 = vline(peaklat);  set(h2,'Color','k');
    set(ph,'edgecolor',h_color,'facecolor',h_color);
    set(gca,'XLim',[pre post]);
    ylabel('spks/sec'); xlabel('t (ms) from stimulus onset');
    title(gca,sprintf('psth: %d n trials',length(spkTPs)));
    
end

%%
% Use CRFs to classify as well:

if length(unique(STIM.contrast)) > 1
    
    %reload spike time points since they were sub-selected above:
    % sort/pick trials [before iterating units]
    stimfeatures = {...
        'tilt'...
        'sf'...
        'contrast'...
        'fixedc'...
        'diameter'...
        'eye'...
        'varyeye'...
        'oridist'...
        'gabor'...
        'gabor_std'...
        'phase'...
        };
    clear(stimfeatures{:})
    
    obs = 0; clear spkTPs STIM
    for t = 1: length(pEvC)
        
        stimon  =  pEvC{t} == 23 | pEvC{t} == 25  | pEvC{t} == 27   | pEvC{t} == 29  | pEvC{t} == 31;
        stimoff =  pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32;
        
        st = pEvT{t}(stimon);
        en = pEvT{t}(stimoff);
        
        stim =  find(grating.trial == t); if any(diff(stim) ~= 1); error('check grating file'); end
        
        for p = 1:length(en)
            obs = obs + 1;
            
            if  any(obs == badobs) || ...
                    (flag_RewardedTrialsOnly && ~any(pEvC{t} == 96))
                
                spkTPs(obs,:) = [0 0];
                for f = 1:length(stimfeatures)
                    STIM.(stimfeatures{f})(obs,:) = NaN;
                end
            else
                
                spkTPs(obs,:) = [st(p) en(p)];
                for f = 1:length(stimfeatures)
                    STIM.(stimfeatures{f})(obs,:) = grating.(stimfeatures{f})(stim(p));
                end
            end
        end
    end % looked at all trials
    
    % get electrrode index
    elabel = el;
    eidx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x',elabel)),{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0)));
    if isempty(eidx)
        error('no %s',elabel)
    end
    eI =  NEV.Data.Spikes.Electrode == eidx;
    units = unique(NEV.Data.Spikes.Unit(eI));
    for u = 0:max(units)
        if u > 0
            elabel = sprintf('%s - unit%u',el,u);
            I = eI &  NEV.Data.Spikes.Unit == u;
        else
            elabel = sprintf('%s - all spikes',el);
            I = eI;
        end
        
        % get SPK and WAVE
        clear SPK WAVE RESP
        SPK = double(NEV.Data.Spikes.TimeStamp(I)); % in samples
        WAVE = double(NEV.Data.Spikes.Waveform(:,I));
        RESP = NaN(length(spkTPs),1);
        pre = -25; post = 200;
        
        unqc = unique(STIM.contrast);
        for c = 1:length(unqc)
            
            h_spkTPs = spkTPs(STIM.contrast == unqc(c) & STIM.fixedc == 0,:);
            
            for r = 1:length(h_spkTPs)
                st = h_spkTPs(r,1);
                en = h_spkTPs(r,2);
                if st ~= 0 && en ~= 0
                    RESP(r,:)   = sum(SPK > st & SPK < en);
                end
            end
            
            % psth:
            binsize = 5; % ms
            triallen = length([pre:post]);
            fs = 1000;
            ntrials = size(RESP,1);
            
            lastBin = binsize * ceil((triallen-1)*(1000/(fs*binsize)));
            edges = 0 : binsize : lastBin;
            tedges = edges +pre;
            x = (mod(SPK./1000-1,triallen)+1)*(1000/fs);
            r = (histc(x,edges)*1000) / (ntrials*binsize);
            
            
            
            
            
        end
        
        % psth:
        binsize = 5; % ms
        triallen = length([pre:post]);
        fs = 1000;
        ntrials = size(RESP,1);
        
        lastBin = binsize * ceil((triallen-1)*(1000/(fs*binsize)));
        edges = 0 : binsize : lastBin;
        tedges = edges +pre;
        x = (mod(SPK./1000-1,triallen)+1)*(1000/fs);
        r = (histc(x,edges)*1000) / (ntrials*binsize);
        peakr(c) = max(r(tedges>0)); %  max resp
    end
    
    figure, set(gcf,'Color',[1 1 1]);
    plot(unqc.*100,peakr,'o','Color',[.2 .4 .6],'MarkerFaceColor',[.2 .4 .6]);
    set(gca,'Box','off','FontSize',14); xlim([0 max(unqc).*100+1]);
    ylabel('peak response (spks/sec)'); xlabel('contrast in DE (%)'); 
    
end


%     %%
%     figure
%     subplot(2,3,1)
%     plot(RESP);
%     axis tight; box off;
%     xlabel('obs ct')
%     ylabel('# of spikes')
%     title(sprintf('%s\n EYE = %u',elabel,EYE))
%     
%     subplot(2,3,2)
%     hist(RESP);
%     box off;
%     xlabel('# of spikes')
%     ylabel('frequency')
%     title(BRdatafile,'interpreter','none')
% 
%     
%     subplot(2,3,3)
%     plot(mean(WAVE,2),'-'); hold on
%     plot(mean(WAVE,2)+ std(WAVE,[],2),':'); hold on
%     plot(mean(WAVE,2)- std(WAVE,[],2),':'); hold on
%     xlabel('waveform')
%     axis tight; box off
%     
%     clear resp feature x y f
%     header = grating.header{1};
%     switch header
%         case 'rfori'
%             resp = RESP(STIM.eye==EYE);
%             feature = STIM.tilt(STIM.eye==EYE);
%             [uR sR gname n] = grpstats(resp,feature, {'mean','sem','gname','numel'});
%             y = uR;
%             x = cellfun(@(x) str2num(x),gname);
%             y = [y; y];
%             x = [x ; x+180];
%             err = [sR; sR];
%             f = fit(x,y,'smoothingspline');
%             
%             % SPECIAL PLOT
%             subplot(2,3,6)
%             theta = deg2rad(feature);
%             roh = resp;
%             polar(theta, roh,'bx'); hold on
%             polar(theta+pi, roh,'bx'); hold on
%             [uRoh mRoh uTheta n] = grpstats(roh, theta, {'mean','median','gname','numel'});
%             uTheta = str2double(uTheta);
%             polar(uTheta, uRoh,'r.'); hold on
%             polar(uTheta+pi, uRoh,'r.'); hold on
%             polar(uTheta, mRoh,'go'); hold on
%             polar(uTheta+pi, mRoh,'go'); hold on
%             title(sprintf('n = [%u %u]',min(n), max(n)))
%             axis tight; axis square; box off;
%             
%         case 'rfsf'
%             resp = RESP(STIM.eye==EYE);
%             feature = STIM.sf(STIM.eye==EYE);
%             [uR sR gname n] = grpstats(resp,feature, {'mean','sem','gname','numel'});
%             y = uR;
%             x = cellfun(@(x) str2num(x),gname);
%             f = fit(x,y,'smoothingspline');
%             err = sR;
%             
%         case 'rfsize'
%             resp = RESP(STIM.eye==EYE);
%             feature = STIM.diameter(STIM.eye==EYE);
%             [uR sR gname n] = grpstats(resp,feature, {'mean','sem','gname','numel'});
%             y = uR;
%             x = cellfun(@(x) str2num(x),gname);
%             f = fit(x,y,'smoothingspline');
%             err = sR;
%             
%     end
%     
%     subplot(2,3,4)
%     boxplot(resp,feature)
%     p=anovan(resp,feature,'display','off');
%     title(sprintf('p = %0.3f,',p))
%     xlabel(header)
%     ylabel('# of spikes')
%     axis tight; box off;
%     
%     subplot(2,3,5)
%     plot(f,x,y); hold on
%     errorbar(x,y,err,'linestyle','none'); hold on
%     axis tight; axis square; box off; legend('off')
%     
%     switch header
%         case 'rfori'
%             plot([180 180],ylim,'k:');
%     end




