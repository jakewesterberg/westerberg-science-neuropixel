clear

BRdatafile = '151204_E_rsvp004';
brdrname = sprintf('Z:\\%s',BRdatafile(1:8));
badobs = getBadObs(BRdatafile);
mldrname = sprintf('Y:\\%s',BRdatafile(1:8));
%mldrname = 'Y:\Early RSVP Data';

% behavoral data and stimulus info
[cue, cuedD, cuedS, uncuedD, uncuedS, npres] = loadRSVPdata(mldrname,BRdatafile);
contrast = [cuedD.contrast(1) cuedS.contrast(1)];
grating =  unique(uncuedD.tilt)';
BHV = concatBHV([mldrname filesep BRdatafile '.bhv']);

% parameters that are set on the ML side, manually put here for use
rsvp_loc = [0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4];
cue_loc  = [1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1 0 0]; %1 = RF
stim_name = {...
    'dCOS',...
    'MC1',...
    'MC2',...
    'BC1',...
    'BC2'};
stimXattn_name = {...
    'U-dCOS',...
    'U-MC1',...
    'U-MC2',...
    'U-BC1',...
    'U-BC2',...
    'C-dCOS',...
    'C-MC1',...
    'C-MC2',...
    'C-BC1',...
    'C-BC2'};
rsvp_ln = npres;
R = nan(24, 10);

badtrls = [setdiff(uncuedD.trial,uncuedS.trial); setdiff(uncuedS.trial,uncuedD.trial)];
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

