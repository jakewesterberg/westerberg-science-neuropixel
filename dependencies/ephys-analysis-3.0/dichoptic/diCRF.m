didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Mar14/'
list    = dir([didir '*_KLS*.mat']); % kls only
Fs = 1000;
rwin   = [50 100; 150 250; 50 250; -50 0];

sdfwin  = [-0.050 0.250]; %s
blwin   = [-0.050 0    ]; %s
alpha   = 0.05;
mintrls = 5;

clear CRF 
uct = 0;
for i = 1:length(list)
    
    % load session data
    clear penetration klsnum
    penetration = list(i).name(1:11);
    klsnum      = str2double(list(i).name(end-4));
    
    clear matobj win_ms
    matobj = matfile([didir list(i).name]);
    win_ms = matobj.win_ms;
    if ~isequal(win_ms,rwin)
        error('check win')
    end
    
    clear STIM nel clusters difiles
    STIM = matobj.STIM;
    nel = length(STIM.el_labels);
    clusters = STIM.clusters(:,:,klsnum);
    difiles = unique(STIM.filen(STIM.ditask & STIM.cued == 0));
    if ~any(difiles)
        continue
    end
    
    for e = 1:nel
        
        clear fileclust
        fileclust = clusters(e,:);
        if all(isnan(fileclust))
            continue
        end
        
        clear goodfiles allfiles
        allfiles = 1:length(STIM.filelist);
        goodfiles = find(~isnan(fileclust));
        
        % extract relavant info about tuning
        clear X X0 X1
        % (A) do not subtract baseline
        resp = squeeze(matobj.RESP(e,3,:)); % 3 = full,  50-250 ms;
        X1 = diUnitTuning(resp,STIM,e,goodfiles); clear resp
        % (B) subtract baseline
        resp = squeeze(matobj.RESP(e,3,:) - matobj.RESP(e,4,:)) ; %4 = baseline -50 0
        X0 = diUnitTuning(resp,STIM,e,goodfiles); clear resp
        %quickly check X1 v X0
        if  ~isequal(X1.dicontrasts,X0.dicontrasts) ...
                || ~isequal(X1.diori,X0.diori) ...
                ||  ~(X1.oriana == X0.oriana) ...
                ||  ~(X1.occana == X0.occana) ...
                ||  ~(X1.diana  == X0.diana)
            error('look into X0 vs. X1')
        end
        
        % exclustion critera
        if ~X1.diana
            fprintf('no diana, skipping unit\n')
            continue
        elseif all(isnan(X1.dipref))
            fprintf('cannot determin dipref, skipping unit\n')
            continue
        elseif ~isequal(X1.dipref,X0.dipref)
            fprintf('X1 and X0 have diffrent dipref, skipping unit\n')
            continue
        end
        
        clear I
        I = STIM.ditask...
            & STIM.adapted == 0 ...
            & STIM.rns == 0 ...
            & STIM.cued == 0 ...
            & STIM.motion == 0 ...
            & ismember(STIM.filen,goodfiles);
        
        % Setup binocular analysis by sortting data
        % so that they are [prefeye nulleye]
        clear eyes sortidx contrasts tilts
        eyes      = STIM.eyes;
        contrasts = STIM.contrast;
        tilts     = STIM.tilt;
        if X1.dipref(1) == 2
            [eyes,sortidx] = sort(eyes,2,'ascend');
        else
            [eyes,sortidx] = sort(eyes,2,'descend');
        end
        for ww = 1:length(eyes)
            contrasts(ww,:) = contrasts(ww,sortidx(ww,:));
            tilts(ww,:)     = tilts(ww,sortidx(ww,:));
        end; clear ww
        
        % setup and iterate conditions
        clear prefeye prefori nulleye nullori dicontrasts
        prefeye = X1.dipref(1);
        nulleye = X1.dinull(1);
        prefori = X1.dipref(2);
        nullori = X1.dinull(2);
        dicontrasts = [0 X1.dicontrasts];
        
        ditilts = [... eye 1 stim, eye 2 stim
            prefori prefori;...
            prefori nullori;...
            nullori nullori;...
            nullori prefori];
        ditilts_good = false(4,1);
        
        clear RESP 
        for ori = 1:4
            trls = cell(length(dicontrasts));
            for eye1 = 1:length(dicontrasts);
                for eye2 = 1:length(dicontrasts);
                    clear II
                    II =  I ...
                        &   contrasts(:,1) == dicontrasts(eye1) ...
                        &   contrasts(:,2) == dicontrasts(eye2) ...
                        & ( tilts(:,1) == ditilts(ori,1) | isnan(tilts(:,1)) ) ...
                        & ( tilts(:,2) == ditilts(ori,2) | isnan(tilts(:,2)) );
                    x = find(II);
                    if length(x) > mintrls
                        trls{eye2,eye1} = x;
                    end
                end
            end
            
                        
            for win = 1:4
                clear resp
                resp = squeeze(matobj.RESP(e,win,:));
                if  all(all(cellfun(@isempty,trls(2:end,2:end))))
                    RESP(:,:,ori,win) = nan(length(dicontrasts)); 
                else
                    RESP(:,:,ori,win) = cellfun(@(x) nanmean(resp(x)),trls);
                    ditilts_good(ori) = true;
                end
            end
        end
        if all(all(all(all(isnan(RESP)))))
            continue
        end
        
        % get another measure of bl
        clear resp bl
        resp = squeeze(matobj.RESP(e,end,:));
        bl   = nanmean(resp(I));
        
        % SAVE UNIT INFO!
        uct = uct + 1;
        CRF(uct).penetration = penetration;
        CRF(uct).header = penetration(1:8);
        CRF(uct).monkey = penetration(8);
        CRF(uct).runtime = now;
        
        CRF(uct).depth = STIM.depths(e,:)';
        CRF(uct).kls   = 1;
        
        CRF(uct).occana       = X1.occana;
        CRF(uct).oriana       = X1.oriana;
        CRF(uct).diana        = X1.diana;
        CRF(uct).dicontrast   = dicontrasts;
        
        CRF(uct).prefeye    = prefeye;
        CRF(uct).prefori    = prefori;
        
        CRF(uct).ori        = X1.ori';
        CRF(uct).occ        = X1.occ';
        CRF(uct).bio        = X1.bio';
        CRF(uct).dianov     = X1.dianp'; % p for main effect of each 'eye' 'tilt' 'contrast'
        
        CRF(uct).ori0       = X0.ori';
        CRF(uct).occ0       = X0.occ';
        CRF(uct).bio0       = X0.bio';
        CRF(uct).dianov0    = X0.dianp'; % p for main effect of each 'eye' 'tilt' 'contrast'
       
        CRF(uct).RESP       = RESP;
        CRF(uct).bl         = bl; 
        CRF(uct).ditilts    = ditilts;
        CRF(uct).dicond     = ditilts_good; 
        CRF(uct).win        = win_ms;
        
    end
