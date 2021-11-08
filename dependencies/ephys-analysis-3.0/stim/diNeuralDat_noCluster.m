function [RESP, win_ms, SDF, sdftm, PSTH, psthtm, SUA, spktm]= diNeuralDat_noCluster(STIM,datatype,flag_1kHz,win_ms)

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
    
    if i == 1 || STIM.filen(i) ~= filen 
        
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
            load([sortdir BRdatafile '/ss.mat'],'ss');
            for e=1:nel
                idx = find(STIM.units(e).fileclust(:,1) == filen); %% swapped from 2 to 1  - BM 6/15/20
                if isempty(idx)
                    empty(e) = true;
                else
                    clust = STIM.units(e).fileclust(idx,2); %% swapped from 1 to 2  - BM 6/15/20
                    SPK{e,1} = ss.spikeTimes(ismember(ss.spikeClusters,clust));
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
    rwin(stimoff)  = tp(2); 
    
    
            
            
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

% trim PSTH to match
if ~isempty(PSTH)
    trim = psthtm < -0.15 | psthtm > psthtm(end) -0.15;
    psthtm(trim) = [];
    PSTH(:,trim,:) = [];
end
