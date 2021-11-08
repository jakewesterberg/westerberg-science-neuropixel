%% bincontrast.m
% Loads in all ditask units. IDX is the info struct. UNIT and PEN contain
% data

clear
% choose dataset
dataset = 'diSTIM_4Levels_1';
datatype = 'kls';

% Setup directory for files of interest
if strcmp(getenv('username'),'mitchba2')
    didir = strcat('D:\dMUA\',dataset,'\');
elseif strcmp(getenv('username'),'bmitc')
    didir = strcat('C:\Users\bmitc\Documents\MATLAB\Data\',dataset,'\');
elseif strcmp(getenv('username'),'bmitc_000')
    didir = strcat('C:\Users\bmitc_000\Documents\MATLAB\Data\',dataset,'\');
end

% create a list of data files in the above directory
list = dir([didir '*_AUTO.mat']);


% Check to make sure that folder actually exists.  Warn user if it doesn't.
if ~isfolder(didir)
    errorMessage = sprintf('Error: The following folder does not exist:\n%s', myFolder);
    uiwait(warndlg(errorMessage));
    return;
end

% script choices
flag_save = 1;         % save the dataset?
baseline_correct = 1;  % baseline correct data?
normalize = 0;         % normalize data (0 to 1)
balanced = 1;          % balance the trial counts?
resp_type = 1;         % 1 is normal; 2 is shifted; 3 is based in RESP.matobj

% Counts
N = 0;
uct = 0;

% constants for all files
switch dataset
    case 'diSTIM_4Levels_1'
        sdfWin = -.150:.001:.450; % pre-defined window for all SDF
    case 'diSTIM_4Levels_2'
        sdfWin = -.150:.001:.250;
    case 'bincontrast'
        sdfWin = -.150:.001:.500;
    otherwise
        sdfWin = -.150:.001:.200;
end

tw = 1:length(sdfWin);

% RESP type
% the condensed neural response can have 4 windows or shifted windows
if resp_type == 1
    win_idx = [201 251; 301 501; 201 501; 101 151];
elseif resp_type == 2
    win_idx = [101 151; 201 251; 211 261; 221 271; 231 281; 241 291; 251 301; 261 311; 271 321; 281 331; 291 341; 301 351;...
        311 361; 321 371; 331 381; 341 391; 351 401; 361 411; 371 421; 381 431; 391 441; 401 451; 411 461; 421 471; 431 481; 441 491; 451 501; 201 501];
end

% Penetration Loop
for pen = 1:length(list)
    tic
    
    % Load penetration data
    clear penetration
    penetration = list(pen).name(1:11);
    
    load([didir penetration '.mat'],'STIM')
    matobj = matfile([didir penetration '_AUTO.mat']);
    
    win_ms = matobj.win_ms;
    if ~isequal(win_ms,[50 100; 150 250; 50 250; -50 0])
        warning('check RESP window')
    end
    
    N = N+1; % will have a running count of penetrations
    
    % Electrode Loop
    for e = 1:length(STIM.depths)
        uct = uct+1;
        
        % Task selection
        switch datatype
            case 'kls'
                goodtasks = STIM.units(e).fileclust(:,1);
            otherwise
                goodtasks = unique(STIM.filen);
        end
        
        % resp creation from SDF
        switch resp_type
            case 1
                sdf = squeeze(matobj.SDF(e,:,:));
                resp = nan(size(win_idx,1),size(sdf,2));
                for w = 1:size(win_idx,1)
                    resp(w,:) = nanmean(sdf(win_idx(w,1):win_idx(w,2),:),1);
                end
                resp = squeeze(bsxfun(@minus,resp(3,:), resp(4,:)))';% baseline corrects resp(3) by resp(4)
            case 2
                sdf = squeeze(matobj.SDF(e,:,:));
                resp = nan(size(win_idx,1),size(sdf,2));
                for w = 1:size(win_idx,1)
                    resp(w,:) = nanmean(sdf(win_idx(w,1):win_idx(w,2),:),1);
                end
                resp = squeeze(bsxfun(@minus,resp(end,:), resp(1,:)))';% baseline corrects resp(3) by resp(4)
            otherwise
                resp = squeeze(matobj.RESP(e,:,:)); % pulls out matobj RESP, (e x time x trial)
                resp = squeeze(bsxfun(@minus,resp(3,:), resp(4,:)))';% baseline corrects resp(3) by resp(4)
        end
        
        % Unit Tuning. Decide DE, NDE, PS, and NS
        try 
        X = diUnitTuning(resp,STIM,goodtasks); %get tuning info for the unit
        catch
            warning('diUnitTuning failed for unit %d',e)
            continue
        end
        
        DE = X.dipref(1); % preferred eye
        NDE = X.dinull(1); % non-preferred ete
        PS = X.dipref(2); % preferred stimulus
        NS = X.dinull(2); % null stimulus
        
        if isnan(DE) || isnan(NDE) || isnan(PS) || isnan(NS)
            warning('DiUnitTuning passed for unit %d, but produced NaNs',e)
            continue
        end
        
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
       
        
        % establish constant conditions
        I = STIM.ditask ...
            & STIM.adapted == 0 ... %is not adapted
            & STIM.rns == 0 ... %not random noise stimulus
            & STIM.cued == 0 ... %not cued or uncued
            & STIM.motion == 0 ... %not moving
            & ismember(STIM.filen,goodtasks); % things that should be included.
        
        % pull out the data for single electrode
        clear sdf sdftm resp
        sdftm =  matobj.sdftm;
        sdf   = squeeze(matobj.SDF(e,:,:)); % load only the channel of interest from matobj
        
        switch resp_type
            case 1
                for w = 1:size(win_idx,1) % for each resp window
                    resp(w,:) = nanmean(sdf(win_idx(w,1):win_idx(w,2),:),1); % take the average of each window and place in resp variable
                end
            case 2
                for w = 1:size(win_idx,1) % for each resp window
                    resp(w,:) = nanmean(sdf(win_idx(w,1):win_idx(w,2),:),1); % take the average of each window and place in resp variable
                end
            otherwise
                resp = squeeze(matobj.RESP(e,:,:));
        end
        
        if baseline_correct == true
            sdf   = bsxfun(@minus,sdf, mean(sdf(101:151,:),1)); % this is -.50 to 0
            resp  = bsxfun(@minus,resp, resp(end,:)); % resp 4 is already the mean -.50 to 0
        end
        
        % Define stimulus levels for this unit
        stimcontrast = [0 X.dicontrasts]; % 0 and all contrast levels
        numC = length(stimcontrast);
        
        
        %% Pull out data by binocular condition, one contact at a time
        
        % pre-allocate
        clear binSDF binSDFerror binRESP binRESPerror binTrlNum
        bincond     = {'PS','NS'}; % PS = Preferred stimulus; NS = Null stimulus
        binSDF     = nan(numC,length(tw),2); % contrast x time x condition (PS or NS)
        binSDFerror   = nan(numC, length(tw),2); % contrast x time x condition
        binRESP    = nan(numC,size(resp,1),2); % contrast x timewindow x condition
        binRESPerror  = nan(numC,size(resp,1),2); % contrast x time x condition
        binTrlNum     = nan(4,2); % contrast x condition
        
        for bin = 1:size(bincond,2) % for each binocular condition
            for c = 1:length(stimcontrast) % for each contrast level
                switch bincond{bin}
                    case 'PS'
                        if c == 1
                            trls = STIM.blank;
                        else
                            trls = I & STIM.botheyes... % should this be STIM.dioptic?
                                & contrasts(:,1) == stimcontrast(c)... % contrast in dom eye
                                & contrasts(:,2) == stimcontrast(c)... % contrast in null eye
                                & tilts(:,1) == X.dipref(2)... % pref orientation in dom eye
                                & tilts(:,2) == X.dipref(2); 
                        end
                    case 'NS'
                        if c == 1
                            trls = STIM.blank;
                        else
                            trls = I & STIM.botheyes...
                                & contrasts(:,1) == stimcontrast(c)... % contrast in dom eye
                                & contrasts(:,2) == stimcontrast(c)... % contrast in null eye
                                & tilts(:,1) == X.dinull(2)... % null orientation in dom eye
                                & tilts(:,2) == X.dinull(2); % null orientation in null eye
                        end
                end
                
                if sum(trls) >= 5
                    binSDF(c,:,bin)   = nanmean(sdf(tw,trls),2);
                    binSDFerror(c,:,bin)   = (nanstd(sdf(tw,trls),0,2))./(sqrt(sum(trls)));
                    binRESP(c,:,bin)    = nanmean(resp(:,trls),2);
                    binRESPerror(c,:,bin)   = (nanstd(resp(:,trls),0,2))./(sqrt(sum(trls)));
                else
                    binSDF(c,:,bin)   = nan(size(tw,2),1);
                    binSDFerror(c,:,bin)   = nan(size(tw,2),1);
                end
                
                binTrlNum(c,bin) = sum(trls);
                Trls.bin(c,bin,pen) = sum(trls);
            end
        end
        
        % Organize the unit responses into UNIT struct
        if normalize == true
            for cond = 1:size(bincond,2)
                temp.BIN.(bincond{cond}).SDF = []; % placeholder
                temp.BIN.(bincond{cond}).RESP = []; % placeholder
            end
        else
            for cond = 1:size(bincond,2)
                UNIT.BIN.(bincond{cond}).SDF(:,:,uct) = binSDF(:,:,cond);
                UNIT.BIN.(bincond{cond}).SDF_error(:,:,uct) = binSDFerror(:,:,cond);
                UNIT.BIN.(bincond{cond}).RESP(:,:,uct)  = binRESP(:,:,cond);
                UNIT.BIN.(bincond{cond}).RESP_error(:,:,uct)  = binRESPerror(:,:,cond);
            end          
        end
        
        % Organize the conditions in PEN struct to isolate by penetration
        for cond = 1:size(bincond,2)
            PEN(pen).BIN.(bincond{cond}).SDF(:,:,e) = binSDF(:,:,cond);
            PEN(pen).BIN.(bincond{cond}).SDF_error(:,:,e) = binSDFerror(:,:,cond);
            PEN(pen).BIN.(bincond{cond}).RESP(:,:,e)  = binRESP(:,:,cond);
            PEN(pen).BIN.(bincond{cond}).RESP_error(:,:,e)  = binRESPerror(:,:,cond);
        end
        
        clear bin trls c
        
        %% Monocular data
        
        % pre-allocate data matrices
        clear moncond monSDF monSDFerror monRESP monRESPerror monTrlNum
        moncond     = {'DE_PS','NDE_PS','DE_NS','NDE_NS'};
        monSDF     = nan(numC,length(tw),4);  % contrast x time x condition
        monSDFerror   = nan(numC, length(tw),4); % contrast x time x condition
        monRESP    = nan(numC,4,4); % contrast x timewindow x condition
        monRESPerror  = nan(numC,4,4); % contrast x timewindow x condition
        monTrlNum     = nan(numC,4);  % contrast x condition
        
        for mon = 1:size(moncond,2) % for each condition
            for c = 1:length(stimcontrast) % for each contrast level
                switch moncond{mon}
                    case 'DE_PS'
                        if c == 1
                            trls = STIM.blank; % zero contrast in both eyes
                        else
                            trls = I & STIM.monocular & DE... % is monocular and dominant eye
                                & contrasts(:,1) == stimcontrast(c)... % contrast in dom eye
                                & tilts(:,1) == X.dipref(2); % pref orientation in dom eye
                        end
                        
                        if balanced == true
                            n = binTrlNum(c,1); % number of trials to keep
                            f = find(trls); % find the location of the logical 1's in monocular trials
                            f = f(randperm(numel(f))); % randomize the find results
                            trls(f(n+1:end)) = false; % get rid of the other trials beyond the random n
                        end
                        
                    case 'NDE_PS'
                        if c == 1
                            trls = STIM.blank;
                        else
                            trls = I & STIM.monocular & NDE...  % is monocular and non-dominant eye
                                & contrasts(:,2) == stimcontrast(c) ... % contrast in non-dom eye
                                & tilts(:,2) == X.dipref(2); % pref orientation in non-dom eye
                        end
                        
                        if balanced == true
                            n = binTrlNum(c,1); % number of trials to keep
                            f = find(trls); % find the location of the logical 1's in monocular trials
                            f = f(randperm(numel(f))); % randomize the find results
                            trls(f(n+1:end)) = false; % get rid of the other trials beyond the random n
                        end
                        
                    case 'DE_NS'
                        if c == 1
                            trls = STIM.blank;
                        else
                            trls = I & STIM.monocular & DE... % is monocular and DE
                                & contrasts(:,1) == stimcontrast(c)... % contrast in dom eye
                                & tilts(:,1) == X.dinull(2); % pref orientation in dom eye
                        end
                        
                        if balanced == true
                            n = binTrlNum(c,2); % number of trials to keep
                            f = find(trls); % find the location of the logical 1's in monocular trials
                            f = f(randperm(numel(f))); % randomize the find results
                            trls(f(n+1:end)) = false; % get rid of the other trials beyond the random n
                        end
                        
                    case 'NDE_NS'
                        if c == 1
                            trls = STIM.blank;
                        else
                            trls = I & STIM.monocular & NDE...
                                & contrasts(:,2) == stimcontrast(c)... % contrast in dom eye
                                & tilts(:,2) == X.dinull(2); % pref orientation in dom eye
                        end
                        
                        if balanced == true
                            n = binTrlNum(c,2); % number of trials to keep
                            f = find(trls); % find the location of the logical 1's in monocular trials
                            f = f(randperm(numel(f))); % randomize the find results
                            trls(f(n+1:end)) = false; % get rid of the other trials beyond the random n
                        end
                end
                
                % pass if trial numbers are greater than 4
                if sum(trls) >= 5
                    monSDF(c,:,mon)   = nanmean(sdf(tw,trls),2);
                    monSDFerror(c,:,mon)   = (nanstd(sdf(tw,trls),0,2))./(sqrt(sum(trls)));
                    monRESP(c,:,mon)    = nanmean(resp(:,trls),2);
                    monRESPerror(c,:,mon)   = (nanstd(resp(:,trls),0,2))./(sqrt(sum(trls)));
                end
                monTrlNum(c,mon) = sum(trls); % stores trial count by contrast and condition
                Trls.mon(c,mon,pen) = sum(trls); % stores trial count by contrast, condition, and penetration
            end
        end
        
        % Organize the unit responses into UNIT struct
        try
            for cond = 1:size(moncond,2)
                UNIT.MON.(moncond{cond}).SDF(:,:,uct) = monSDF(:,:,cond);
                UNIT.MON.(moncond{cond}).SDF_error(:,:,uct) = monSDFerror(:,:,cond);
                UNIT.MON.(moncond{cond}).RESP(:,:,uct)  = monRESP(:,:,cond);
                UNIT.MON.(moncond{cond}).RESP_error(:,:,uct)  = monRESPerror(:,:,cond);
            end
        catch
            warning('Incoming units have more or fewer contrast levels')
            disp('Some responses could not be placed into the UNIT struct');
        end
        
        % Organize the unit responses by penetration
        for cond = 1:size(moncond,2)
            PEN(pen).MON.(moncond{cond}).SDF(:,:,e) = monSDF(:,:,cond);
            PEN(pen).MON.(moncond{cond}).SDF_error(:,:,e) = monSDFerror(:,:,cond);
            PEN(pen).MON.(moncond{cond}).RESP(:,:,e)  = monRESP(:,:,cond);
            PEN(pen).MON.(moncond{cond}).RESP_error(:,:,e)  = monRESPerror(:,:,cond);
        end

        clear trls mon c cond
        
        %% Dichoptic conditions
        
        clear diSDF diRESP diRESPerror diSDFerror diTrlNum
        dicontrast = combvec(stimcontrast,stimcontrast)';
        dicond     = {'PS','NS'};
        diSDF     = nan(size(dicontrast,1), length(tw),2);
        diSDFerror   = nan(size(dicontrast,1), length(tw),2);
        diRESP    = nan(size(dicontrast,1),4,2);
        diRESPerror  = nan(size(dicontrast,1),4,2);
        diTrlNum     = nan(size(dicontrast,1),2);
        
        for di = 1:size(dicond,2)
            for c = 1:length(dicontrast)
                switch dicond{di}           % Find the trials you want to look at
                    case 'PS'
                        if c == 1
                            trls = STIM.blank;
                        else
                            if dicontrast(c,2) == 0
                                trls = I & STIM.monocular...
                                    & contrasts(:,1) == dicontrast(c,1)... % contrast in dom eye
                                    & tilts(:,1) == PS; % pref orientation in dom eye
                            elseif dicontrast(c,1) == 0
                                trls = I & STIM.monocular...
                                    & contrasts(:,2) == dicontrast(c,2)... % contrast in NDE
                                    & tilts(:,2) == PS; % pref orientation in NDE
                            else
                                trls = I ...
                                    & contrasts(:,1) == dicontrast(c,1)... % contrast in DE
                                    & contrasts(:,2) == dicontrast(c,2)... % contrast in NDE
                                    & tilts(:,1) == PS... % pref orientation in DE
                                    & tilts(:,2) == PS;  % pref orientation in NDE
                            end
                        end
                    case 'NS'
                        if c == 1
                            trls = STIM.blank;
                        else
                            if dicontrast(c,2) == 0
                                trls = I & STIM.monocular...
                                    & contrasts(:,1) == dicontrast(c,1)... % contrast in dom eye
                                    & tilts(:,1) == NS; % pref orientation in dom eye
                            elseif dicontrast(c,1) == 0
                                trls = I & STIM.monocular...
                                    & contrasts(:,2) == dicontrast(c,2)... % contrast in NDE
                                    & tilts(:,2) == NS; % pref orientation in NDE
                            else
                                trls = I ...
                                    & contrasts(:,1) == dicontrast(c,1)... % contrast in DE
                                    & contrasts(:,2) == dicontrast(c,2)... % contrast in NDE
                                    & tilts(:,1) == NS... % pref orientation in DE
                                    & tilts(:,2) == NS;  % pref orientation in NDE
                            end
                        end
                end
                
                if sum(trls) >= 5
                    diSDF(c,:,di)   = nanmean(sdf(tw,trls),2);
                    diSDFerror(c,:,di)   = (nanstd(sdf(tw,trls),0,2))./(sqrt(sum(trls)));
                    diRESP(c,:,di)    = nanmean(resp(:,trls),2);
                    diRESPerror(c,:,di)   = (nanstd(resp(:,trls),0,2))./(sqrt(sum(trls)));
                else
                    diSDF(c,:,di)   = nan(size(tw,2),1);
                    diSDFerror(c,:,di)   = nan(size(tw,2),1);
                end
                
                diTrlNum(c,di) = sum(trls);
                Trls.di(c,di,pen) = sum(trls);
            end
        end
        
        % Organize the conditions into UNIT struct
        % This is outside the above forloop to transfer the nan logic safely
        try
            for cond = 1:size(dicond,2)
                UNIT.DI.(dicond{cond}).SDF(:,:,uct) = diSDF(:,:,cond);
                UNIT.DI.(dicond{cond}).SDF_error(:,:,uct) = diSDFerror(:,:,cond);
                UNIT.DI.(dicond{cond}).RESP(:,:,uct)  = diRESP(:,:,cond);
                UNIT.DI.(dicond{cond}).RESP_error(:,:,uct)  = diRESPerror(:,:,cond);
            end
        catch
        end
        
        % Organize the conditions in PEN struct to isolate by penetration
        for cond = 1:size(dicond,2)
            PEN(pen).DI.(dicond{cond}).SDF(:,:,e) = diSDF(:,:,cond);
            PEN(pen).DI.(dicond{cond}).SDF_error(:,:,e) = diSDFerror(:,:,cond);
            PEN(pen).DI.(dicond{cond}).RESP(:,:,e)  = diRESP(:,:,cond);
            PEN(pen).DI.(dicond{cond}).RESP_error(:,:,e)  = diRESPerror(:,:,cond);
        end
        clear trls c di
        
        %% SAVE UNIT in dMUA structure
        
        IDX(uct).penetration = STIM.penetration;
        IDX(uct).v1lim = STIM.v1lim;
        if contains('kls',datatype)
            IDX(uct).depth = STIM.units(e).depth';  % This could use some sorting by depth
            IDX(uct).wave = STIM.units(e).wave;
        else
            IDX(uct).depth = STIM.depths(e,:)';
        end
        IDX(uct).depth = STIM.depths(e,:)';
        
        IDX(uct).prefeye    = DE;
        IDX(uct).prefori    = PS;
        IDX(uct).nulleye    = NDE;
        IDX(uct).nullori    = NS;
        IDX(uct).effects     = X.dianp; % p for main effect of each 'eye' 'tilt' 'contrast'
        
        IDX(uct).X      =   X;
        
        IDX(uct).occana       = X.occana;
        IDX(uct).oriana       = X.oriana;
        IDX(uct).diana        = X.diana;
        
        
        IDX(uct).occ   = X.occ';    % how much it prefers one eye over the other
        IDX(uct).ori   = X.ori';    % how much it prefers one orientation over the other
        IDX(uct).bio   = X.bio';    % How much it prefers both eyes over one
        
        IDX(uct).SDFlength     = length(matobj.sdftm);
        IDX(uct).monLevels     = stimcontrast;
        IDX(uct).diLevels      = dicontrast;
        IDX(uct).monTrials     = monTrlNum;
        IDX(uct).binTrials     = binTrlNum;
        IDX(uct).diTrials      = diTrlNum;
        IDX(uct).exactTrials   = [sum(monTrlNum(2:end,:),'all'),...
            sum(binTrlNum(2:end,:),'all'),...
            sum(diTrlNum,'all')-...
            (sum(monTrlNum(2:end,:),'all')+sum(binTrlNum(2:end,:),'all'))]; % sum of di minus bin and mon
        IDX(uct).Total  = sum(IDX(uct).diTrials(:,:),'all');
          
        toc
    end
    
    clear I L lf bf mf layers STIM
end

clearvars -except sdfWin Trls PEN IDX UNIT flag_save addAnalyses N uct dataset

IDX( all( cell2mat( arrayfun( @(x) structfun( @isempty, x ), IDX, 'UniformOutput', false ) ), 1 ) ) = [];


%% SAVE
% Need to save workspace

if flag_save == true
    if strcmp(getenv('username'),'mitchba2')
        cd('C:/users/mitchba2/Documents/MATLAB/workspace/');
    elseif strcmp(getenv('username'),'bmitc')
        cd('C:/Users/bmitc/Documents/MATLAB/workspaces/');
    elseif strcmp(getenv('username'),'bmitc_000')
        cd('C:/Users/bmitc_000/Documents/MATLAB/workspaces/');
    end
    save(sprintf('dMUA_%s',dataset),'IDX','UNIT','PEN','Trls','N','uct','sdfWin','dataset');
    try
        cd('D:\')
        save(sprintf('dMUA_%s',dataset),'IDX','UNIT','PEN','Trls','N','uct','sdfWin','dataset');
    catch
        disp('No external drive detected');
    end
    fprintf('Workspace saved\n');
end

fprintf('Complete\n');
