% Objective: Display raw and averaged spiking data
% What you need: Aligned spiketimes per trial
% Example data: Cortical multi-unit responses to repeated presentation of pure tone

%%% Felix Schneider
%%% Auditory Cognition Group: https://www.auditorycognition.org/
%%% Biosciences Institute, Newcastle University Medical School
%%% 02/2020

if strcmp(getenv('username'),'bmitc')
    figDir = 'C:\Users\bmitc\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'mitchba2')
    figDir = 'C:\Users\mitchba2\OneDrive - Vanderbilt\Maier Lab\Figures\';
elseif strcmp(getenv('username'),'bmitc_000')
    figDir = 'C:\Users\bmitc_000\OneDrive - Vanderbilt\Maier Lab\Figures\';
end

% toggle to save figures
flag_figsave = 1;

%% 1. Load in trial-wise spiking data
clear unit c stm optimal binarySpks sdf
unit = 5;
c = 4;
stm = 'monocular';
tw = 1:length(sdfWin);

monCond     = {'DE_PS','NDE_PS','DE_NS','NDE_NS'};
binCond     = {'PS','NS'};
mon = 1;
bin = 1;


clear binarySpks
if strcmp(stm, 'monocular')
    binarySpks = SUA(unit).MON.(monCond{mon}){1,c}(tw,:);

else
    binarySpks = SUA(unit).BIN.(binCond{bin}){1,c}(tw,:);

end

clear spikeTimes
for iTrials = 1:size(binarySpks,2)
spikeTimes{iTrials} = sdfWin(:,binarySpks(:,iTrials)==1)';
end

% 2. Raster plot

figure('Units','normalized','Position',[0 0 .3 1])
ax = subplot(4,1,1); hold on

% For all trials...
for iTrial = 1:length(spikeTimes)
                  

    spks            = spikeTimes{iTrial}';      % Get all spikes of respective trial    
    xspikes         = repmat(spks,3,1);         % Replicate array
    yspikes      	= nan(size(xspikes));
    
% Get all spikes of respective trial    
    xspikes         = repmat(spks,3,1);         % Replicate array
    yspikes      	= nan(size(xspikes));       % NaN array
    
    if ~isempty(yspikes)
        yspikes(1,:) = iTrial-1;                % Y-offset for raster plot
        yspikes(2,:) = iTrial;
    end
    
    plot(xspikes, yspikes, 'Color', 'k')
end

ax.XLim             = [-.15 .5];
ax.YLim             = [0 length(spikeTimes)];
ax.XTick            = [0 .25];

ax.XLabel.String  	= 'Time [s]';
ax.YLabel.String  	= 'Trials';

% 3. Peristimulus time histogram (PSTH)

all = [];
for iTrial = 1:length(spikeTimes)
    all             = [all; spikeTimes{iTrial}];               % Concatenate spikes of all trials             
end

ax                  = subplot(4,1,2);
nbins               = 100;
h                   = histogram(all,nbins);
h.FaceColor         = 'k';

mVal                = max(h.Values)+round(max(h.Values)*.1);
ax.XLim             = [-.15 .5];
ax.YLim             = [0 mVal];
ax.XTick            = [0 .25];
ax.XLabel.String  	= 'Time [s]';
ax.YLabel.String  	= 'Spikes/Bin';

% slength             = length(tw);                                  % Length of signal trace [ms]
% bdur                = slength/nbins;                        % Bin duration in [ms]
% nobins              = 30000/bdur;                            % No of bins/sec
% for iLab = 1:length(ax.YTickLabel)
%     lab             = str2num(ax.YTickLabel{iLab});
%     conv            = (lab / length(spikeTimes)) * nobins; 	% Convert to [Hz]: avg spike count * bins/sec
%     newlabel{iLab}  = num2str(round(conv));                 % Change YLabel
% end
% ax.YTickLabel       = newlabel;
% ax.YLabel.String  	= 'Firing Rate [Hz]';

% 4. Spike density function

tstep     	= .001;                     % Resolution for SDF [s]
sigma   	= .005;                     % Width of gaussian/window [s]
time     	= sdfWin; %tstep-.15:tstep:.400;        % Time vector