end


% 
% 
% 
% %%
% 
% 
% 
% for win = 1:2
%     
%     for norm = 0:1
%         
%         clear crf i
%         crf  = CRF(win).resp;
%         i = max(crf(:,:,1))' > 5;
%         
%         if norm == 1
%             crf = bsxfun(@minus,crf,min(crf(:,:,1)));
%             crf = bsxfun(@rdivide,crf,max(crf(:,:,1)));
%         end
%         
%         figure
%         for crit = 1:2
%             clear ii
%             if crit == 1
%                 ii = i & CRF(win).occ < 0.05;
%                 titlestr = sprintf('%u to %u ms\nOcular Biased, n = %u',rwin(win,1),rwin(win,2),sum(ii));
%             else
%                 ii = i & CRF(win).occ >= 0.05;
%                 titlestr = sprintf('%u to %u ms\nEquiocular, n = %u',rwin(win,1),rwin(win,2),sum(ii));
%             end
%             ii = ii & ~any(isnan(crf(1,:,:)),3)';
%             
%             subplot(2,2,crit)
%             plot(fx,nanmean(crf(:,ii,2),2),'b'); hold on
%             plot(fx,nanmean(crf(:,ii,3),2),'r')
%             plot(fx,nanmean(crf(:,ii,1),2),'k')
%             axis tight
%             title(titlestr)
%             if crit == 1 && norm == 1
%                 ylabel('Norm. CRF');
%             elseif  crit == 1
%                 ylabel('CRF');
%             end
%             
%             subplot(2,2,3 + (crit-1));
%             plot(fx,nanmean(crf(:,ii,2) - crf(:,ii,1),2),'b');
%             hold on; axis tight
%             plot(fx,nanmean(crf(:,ii,3) - crf(:,ii,1),2),'r');
%             plot(xlim,[0 0],'k')
%             xlabel('Contrast')
%             if crit == 1 && norm == 1
%                 ylabel('Delta Norm. CRF');
%             elseif crit == 1
%                 ylabel('Delta CRF');
%             end
%             
%         end
%     end
% end
% 
% %%


