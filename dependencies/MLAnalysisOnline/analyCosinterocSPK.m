
BRdatafile = '160115_E_mcosinteroc002';

switch BRdatafile(1:6)
    case '151208'
        DOMEYE = 2;
        PREFORI = 107;
    case '151207'
        DOMEYE = 2;
        PREFORI = 85;
    case '151211'
         DOMEYE = 3;
        PREFORI = 110;
    case '151221'
        DOMEYE = 2;
        PREFORI = 90;
    case '151223'
        DOMEYE = 3;
        PREFORI = 110;
    case '160115'
        DOMEYE = 3;
        PREFORI = 115;
end

if ispc
    brdrname = sprintf('Z:\\%s',BRdatafile(1:8));
    mldrname = sprintf('Y:\\%s',BRdatafile(1:8));
else
    brdrname = sprintf('/Volumes/Drobo/DATA/NEUROPHYS/rig022/%s',BRdatafile(1:8));
    mldrname = brdrname;
end

if isempty(strfind(BRdatafile,'m'))
    ext = '.gCOSINTEROCGrating_di';
else
    ext = '.gMCOSINTEROCGrating_di';
end

grating = readgGrating([mldrname filesep BRdatafile ext]);


badobs = getBadObs(BRdatafile);

flag_RewardedTrialsOnly = false;

clear SPK WAVE NEV
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

