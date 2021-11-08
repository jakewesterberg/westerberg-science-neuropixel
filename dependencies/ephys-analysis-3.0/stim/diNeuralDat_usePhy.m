function [RESP, win_ms, SDF, sdftm, PSTH, psthtm, SUA, spktm]= diNeuralDat_usePhy(STIM,datatype,flag_1kHz,win_ms)
%taken from diNeuralDat_noCluster.m

if nargin < 4 || isempty(win_ms)
    win_ms    = [50 100; 150 250; 50 250; -50 0]; % ms;
    % note, when win_ms exceeds stimulus duration, data will be trunkated
end
if nargin < 3 || isempty(flag_1kHz)
    flag_1kHz = true;
end

%%
%

if ~any(strcmp({'kls'},datatype))
    error('This function is exclusive to kls datatype')
end

tfdouble = isa(STIM.tp_pt,'double');
if ~tfdouble
    warning('Expecting STIM.tp_pt to be a double but it is not. Unexpected behavior possible.')
end

global SORTDIR
if ~isempty(SORTDIR)
    sortdir = SORTDIR;
else
    sortdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';
end

bin_ms    = 10;
nwin      = size(win_ms,1);   % number of windows in RESP 


el_labels = STIM.el_labels;
nel       = length(STIM.units);


Fs = 30000;
TP = STIM.tp_pt;

%% BMC breakdown from 9/5/2020
% 1. sdftm is created at 1kHx, it is in ms realtive to stim onset. This is
% esentially -300ms:(150ms + max diff in timepoints per row/30). Here this
% finds -300:1600ish... So its captures enought for BRFS. It is finding
% that some stim offsets are long -- i.e. brfs trials with adapter adn
% suppressor.

