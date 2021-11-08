
BRdatafile = '160129_I_dots012';

if ispc
    brdrname = sprintf('Z:\\%s',BRdatafile(1:8));
    mldrname = sprintf('Y:\\%s',BRdatafile(1:8));
else
    brdrname = sprintf('/Volumes/Drobo/DATA/NEUROPHYS/rig022/%s',BRdatafile(1:8));
    mldrname = brdrname;
end


dots = readgDotsXY([mldrname filesep BRdatafile '.gDotsXY_di']); % read in text file with stim parameters
badobs = getBadObs(BRdatafile);


flag_RewardedTrialsOnly = true;

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


    % get electrrode index
    elabel = 'White'; 
    eidx = find(cell2mat(cellfun(@(x) ~isempty(strfind(x',elabel)),{NEV.ElectrodesInfo.ElectrodeLabel},'UniformOutput',0)));
    if isempty(eidx)
        error('no %s',elabel)
    end
    eidx = 65; 
    eI =  NEV.Data.Spikes.Electrode == eidx;
    units = unique(NEV.Data.Spikes.Unit(eI));
    for u = 0:max(units)
%         if u > 0
%             elabel = sprintf('eD%02u - unit%u',e,u);
%             I = eI &  NEV.Data.Spikes.Unit == u;
%         else
%             elabel = sprintf('eD%02u - all spikes',e);
%             I = eI;
%         end
         I = eI; 
        % get SPK and WAVE
        clear SPK Fs
        SPK = double(NEV.Data.Spikes.TimeStamp(I)); % in samples
        WAVE = double(NEV.Data.Spikes.Waveform(:,I));
        %Fs = double(NEV.MetaTags.SampleRes);
        
        
        ct = 0; clear r x y d eye
        trls = find(cellfun(@(x) sum(x == 23) == sum(x == 24),pEvC));
        for i = 1:length(trls)
            t = trls(i);
            
            if flag_RewardedTrialsOnly && ~any(pEvC{t} == 96)
                % skip if not rewarded (event code 96)
                continue
            end
            
            stimon  =  pEvC{t} == 23 | pEvC{t} == 25  | pEvC{t} == 27   | pEvC{t} == 29  | pEvC{t} == 31;
            stimoff =  pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32;
            
            st = pEvT{t}(stimon);
            en = pEvT{t}(stimoff);
            stim =  find(dots.trial == t);
            
            maxpres = min([length(st) length(en) length(stim)]);
            
            for p = 1:maxpres
                ct = ct + 1;
                x(ct) = dots.dot_x(stim(p));
                y(ct) = dots.dot_y(stim(p));
                d(ct) = dots.diameter(stim(p));
                eye(ct) = dots.dot_eye(stim(p));
                if any(ct == badobs)
                    r(ct) = NaN;
                else
                    r(ct) = sum(SPK > st(p) & SPK < en(p));
                end
                
            end
            
        end
        if ~any(r)
            fprintf('\n no spikes for %s\n',elabel)
            continue
        end
        
        
        %figure('position', [670   554   957   424])
        figure
        subplot(2,3,1)
        plot(r);
        axis tight; box off;
        xlabel('stim prez')
        ylabel('# of spikes')
        title(elabel)
        
        subplot(2,3,4)
        plot(mean(WAVE,2),'-'); hold on
        plot(mean(WAVE,2)+ std(WAVE,[],2),':'); hold on
        plot(mean(WAVE,2)- std(WAVE,[],2),':'); hold on
        xlabel('waveform')
        axis tight; box off
        
        
        % NOW REMOVE NANs to not messs up ct, NaNs in "r" indicate "badobs"
        x = x(~isnan(r)); y = y(~isnan(r)); r = r(~isnan(r)); eye = eye(~isnan(r)); d = d(~isnan(r));
        
        subplot(2,3,[2 5])
        map = jet(max(r)+1);
        scatter3(x,y,r,30,map(r+1,:),'LineWidth',1.5);
        xlabel('horz. cord.')
        ylabel('vertical cord.')
        zlabel('spk response')
        set(gca,'box','off','view',[-.5 90])
        title(sprintf('%s',BRdatafile),'interpreter','none')
        
        subplot(2,3,[3 6])
        fitstr = 'cubicinterp';%;'cubicinterp';
        f = fit([x', y'],r',fitstr);
        h = plot(f,[x', y'],r');
        xlabel('horz. cord.')
        ylabel('vertical cord.')
        set(h(1),'FaceAlpha',1,'EdgeColor','none')
        set(h(2),'Marker','none')
        set(gca,'box','off','view',[0 90])
        c = colorbar('Location','NorthOutside');
        xlabel(c,sprintf('fit (%s)',fitstr))
        axis equal
        
        
        
        %% square matrix
        %     X = unique(x);
        %     Y = unique(y);
        %     [horz vert]=meshgrid(X,Y);
        %     U = NaN(size(horz));
        %     M = NaN(size(horz));
        %     S = NaN(size(horz));
        %     N = NaN(size(horz));
        %     for m = 1:length(X)
        %         for n = 1:length(Y)
        %             clear I
        %             I = x == X(m) & y == Y(n);
        %             idx = find(horz == X(m) & vert == Y(n));
        %             if any(I)
        %                 U(idx) = nanmean(r(I));
        %                 M(idx) = nanmedian(r(I));
        %                 S(idx) = nanstd(r(I));
        %                 N(idx) = sum(r(I));
        %             end
        %         end
        %     end
        
        
    end