for e = 1:24
    
    % get electrrode index
    elabel = sprintf('eD%02u',e);
    eidx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x',elabel)),{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0)));
    if isempty(eidx)
        error('no %s',elabel)
    end
    eI =  NEV.Data.Spikes.Electrode == eidx;
    units = unique(NEV.Data.Spikes.Unit);
    for u = 0:max(units)
        I = eI &  NEV.Data.Spikes.Unit == u;
        if ~u
            elabel = sprintf('eD%02u - unit%u',e,u);
        end
        
        % get SPK and WAVE
        clear SPK Fs
        SPK = double(NEV.Data.Spikes.TimeStamp(I)); % in samples
        WAVE = double(NEV.Data.Spikes.Waveform(:,I));
        Fs = double(NEV.MetaTags.SampleRes);
        %SPK = SPK ./ Fs .* 1000;
        
        %%
        
        
        ct = 0; clear attn stim r sXa
        maxtr = length(pEvC);
        for tr = 1:maxtr
            if BHV.trialerror(tr) > 0 || any(tr == badtrls)
                % skip if not correct trial, or the record is bad
                continue
            end
            
            target = rsvp_loc(BHV.conditionnumber(tr));
            rfcued =  logical(cue_loc(BHV.conditionnumber(tr)));
            if rfcued
                stimuli = double(cuedD.stimcond(cuedD.trial == tr));
            else
                stimuli = double(uncuedD.stimcond(uncuedD.trial == tr));
            end
            if isempty(stimuli)
                continue
            end
           
            
            p = 0;
            while p < rsvp_ln
                p = p + 1;
                
                if p == target || stimuli(p) == 99
                    % want to exclude presnetations with a saccade, and all
                    % subsequent presnetations
                    p = rsvp_ln;
                    continue
                end
                
                ct = ct +1;
                
                st = pEvT{tr}( pEvC{tr}== (27 + (p-1)*2) );
                en = st + (450/1000) * Fs; %stim pres is 500, but don't want to catch stim off by accident
                
                attn(ct) = rfcued;
                stim(ct) = stimuli(p);
                
                if any(ct == badobs)
                    r(ct) = NaN;
                else
                    r(ct) = sum(SPK > st & SPK < en);
                end
                
            end
            
        end
        if ct == 0 || sum(r~=0) < 5 || max(r) < 5
            continue
        end
        sXa = (attn*5)+stim;
        missingcond = setdiff([1:10],unique(sXa));
        sXa = [sXa missingcond];
        r = [r nan(size(missingcond))];
        
        % group stats
        [uR mR sR gstim N] = grpstats(r,  sXa, {'mean','median','sem','gname','numel'});
        gstim = str2double(gstim);
        if u == 0
            R(e,gstim) = mR;
        end
        
        % plotting
        figure('position', [670   554   957   424])
        
        subplot(2,3,1)
        plot(r);
        axis tight; box off;
        xlabel('stim prez (ct)')
        ylabel('# of spikes')
        title(sprintf('%s: %s',BRdatafile, elabel),'interpreter','none')
        set(gca,'TickDir','out','box','off');
        
        subplot(2,3,4)
        plot(mean(WAVE,2),'-'); hold on
        plot(mean(WAVE,2)+ std(WAVE,[],2),':'); hold on
        plot(mean(WAVE,2)- std(WAVE,[],2),':'); hold on
        xlabel('waveform')
        axis tight; box off; set(gca,'TickDir','out');
        
        subplot(2,3,[2 5])
        labels = stimXattn_name(unique(sXa));
        boxplot(r,sXa,'labels',labels,'labelorientation','inline'); hold on
        p=anovan(r,sXa','display','off');
        title(sprintf('contrast = [%0.2f %0.2f], ori = [%u %u]\np = %0.3f,',contrast(1), contrast (2), grating(1), grating(2), p))
        ylabel('# of spikes')
        axis tight; box off; set(gca,'TickDir','out');
        plot([5.5 5.5], ylim,'k:')
        
        subplot(2,3,[3 6])
        bh = bar( [uR([1 6]), uR([2 7])],'linestyle','none'); hold on
        errorbar([.85 1.15 1.85 2.15],uR([1 2 6 7]),sR([1 2 6 7]),'linestyle','none','LineWidth',2,'color','k')
        text([.85 1.15 1.85 2.15],[0 0 0 0], num2str(N([1 2 6 7])),'HorizontalAlignment','center','FontSize', 8,'FontName','Arial','VerticalAlignment','bottom','Color',[1 1 1],'FontWeight','Bold'); hold on
        
        set(gca,'XtickLabel',{'Uncued','Cued'},'TickDir','out');
        legend({'dCOS','MC1'},'Location','SouthOutside')
        ylabel('Mean # of spikes +/- S.E.M')
        box off;
        
        % 3 testes
        for test = 1:4
            clear x1 x2
            switch test
                case 1
                    x1 = r(sXa == find(strcmp(stimXattn_name,'U-dCOS')));
                    x2 = r(sXa == find(strcmp(stimXattn_name,'U-MC1')));
                    x = [.85 1.15];
                case 2
                    x1 = r(sXa == find(strcmp(stimXattn_name,'C-dCOS')));
                    x2 = r(sXa == find(strcmp(stimXattn_name,'C-MC1')));
                    x = [.85 1.15]+1;
                case 3
                    x1 = r(sXa == find(strcmp(stimXattn_name,'U-MC1')));
                    x2 = r(sXa == find(strcmp(stimXattn_name,'C-MC1')));
                    x = [1.15 2.15] ;
                case 4
                    x1 = r(sXa == find(strcmp(stimXattn_name,'U-dCOS')));
                    x2 = r(sXa == find(strcmp(stimXattn_name,'C-dCOS')));
                    x = [.85 1.85];
            end
            [h,p,~,stats] = ttest2(x1,x2,0.5);
            inc =  max(ylim)*.05;
            if p < .05
                plot(x,[inc inc].*-test,'+','linestyle','-','Color',[.8 0 0]); hold on
            else
                plot(x,[inc inc].*-test,'+','linestyle','-','Color',[.2 .2 .2]); hold on
            end
            if p < 0.001
                text(mean(x),-inc*test,'p < 0.001','HorizontalAlignment','center','FontSize', 6,'FontName','Arial','VerticalAlignment','bottom'); hold on
            else
                text(mean(x),-inc*test,sprintf('p = %0.3f',p),'HorizontalAlignment','center','FontSize', 6,'FontName','Arial','VerticalAlignment','bottom'); hold on
            end
            
        end
        
    end
end
%%
if ~all(isnan(R))
    figure('position', [670   42   957   424])
    imagesc(R);
    set(gca,'XTick',[1:10],'XTickLabel',stimXattn_name,'Box','off','TickDir','out')
    c = colorbar; ylabel(c,'median spikes')
    for x = 1:10
        text(x,0,num2str(N(x)),'HorizontalAlignment','center'); hold on;
    end
    text(1,-1,'Number of presetations = '); hold on;
    ylabel(sprintf('%s\nChannel #',BRdatafile))
    
    figure('position', [670   42   957   424])
    sR = bsxfun(@minus, R, min(R,[],2));
    nR = bsxfun(@rdivide, sR, max(R,[],2)-min(R,[],2));
    imagesc(nR);
    set(gca,'XTick',[1:10],'XTickLabel',stimXattn_name,'Box','off','TickDir','out')
    c = colorbar; ylabel(c,'norm. spikes')
    for x = 1:10
        text(x,0,num2str(N(x)),'HorizontalAlignment','center'); hold on;
    end
    text(1,-1,'Number of presetations = '); hold on;
    ylabel('Channel #')
end


