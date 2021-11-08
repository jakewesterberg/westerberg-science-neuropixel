%% IDX_Tuning.m 
% Loads in ditask units. IDX is the info struct. UNIT and PEN contain data
% Author: Blake M
% Release: 7-17-20

clear

% choose dataset
dataset = 'kls_test';
datatype = 'kls';
tuning  = 'ori';

% diSTIM_allLevels_2 - best so far

% Setup directory for files of interest
if strcmp(getenv('username'),'mitchba2')
    didir = strcat('D:\dMUA\',dataset,'\');
elseif strcmp(getenv('username'),'bmitc')
    didir = strcat('C:\Users\bmitc\Documents\MATLAB\Data\',dataset,'\');
elseif strcmp(getenv('username'),'bmitc_000')
    didir = strcat('C:\Users\bmitc_000\Documents\MATLAB\Data\',dataset,'\');
end

% create a list of data files in the above directory
list    = dir([didir '*_',upper(datatype),'.mat']);

% Check to make sure that folder actually exists.  Warn user if it doesn't.
if ~isfolder(didir)
    errorMessage = sprintf('Error: The following folder does not exist:\n%s', myFolder);
    uiwait(warndlg(errorMessage));
    return;
end

% script choices
flag_save = 0;
flag_addbaseline = 0;
baseline_correct = 0;

% Counts
N = 0;
uct = 0;

% constants for all files
switch dataset
    case {'diSTIM_4Levels_1'}
        sdfWin = -.150:.001:.500; % pre-defined window for all SDF
    otherwise
        sdfWin = -.150:.001:.250;
end

tw = 1:length(sdfWin);
win_idx = [201 251; 301 501; 201 501; 101 151];


% Penetration Loop
for pen = 1:length(list)
    tic
    
    % Load penetration data
    clear penetration
    penetration = list(pen).name(1:11);
    
    load([didir penetration '.mat'],'STIM')
    matobj = matfile([didir penetration '_',upper(datatype),'.mat']);

    N = N+1; % will have a running count of penetrations
    
    % Electrode Loop
    for e = 1:length(STIM.units) % this has to change for kls data
        uct = uct+1;
    
        % pull out the data for single electrode
        clear sdf sdftm resp psth
        sdftm =  matobj.sdftm;
        psthtm =  matobj.psthtm;
        sdf   = squeeze(matobj.SDF(e,:,:)); 
        psth = squeeze(matobj.PSTH(e,:,:));  
        resp = squeeze(matobj.RESP(e,:,:)); 
        
        if strcmp('kls',datatype)
            sua = squeeze(matobj.SUA(e,:,:));
        end
        
        if baseline_correct == true
            sdf   = bsxfun(@minus,sdf, mean(sdf(101:151,:),1)); % this is -.50 to 0
            resp  = bsxfun(@minus,resp, resp(4,:)); % resp 4 is the mean -.50 to 0
        end
        
        %% Task Selection
        
        goodtasks = STIM.units(e).fileclust(:,1);
 
        % establish constant conditions
 
        I = STIM.adapted == 0 ...           % is not adapted
            & STIM.cued == 0 ...              % not cued or uncued
            & STIM.motion == 0;               % not moving
               
        %% Switch case
        % size, spatial frequency, or orientation
        switch tuning
            case 'size'  %% Size Tuning
                clear tuningtasks
                tuningtasks = find(strcmp(STIM.paradigm,'rfsize'));
                sizes = nanunique(STIM.diameter(1:59));
                numSizes = length(sizes);
                
                % pre-allocate
                clear SDF SDFerror RESP RESPerror TrlNum
                
                SDF     = nan(numSizes,length(tw));  % sizes x time
                SDFerror   = nan(numSizes, length(tw)); % sizes x time
                RESP    = nan(numSizes,size(resp,1)); % sizes x timewindow
                RESPerror  = nan(numSizes,size(resp,1)); % sizes x timewindow
                TrlNum     = nan(numSizes);  % sizes
                
                for i = 1:length(sizes) % for each size
                    trls = I & ismember(STIM.filen,tuningtasks) ...
                        & STIM.rns... % is rns
                        & STIM.diameter == sizes(i);
                    
                    SDF(i,:)   = nanmean(sdf(tw,trls),2);
                    SDFerror(i,:)   = (nanstd(sdf(tw,trls),0,2))./(sqrt(sum(trls)));
                    RESP(i,:)    = nanmean(resp(:,trls),2);
                    RESPerror(i,:)   = (nanstd(resp(:,trls),0,2))./(sqrt(sum(trls)));

                    TrlNum(i) = sum(trls);
                    Trls.size(i,pen) = sum(trls); % stores trial count by contrast, condition, and penetration
                    
                    SUA(uct).size{i}  = sua(tw,trls);
                end
                
                % Organize the unit responses into UNIT struct
                try
                    UNIT.(datatype).size.SDF(:,:,uct) = szSDF;
                    UNIT.(datatype).size.SDF_error(:,:,uct) = szSDFerror;
                    UNIT.(datatype).size.RESP(:,:,uct)  = szRESP;
                    UNIT.(datatype).size.RESP_error(:,:,uct)  = szRESPerror;
                    
                catch
                    warning('Incoming units have more or fewer features')
                    disp('They could not be placed into the UNIT struct');
                end
                
                clear trls i
                
                
            case 'sf' % Spatial frequency tuning
                sfs = nanunique(STIM.sf);
                numSfs = length(sfs);
                tuningtasks = find(strcmp(STIM.paradigm,'rfsf'));
                
                % pre-allocate
                clear SDF SDFerror RESP RESPerror TrlNum
                
                sfSDF     = nan(numSfs,length(tw));  % sizes x time
                sfSDFerror   = nan(numSfs, length(tw)); % sizes x time
                sfRESP    = nan(numSfs,size(resp,1)); % sizes x timewindow
                sfRESPerror  = nan(numSfs,size(resp,1)); % sizes x timewindow
                sfTrlNum     = nan(numSfs);  % sizes
                
                for s = 1:length(sfs) % for each size
                    trls = I & ismember(STIM.filen,tuningtasks) ...
                        & STIM.sf == sfs(s);
                    
                    sfSDF(s,:)   = nanmean(sdf(tw,trls),2);
                    sfSDFerror(s,:)   = (nanstd(sdf(tw,trls),0,2))./(sqrt(sum(trls)));
                    sfRESP(s,:)    = nanmean(resp(:,trls),2);
                    sfRESPerror(s,:)   = (nanstd(resp(:,trls),0,2))./(sqrt(sum(trls)));
                
                    TrlNum(i) = sum(trls);
                    Trls.sf(i,pen) = sum(trls); % stores trial count by contrast, condition, and penetration
                    
                    SUA(uct).sf{i}  = sua(tw,trls);
                end
   
                % Organize the unit responses into UNIT struct
                
                try
                    UNIT.sf.SDF(:,:,uct) = sfSDF;
                    UNIT.sf.SDF_error(:,:,uct) = sfSDFerror;
                    UNIT.sf.RESP(:,:,uct)  = sfRESP;
                    UNIT.sf.RESP_error(:,:,uct)  = sfRESPerror;
                    
                catch
                    warning('Incoming units have more or fewer contrast levels')
                    disp('They could not be placed into the UNIT struct');
                end
       
            case 'ori' % Orientation Tuning
                clear tuningtasks
                tuningtasks = find(strcmp(STIM.paradigm,'rfori'));
                oris = nanunique(STIM.tilt);
                numOris = length(oris);
                
                % pre-allocate
                SDF     = nan(numOris,length(tw));  % sizes x time
                SDFerror   = nan(numOris, length(tw)); % sizes x time
                RESP    = nan(numOris,size(resp,1)); % sizes x timewindow
                RESPerror  = nan(numOris,size(resp,1)); % sizes x timewindow
                TrlNum     = nan(numOris);  % sizes
                
                for t = 1:length(oris) % for each size
                    trls = I & ismember(STIM.filen,goodtasks) ...
                        & STIM.tilt(:,1) == oris(t);
                    
                    SDF(t,:)   = nanmean(sdf(tw,trls),2);
                    SDFerror(t,:)   = (nanstd(sdf(tw,trls),0,2))./(sqrt(sum(trls)));
                    RESP(t,:)    = nanmean(resp(:,trls),2);
                    RESPerror(t,:)   = (nanstd(resp(:,trls),0,2))./(sqrt(sum(trls)));
                    
                    TrlNum(t) = sum(trls);
                    Trls.ori(t,pen) = sum(trls); % stores trial count by contrast, condition, and penetration
                    
                    SUA(uct).ori{t}  = sua(tw,trls);
                end
                
                % Organize the unit responses into UNIT struct
                try
                    UNIT.(datatype).ori.SDF(:,:,uct) = oriSDF;
                    UNIT.(datatype).ori.SDF_error(:,:,uct) = oriSDFerror;
                    UNIT.(datatype).ori.RESP(:,:,uct)  = oriRESP;
                    UNIT.(datatype).ori.RESP_error(:,:,uct)  = oriRESPerror;
                    
                catch
                    warning('Incoming units have more or fewer orientations')
                    disp('They could not be placed into the UNIT struct');
                end
                
                % Determine Neuron's Orientation Tuning (exclusive to rfori)
                X.oriana = false;
                X.ori(1,1:14) = NaN;
                
                clear trls TRLS
                trls = I & ismember(STIM.filen,goodtasks);
                TRLS = find(trls);
                
                if ~isempty(TRLS)
                    % test for a significant main effect of tilt, also find theta
                    tilt_p = anovan(resp(1,TRLS),STIM.tilt(TRLS),'display','off');
                    [u,theta] = grpstats(resp(1,TRLS),STIM.tilt(TRLS),{'mean','gname'});
                    theta = str2double(theta);
                    % find peak theta
                    clear mi peak
                    [~,mi]=max(u);
                    peak = theta(mi);
                    % reshape data so that peak is in middle
                    clear x y grange
                    x = wrapTo180([theta-peak theta-peak+180]);
                    y = [u u];
                    grange = find(x >= -90  & x <= 90) ;
                    x = x(grange); y = y(grange);
                    [x,idx] = sort(x); y = y(idx);
                    
                    % remove nan (helps with fitting)
                    x(isnan(y)) = []; y(isnan(y)) = [];
                    if ~isempty(y)
                        if length(y) > 5
                            % fit x and y with gauss, save gauss params
                            clear gparam
                            [gparam,gerror] = gaussianFit(x,y,false); % gparam = mu sigma A
                            X.ori(1,1:8) = [tilt_p peak real(gparam') real(gerror')];
                            % fit x and y with gauss2:
                            %   f(x) =  a1*exp(-((x-b1)/c1)^2) + a2*exp(-((x-b2)/c2)^2)
                            if length(y) > 6
                                f = fit(x,y,'gauss2');
                                X.ori(1,9:end) = [f.b1 f.c1 f.a1 f.b2 f.c2 f.a2]; %  mu sigma A
                            end
                        else
                            % cannot fig gaus, but save peak
                            X.ori(1,1:2) = [tilt_p peak];
                        end
                        
                        % signal that oriana happened
                        X.oriana = true;
                    end
                end  % end if TRLS is empty
                
        end
        
% g1 = find(SUA(3).MON.DE_PS{1,4}(:,1)==1);
% g2 = diff(g1);
% g3 = g2/30;
 
        %% SAVE UNIT in IDX structure
        
        IDX(uct).penetration    = STIM.penetration;
        IDX(uct).v1lim          = STIM.v1lim;
        IDX(uct).depth          = STIM.units(e).depth';  % This could use some sorting by depth
        IDX(uct).wave           = STIM.units(e).wave;
        IDX(uct).SDFlength      = length(matobj.sdftm);
        
        switch tuning
            case 'ori'
                IDX(uct).oris             = oris;
                IDX(uct).X                = X;
                IDX(uct).orituning        = [x,y];
                IDX(uct).oriFit          = f;
                IDX(uct).oriTrials        = TrlNum;
                
            case 'size'
                IDX(uct).sizes           = sizes;
                IDX(uct).szTrials        = TrlNum;
                
            case 'sf'
                IDX(uct).sfs             = sfs;
                IDX(uct).sfTrials        = TrlNum;
        end

        toc
    end
    
end

%%
clearvars -except sdfWin Trls PEN IDX UNIT SUA flag_save balanced normalize baseline_correct N uct dataset cbins tuning

% get rid of empty rows

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
save(sprintf('%s_workspace',dataset),'IDX','UNIT','PEN','Trls','balanced','normalize','baseline_correct','N','uct','sdfWin','dataset','datatype');
    try 
    cd('D:\')
    save(sprintf('%s_workspace',dataset),'IDX','UNIT','PEN','Trls','balanced','normalize','baseline_correct','N','uct','sdfWin','dataset','datatype');
    catch
    disp('No external drive detected');
    end
fprintf('Workspace saved\n');
end

fprintf('Complete\n');
