clear

didir   = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Nov22/';
list    = dir([didir '*_KLS.mat']);
sdfwin  = [-0.05 0.5]; %s
Fs      = 1000;

assumedwin   = [50 100; 150 250; 50 250];
signaltype = {'kls1','kls2'};

uct = 0; XYZ = []; clear SDF INFO 
skip = 0; 
for i = 1:length(list)
    i
    uct
    % load session data
    clear penetration
    penetration = list(i).name(1:11);
    
    clear STIM nel
    load([didir penetration '.mat'],'STIM')
    nel = length(STIM.el_labels);
    
    for slt = 1:length(signaltype)
        
        clear matobj win_ms clusterstr ksl
        switch signaltype{slt}
            case 'kls1'
                kls = 1;
                clusterstr = 'clusters';
                wavestr = 'waves';
                matobj = matfile([didir penetration '_KLS.mat']);
            case 'kls2'
                if isempty(STIM.('rclusters'))
                    continue
                end
                kls = 1;
                clusterstr = 'rclusters';
                wavestr = 'rwaves';
                matobj = matfile([didir penetration '_KLS.mat']);
            case 'nev'
                kls = 0;
                matobj = matfile([didir penetration '_AUTO.mat']);
            case 'csd'
                kls = 0;
                matobj = matfile([didir penetration '_CSD.mat']);
        end
        
        win_ms = matobj.win_ms;
        if ~isequal(win_ms,assumedwin)
            error('check window assumptions')
        end
        
        for e = 1:nel
            
            % get "goodfiles" for each cluster
            % i.e., the files over which the cluster is present
            % pref for ditasks if there are more than 1 set of clusters at depth
            clear goodfiles allfiles unitid wave
            allfiles = 1:length(STIM.filelist);
            if ~kls
                goodfiles = allfiles;
                unitID = nan;
                wave = nan(61,1);
            else
                goodfiles = find(~isnan(STIM.(clusterstr)(e,:)));
                if isempty(goodfiles)
                    continue
                elseif ~isequal(goodfiles,allfiles)...
                        && length(goodfiles)>1 ...
                        && any(diff(goodfiles) > 1)
                    goodfiles = unique(STIM.filen(ismember(STIM.filen, goodfiles) & STIM.ditask));
                end
                cnum   = STIM.(clusterstr)(e,goodfiles);
                cfile  = STIM.filelist(goodfiles);
                unitID = cell(length(cnum),1);
                for cu = 1:length(cnum);
                    [~,q] = fileparts(cfile{cu});
                    unitID{cu} = sprintf('%s_c%03u',q,cnum(cu));
                end
                wave = squeeze(nanmean(STIM.(wavestr)(e,goodfiles,:),2));
            end
            if any(diff(goodfiles) > 1)
                %error('check goodfiles')
                continue %DEV: need to figure out a way to slavage
            end
            
            % check for correct conditions
            I =  STIM.ditask...
                & STIM.adapted == 0 ...
                & STIM.rns == 0 ...
                & STIM.cued == 0 ...
                & STIM.motion == 0 ...
                & ismember(STIM.filen,goodfiles);
            if ~any(I); continue; end
            diori  = unique(STIM.tilt(I & STIM.monocular,1));
            dicont = unique(STIM.contrast(I & STIM.monocular,1));
            % Make binocular analysis easier by sortting data
            % by sortting data so that they are [2 3]
            clear eyes sortidx contrasts tilts
            eyes      = STIM.eyes;
            contrasts = STIM.contrast;
            tilts     = STIM.tilt;
            [eyes,sortidx] = sort(eyes,2,'ascend');
            for ww = 1:length(eyes)
                contrasts(ww,:) = contrasts(ww,sortidx(ww,:));
                tilts(ww,:)     = tilts(ww,sortidx(ww,:));
            end; clear ww
            
            % iterate through all stimulus combinations and check for
            % monocualr and binocular varients
            keyct = 0; KEY = zeros(2*(length(dicont)^2),4); TRLS = cell(2*(length(dicont)^2),3);
            for o = 1:length(diori) % orientations in di task
                for c2 = 1:length(dicont) % contrast in eye2
                    for c3 = 1:length(dicont) % contrast in eye3
                        keyct = keyct +1;
                        KEY(keyct,1:3) = [diori(o) dicont(c2) dicont(c3)];
                        % check for both monocular conditions
                        TRLS{keyct,1} = find(I ...
                            & STIM.monocular ...
                            & STIM.tilt(:,1) == diori(o) ...
                            & STIM.eyes(:,1) == 2 ...
                            & STIM.contrast(:,1) == dicont(c2));
                        TRLS{keyct,2} = find(I ...
                            & STIM.monocular ...
                            & STIM.tilt(:,1) == diori(o) ...
                            & STIM.eyes(:,1) == 3 ... !
                            & STIM.contrast(:,1) == dicont(c3)); %!
                        % check for bonocualr conditon
                        TRLS{keyct,3} = find(I & ...
                            all(tilts == diori(o),2) ...
                            & contrasts(:,1) == dicont(c2) ...
                            & contrasts(:,2) == dicont(c3));
                        n = cellfun(@length,TRLS(keyct,:));
                        if all(n > 5)
                            KEY(keyct,4) = 1;
                        else
                            KEY(keyct,4) = 0;
                        end
                    end
                end
            end
            if sum(KEY(:,4)) < 3
                continue
            end
            TRLS = TRLS(KEY(:,4)==1,:);
            KEY  = KEY(KEY(:,4)==1,:);
            
            % check for significant changes from baseline
            % on the trls isolated above
            clear trls I
            trls = unique([cell2mat(TRLS(:,1)); cell2mat(TRLS(:,2)); cell2mat(TRLS(:,3))]);
            I = ismember(trls(1):trls(end),trls);
            clear resp q75
            resp = squeeze(matobj.RESP(e,1,trls(1):trls(end))); % 1 = early,  50-100 ms
            if all(isnan(resp))
                continue
            end
            resp = resp(I);
            q75 = quantile(resp,.75);
            if mean(resp(resp >= q75)) < 5
                continue
            end
            clear sdf
            sdf   = squeeze(matobj.SDF(e,:,trls(1):trls(end)));
            sdf   = sdf(:,I);
            sdf = sdf(:,resp >= q75);
            sdftm = matobj.sdftm;
            h = ttest(...
                nanmean(sdf(sdftm >=  0.05 & sdftm <= 0.10,:)), ...
                nanmean(sdf(sdftm >= -0.05 & sdftm <= 0   ,:)),...
                'Tail','right'); 
            if isnan(h) || h == 0
                continue
            end
            clear bl
            bl = nanmean(nanmean(sdf(sdftm >= -0.05 & sdftm <= 0   ,:))); 
            clear sdf; 
            
             % setup SDF padding for later
            clear tm pad st en
            tm = sdftm;
            if tm(end) < sdfwin(2)
                pad = [tm(end):diff(tm(1:2)):sdfwin(2)];
                pad(1) = [];
                en = length(tm);
                st = find(tm> sdfwin(1),1);
                tm = [tm pad];
                tm = tm(st : end);
                pad(:) = NaN;
            else
                pad = [];
                en = find(tm > sdfwin(2),1)-1;
                st = find(tm > sdfwin(1),1);
                tm = tm(st : en);
            end
            
            % also check for a main effect of contrast in the monocular conditions
            clear I resp p
            I    = unique([cell2mat(TRLS(:,1)); cell2mat(TRLS(:,2))]);
            resp = squeeze(matobj.RESP(e,3,:)); % 3 = full,  50-250 ms (see also below)
            p = anovan(resp(I),{STIM.eye(I,1),STIM.tilt(I,1),STIM.contrast(I,1)},...
                'display','off',...
                'model',[0 0 1; 1 0 1; 0 1 1]);
            if all(p >= 0.05)
                continue
            end
            
            % extract relavant info about
            % ori and contrast levles
            clear biori *maxc *minc 
            biori = nanunique(KEY(:,1));
            [dmaxc,maxc]=min(abs(KEY(:,2) - 1.00));
            [dminc,minc]=min(abs(KEY(:,2) - 0.25));
            maxc = KEY(maxc,2);
            minc = KEY(minc,2);
            if dmaxc > 0.1
                maxc = NaN;
            end
            if dminc > 0.1
                minc = NaN;
            end
            
            % extract relavant info about tuning 
            clear X 
            X = diUnitTuning(resp,STIM,e,goodfiles); % last call of RESP should be for full window (see above)
            clear prefeye prefori
            if X.diana
                prefeye = X.dipref(1);
                prefori = X.dipref(2);
            elseif X.oriana && X.occana
                % occularity is (2v3) (ipsivcontra)
                if sign(X.occ(3)) == 1
                    prefeye = 2;
                else
                    prefeye = 3;
                end
                prefori = X.occ(2); 
            else
                skip = skip + 1; 
                continue
            end
            
            % rearange TRLS and KEY to be [preff null bi]
            % right now it is [2 3 bi]
            if prefeye == 3
                TRLS = TRLS(:,[2 1 3]);
                KEY  = KEY(:,[1 3 2 4]);
            end
           
            % [DEV] for now, only look at preffered ori [DEV]
           clear oI
           oI = KEY(:,1) == prefori;
           if isnan(X.dipref(2)) || ~any(biori == prefori) ...
                   || sum(oI) < 2;
               skip = skip + 1; 
               continue
           end
           
            % yay, this is a unit to analyze!
            uct    = uct + 1; 
                        
            % SDFs for MIN and MAX CONTRAST
            cnt = [maxc minc];
            for c = 1:2
                cI = diff(KEY(:,2:3),[],2) == 0 & KEY(:,2) == cnt(c);
                if any(cI)
                    for cond = 1:3;
                        clear trls I dat
                        trls  = TRLS{cI,cond};
                        I = ismember(trls(1):trls(end),trls);
                        dat = squeeze(matobj.SDF(e,:,trls(1):trls(end)));
                        dat = nanmean(dat(tm>=sdfwin(1) & tm<=sdfwin(2),I),2);
                        SDF(:,cond,uct,c) = cat(1,dat,pad);
                    end
                else
                    SDF(:,1:3,uct,c) = NaN;
                end
            end
            
                                    
            %SCALER RESPONSES for all Contrasts
            win = 3; % could add a for loop here
            clear resp
            resp = squeeze(matobj.RESP(e,win,:));
                        
            clear dat stim
            stim = KEY(oI,1:3);
            dat  = cellfun(@(x) nanmean(resp(x)),TRLS(oI,:));
            dat(:,end+1) = bl; % baseline 
            dat(:,end+1) = dat(end,1); % max monocular
            dat(:,end+1) = (X.dianp(1) < 0.05 || X.occ(1) < 0.05); % significant eye tuning 
            dat(:,end+1) = (X.dianp(2) < 0.05 || X.ori(1) < 0.05); % significant ori tuning
                        
            XYZ = cat(1,XYZ,[repmat(uct,size(stim,1),1) stim dat]);
            
            % save INFO
            INFO(uct).penetration = penetration;
            INFO(uct).header  = penetration(1:8);
            INFO(uct).monkey  = penetration(8);
            INFO(uct).unitID  = unitID; 
            INFO(uct).wave    = wave; 
            INFO(uct).runtime = now;
            
            INFO(uct).depth = STIM.depths(e,:)';
            
            INFO(uct).occana       = X.occana;
            INFO(uct).oriana       = X.oriana;
            INFO(uct).diana        = X.diana;
            
            INFO(uct).ori   = X.ori';
            INFO(uct).occ   = X.occ';
            INFO(uct).bio   = X.bio';
            
            INFO(uct).prefeye    = X.dipref(1);
            INFO(uct).prefori    = X.dipref(2);
            INFO(uct).dianov     = X.dianp; 
            
            INFO(uct).tm        = tm;
            
        end
    end
    