for e =2:18
    
    % get electrrode index
    elabel = sprintf('eD%02u',e);
    eidx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x',elabel)),{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0)));
    if isempty(eidx)
        continue 
        % error('no %s',elabel)
    end
    eI =  NEV.Data.Spikes.Electrode == eidx;
    units = unique(NEV.Data.Spikes.Unit(eI));
    for u = max(units):-1:0
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
        %Fs = double(NEV.MetaTags.SampleRes);
        
        
        %%
        ct = 0; clear CRF STIM prefContrast nullContrast MON mContrast
        for t = 1:length(pEvC)
            if flag_RewardedTrialsOnly && ~any(pEvC{t} == 96)
                % skip if not rewarded (event code 96)
                continue
            end
            stimon  =  pEvC{t} == 23 | pEvC{t} == 25  | pEvC{t} == 27   | pEvC{t} == 29  | pEvC{t} == 31;
            stimoff =  pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32;
            
            st = pEvT{t}(stimon);
            en = pEvT{t}(stimoff);
            stim =  find(grating.trial == t);
            for p = 1:length(en)
              
                
                clear eye tilt oridist eye_contrast other_contrast
                eye            = grating.eye(stim(p)); % 2 = right, 3 = left ??????
                tilt           = grating.tilt(stim(p));
                other_tilt     = uCalcTilts0to179(tilt, oridist);
                eye_contrast   = grating.contrast(stim(p));
                other_contrast = grating.fixedc(stim(p));
                
                if (other_contrast == 0) || ( eye_contrast == 0) || (eye == DOMEYE && tilt == PREFORI) || (other_eye == DOMEYE && other_tilt == PREFORI)
                    ct = ct +1;
                    
                    if   other_contrast == 0
                        MON(ct,1) = true;
                        STIM{ct,1} = sprintf('Mon: Eye = %u, Ori = %u',eye, tilt);
                        
                        mContrast(ct,1) = double(round(eye_contrast .* 100) / 100);
                           prefContrast(ct,:) = NaN;
                        nullContrast(ct,:) = NaN;
                    
                    elseif eye_contrast == 0;
                        MON(ct,1) = true;
                        STIM{ct,1} = sprintf('Mon: Eye = %u, Ori = %u',other_eye, other_tilt);
                        
                        mContrast(ct,1) = double(round(other_contrast .* 100) / 100);
                        prefContrast(ct,:) = NaN;
                        nullContrast(ct,:) = NaN;
                    
                    elseif eye == DOMEYE && tilt == PREFORI
                        MON(ct,1) = false;
                        
                        mContrast(ct,:)    = NaN;
                        prefContrast(ct,:) = double(round(eye_contrast .* 100) / 100);
                        nullContrast(ct,:) = double(round(other_contrast .* 100) / 100);
                        
                        if tilt == other_tilt
                            STIM{ct,1} = 'Binocular';
                        else
                            STIM{ct,1} = 'dCOS';
                        end
                        
                    elseif other_eye == DOMEYE && other_tilt == PREFORI
                        MON(ct,1) = false;
                        
                        mContrast(ct,:)    = NaN;
                        prefContrast(ct,:) = double(round(other_contrast .* 100) / 100);
                        nullContrast(ct,:) = double(round(eye_contrast .* 100) / 100);
                        
                         if tilt == other_tilt
                            STIM{ct,1} = 'Binocular';
                        else
                            STIM{ct,1} = 'dCOS';
                        end
                        
                    end
                    
                   
                    if any(ct == badobs)
                        CRF(ct) = NaN;
                    else
                        CRF(ct) = sum(SPK > st(p) & SPK < en(p));
                    end
                    
                end
            end
            
        end
        
        
        if ~any(CRF)
            continue
        end
        
        figure('Position',[  264   201   902   679])
        
        
        subplot(2,3,1)
        plot(CRF);
        axis tight; box off;
        xlabel('stim prez')
        ylabel('# of spikes')
        title(elabel)
        axis tight; box off; set(gca,'TickDir','out');
        
        subplot(2,3,4)
        plot(mean(WAVE,2),'-'); hold on
        plot(mean(WAVE,2)+ std(WAVE,[],2),':'); hold on
        plot(mean(WAVE,2)- std(WAVE,[],2),':'); hold on
        xlabel('waveform')
        axis tight; box off; set(gca,'TickDir','out');
        
        subplot(2,3,[2 3])
        % PLOT Monocular CRF
        uStim =  unique(STIM); uStim(strcmp(uStim,'Binocular')) = []; uStim(strcmp(uStim,'dCOS')) = []; 
        strct = 0; clear str
        map = lines(4);
        for s = 1:length(uStim)
                I = strcmp(STIM,uStim{s});
                
                [y err gstim] = grpstats(CRF(I), mContrast(I,:), {'mean','sem','gname'});
                
                if ~isempty(y)
                    strct = strct + 1;
                    str{strct} = sprintf('%s',uStim{s});
                    x =  str2double(gstim(:));
                    h = errorbar(x,y,err,'Marker','o','Color',map(s,:),'LineWidth',1.5); hold all
                    %h = plot(x,y,'Marker','o','Color',map(c,:),'LineWidth',1.5); hold all
                end
                
                
            
        end
        box off; set(gca,'TickDir','out');
        legend(str,'Location','Best')
        title(sprintf('%s: %s',BRdatafile, elabel),'interpreter','none')
        ylabel('mean response')
        xlabel(sprintf('Contrast of ORI = %u in EYE = %u',PREFORI,DOMEYE))
        
        
        
        
        subplot(2,3,[5 6])
        strct = 0; clear str

        % 1st plot monocular CRF
        mcond = sprintf('Mon: Eye = %u, Ori = %u',DOMEYE, PREFORI);
        I = strcmp(STIM,mcond);
        [y err gstim] = grpstats(CRF(I), mContrast(I,:), {'mean','sem','gname'});
        if ~isempty(y)
            strct = strct + 1;
            str{strct} = mcond;
            x =  str2double(gstim(:));
            %h = errorbar(x,y,err,'Marker','o','Color',map(s,:),'LineWidth',1.5); hold all
            h = plot(x,y,'Marker','none','Color',[0 0 0],'LineWidth',1.5); hold all
        end
        
        % PLOT dichoptic CRFs
        uStim = {'dCOS','Binocular'};
        uContrast=unique(nullContrast);
        map = prism(6); map(3,:) = []; map =flipud(map);
        for s = 1:length(uStim)
            for c = 1:length(uContrast)
                % one line for each "nullContrast" so that x-axis can be "prefContrast"
                I = strcmp(STIM,uStim{s}) & nullContrast == uContrast(c);
                
                [y err gstim] = grpstats(CRF(I), prefContrast(I,:), {'mean','sem','gname'});
                
                if ~isempty(y)
                    strct = strct + 1;
                    str{strct} = sprintf('%s - %0.2f',uStim{s},uContrast(c));
                    x =  str2double(gstim(:));
                    h = errorbar(x,y,err,'Marker','o','Color',map(c,:),'LineWidth',1.5); hold all
                    %h = plot(x,y,'Marker','o','Color',map(c,:),'LineWidth',1.5); hold all
                    switch uStim{s}
                        case 'Monocular'
                            set(h,'LineWidth',2,'Color',[0 0 0])
                        case 'dCOS'
                            set(h,'LineStyle','--')
                    end
                end
                
                
            end
        end
        box off; set(gca,'TickDir','out');
        legend(str,'Location','Best')
        title(sprintf('%s: %s',BRdatafile, elabel),'interpreter','none')
        ylabel('mean response')
        xlabel(sprintf('Contrast of ORI = %u in EYE = %u',PREFORI,DOMEYE))
        
    end
