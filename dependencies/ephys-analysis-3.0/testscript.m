clear

load('\Users\bmitc\Box Sync\Data_2\160420_E_eD.mat')
matobj = matfile('\Users\bmitc\Box Sync\Data_2\160420_E_eD_AUTO');

for e = 1:length(STIM.depths) 
    win_ms = matobj.win_ms;
    if ~isequal(win_ms,[40 140; 141 450; 50 250; -50 0])    
        error('check win')       
    end
    resp  = squeeze(matobj.RESP(e,3,:)); %pulls out matobj RESP
    X = diUnitTuning(resp,STIM) ; 
    
    if X.diana == 1 && X.dianp(end) < 0.05 
    figure(e); clf
        
        clear I
        goodfiles = unique(STIM.filen); 
        I = STIM.ditask...
            & STIM.adapted == 0 ...
            & ~STIM.blank ...
            & STIM.rns == 0 ...
            & STIM.cued == 0 ...
            & STIM.motion == 0 ...
            & ismember(STIM.filen,goodfiles);
        
        for eye = 2:3 %eye 2 = 
            for ori = 1:2
                
                    II = I & ...
                        STIM.monocular == 1 &...
                        STIM.eye == eye & ...
                        STIM.tilt(:,1) == X.diori(ori);
                    
                    [u, gname] = grpstats(resp(II),{STIM.contrast(II,1)},{'mean','gname'});
                    contrast = str2double(gname);
                    plot(contrast,u,'-o','MarkerFaceColor','b',...
                        'MarkerEdgeColor','b','linewidth',1.5,'markersize',6); hold on
                    set(gca,'box','off','FontSize',12,'linewidth',1.5)
                    xlabel('stimulus contrast'); ylabel('impulses per sec');
%                     legend('DE - Pref Ori','DE - Null Ori','NDE - Pref Ori','NDE - Null Ori');
                
            end
        end
        
        for ori = 1:2
                III = I & ...
                    STIM.monocular == 0 &...
                    STIM.tilt(:,1) == X.diori(ori);

                    [u, gname] = grpstats(resp(III),{STIM.contrast(III,1)},{'mean','gname'});
                    contrast = str2double(gname);
                    plot(contrast,u,'-d','linewidth',1.5,...
                        'MarkerFaceColor','r','MarkerEdgeColor','r','markersize',6); hold on

        end
                    xlabel('stimulus contrast'); ylabel('impulses per sec');
                    legend('NDE|0','NDE|90','DE|0','DE|90','BIN|0','BIN|90','location','northwest');
                    sgtitle({STIM.penetration,'',STIM.el_labels(e)},'interpreter','off');
    end
cd('C:\Users\bmitc\OneDrive\4. Vanderbilt\Maier Lab\Figures\')
saveas(gcf, strcat('firstdMUA', '.svg'));
end



%% Use this almost exactly
 % sort data so that they are [prefeye nulleye]
                    clear eyes sortidx contrasts tilts
                    eyes      = STIM.eyes;
                    contrasts = STIM.contrast;
                    tilts     = STIM.tilt;
                    if X.dipref(1) == 2
                        [eyes,sortidx] = sort(eyes,2,'ascend');
                    else
                        [eyes,sortidx] = sort(eyes,2,'descend');
                    end
                    for w = 1:length(eyes)
                        contrasts(w,:) = contrasts(w,sortidx(w,:)); % sort contrasts in dominant eye and non-dominant eye
                        tilts(w,:)     = tilts(w,sortidx(w,:));
                    end; clear w
                    
                    % get di trials
                    clear I
                    I = STIM.ditask...
                        & STIM.adapted == 0 ...
                        & ~STIM.blank ...
                        & STIM.rns == 0 ... %not random noise stimulus
                        & STIM.cued == 0 ... %not cued or uncued
                        & STIM.motion == 0 ... %not moving
                        & ismember(STIM.filen,goodfiles); % things that should be included. We want to get STIM adapted too.
                    % ^ keep constant
                    
                    % analyze by DI condition
                    clear sdftm dicond *SDF sdf
                    sdf   = squeeze(matobj.SDF(e,:,:)); % load for just that channel from the matobj
                    sdftm =  matobj.sdftm;
                    dicond = {'Monocular','Binocular','dCOS'}; %not using dCOS, going to use all contrast levels
                    
                    contrast_max = max(X.dicontrasts);
                [~,idx] = min(abs(X.dicontrasts - contrast_max/2));
                
                    contrast_half = intersect(X.dicontrasts,0.40:0.05:0.5);
                    stimcontrast = [contrast_max contrast_half];
                    sdfct = 0; rSDF = nan(6,length(sdftm));
                    for c = 1:2             % gets out contrast max and contrast half in the preferred eye.
                        for di = 1:3
                            sdfct = sdfct +1;
                            clear trls
                            switch dicond{di}           % Find the trials you want to look at
                                case 'Monocular'
                                    trls = I &...
                                        STIM.eye == X.dipref(1) & ...
                                        STIM.tilt(:,1) == X.dipref(2) & ...
                                        STIM.contrast(:,1) == stimcontrast(c) & ...
                                        STIM.monocular;
                                case 'Binocular'
                                    trls = I &...
                                        tilts(:,1) == X.dipref(2) & ...
                                        tilts(:,2) == X.dipref(2) & ...
                                        contrasts(:,1) == stimcontrast(c) & ...
                                        contrasts(:,2) == contrast_max;   % Contrast max is always in the non-dominant eye.
%                                 case 'dCOS'
%                                     trls = I &...
%                                         tilts(:,1) == X.dipref(2) & ...
%                                         tilts(:,2) == X.dinull(2) & ...
%                                         contrasts(:,1) == stimcontrast(c) & ...
%                                         contrasts(:,2) == contrast_max;
                            end
                        end
                    end
    