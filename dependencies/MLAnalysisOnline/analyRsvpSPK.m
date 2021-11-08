% TO DO:
% - add in mcos stimulus to analysis and graphs
% - add back in stats tests

clear
filelist = {'160423_E_rsvp001'};
el = 'eD';
el_array = [23];

StimTm  = 150; % total ms stimulus must be on to be counted in trigger 
SartTime = 50; % ms from stimulus on
Obs = getRsvpTPs(filelist,StimTm,'samples');
Fs = 30000; % NEV FS = 30,000

badobs = [1:200];

barcond = {'MC1a','BC1','BC2','dCOS1','dCOS2'};


for i = 1:length(filelist)
    BRdatafile = filelist{i};
    
    if ispc
        brdrname = sprintf('Z:\\%s',BRdatafile(1:8));
        mldrname = sprintf('Y:\\%s',BRdatafile(1:8));
    else
        brdrname = sprintf('/Volumes/Drobo/DATA/NEUROPHYS/rig022/%s',BRdatafile(1:8));
        mldrname = brdrname;
    end
    
    % load neural data:
filename = fullfile(brdrname,[BRdatafile '.nev']);
        NEV = openNEV(filename,'read','uV');
    
    % save NEV data across files
    if i == 1
        spk.ElectrodeLabel = {NEV.ElectrodesInfo.ElectrodeLabel};
        spk.Electrode = [];
        spk.Unit = [];
        spk.TimeStamp = [];
        spk.Electrode = [];
        spk.Waveform  = [];
        spk.FileNum   = [];
    end
    spk.Electrode = [spk.Electrode (NEV.Data.Spikes.Electrode)];
    spk.Unit      = [spk.Unit (NEV.Data.Spikes.Unit)];
    spk.TimeStamp = [spk.TimeStamp (NEV.Data.Spikes.TimeStamp)];
    spk.Waveform  = [spk.Waveform NEV.Data.Spikes.Waveform];
    spk.FileNum   = [spk.FileNum repmat(i,size(NEV.Data.Spikes.Electrode))];
    
end


for j = 1:length(el_array)
    e = el_array(j);
    
    % get electrrode index
    elabel = sprintf('%s%02u',el,e);
    eidx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x',elabel)),spk.ElectrodeLabel,'UniformOutput',0)));
    if isempty(eidx)
        fprintf('\nno %s\n',elabel)
        continue
    end
    eI =  spk.Electrode == eidx;
    units = unique(spk.Unit(eI));
    units(units>10) = [];
    for u = 0:max(units)
        if u > 0
            elabel = sprintf('%s%02u - unit%u',el,e,u);
            I = eI & spk.Unit == u;
        else
            elabel = sprintf('%s%02u - all spikes',el,e);
            I = eI;
        end
        unitID = sprintf('%s%02u-unit%u',el,e,u);
        
        % get SPK and WAVE
        clear SPK WAVE RESP SUA
        SPK  = double(spk.TimeStamp(I)); % in samples
        FIL  = spk.FileNum(I);
        WAVE = double(spk.Waveform(:,I));
        RESP = NaN(length(Obs.tp),1);
        SUA  = cell(length(Obs.tp),1);
                
        for r = 1:length(Obs.tp)
            st = Obs.tp(r) + SartTime/1000 * Fs;
            en = Obs.tp(r) + StimTm/1000 * Fs;
            fl = Obs.fl(r);
            tm = (en-st) / Fs; 
            bl =  Obs.tp(r) - 0.1*Fs;
            if st ~= 0 && en ~= 0
                if any(badobs == r)
                    RESP(r,:) = NaN;
                    SUA{r,:} = [];
                else
           191         RESP(r,:) = sum(SPK >= st & SPK <= en & FIL == fl) / tm; % units of spk / sec
                    SUA{r,:}  = SPK(SPK >= bl & SPK <= en & FIL == fl) - Obs.tp(r);
                end
            end
        end
        
              
        % group stats
        [uR, mR, sR, gstim, N] = grpstats(RESP,  Obs.sXa, {'mean','median','sem','gname','numel'});
        gstim = str2double(gstim);

        % plotting
        figure('position', [670   554   957   424])
        
        subplot(2,3,1)
        plot(RESP);
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
        labels = Obs.sXa_name(nanunique(Obs.sXa));
        boxplot(RESP,  Obs.sXa,'labels',labels,'labelorientation','inline'); hold on
        p=anovan(RESP,Obs.sXa,'display','off');
        title(sprintf('contrast = [%0.2f %0.2f], ori = [%u %u]\np = %0.3f,',Obs.contrast(1), Obs.contrast (2), Obs.grating(1), Obs.grating(2), p))
        ylabel('# of spikes')
        axis tight; box off; set(gca,'TickDir','out');
        plot([max(Obs.stim)+0.5 max(Obs.stim)+0.5], ylim,'k:')
        
        subplot(2,3,[3 6])
        idx = [];
        for b = 1:length(barcond)
            idx = [idx find(strcmp(Obs.stim_name,barcond{b}))];
        end
        bh = bar([uR(idx), uR(max(Obs.stim)+idx)],'linestyle','none'); hold on
        errorbar([1:length(idx)]-0.15,uR(idx              ),sR(idx              ),'linestyle','none','LineWidth',2,'color','k'); hold on
        errorbar([1:length(idx)]+0.15,uR(idx+max(Obs.stim)),sR(idx+max(Obs.stim)),'linestyle','none','LineWidth',2,'color','k'); hold on        
        text([1:length(idx)]-0.15, zeros(size(idx)), num2str(N(idx              )),'HorizontalAlignment','center','FontSize', 8,'FontName','Arial','VerticalAlignment','bottom','Color',[0 1 0],'FontWeight','Bold'); hold on
        text([1:length(idx)]+0.15, zeros(size(idx)), num2str(N(idx+max(Obs.stim))),'HorizontalAlignment','center','FontSize', 8,'FontName','Arial','VerticalAlignment','bottom','Color',[0 1 0],'FontWeight','Bold'); hold on
        
        axis tight
        set(gca,'XtickLabel',barcond,'TickDir','out');
        legend({'Uncued','Cued'},'Location','NorthOutside')
        ylabel('Mean # of spikes +/- S.E.M')
        box off;
        title(sprintf('Window = %u to %u ms realtive to Stim On',SartTime,StimTm))
        
        %bar ttests
        inc =  max(ylim)*.05;
        for b = 1:length(barcond)
            clear uncued cued
            uncued = find(strcmp(Obs.stim_name,barcond{b}));
            cued = find(strcmp(Obs.stim_name,barcond{b})) + max(Obs.stim);
            x = [.85 1.15] + b - 1;
            
            [h,p,~,stats] = ttest2(RESP(Obs.sXa==uncued),RESP(Obs.sXa==cued),0.5);
            if p < .05
                plot(x,-1.*[inc inc],'+','linestyle','-','Color',[.8 0 0]); hold on
            else
                plot(x,-1.*[inc inc],'+','linestyle','-','Color',[.2 .2 .2]); hold on
            end
            if p < 0.001
                text(mean(x),-inc,'p < 0.001','HorizontalAlignment','center','FontSize', 6,'FontName','Arial','VerticalAlignment','bottom'); hold on
            else
                text(mean(x),-inc,sprintf('p = %0.3f',p),'HorizontalAlignment','center','FontSize', 6,'FontName','Arial','VerticalAlignment','bottom'); hold on
            end
        end
        
        % 3 testes