end

%
%     figure
%     map = jet(2);
%     scatter3(prefContrast,nullContrast,CRF,[],map(dCOS+1,:))
%
%
%
% ahahah
%
%
%     figure('Position',[ 11         558        1904         420])
%     subplot(2,3,1)
%     plot(CRF);
%     axis tight; box off;
%     xlabel('stim prez')
%     ylabel('# of spikes')
%     title(elabel)
%
%     subplot(2,3,2)
%     hist(CRF);
%     box off;
%     xlabel('# of spikes')
%     ylabel('frequency')
%
%     subplot(2,3,3)
%     plot(mean(WAVE,2),'-'); hold on
%     plot(mean(WAVE,2)+ std(WAVE,[],2),':'); hold on
%     plot(mean(WAVE,2)- std(WAVE,[],2),':'); hold on
%     xlabel('waveform')
%     axis tight; box off
%
%     subplot(2,3,4)
%     CRF
%
%
%     %     boxplot(r,tilt)
% %     p=anovan(r,tilt','display','off');
%     title(sprintf('p = %0.3f,',p))
%     xlabel(group)
%     ylabel('# of spikes')
%     axis tight; box off;
%
%
%     subplot(2,3,5)
%     theta = deg2rad(tilt(eye==EYE));
%     roh = CRF(eye==EYE);
%
%     polar(theta, roh,'bx'); hold on
%     polar(theta+pi, roh,'bx'); hold on
%     [uRoh mRoh uTheta n] = grpstats(roh, theta, {'mean','median','gname','numel'});
%     uTheta = str2double(uTheta);
%     polar(uTheta, uRoh,'r.'); hold on
%     polar(uTheta+pi, uRoh,'r.'); hold on
%     polar(uTheta, mRoh,'go'); hold on
%     polar(uTheta+pi, mRoh,'go'); hold on
%     title(sprintf('n = [%u %u]',min(n), max(n)))
%     axis tight; axis square; box off;
%
%     subplot(2,3,6)
%     clear x y f
%     [uR sR uTilt n] = grpstats(CRF(eye==EYE), tilt(eye==EYE), {'mean','sem','gname','numel'});
%     y = uR;
%     x = cellfun(@(x) str2num(x),uTilt);
%     y = [y; y];
%     x = [x ; x+180];
%     f = fit(x,y,'smoothingspline');
%     plot(f,x,y); hold on
%     errorbar(x,y,[sR; sR],'linestyle','none'); hold on
%     axis tight; axis square; box off; legend('off')
%     plot([180 180],ylim,'k:');
%
%
%
%



%%
% figure;
% subplot(1,2,1)
% plot(R);
% axis tight; box off;
% subplot(1,2,2)
% hist(R);
% axis tight; box off;
% title(elabel)
%
%
%
%
%


