
BRdatafile = '151208_E_kanizsa001';

if ispc
    brdrname = sprintf('Z:\\%s',BRdatafile(1:8));
    mldrname = sprintf('Y:\\%s',BRdatafile(1:8));
else
    brdrname = sprintf('/Volumes/Drobo/DATA/NEUROPHYS/rig022/%s',BRdatafile(1:8));
    mldrname = brdrname;
end

kanizsa = readKanizsa([mldrname filesep BRdatafile '.gKanizsa']); % read in text file with stim parameters
badobs = getBadObs(BRdatafile);

clear stim_names
for k = 1:max(kanizsa.stimidx);
    idx = find(kanizsa.stimidx == k,1,'first');
    if ~isempty(idx)
        stim_names{k,1} = sprintf('%s - %s - %s - %s',kanizsa.figure_string{idx},kanizsa.color_string{idx},kanizsa.dioptic_string{idx},kanizsa.contour_string{idx});
    end
end

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


for e =14
    
    elabel = sprintf('eD%02u',e);
    % get electrrode index
    eidx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x',elabel)),{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0)));
    I =  NEV.Data.Spikes.Electrode == eidx;
    SPK = double(NEV.Data.Spikes.TimeStamp(I));
    WAVE = double(NEV.Data.Spikes.Waveform(:,I));
    Fs = double(NEV.MetaTags.SampleRes);
    
    
    %%
    clear r 
    for t = 1:length(pEvC)
        
        st = pEvT{t}(find(pEvC{t} == 23,1,'last')) + 150/1000*Fs;
        en = st + 1150/1000*Fs; % pEvT{t}(pEvC{t} == 24);
        
        if ~any(pEvC{t} == 96) || isempty(st) || isempty(en) || any(t == badobs)
            r(t) = NaN;
        else
            r(t) = sum(SPK > st & SPK < en);
        end
        
    end
    
    
   
    
    figure('Position',[ 11         200        1904         800])
    subplot(2,3,1)
    plot(r);
    axis tight; box off;
    xlabel('stim prez')
    ylabel('# of spikes')
    title(elabel)
    
    subplot(2,3,2)
    hist(r);
    box off;
    xlabel('# of spikes')
    ylabel('frequency')
    
    subplot(2,3,3)
    plot(mean(WAVE,2),'-'); hold on
    plot(mean(WAVE,2)+ std(WAVE,[],2),':'); hold on
    plot(mean(WAVE,2)- std(WAVE,[],2),':'); hold on
    xlabel('waveform')
    axis tight; box off
    
    subplot(2,3,[4 5 6])
    I = kanizsa.stimidx <= 4;
    dat = r(I);
    group = {kanizsa.figure_string(I),kanizsa.dioptic_string(I),kanizsa.contour_string(I),kanizsa.color_string(I)};

    boxplot(dat, group)
    p=anovan(dat, group,'display','off');
    title(sprintf('p = %0.3f,',p))
    xlabel('stimidx')
    ylabel('# of spikes')
    axis tight; box off;
    
%    group = {kanizsa.figure_string,kanizsa.color_string,kanizsa.dioptic_string,kanizsa.contour_string};
% group = {kanizsa.figure_string};
% e
%    p = anovan(r,group,'varnames',{'figure'})
    
    
    
    
    %
    % subplot(2,3,5)
    % theta = deg2rad(tilt(eye==EYE));
    % roh = r(eye==EYE);
    %
    % polar(theta, roh,'bx'); hold on
    % polar(theta+pi, roh,'bx'); hold on
    % [uRoh mRoh uTheta n] = grpstats(roh, theta, {'mean','median','gname','numel'});
    % uTheta = str2double(uTheta);
    % polar(uTheta, uRoh,'r.'); hold on
    % polar(uTheta+pi, uRoh,'r.'); hold on
    % polar(uTheta, mRoh,'go'); hold on
    % polar(uTheta+pi, mRoh,'go'); hold on
    % title(sprintf('n = [%u %u]',min(n), max(n)))
    % axis tight; axis square; box off;
    %
    % subplot(2,3,6)
    % clear x y f
    % [uR sR uTilt n] = grpstats(r(eye==EYE), tilt(eye==EYE), {'mean','sem','gname','numel'});
    % y = uR;
    % x = cellfun(@(x) str2num(x),uTilt);
    % y = [y; y];
    % x = [x ; x+180];
    % f = fit(x,y,'smoothingspline');
    % plot(f,x,y); hold on
    % errorbar(x,y,[sR; sR],'linestyle','none'); hold on
    % axis tight; axis square; box off; legend('off')
    % plot([180 180],ylim,'k:');
    
    
    
    
    
end