%         stimXattn_name =  Obs.sXa_name;
%         for test = 1:4
%             clear x1 x2
%             switch test
%                 case 1
%                     x1 = r(sXa == find(strcmp(stimXattn_name,'U-dCOS1')));
%                     x2 = r(sXa == find(strcmp(stimXattn_name,'U-MC1')));
%                     x = [.85 1.15];
%                 case 2
%                     x1 = r(sXa == find(strcmp(stimXattn_name,'C-dCOS1')));
%                     x2 = r(sXa == find(strcmp(stimXattn_name,'C-MC1')));
%                     x = [.85 1.15]+1;
%                 case 3
%                     x1 = r(sXa == find(strcmp(stimXattn_name,'U-MC1')));
%                     x2 = r(sXa == find(strcmp(stimXattn_name,'C-MC1')));
%                     x = [1.15 2.15] ;
%                 case 4
%                     x1 = r(sXa == find(strcmp(stimXattn_name,'U-dCOS1')));
%                     x2 = r(sXa == find(strcmp(stimXattn_name,'C-dCOS1')));
%                     x = [.85 1.85];
%             end
%             [h,p,~,stats] = ttest2(x1,x2,0.5);
%             inc =  max(ylim)*.05;
%             if p < .05
%                 plot(x,[inc inc].*-test,'+','linestyle','-','Color',[.8 0 0]); hold on
%             else
%                 plot(x,[inc inc].*-test,'+','linestyle','-','Color',[.2 .2 .2]); hold on
%             end
%             if p < 0.001
%                 text(mean(x),-inc*test,'p < 0.001','HorizontalAlignment','center','FontSize', 6,'FontName','Arial','VerticalAlignment','bottom'); hold on
%             else
%                 text(mean(x),-inc*test,sprintf('p = %0.3f',p),'HorizontalAlignment','center','FontSize', 6,'FontName','Arial','VerticalAlignment','bottom'); hold on
%             end
%             
%         end
        
    end
end
%%
% if ~all(isnan(R))
%     figure('position', [670   42   957   424])
%     imagesc(R);
%     set(gca,'XTick',[1:10],'XTickLabel',stimXattn_name,'Box','off','TickDir','out')
%     c = colorbar; ylabel(c,'median spikes')
%     for x = 1:10
%         text(x,0,num2str(N(x)),'HorizontalAlignment','center'); hold on;
%     end
%     text(1,-1,'Number of presetations = '); hold on;
%     ylabel(sprintf('%s\nChannel #',BRdatafile))
%
%     figure('position', [670   42   957   424])
%     sR = bsxfun(@minus, R, min(R,[],2));
%     nR = bsxfun(@rdivide, sR, max(R,[],2)-min(R,[],2));
%     imagesc(nR);
%     set(gca,'XTick',[1:10],'XTickLabel',stimXattn_name,'Box','off','TickDir','out')
%     c = colorbar; ylabel(c,'norm. spikes')
%     for x = 1:10
%         text(x,0,num2str(N(x)),'HorizontalAlignment','center'); hold on;
%     end
%     text(1,-1,'Number of presetations = '); hold on;
%     ylabel('Channel #')
% end