end

%%
 norm = 1
    clear sdf *dat step unitstr n
    
    switch norm
        case 0
            sdf = SDF;
            xdat = XYZ(:,5) - XYZ(:,8);
            ydat = XYZ(:,6) - XYZ(:,8);
            zdat = XYZ(:,7) - XYZ(:,8);
            step = 1;
            unitstr = 'spk/s';
        case 1
            sdf = bsxfun(@minus,SDF, SDF(:,1,:,:));
            xdat = XYZ(:,5) - XYZ(:,8);
            ydat = XYZ(:,6) - XYZ(:,8);
            zdat = sqrt(power(xdat,2) + power(ydat,2)) - (XYZ(:,7) - XYZ(:,8));
            step = 1;
            unitstr = 'delta spk/s';
        case 2
            sdf = bsxfun(@minus,SDF, SDF(:,1,:,:));
            r = sqrt(sum(XYZ(:,1:2).^2,2)) - XYZ(:,3); 
    end
%     sdf = cat(2,sdf,...
%         sqrt(power(sdf(:,1,:,:),2) + power(sdf(:,2,:,:),2))); 
%         


clf
subplot(2,2,1)
plot(INFO(1).tm,nanmean(sdf(:,:,:,1),3)); hold on
n = sum(squeeze(~any(isnan(sdf(1,:,:,1)),2))); 
set(gca,'Box','off','tickdir','out'); axis tight 
title(sprintf('Contrast 100%% (n = %u sua)',n))
xlabel('Time(s)')
ylabel(sprintf('Mean Resp (%s)',unitstr))

