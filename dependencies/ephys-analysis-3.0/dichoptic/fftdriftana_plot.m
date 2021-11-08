clear; close all



filename = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/160905_E_drfori001.ppnev';



% mathcing kiolsort
sortdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';
[~,fname,~] = fileparts(filename);
klsfile = [sortdir '/' fname '/ss.mat'];
if exist(klsfile,'file')
    load(klsfile)
else
    sksksks
end


load(filename,'ppNEV','-MAT')
filename = ppNEV.filename;
NEV = ppNEV; clear ppNEV;



% 
% TuneList = importTuneList();
% ~cellfun(@isempty,TuneList.drfori)

%%
EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
EventSampels = double(NEV.Data.SerialDigitalIO.TimeStamp);
[pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);
ElectrodeLabel = cellfun(@(x) x(1:4)',{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0);

Fs = double(NEV.MetaTags.SampleRes);

ext = '.gRFORIDRFTGrating_di';
mainparam = 'motion'; % defined later, DIFFRENT from stactic tuning plots
grating = readgDRFTGrating([filename ext]);

%%

stimfeatures = {...
    'trial'...
    'tilt'...
    'sf'...
    'contrast'...
    'eye'...
    'temporal_freq'...
    'motion'...
    'pres'}; 




obs = 0; clear STIM
for t = 1: length(pEvC)
    % examin presentations ONLY if there is a off event marker (not a break fixation)
    stim =  find(grating.trial == t); if any(diff(stim) ~= 1); error('check stim file'); end
    nstim = sum(pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32); if nstim == 0; continue; end
    for p = 1:nstim %\
        obs = obs + 1;
        STIM.('trl')(obs,:) = t;
        STIM.('prez')(obs,:) = p;
        STIM.('reward')(obs,:) = any(pEvC{t} == 96);
        STIM.('filen')(obs,:) = j;
        stimon  =  pEvC{t} == 21 + p*2;
        stimoff =  pEvC{t} == 22 + p*2;
        st = double(pEvT{t}(stimon));
        en = double(pEvT{t}(stimoff));
        STIM.tp_sp(obs,:) = [st(end) en];
        STIM.tp_ms(obs,:) = round([st(end) en] ./ Fs * 1000);
        % write STIM features
        for f = 1:length(stimfeatures)
            STIM.(stimfeatures{f})(obs,:) = grating.(stimfeatures{f})(stim(p));
        end
    end
end

%%
clear PSTH* bin_sp clusterstr
bin_sp = 10/1000 * Fs;

for e = 1:size(ss.clusterMap,1)
    elabel = ss.chanIDs{ss.clusterMap(e,2)};
    
    for w = 1:2
        clear I SPK
    
        if w == 1
            I = ss.spikeClusters == ss.clusterMap(e,1);
            clusterstr{e,:} = sprintf('Clust #%u on %s',ss.clusterMap(e,1), ss.chanIDs{ss.clusterMap(e,2)});
            SPK = ss.spikeTimes(I);
        else
            I   =  NEV.Data.Spikes.Electrode == find(strcmp(ElectrodeLabel,elabel));
            SPK = unique(double(NEV.Data.Spikes.TimeStamp(I)));
        end
        
        for t = 1:length(STIM.tp_sp)
            % trigger points
            tp      = STIM.tp_sp(t,1);
            st        = tp + (200/1000*Fs);
            en        = tp + (1000/1000*Fs);
            
            edges  = st: bin_sp : en-1;
            
            spk = SPK(SPK >= st & SPK < en);
            
            if ~isempty(spk)
                
                suatm = st:en;
                sua = zeros(length(suatm),1);
                [~,IA,~] = intersect(suatm,spk,'stable') ;
                sua(IA) = 1;
                        
                PSTHA(e,w,:,t) = sua;
                PSTHB(e,w,:,t) = histc(spk,edges) .* (Fs/bin_sp); %  bin/s  = (Fs/bin_sp) ?????
            end
            
        end
    end
end

PSTHB(:,:,end,:) = []; 
bintm = (edges(1:end-1) -st) / Fs; 
bintm = bintm + (200/1000);

%%

uTF = unique(STIM.temporal_freq);
for e = 1:size(PSTHB,1)
    
    
    for tf = 1:length(uTF)
        figure('Position',[0 0 601 874]);
        
        for w = 1:2
            
            raw   = squeeze(PSTHA(e,w,:,STIM.temporal_freq == uTF(tf)));
            psth  = squeeze(PSTHB(e,w,:,STIM.temporal_freq == uTF(tf))) ;
            dpsth = bsxfun(@minus, psth, mean(psth,1));
            
            [~,sorted]=sort(sum(abs(psth),1),2,'descend');
            psth  = psth(:,sorted);
            dpsth = dpsth(:,sorted); 
            raw   = raw(:,sorted);
            
            subplot(5,2,w)
            [tm,trl] = find(raw);
            tm = tm ./ Fs + 200/1000;
            plot(tm,trl,'k.')
            box off
            set(gca,'TickDir','out','Ytick',[],'ydir','reverse'); axis tight
            if w == 1
                title(sprintf('%s--%s\n TF = %uHz',fname,clusterstr{e},uTF(tf)),'interpreter','none')
                ylabel('KLS')
            else
                ylabel('NEV')
            end
                        
            subplot(5,2,w+2)
            imagesc(bintm,1:size(psth,2),psth')
            box off
            set(gca,'TickDir','out','Ytick',[]);
            c=colorbar('northoutside');
            if w == 1
                xlabel(c,'KLS')
                ylabel(sprintf('Bin = %0.0fms',diff(bintm(1:2))*1000))
            else
                xlabel(c,'NEV')
            end
            
            
            [ratio,freq, power] = ratio_ftf_f0(psth,Fs / bin_sp,uTF(tf));
            subplot(5,2,w+4)
            
            colors = parula(size(psth,2));
            set(gca,'ColorOrder',colors); hold on
            plot(freq(freq<20),power(freq<20,:),'-o'); 
            axis tight; box off
            set(gca,'TickDir','out');
            plot(uTF([tf tf]),ylim,'k')
            title(sprintf('f_T_F / f_0 = %g',ratio))
            if w ==1
               ylabel(sprintf('Power of \nRaw PSTH'))
            end
            
            
            
            subplot(5,2,w+6)
            imagesc(bintm,1:size(dpsth,2),dpsth')
            box off
            set(gca,'TickDir','out','Ytick',[]);
            c=colorbar('northoutside');
            if w == 1
                xlabel(c,sprintf('KLS (\\Delta PSTH)'))
                ylabel(sprintf('Bin = %0.0fms',diff(bintm(1:2))*1000))
            else
                xlabel(c,sprintf('NEV (\\Delta PSTH)'))
            end
            
            
            [ratio,freq, power] = ratio_ftf_fnot(dpsth,Fs / bin_sp,uTF(tf));
            subplot(5,2,w+8)
            
            colors = parula(size(dpsth,2));
            set(gca,'ColorOrder',colors); hold on
            plot(freq(freq<20),power(freq<20,:),'-o'); 
            axis tight; box off
            set(gca,'TickDir','out');
            plot(uTF([tf tf]),ylim,'k')
            title(sprintf('f_T_F / f_n_o_t = %g',ratio))
            if w ==1
                ylabel(sprintf('Power of\n\\Delta PSTH'))
                xlabel('Freq. (Hz)')
            end
            
            
        end
        
    end
    
end
%%
