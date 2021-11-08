
clear
BRdatafile = '160102_E_rsvp001';


if ispc
    brdrname = sprintf('Z:\\%s',BRdatafile(1:8));
    mldrname = sprintf('Y:\\%s',BRda1afile(1:8));
else
    brdrname = sprintf('/Volumes/Drobo/DATA/NEUROPHYS/rig022/%s',BRdatafile(1:8));
    mldrname = brdrname;
end

Obs = getRsvpTPs(BRdatafile,'samples');
badobs = getBadObs(BRdatafile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% load neural data:
filename = fullfile(brdrname,BRdatafile);
NEV = openNEV(strcat(filename,'.nev'),'read','overwrite','uV');


for e = 1:32
    
    % get electrrode index
    elabel = sprintf('eD%02u',e);
    eidx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x',elabel)),{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0)));
    if isempty(eidx)
        continue
        %error('no %s',elabel)
    end
    eI =  NEV.Data.Spikes.Electrode == eidx;
    units = unique(NEV.Data.Spikes.Unit(eI));
    for u = 0:max(units)
        if u > 0
            elabel = sprintf('eD%02u - unit%u',e,u);
            I = eI &  NEV.Data.Spikes.Unit == u;
        else
            elabel = sprintf('eD%02u - all spikes',e);
            I = eI;
        end
        
        % get SPK and WAVE
        clear SPK Fs
        SPK = double(NEV.Data.Spikes.TimeStamp(I)); % in samples
        WAVE = double(NEV.Data.Spikes.Waveform(:,I));
        Fs = double(NEV.MetaTags.SampleRes);
        
        ct = 0; clear r sXa
        for p = 1:length(Obs.tp)
            if Obs.saccade(p)
                continue
            end
            ct = ct +1;
            st = Obs.tp(p);
            en = st + 450/1000 * Fs;
            sXa(ct) = Obs.sXa(p);
            if any(ct == badobs)
                r(ct) = NaN;
            else
                r(ct) = sum(SPK > st & SPK < en);
            end
        end
        
        
        
        % group stats
        [uR, mR, sR, gstim, N] = grpstats(r,  sXa, {'mean','median','sem','gname','numel'});
        gstim = str2double(gstim);
%         if u == 0
%             R(e,gstim) = mR;
%         end
        
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
        labels = Obs.sXa_name(unique(sXa));
        boxplot(r,sXa,'labels',labels,'labelorientation','inline'); hold on
        p=anovan(r,sXa','display','off');
        title(sprintf('contrast = [%0.2f %0.2f], ori = [%u %u]\np = %0.3f,',Obs.contrast(1), Obs.contrast (2), Obs.grating(1), Obs.grating(2), p))
        %title(p);
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
        stimXattn_name =  Obs.sXa_name;
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