subplot(2,2,3)
plot(INFO(1).tm,nanmean(sdf(:,:,:,2),3));hold on
n = sum(squeeze(~any(isnan(sdf(1,:,:,1)),2))); 
set(gca,'Box','off','tickdir','out'); axis tight 
title(sprintf('Contrast 25%% (n = %u sua)',n))
xlabel('Time(s)')
ylabel(sprintf('Mean Resp (%s)',unitstr))



% fit quadratic summation model

clear fx fy fz f
fx = min(xdat):step:max(xdat); 
fy = min(ydat):step:max(ydat); 
for f = 1:length(fy)
    fz(:,f) = sqrt(fx.^2 + fy(f)^2);
end
fx = repmat(fx',1,size(fz,2)); 
fy = repmat(fy,size(fz,1),1);
if norm == 1
    fz = fz - fz; 
end


clear b*
[N,Xedges,Yedges,binX,binY] = histcounts2(xdat,ydat);
[u, gname] = grpstats(zdat,{binX,binY},{'mean','gname'});
gname = str2double(gname); 
bx = (Xedges(gname(:,1))) + diff(Yedges(1:2));
by = (Yedges(gname(:,2))) + diff(Xedges(1:2));
bz = u; 


subplot(2,2,[2 4])
surf(fx,fy,fz,'FaceAlpha',0.3,'LineStyle','none','FaceColor','k'); hold on
scatter3(xdat,ydat,zdat,'rx'); hold on
plot3(bx(1:end-1),by(1:end-1),bz(1:end-1),'bo')
xlabel('Monocular Pref')
ylabel('Monocular Null')
zlabel('Binocular')
legend({'SS Model','Obs','Mean'},'Location','Best'); 

%%
% 
% 
% 
% subplot(1,2,2)
% r = sqrt(sum(XYZ(:,1:2).^2,2)) - XYZ(:,3); 
% fz = zeros(size(fz));
% surf(fx,fy,fz,'FaceAlpha',0.3,'LineStyle','none','FaceColor','k'); hold on
% scatter3(XYZ(:,1),XYZ(:,2),r,'go'); hold on


%%
%
%             % check for significant changes from baseline
%             clear RESP  clear I SDF sdftm h stats
%             I = find(ismember(STIM.filen,goodfiles));
%             RESP = squeeze(matobj.RESP(e,1,I)); % 1 = early,  50-100 ms
%              if all(isnan(RESP))
%                 continue
%             end
%             SDF   = squeeze(matobj.SDF(e,:,I));
%             sdftm = matobj.sdftm;
%             q75 = quantile(RESP,.75);
%             if q75 < 5
%                 continue
%             end
%             SDF = SDF(:,RESP >= q75);
%             [h,~,~,stats] = ttest(...
%                 nanmean(SDF(sdftm >=  0.05 & sdftm <= 0.10,:)), ...
%                 nanmean(SDF(sdftm >= -0.05 & sdftm <= 0   ,:)),...
%                 'Tail','right');
%             if h == 0 || stats.df < 10
%                 continue
%             end
%
%
%
%
%
%             I = STIM.ditask...
%                 & STIM.adapted == 0 ...
%                 & STIM.rns == 0 ...
%                 & STIM.cued == 0 ...
%                 & STIM.motion == 0 ...
%                 & ismember(STIM.filen,goodfiles)...
%                 & STIM.diconflict...
%                 & ~STIM.monocular;
%
%
%
%
%
%             % TUNING ANA
%             % note, here I am looking at the full response
%             clear RESP
%             RESP = squeeze(matobj.RESP(e,3,:)); % 3 = full,  50-250 ms
%
%             X = diUnitTuning(RESP,STIM,e,goodfiles);
%
%                uct = uct+1;
%
%                 % Setup binocular analysis by sortting data
%                 % so that they are [prefeye nulleye]
%                 clear eyes sortidx contrasts tilts
%                 eyes      = STIM.eyes;
%                 contrasts = STIM.contrast;
%                 tilts     = STIM.tilt;
%                 if X.dipref(1) == 2
%                     [eyes,sortidx] = sort(eyes,2,'ascend');
%                 else
%                     [eyes,sortidx] = sort(eyes,2,'descend');
%                 end
%                 for ww = 1:length(eyes)
%                     contrasts(ww,:) = contrasts(ww,sortidx(ww,:));
%                     tilts(ww,:)     = tilts(ww,sortidx(ww,:));
%                 end; clear ww
%
%                 for win = 1:2
%                     clear RESP
%                     RESP = squeeze(matobj.RESP(e,win,:));
%
%                     diStim = {'Monocular','Binocular','dCOS'};
%                     for s = 1:3
%                         clear I
%                         I =   STIM.ditask...
%                             & STIM.adapted == 0 ...
%                             & STIM.rns == 0 ...
%                             & STIM.cued == 0 ...
%                             & STIM.motion == 0 ...
%                             & ismember(STIM.filen,goodfiles);
%                         switch diStim{s}
%                             case 'Monocular'
%                                 I = I ...
%                                     & ( STIM.monocular ...
%                                     &   STIM.eye == X.dipref(1) ...
%                                     &   STIM.tilt(:,1) == X.dipref(2) )...
%                                     | (STIM.blank);
%                             case 'Binocular'
%                                 I =  I ...
%                                     & (...
%                                     tilts(:,1) == X.dipref(2) ...
%                                     & tilts(:,2) == X.dipref(2) ...
%                                     & contrasts(:,2) == max(contrasts(:,2))...
%                                     ) | (...
%                                     isnan(tilts(:,1)) ...
%                                     & tilts(:,2) == X.dipref(2) ...
%                                     & contrasts(:,1) == 0 ...
%                                     & contrasts(:,2) == max(contrasts(:,2))...
%                                     );
%                             case 'dCOS'
%                                 I =  I ...
%                                     & (...
%                                     tilts(:,1) == X.dipref(2) ...
%                                     & tilts(:,2) == X.dinull(2) ...
%                                     & contrasts(:,2) == max(contrasts(:,2))...
%                                     ) | (...
%                                     isnan(tilts(:,1)) ...
%                                     & tilts(:,2) == X.dinull(2) ...
%                                     & contrasts(:,1) == 0 ...
%                                     & contrasts(:,2) == max(contrasts(:,2))...
%                                     );
%                         end
%
%                         clear u n gname x y w
%                         [u, n, gname]= grpstats(RESP(I),contrasts(I,1),{'mean','numel','gname'});
%                         x   = str2double(gname);
%                         y   = u;
%                         y(n<5) = [];
%                         x(n<5) = [];
%
%                         switch diStim{s}
%                             case 'Monocular'
%                                 clear bl
%                                 if ~any(x == 0)
%                                     x = [0;x];
%                                     if any(STIM.blank)
%                                         y = [nanmedian(RESP(STIM.blank));y];
%                                     else
%                                         y = [0;y];
%                                     end
%                                 end
%                                 bl = y(x == 0);
% %                             otherwise
% %                                 y(x == 0) = bl;
%                         end
%
%                         clear crf fy
%                         fy = nan(size(fx)); crf.sse = NaN;
%                         if length(y) >= 3
%                             crf = fmsCRF(x,y);
%                             fy = feval(crf.fun,fx);
%                         end
%
%                         % save
%                         CRF(win).resp(:,uct,s) = fy;
%                         CRF(win).gof(uct,s)    = crf.sse;
%                         CRF(win).occ(uct,:)    = X.dianp(1);
%
%                     end
%                 end
%             end
%         end
%     end
% end
%
% %%
%
%
%
% for win = 1:2
%
%     for norm = 0:1
%
%     clear crf i
%     crf  = CRF(win).resp;
%     i = max(crf(:,:,1))' > 5;
%
%     if norm == 1
%         crf = bsxfun(@minus,crf,min(crf(:,:,1)));
%         crf = bsxfun(@rdivide,crf,max(crf(:,:,1)));
%     end
%
%     figure
%     for crit = 1:2
%         clear ii
%         if crit == 1
%             ii = i & CRF(win).occ < 0.05;
%             titlestr = sprintf('%u to %u ms\nOcular Biased, n = %u',assumedwin(win,1),assumedwin(win,2),sum(ii));
%         else
%             ii = i & CRF(win).occ >= 0.05;
%             titlestr = sprintf('%u to %u ms\nEquiocular, n = %u',assumedwin(win,1),assumedwin(win,2),sum(ii));
%         end
%         ii = ii & ~any(isnan(crf(1,:,:)),3)';
%
%         subplot(2,2,crit)
%         plot(fx,nanmean(crf(:,ii,2),2),'b'); hold on
%         plot(fx,nanmean(crf(:,ii,3),2),'r')
%         plot(fx,nanmean(crf(:,ii,1),2),'k')
%         axis tight
%         title(titlestr)
%         if crit == 1 && norm == 1
%             ylabel('Norm. CRF');
%         elseif  crit == 1
%             ylabel('CRF');
%         end
%
%         subplot(2,2,3 + (crit-1));
%         plot(fx,nanmean(crf(:,ii,2) - crf(:,ii,1),2),'b');
%         hold on; axis tight
%         plot(fx,nanmean(crf(:,ii,3) - crf(:,ii,1),2),'r');
%         plot(xlim,[0 0],'k')
%         xlabel('Contrast')
%         if crit == 1 && norm == 1
%             ylabel('Delta Norm. CRF');
%         elseif crit == 1
%             ylabel('Delta CRF');
%         end
%
%     end
%     end
% end

%%