% 2. loop trials

    % 3. on 1st trial loop (or a new paradigm) create the variable SPK. This is
    % found wherever the spiketimes outputs from phy matchets up with the
    % clusters from phy (per {e} or unit found)

    % 4. get out tp, thich is TP(trial# for this loop,:). Its the 30kHz
    % timepoints for this trial in the loop

    % 5. Loop the # of units found on this recording session from Phy.

        % 6. Get x... This one is difficult. x is the spiketime for a given
        % unit minus the photodiode onset for this given trial.
        % This essentially aligns the spiketime output for this unit to the
        % 0-point of the trial onset of the trial of this given loop.
        % i.e. for 151221 unit #4 the SPK{e} is a 41207x1 cell. All of the
        % times in this cell are the times of a given spike. Trial #1's onset
        % time is 160829 (TP(1,1) = tp(1) = 160829). The 41207 spike times in
        % SPK{4} occur between timepoint 4135 and 338,168,460. This is the
        % range of the entire paradigm file. These spike times are all adjusted
        % left by 160829 timepoints for the first trial. Timepoint 160829
        % becomes 0. This repeats depending on the trial.

        % 7. These timepoints can now be referenced agains sdftm (-300:1815).
        % Any spike found within that range is put out into [spk,spktm] with
        % the intersect function. 
        % spk are the values of sdftm where a spike was found, in
        % order of sdftm. spktm are the indexed spots in sdftm where spk is
        % found. Therefore, the spktm output of diNeuralDat_usePhy.m has little
        % to no meaning, as it changes per unit per trial. spk is the ultimate
        % variable of value out of the intersection of x and sdftm.

        % 8. sua is a binary output for "spk found" in each ms bin along sdftm

        % 9. SUA is the main output of (unit x binary spks along sdftm x trial)

    % end --- end of unit loop
% end    -- end of trial loop
    
    
    
%%
% pre-allocation
RESP      = nan(nel,nwin,length(STIM.tp_pt));

bin_sp    = bin_ms/1000*Fs;
psthtm    = [-0.3*Fs : bin_sp : 0.15*Fs + max(diff(TP,[],2)) + bin_sp];
PSTH      = nan(nel,length(psthtm),length(STIM.tp_pt));

if ~flag_1kHz
    r = 1;
else
    r = 30;
end

sdftm     = [-0.3*Fs/r: 0.15*Fs/r + max(diff(TP,[],2)/r)];
SDF       = nan(nel,length(sdftm),length(STIM.tp_pt));
k         = jnm_kernel( 'psp', (20/1000) * (Fs/r) );



% iterate trials, loading files as you go
for i = 1:length(STIM.trl)
    
    if i == 1 || STIM.filen(i) ~= filen %this seems backwards to me? happens on the first STIM.trl or when the filenumber changes?
        
        clear filen filename BRdatafile
        filen = STIM.filen(i);
        filename  = STIM.filelist{filen};
        [~,BRdatafile,~] = fileparts(filename);
        
        % setup SPK cell array
        SPK   = cell(nel,1);
        empty = false(size(SPK)); 
        
        
        % load KS data, never concatenated
        % diClusters already screened and assigned units
        for e=1:nel
            filematch = STIM.units(e).fileclust(:,1) == filen;  %% swapped from 2 to 1  - BM 6/15/20
            if filematch
                break
            end
        end
        if filematch
            for e=1:nel
                idx = find(STIM.units(e).fileclust(:,1) == filen); %% swapped from 2 to 1  - BM 6/15/20
                if isempty(idx)
                    empty(e) = true;
                else
                    clust = STIM.units(e).fileclust(idx,2); %% swapped from 1 to 2  - BM 6/15/20
                    SPK{e,1} = STIM.phy.spike_times(ismember(STIM.phy.spike_clusters,clust));
                end
            end
        end
  
    end  % end the if statement
    
    % get TP and rwin
    clear tp rwin
    tp = TP(i,:) ; % TP is always Fs = 30000 because it is recorded by NEV
    if any(isnan(tp))
        continue
    end
    
    rwin = tp(1) + (win_ms/1000*Fs);
    % deal with instnaces where the window exceeds stimulus offset
    stimoff = rwin > tp(2); 
    rwin(stimoff)  = tp(2); % Only used for pulling out RESP. sdftm defines the sdf window.
    
    
            
            
    for e = 1:length(SPK)
        if empty(e)
            continue
        elseif ~isa(SPK{e},'double')
            warning('does not work if SPK is not double, converting now');
            SPK{e} = double(SPK{e});
        end
        
        clear spk sua psth sdf x;
        if ~flag_1kHz
            x = SPK{e} - tp(1);
        else
            x = unique(round( (SPK{e} - tp(1)) ./r ));
        end
        
        [spk,spktm,~] = intersect(sdftm,x,'stable') ;
        sua = zeros(size(sdftm));
        
        if ~isempty(spk)
            psth = histc(spk,psthtm) .* (Fs/bin_sp);
            PSTH(e,psthtm<=diff(tp),i) = psth(psthtm<=diff(tp));
            
            sua(spktm) = 1;
            sdf = conv(sua,k,'same') * Fs/r;
        else
            sdf = sua;
        end
        sdf(sdftm > diff(tp/r)) = [];
        sua(spktm > diff(tp/r)) = [];  % testing - BM
        SDF(e,1:length(sdf),i) = sdf;
        SUA(e,1:length(sua),i) = sua;  % testing - BM
    end
    
    
    for w = 1:nwin
        % scaler value
        clear spk x
        spk = cellfun(@(x) sum(x>=rwin(w,1) & x<=rwin(w,2)),SPK) ;
        x = spk ./ (diff(rwin(w,:)) / Fs);
        x(empty) = NaN;
        RESP(:,w,i) = x;
    end
            
end % done iterating trials


% remove last bin (inf) and center time vector
if ~isempty(PSTH)
    PSTH(:,end,:) = [];
    psthtm(end) = [];
    psthtm = psthtm + bin_sp/2;
    % convert time vector to seconds
    psthtm = psthtm./Fs;
end

% convert time vector to seconds
sdftm = sdftm./(Fs/r);

% trim SDF of convolution extreams %MAY NEED DEV
trim = sdftm < -0.15 | sdftm > sdftm(end) -0.15;
sdftm(trim) = [];
SDF(:,trim,:) = [];
SUA(:,trim,:) = [];

% trim PSTH to match
if ~isempty(PSTH)
    trim = psthtm < -0.15 | psthtm > psthtm(end) -0.15;
    psthtm(trim) = [];
    PSTH(:,trim,:) = [];
end
