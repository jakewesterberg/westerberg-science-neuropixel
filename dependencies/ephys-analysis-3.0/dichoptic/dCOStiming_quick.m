

clear 

figsavepath = '/Volumes/Drobo2/USERS/Michele/Dichoptic/quick timing plots/';
autodir = '/Volumes/Drobo2/DATA/NEUROPHYS/AutoSort-ed/';


paradigm = {'mcosinteroc','brfs'};

TuneList = importTuneList(1); xct = 0; 
for s = 1:length(TuneList.Datestr)
    
    clearvars -except s TuneList figsavepath autodir paradigm xct xDI xBI xXX
    s
    
    clear header el
    header = TuneList.Penetration{s}(1:end-3);
    el     = TuneList.Penetration{s}(end-1:end);
    
    clear drobo
    switch TuneList.Drobo(s)
        case 1
            drobo = 'Drobo';
        otherwise
            drobo = sprintf('Drobo%u',TuneList.Drobo(s));
    end
    ct = 0; filelist = {};
    for p = 1:length(paradigm)
        clear exp
        exp = TuneList.(paradigm{p}){s};
        for d = 1:length(exp)
            ct = ct + 1;
            filelist{ct,1} = sprintf('/Volumes/%s/Data/NEUROPHYS/rig%03u/%s_%s/%s_%s_%s%03u',...
                drobo,TuneList.Rig(s),TuneList.Datestr{s},TuneList.Monkey{s},TuneList.Datestr{s},TuneList.Monkey{s},paradigm{p},exp(d));
        end
    end
    if isempty(filelist)
        continue
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    
    % stimulus info
    STIM        = getDiTPs(filelist);
    uTilt       = nanunique([STIM.s1_tilt STIM.s2_tilt]);
    uContrast   = nanunique([STIM.s1_contrast; STIM.s2_contrast]);
    
    % determin main contrasts levels for TC analysis
    contrast_max = max(uContrast);
    [~,idx] = min(abs(uContrast - contrast_max/2));
    contrast_half   = uContrast(idx);
    contrast_full = contrast_max;
    %%
    
    % monocular
    M = find(...
        strcmp(STIM.stim,'Monocular') & STIM.soa==0 & STIM.s2_contrast == contrast_half);
    
    x = [STIM.s2_eye(M) STIM.s2_tilt(M)];
    ct = 0; clear y
    for eye = 2:3
        for tilt = 1:2
            ct = ct +1;
            y(ct) = any(x(:,1) == eye & x(:,2) == uTilt(tilt));
        end
    end
    
    if ~all(y)
        continue
    end
    
    
    
    fln = 1; clear RESP
    for t = 1:length(M)
        trl = M(t);
        
        if (t == 1) || fln ~= STIM.filen(trl)
            clear ppNEV
            [fpath,fname] = fileparts(STIM.filelist{fln});
            load([autodir fname '.ppnev'],'ppNEV','-mat')
            Fs = double(ppNEV.MetaTags.TimeRes);
            k = jnm_kernel( 'psp', (20/1000) * Fs );
            nevel =unique(ppNEV.Data.Spikes.Electrode);
        end
        
        
        st        = STIM.tp_sp(trl,1) + (50/1000*Fs);
        en        = STIM.tp_sp(trl,2);
        stim_sec  = (en - st) / Fs; % seconds
        
        
        for e =1:length(nevel)
            I   =  ppNEV.Data.Spikes.Electrode == nevel(e);
            if ~any(I)
                continue
            end
            SPK = unique(double(ppNEV.Data.Spikes.TimeStamp(I)));
            
            RESP(e,t) = sum(SPK > st & SPK < en) / stim_sec;
            
        end
    end
    %%
    
    for e = 1:size(RESP,1)
        p = anovan(RESP(e,:),{STIM.s2_eye(M),STIM.s2_tilt(M)},'display','off');
        
        if all(p<0.05)
            
            clear prefeye prefori mI dI
            
            [u, g]=grpstats(RESP(e,:) ,{STIM.s2_eye(M),STIM.s2_tilt(M)},{'mean','gname'});
            [~,mI] = max(u);
            prefeye = str2num(g{mI,1});
            prefori = str2num(g{mI,2});
            
            mI = strcmp(STIM.stim,'Monocular') & STIM.soa==0 & STIM.s2_contrast == contrast_half & ...
                STIM.s2_tilt == prefori & STIM.s2_eye == prefeye;
            
            dI = STIM.soa == 0 & (...
                (STIM.s2_tilt == uTilt(uTilt~=prefori) & STIM.s2_contrast == contrast_full & ...
                STIM.s1_tilt == prefori & STIM.s1_eye == prefeye & STIM.s1_contrast == contrast_half) |...
                (STIM.s1_tilt == uTilt(uTilt~=prefori) & STIM.s1_contrast == contrast_full & ...
                STIM.s2_tilt == prefori & STIM.s2_eye == prefeye & STIM.s2_contrast == contrast_half) );
            
            bI = STIM.soa == 0 & (...
                (STIM.s2_tilt == prefori & STIM.s2_contrast == contrast_full & ...
                STIM.s1_tilt == prefori & STIM.s1_eye == prefeye & STIM.s1_contrast == contrast_half) |...
                (STIM.s1_tilt == prefori & STIM.s1_contrast == contrast_full & ...
                STIM.s2_tilt == prefori & STIM.s2_eye == prefeye & STIM.s2_contrast == contrast_half) );
            
            
            if ~(any(mI) && any(dI) && any(bI))
                continue
            end
            
           % figure
           clear X
            colors = ([0 0 0; 1 0 0; 0 0 1]);
            for cond = 3:-1:1
                clear OBS SUA SDF
                if cond == 1
                    OBS = find(mI);
                elseif cond == 2
                    OBS = find(dI);
                elseif cond == 3
                    OBS = find(bI);
                end
                
               
                
                for t = 1:length(OBS)
                    trl = OBS(t);
                    
                    if (t == 1) || fln ~= STIM.filen(trl)
                        clear ppNEV
                        [fpath,fname] = fileparts(STIM.filelist{fln});
                        load([autodir fname '.ppnev'],'ppNEV','-mat')
                        Fs = double(ppNEV.MetaTags.TimeRes);
                        k = jnm_kernel( 'psp', (20/1000) * Fs );
                        nevel =unique(ppNEV.Data.Spikes.Electrode);
                    end
                    
                    % trigger points
                    tp      = STIM.tp_sp(trl,1);
                    st        = tp - (200/1000*Fs);
                    en        = tp + (700/1000*Fs);
                    
                    % setup SUA matrix
                    clear sua sdf tm
                    sua = zeros(length(st:en),1);
                    tm  = st:en;
                    
                    I   =  ppNEV.Data.Spikes.Electrode == nevel(e);
                    if ~any(I)
                        continue
                    end
                    SPK = unique(double(ppNEV.Data.Spikes.TimeStamp(I)));
                    
                    spk = SPK(SPK > st & SPK < en);
                    if ~isempty(spk)
                        [~,IA,~] = intersect(tm,spk,'stable') ;
                        sua(IA) = 1;
                        SDF(:,t) = conv(sua,k,'same') * Fs;
                    end
                    
                    
                end
                
                X(:,cond) = mean(SDF,2); 
                %plot((tm-tp)/Fs,mean(SDF,2),'Color',colors(cond,:)); hold on
            end
           
            xct = xct + 1; 
            xDI(xct,:) = X(:,1) - X(:,2);
            xBI(xct,:) = X(:,1) - X(:,3); 
            xXX(xct,:) = X(:,3) - X(:,2); 
            
%             title(sprintf('%s\n%s',STIM.header,ppNEV.ElectrodesInfo(nevel(e)).ElectrodeLabel(1:4)'),'interpreter','none')
%             legend({'Binocular','dCOS','Monocular'},'Location','Best')
%             box off
%             set(gca,'tickdir','out');
%             xlabel('Time (s)')
%             ylabel('Mean Response (imp./s)')
%             axis tight
%             plot([0,0],ylim,':k')
%             plot([.5,.5],ylim,':k')
            
%             figfilename = sprintf('%s/%s_%s.png',figsavepath,STIM.header,ppNEV.ElectrodesInfo(nevel(e)).ElectrodeLabel(1:4)');            
%             saveas(gcf,figfilename)
%             close all
        end
    end
end


%%
figure

dat = xXX;
titlestr = 'Binocular - dCOS';

Fs=30000;
tm=(-.2:1/Fs:.7);
plot(tm,dat); hold on
plot(tm,mean(dat,1),'k','LineWidth',2)
plot(xlim,[0 0],'k')
xlabel('Time (s)')
ylabel('dMUA Difference (imp./s)')
box off
set(gca,'TickDir','out');
title(titlestr)