clear spks gauss out iSpk mu p1 p2 gauss sdf
for iTrial = 1:length(spikeTimes)
    spks    = []; 
    gauss   = []; 
    spks   	= spikeTimes{iTrial}';          % Get all spikes of respective trial
    
    if isempty(spks)            
        out	= zeros(1,length(time));    % Add zero vector if no spikes
    else
        
        % For every spike
        for iSpk = 1:length(spks)
            
            % Center gaussian at spike time
            mu              = spks(iSpk);
            
            % Calculate gaussian
            p1              = -1 * ((time - mu)/sigma) .^ 2;
            p2              = (sigma * sqrt(2*pi));
            gauss(iSpk,:)   = exp(p1) ./ p2;
            
        end
        
        % Sum over all distributions to get spike density function
        sdf(iTrial,:)       = sum(gauss,1);
    end
end


% Single trial display
ax                  = subplot(4,1,3);
imagesc(sdf)
ax.XLabel.String  	= 'Time [s]';
ax.YLabel.String  	= 'Trials';
ax.XLim             = [1 find(sdfWin==0.5)];
ax.XTick            = [find(sdfWin==0) find(sdfWin==0.25)];
ax.XTickLabel       = {'0', '0.25'};
colormap jet 

% Average response
ax = subplot(4,1,4);
plot(nanmean(sdf), 'Color', 'k', 'LineWidth', 1.5)
mVal = max(nanmean(sdf)) + round(max(nanmean(sdf))*.1);

ax.XLim             = [1 find(sdfWin==0.5)];
ax.YLim             = [0 mVal];
ax.XTick            = [find(sdfWin==0) find(sdfWin==0.25)];
ax.XTickLabel       = {'0', '0.25'};
ax.XLabel.String  	= 'Time [s]';
ax.YLabel.String  	= 'Firing Rate [Hz]';

% Save figure
if flag_figsave == 1
    cd(strcat(figDir,'sua\'));
    saveas(gcf, strcat('unit-example','.svg'));
    sprintf("Figure saved");
else
    sprintf("Figure was not saved");
end


%% Seperate plots

clear unit c stm optimal binarySpks sdf
unit = 3;
c = 4;
stm = 'monocular';
tw = 1:length(sdfWin);

monCond     = {'DE_PS','NDE_PS','DE_NS','NDE_NS'};
binCond     = {'PS','NS'};
mon = 1;
bin = 1;

% Raster plot

figure('Units','normalized','Position',[0.3,0.5,0.2,0.10])


    
    clear binarySpks
if strcmp(stm, 'monocular')
    binarySpks = SUA(unit).MON.(monCond{mon}){1,c}(tw,:);
    sdf        = squeeze(UNIT.MON.(monCond{mon}).SDF(c,tw,unit));
else
    binarySpks = SUA(unit).BIN.(binCond{bin}){1,c}(tw,:);
    sdf        = squeeze(UNIT.BIN.(binCond{bin}).SDF(c,tw,unit));
end

clear spikeTimes
for iTrials = 1:size(binarySpks,2)
spikeTimes{iTrials} = sdfWin(:,binarySpks(:,iTrials)==1)';
end

ax = subplot(1,1,1); hold on

% For all trials...
for iTrial = 1:length(spikeTimes)
                  

    spks            = spikeTimes{iTrial}';      % Get all spikes of respective trial    
    xspikes         = repmat(spks,3,1);         % Replicate array
    yspikes      	= nan(size(xspikes));
    
% Get all spikes of respective trial    
    xspikes         = repmat(spks,3,1);         % Replicate array
    yspikes      	= nan(size(xspikes));       % NaN array
    
    if ~isempty(yspikes)
        yspikes(1,:) = iTrial-1;                % Y-offset for raster plot
        yspikes(2,:) = iTrial;
    end
    
    plot(xspikes, yspikes, 'Color', 'k')
end

ax.XLim             = [-.15 .5];
ax.YLim             = [0 length(spikeTimes)];
ax.XTick            = [0 .25];

% if c == 4
%     ax.XLabel.String = 'time(s) from stimulus onset';
%     ax.YLabel.String = 'trials';
% else

ax.XLabel.String  	= '';
ax.YLabel.String  	= '';
% end



if flag_figsave == 1
    cd(strcat(figDir,'sua\'));
    saveas(gcf, strcat('raster_',num2str(unit),'_',num2str(c),'.svg'));
    disp("Figure saved");
else
    disp("Figure was not saved");
end

%%
