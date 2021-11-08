function STIM = diTP(filelist,V1)

% remeber, this reverses the eyes

okparadigms = {...
    'rfori',        '.gRFORIGrating_di';...
    'rfsf',         '.gRFSFGrating_di';...
    'rfsize',       '.gRFSIZEGrating_di';...
    'drfori',       '.gRFORIDRFTGrating_di';...
    'cosinteroc',   '.gCOSINTEROCGrating_di';...
    'mcosinteroc',  '.gMCOSINTEROCGrating_di';...
    'bminteroc',    '.gBMINTEROCGrating_di';...
    'dmcosinteroc', '.gMCOSINTEROCDRFTGrating_di';...
    'brfs',         '.gBrfsGratings';...
    'dbrfs',        '';...
    'rsvp',         '.gCue_di';...
    'rfsfdrft',     '.gRFSFDRFTGrating_di'};


mainstimfeatures = {...
    'eye',...
    'contrast',...
    'tilt',...
    'sf',...
    'phase',... for my data, phase never changed between the eyes :-(
    'soa',...
    'motion',...
    'tf',...
    'xpos',...
    'ypos',...
    'diameter',...
    'gabor',...
    'timestamp'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% sort filelist in time, check for BR files on disk
clear T I
for j = 1:length(filelist)
    clear NS_header filename
    filename = filelist{j};
    NS_header = openNSx([filename '.ns2'],'noread');
    if ~isstruct(NS_header) && NS_header == -1
        error('check disk for %s',filename)
    end
    T(j) = datenum(NS_header.MetaTags.DateTime,'dd-mmm-yyyy HH:MM:SS');
end
[~,I]=sort(T);
filelist = filelist(I);
filetime = datestr(T');
clear I NS_header filename T

% determin paradigm, check for grating text files on disk
clear paradigm extension
for j = 1:length(filelist)
    [~,BRdatafile,~] = fileparts(filelist{j});
    
    paradigm{j,:} = BRdatafile(10:end-3);
    idx = strcmp(okparadigms(:,1), paradigm{j,:});
    
    if ~any(idx) || strcmp(okparadigms{idx,2},'');
        error('check filelist for %s',filelist{j})
    elseif ~exist([filelist{j},okparadigms{idx,2}],'file')
        error('cannot find text file: %s',[filelist{j},okparadigms{idx,2}])
    else
        extension{j,:} = okparadigms{idx,2};
    end
    clear BRdatafile
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fpath            = fileparts(filelist{1});
STIM.header      = fpath(end-7:end);

obs = 0;
for j = 1:length(filelist)
    
    % NEV
    clear NEV Fs
    NEV = openNEV(strcat(filelist{j},'.nev'),'noread','nosave','nomat');
    Fs = double(NEV.MetaTags.TimeRes);
    
    % Event Codes from NEV
    clear EventCodes EventSampels pEvC pEvT
    EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
    EventSampels = NEV.Data.SerialDigitalIO.TimeStamp;
    [pEvC, pEvT] = parsEventCodesML(EventCodes,EventSampels);
    
    % stimulus text file
    clear grating
    switch paradigm{j}
        
        case 'bmcBRFS'
            % BRock will need to create a custom readBRFS function for his
            % task. 
        case 'brfs'
            grating    = readBRFS([filelist{j} extension{j}]);
            idx = (strcmp(grating.stim,'Monocular'));
            if ~all(grating.soa(idx) == 0)
                error('not all monocular prez are SOA = 0')
            end
            
        case {'rfori', 'rfsf', 'rfsize','cosinteroc','mcosinteroc','bminteroc'} % my task should go here 
            grating = readgGrating([filelist{j} extension{j}]);
            
        case {'drfori','rfsfdrft','dmcosinteroc'}
            grating = readgDRFTGrating([filelist{j} extension{j}]);
            
        case {'rsvp'} %see getRsvpTPs
            [~,BRdatafile,~] = fileparts(filelist{j});
            type = getRSVPTaskType(BRdatafile(1:6));
            if strcmp('ori',type)
                continue
            end
            paradigm{j,:} = ['rsvp_' type];
            
            % load behavoral data and stimulus info
            clear cue cuedD cuedS uncuedD uncuedS targetD rsvp_ln bhv isCueValid
            [cue, cuedD, cuedS, uncuedD, uncuedS, targetD, ~, rsvp_ln] = loadRSVPdata(fpath,BRdatafile);
            if rsvp_ln ~= 1
                error('rsvp ln > 1')
            end
            bhv = concatBHV([filelist{j} '.bhv']);
            isCueValid = (cue.grating_theta(1:2:end) == targetD.grating_theta);
            
        otherwise
            error('need to specify extention for %s', paradigm{j})
    end
    
    % check that all is good between NEV and grating text file;
    switch paradigm{j,:}
        case {'rsvp_color' 'rsvp_redun'}; 
            [allpass, message] =  checkTrMatch(cuedD,NEV);
            n = length(cuedD.trial);
            grating.trial = cuedD.trial;
            grating.pres = cuedD.pres;
            grating.timestamp = cuedD.timestamp;
            
        otherwise
            n = length(grating.trial);
            [allpass, message] =  checkTrMatch(grating,NEV); % 2021 problems arise here when we don't have the event code sequencing triplets OR ML and BR timestamp misalignment
    end
    if ~allpass  % BM, 10/14/2021 -- Commenting this check out as a test.
    
        allpass
        message
        %error('Not all pass')
        warning('Not all checks passed for checkTrMatch.m');
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % general post-processing of grating structure
    gratingfields = fieldnames(grating);
    if any(strcmp(gratingfields,'motion'))
        grating.motion(grating.motion==0) = -1;
    end
    if any(strcmp(gratingfields,'temporal_freq'))
        grating.tf     = grating.temporal_freq;
        grating        = rmfield(grating,'temporal_freq');
    end
    
    gratingfields = fieldnames(grating);
    nonmatching = setdiff(mainstimfeatures,gratingfields);
    for nm = 1:length(nonmatching)
        switch nonmatching{nm}
            case {'motion','tf'}
                grating.(nonmatching{nm})   = zeros(n,1);
            case 'soa'
                grating.adapted      = false(n,1);
                grating.adapter      = false(n,1);
                grating.suppressor   = false(n,1);
                grating.soa          = zeros(n,1);
            case {'contrast','tilt'}
                grating.(nonmatching{nm}) = nan(n,2);
            otherwise
                grating.(nonmatching{nm}) = nan(n,1);
        end
    end
    grating.phase = double(round(grating.phase,2));
    
    switch paradigm{j}
        
        case {'rfori', 'rfsf','rfsize'}
            grating.cued      = zeros(n,1); % never cued
            grating.ditask    = false(n,1); % never di task
            grating.rsvpmask  = false(n,1); % never rsvpmask
            
            % eye determins object in other eye
            % but always going to be either monocular or dioptic matching
            % NEVER a diconflict
            grating.tilt       = [grating.tilt uCalcTilts0to179(grating.tilt,grating.oridist)];
            grating.contrast   = [grating.contrast grating.fixedc];
            
            grating.blank     = all(grating.contrast == 0,2);
            
            grating.eye(grating.blank == 1) = 0;
            grating.monocular  = (grating.eye == 2 | grating.eye == 3);
            grating.dioptic    = grating.eye == 1; % not true for RNS, see below
            grating.tiltmatch  = grating.dioptic; % not true for RNS, see below
            grating.diconflict = false(n,1); % not true for RNS, see below
            grating.botheyes   = grating.dioptic;
            
            if any(grating.dioptic)
                % duplicate tilt and contrast info for matching dioptic
                grating.tilt(grating.dioptic,2) = grating.tilt(grating.dioptic,1);
                grating.contrast(grating.dioptic,2) = grating.contrast(grating.dioptic,1);
            end
            
            if all(isnan(grating.sf))
                % rns, NEVER dioptic or tiltmatch, no tilt info, eyes always diffrent
                grating.rns       = true(n,1);
                grating.tiltmatch = false(n,1);
                grating.dioptic   = false(n,1);
                grating.tilt(:,:) = NaN;
                grating.diconflict = true(n,1);
            else
                grating.rns       = false(n,1);
            end
            
            % duplicate eyes
            eye1 = grating.eye; eye1(eye1==1) = 2;
            eye2 = eye1; eye2(eye1==2)=3; eye2(eye1==3)=2;
            grating.eyes = [eye1 eye2];
            
        case {'drfori','rfsfdrft'}
            %DEV: not 100% sure this is right for the drifiting files
            
            grating.cued      = zeros(n,1); % never cued
            grating.ditask    = false(n,1); % never di task
            grating.rns       = false(n,1); % never rns
            grating.rsvpmask  = false(n,1); % never rsvpmask
            
            % eye determins object in other eye
            % but always going to be either monocular or dioptic matching
            % NEVER a diconflict
            grating.tilt       = [grating.tilt uCalcTilts0to179(grating.tilt,grating.oridist)];
            grating.contrast    = [grating.contrast grating.fixedc];
            
            grating.blank     = all(grating.contrast == 0,2);
            
            grating.eye(grating.blank == 1) = 0;
            grating.monocular  = (grating.eye == 2 | grating.eye == 3);
            grating.dioptic    = grating.eye == 1;
            grating.tiltmatch  = grating.dioptic; 
            grating.diconflict = false(n,1); 
            grating.botheyes   = grating.dioptic;
            
            % duplicate eyes
            eye1 = grating.eye; eye1(eye1==1) = 2;
            eye2 = eye1; eye2(eye1==2)=3; eye2(eye1==3)=2;
            grating.eyes = [eye1 eye2];
            
        case {'dmcosinteroc'}
            %DEV: not 100% sure this is right for the drifiting files
             
            grating.cued      = zeros(n,1); % never cued
            grating.ditask    = true(n,1); %  always di task
            grating.rns       = false(n,1); % never rns
            grating.rsvpmask  = false(n,1); % never rsvpmask
            
            % eye determins object in other eye
            % dichoptic possible
            grating.tilt       = [grating.tilt uCalcTilts0to179(grating.tilt,grating.oridist)];
            grating.contrast   = [grating.contrast grating.fixedc];
            
            grating.blank      = all(grating.contrast == 0,2);
            grating.monocular  = any(grating.contrast==0,2) & ~grating.blank;
            grating.dioptic    = diff(grating.contrast,[],2) == 0 & diff(grating.tilt,[],2) == 0 & ~grating.blank;
            grating.tiltmatch  = diff(grating.tilt,[],2) == 0 & ~grating.blank;
            grating.diconflict = ~grating.monocular & ~grating.dioptic & ~grating.blank;
            grating.botheyes   = ~grating.monocular & ~grating.blank;
            
            % sort eyes so that monocular info is in column 1 for tilts and contrast
            clear c e t eye2 eyes
            c = sum(grating.contrast,2);
            eye2 = grating.eye; eye2(grating.eye==2)=3; eye2(grating.eye==3)=2;
            eyes = [grating.eye eye2];
            eyes(grating.contrast == 0) = 0;
            e = sum(eyes,2);
            tilts =  grating.tilt;
            tilts(grating.contrast == 0) = 0;
            t = sum(tilts,2);
            
            grating.eye(grating.monocular) = e(grating.monocular);
            grating.eye(grating.blank)     = NaN;
            
            grating.tilt(grating.monocular,1) = t(grating.monocular);
            grating.tilt(grating.monocular,2) = NaN;
            grating.tilt(grating.blank,:) = NaN;
            
            grating.contrast(grating.monocular,1) = c(grating.monocular);
            grating.contrast(grating.monocular,2) = 0;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % duplicate eyes
            clear eye1 eye2
            eye1 = grating.eye;
            eye2 = eye1; eye2(eye1==2)=3; eye2(eye1==3)=2;
            grating.eyes = [eye1 eye2];
            
            % change values in grating.eye to reflect monocular/dioptic
            grating.eye(grating.diconflict | grating.blank) = 0;
            grating.eye(grating.dioptic) = 1;
            
        case {'mcosinteroc','cosinteroc','bminteroc'}
            
            grating.cued      = zeros(n,1); % never cued
            grating.ditask    = true(n,1); % always a di task
            grating.rns       = false(n,1); % never rns
            grating.rsvpmask  = false(n,1); % never rsvpmask
            
            % eye determins object in other eye
            % dichoptic possible
            grating.tilt       = [grating.tilt uCalcTilts0to179(grating.tilt,grating.oridist)];
            grating.contrast   = [grating.contrast grating.fixedc];
            
            grating.blank      = all(grating.contrast == 0,2);
            grating.monocular  = any(grating.contrast==0,2) & ~grating.blank;
            grating.dioptic    = diff(grating.contrast,[],2) == 0 & diff(grating.tilt,[],2) == 0 & ~grating.blank;
            grating.tiltmatch  = diff(grating.tilt,[],2) == 0 & ~grating.blank;
            grating.diconflict = ~grating.monocular & ~grating.dioptic & ~grating.blank;
            grating.botheyes   = ~grating.monocular & ~grating.blank;
            
            % sort eyes so that monocular info is in column 1 for tilts and contrast
            clear c e t eye2 eyes
            c = sum(grating.contrast,2);
            eye2 = grating.eye; eye2(grating.eye==2)=3; eye2(grating.eye==3)=2;
            eyes = [grating.eye eye2];
            eyes(grating.contrast == 0) = 0;
            e = sum(eyes,2);
            tilts =  grating.tilt;
            tilts(grating.contrast == 0) = 0;
            t = sum(tilts,2);
            
            grating.eye(grating.monocular) = e(grating.monocular);
            grating.eye(grating.blank)     = NaN;
            
            grating.tilt(grating.monocular,1) = t(grating.monocular);
            grating.tilt(grating.monocular,2) = NaN;
            grating.tilt(grating.blank,:) = NaN;
            
            grating.contrast(grating.monocular,1) = c(grating.monocular);
            grating.contrast(grating.monocular,2) = 0;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % duplicate eyes
            clear eye1 eye2
            eye1 = grating.eye;
            eye2 = eye1; eye2(eye1==2)=3; eye2(eye1==3)=2;
            grating.eyes = [eye1 eye2];
            
            % change values in grating.eye to reflect monocular/dioptic
            grating.eye(grating.diconflict | grating.blank) = 0;
            grating.eye(grating.dioptic) = 1;
            
        case 'brfs'
            % no PA in this task from what I can tell
            % either both eyes turn on at the same time
            % or "eye" turns on 1st, followed by the other
          
            grating.cued      = zeros(n,1); % never cued
            grating.ditask    = true(n,1); % always a di task
            grating.rns       = false(n,1); % never rns
            grating.rsvpmask  = false(n,1); % never rsvpmask
            
            % eye determins object in other eye
            % dichoptic possible
            grating.tilt       = [grating.tilt uCalcTilts0to179(grating.tilt,grating.oridist)];
            grating.contrast   = [grating.eye_contrast grating.other_contrast];
            
            grating.blank      = all(grating.contrast == 0,2);
            grating.monocular  = grating.contrast(:,2) == 0; % works b/c s1 should never have contrast == 0 in this task
            grating.dioptic    = diff(grating.contrast,[],2) == 0 & diff(grating.tilt,[],2) == 0 & ~grating.blank;
            grating.tiltmatch  = diff(grating.tilt,[],2) == 0 & ~grating.blank;
            grating.diconflict = ~grating.monocular & ~grating.dioptic & ~grating.blank;
            grating.botheyes   = ~grating.monocular & ~grating.blank;
            
            grating.tilt(grating.monocular==1,2) = NaN; % works b/c s1 should never have contrast == 0 in this task
            
            grating.adapted      = (grating.soa>0) & ~grating.blank;
            grating.suppressor   = (grating.soa>0) & ~grating.blank;
             grating.adapter     = false(n,1); % will fill in later
            
            % duplicate eyes
            clear eye1 eye2
            eye1 = grating.eye;
            eye2 = eye1; eye2(eye1==2)=3; eye2(eye1==3)=2;
            grating.eyes = [eye1 eye2];
            
            % change values in grating.eye to reflect monocular/dioptic
            grating.eye(grating.diconflict | grating.blank) = 0;
            grating.eye(grating.dioptic) = 1;
            
            
        case {'rsvp_color' 'rsvp_redun'}; 
            
            grating.rns       = false(n,1);  % never rns
            grating.blank     = false(n,1);  % never blank
            
            grating = rmfield(grating,'eye');
            
            targetposbycond = [NaN NaN 1 1 2 2 3 3 4 4];
            isCueValid = (cue.grating_theta(1:2:end) == targetD.grating_theta);
            stim_name = {...
                'dCOS1';... PREFORI   nullori
                'dCOS2';... nullori   PREFORI
                'BC1';...   PREFORI   PREFORI
                'MC1a';...  PREFORI   nan
                'MC1b';...  nan       PREFORI
                'BC2';...   nullori   nullori
                'MC2a';...  nullori   nan
                'MC2b';...  nan       nullori
                };
            
            rfcuedbycond    = [1 0 1 0 1 0 1 0 1 0]; %1 = RF
            rfcued          = rfcuedbycond(bhv.ConditionNumber)';
            rfcued(rfcued == 0) = -1; % 0 = no cue, -1 = cued away, 1 = cued
            grating.cued    = rfcued;
            
            if any(cellfun(@(x) any(x==25),pEvC)) % DEV: bprobably better to check trial by trial below
                grating.rsvpmask  = true(n,1); 
            else
                grating.rsvpmask  = false(n,1); 
            end
            
            for xx = 1:length(grating.cued)
                clear tempD tempS condition
                if grating.cued(xx) == 1
                    tempD = cuedD;
                    tempS = cuedS;
                    condition = stim_name{cuedD.cued_cond(xx)};
                elseif grating.cued(xx) == -1
                    tempD = uncuedD;
                    tempS = uncuedS;
                    condition = stim_name{uncuedD.uncued_cond(xx)};
                else
                    error('bad cued number')
                end
                grating.eyes(xx,:)     = [tempD.grating_eye(xx)      tempS.grating_eye(xx)];
                grating.tilt(xx,:)     = [tempD.grating_tilt(xx)     tempS.grating_tilt(xx)];
                
                grating.diameter(xx,:) = tempD.grating_diameter(xx,:);
                grating.gabor(xx,:) = tempD.gaborfilter_on(xx,:);
                grating.phase(xx,:) = tempD.grating_phase(xx,:);
                grating.sf(xx,:)    = tempD.grating_sf(xx,:);
                
                clear xpos ypos
                [xpos,ypos]=pol2cart(deg2rad(tempD.grating_theta(xx)),tempD.grating_eccentricity(xx));
                grating.xpos(xx,:) = xpos;
                grating.ypos(xx,:) = ypos;
                
                
                if strcmp(condition(1),'M')
                    if strcmp(condition(end),'a')
                        grating.contrast(xx,:) = [tempD.grating_contrast(xx) 0];
                    elseif strcmp(condition(end),'b')
                        grating.contrast(xx,:)  = fliplr([0 tempS.grating_contrast(xx)]);
                        grating.eyes(xx,:)       = fliplr(grating.eyes(xx,:));
                        grating.tilt(xx,:)      = fliplr(grating.tilt(xx,:));
                    end
                    grating.monocular(xx,:)  = true;
                    grating.tiltmatch(xx,:)  = false;
                    grating.dioptic(xx,:)    = false;
                    grating.diconflict(xx,:) = false;
                    grating.botheyes(xx,:)   = false;
                    
                else
                    grating.contrast(xx,:) = [tempD.grating_contrast(xx) tempS.grating_contrast(xx)];
                    grating.monocular(xx,:) = false;
                    grating.botheyes(xx,:)  = true;
                    
                    if strcmp(condition(1),'B')
                        grating.tiltmatch(xx,:) = 1;
                        if diff(grating.contrast(xx,:)) == 0
                            grating.dioptic(xx,:)    = true;
                            grating.diconflict(xx,:) = false;
                        else
                            grating.dioptic(xx,:)    = false;
                            grating.diconflict(xx,:) = true;
                        end
                        
                    elseif strcmp(condition(1),'d')
                        
                        grating.tiltmatch(xx,:) = false;
                        grating.dioptic(xx,:)   = false;
                        grating.diconflict(xx,:) = true;
                    end
                    
                end
                
            end
            
            grating.ditask = true(n,1);
            
            grating.eye = zeros(size(grating.monocular));
            grating.eye(grating.dioptic) = 1;
            grating.eye(grating.monocular) = grating.eyes(grating.monocular,1);
            
        otherwise
            error('need to specify analysis for %s', paradigm{j})
    end
    
    % CHANGE EYE ASSIGNMENT: 2 signifies IPSI , 3 signifies CONTRA
    if strcmp(V1,'LV1')
        to3 = grating.eye == 2;
        to2 = grating.eye == 3;
        grating.eye(to3) = 3;
        grating.eye(to2) = 2;
        
        to3 = grating.eyes == 2;
        to2 = grating.eyes == 3;
        grating.eyes(to3) = 3;
        grating.eyes(to2) = 2;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    allstimfeatures = cat(2,mainstimfeatures,...
        'monocular',...
        'ditask',...
        'dioptic',...
        'tiltmatch',...
        'rns',...
        'blank',...
        'adapted',...
        'adapter',...
        'suppressor',...
        'cued',...
        'diconflict',...
        'botheyes',...
        'eyes',...
        'rsvpmask');
    
    % sort trials , get TPs
    for t = 1:length(pEvC)
        
        if strcmp(filelist{j},'/Volumes/Drobo2/Data/NEUROPHYS/rig021/170724_I/170724_I_mcosinteroc001')
            if ~exist('ns_header','var')
                ns_header  = openNSx([filelist{j} '.ns6'],'noread');
            end
            if ns_header.MetaTags.DataPoints < pEvT{t}(1)
                continue
            end
        end
        
        if strcmp(paradigm{j},'rsvp_color') ||strcmp(paradigm{j},'rsvp_redun')
            % see getRsvpTPs
            % Key Event Codes:
            %   102 = target onset (red patch inside stimulus)
            %   37  = "redundent cue" for V1 attention dip paper control
            %   each of these event marker is then followed by a "task object on" event marker during the actual flip
            %   44/54 = 'Start/End eye 1', mark aprox. begin and end of saccade
            
            minStimulusTm = 300; 
            
            TrialError = bhv.TrialError(t);
            if TrialError == 3 || TrialError == 4 || TrialError == 5
                continue
            end
            
            CodeNumbers = bhv.CodeNumbers{t};
            CodeTimes   = bhv.CodeTimes{t};
            
            if any(CodeNumbers) == 37
                % redundant cue show, skip (DEV ,could relax). 
                continue
            end
            
            TargetPos = targetposbycond(bhv.ConditionNumber(t));
            RfCued    = rfcuedbycond(bhv.ConditionNumber(t));
            CueValid  = isCueValid(t);
                        
            % calculate time from stimulus to target
            if any(CodeNumbers == 102)
                EM = 25 + 2*targetposbycond(bhv.ConditionNumber(t));
                clear tmidx
                tmidx = [...
                    find(CodeNumbers == EM ,1,'first'),...
                    find(CodeNumbers == 102) + 1 ...
                    ];
                tmidx(CodeNumbers(tmidx) ~= EM) = [];
                if length(tmidx) > 1
                    TargetTm = diff(CodeTimes(tmidx));
                else
                    TargetTm = 0;
                end
            else
                TargetTm = Inf;
            end
            
            for p = 1:rsvp_ln
                EM = 25 + p*2;
                % get START event for this presentation
                st_event = find(CodeNumbers == EM,1,'first');
                if isempty(st_event)
                    continue
                end
                % get END event for this presentation
                em = 0; en_event = [];
                em_array = [EM+1, 44, 97, 96, 18]; % stim off, saccade, break fixation, reward, end trial
                while isempty(en_event)
                    em = em + 1;
                    en_event = find(CodeNumbers == em_array(em),1,'first');
                    if em > length(em_array)
                        break
                    end
                end
                
                % exclude presentations with an early target appearence INSIDE RF
                if p == TargetPos && TargetTm <= minStimulusTm;
                    if RfCued && CueValid
                        % target appeared in RF fewer than 'minStimulusTm' ms from stimulus onset, do not count
                        continue
                    elseif ~RfCued && ~CueValid
                        % target appeared in RF fewer than 'minStimulusTm' ms from stimulus onset, do not count
                        continue
                    end
                elseif p == 0
                    tmidx = [...
                        st_event,...
                        en_event ...
                        ];
                    MaskTm = diff(CodeTimes(tmidx));
                    if MaskTm <= minStimulusTm
                        continue
                    end
                end
                
                
                % exclude presentations with an early saccade [false alarms, or saccades to early targets outside RF]
                if any(CodeNumbers(st_event:en_event) == 44)
                    tmidx = [...
                        st_event,...
                        find(CodeNumbers == 44) ...
                        ];
                    EyeTm = diff(CodeTimes(tmidx));
                    if EyeTm <= minStimulusTm
                        continue
                    end
                end
                
                % all checks passed, meaning this is a presentaion to examin
                idx = cuedD.trial==t & cuedD.pres==p;
                obs  = obs + 1;
                
                STIM.('task'){obs,:}  =  paradigm{j};
                STIM.('filen')(obs,:) = j;
                STIM.('trl')(obs,:)   = t;
                STIM.('prez')(obs,:)  = p; % ????????
                STIM.('reward')(obs,:) = (any(pEvC{t} == 96));
                
                % trigger points
                stimon  =  double(pEvT{t}(find(pEvC{t} == EM,1,'first')));
                stimoff =  stimon + minStimulusTm/1000*Fs;
                
                STIM.tp_ec(obs,:)     = [EM  NaN]; 
                STIM.tp_sp(obs,:)     = [stimon stimoff];
                
                % write STIM features
                for f = 1:length(allstimfeatures)
                    STIM.(allstimfeatures{f})(obs,:) = (grating.(allstimfeatures{f})(idx,:));
                end
                
            end
            
        else
            % examin presentations ONLY if there is a off event marker (not a break fixation)
            stim =  find(grating.trial == t); if any(diff(stim) ~= 1); error('check stim file'); end
            nstim = sum(pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32); if nstim == 0; continue; end
            
            if strcmp(paradigm{j},'brfs') && nstim ~= 1
                %DEV: relax this for soa brfs -- maybe as long as the 2nd stim was on for 500ms
                warning('opertunity for development here, but needed an example file')
            end
            
            for p = 1:nstim
                obs = obs + 1;
                STIM.('task'){obs,:}  =  paradigm{j};
                STIM.('filen')(obs,:) = j;
                STIM.('trl')(obs,:)   = t;
                STIM.('prez')(obs,:)  = p; % ????????
                STIM.('reward')(obs,:) = (any(pEvC{t} == 96));
                
                % trigger points
                stimon  =  pEvC{t} == 21 + p*2;
                stimoff =  pEvC{t} == 22 + p*2;
                
                st = double(pEvT{t}(stimon));
                en = double(pEvT{t}(stimoff));
                
                STIM.tp_ec(obs,:)     = [21  22] + p*2; % see lines 435-6
                STIM.tp_sp(obs,:)     = [st(end) en];
                
                
                % write STIM features
                for f = 1:length(allstimfeatures)
                    STIM.(allstimfeatures{f})(obs,:) = (grating.(allstimfeatures{f})(stim(p),:));
                end
                
                if grating.adapted(stim(p)) 
                    % save adaptor as another monocular presentation
                    
                    obs = obs + 1;
                    STIM.('task'){obs,:}  =  paradigm{j};
                    STIM.('filen')(obs,:) = j;
                    STIM.('trl')(obs,:)   = t;
                    STIM.('prez')(obs,:)  = p; % ????????
                    STIM.('reward')(obs,:) = (any(pEvC{t} == 96));
                    
                    % trigger points
                    STIM.tp_ec(obs,:) = [21  21] + p*2; % see lines 435-6
                    STIM.tp_sp(obs,:) = [st(1) st(2)];
                    
                    % write STIM features
                    for f = 1:length(allstimfeatures)
                        switch allstimfeatures{f}
                            case 'monocular'
                                STIM.(allstimfeatures{f})(obs,:) = 1; % 2/7/20 - Changed from 0 to 1
                            case {'soa'}
                                STIM.(allstimfeatures{f})(obs,:) = 0;
                            case {'adapter'}
                                STIM.(allstimfeatures{f})(obs,:) = true;
                            case {'suppressor','adapted'}
                                STIM.(allstimfeatures{f})(obs,:) = false;                                
                            case 'contrast'
                                STIM.(allstimfeatures{f})(obs,:) = [grating.(allstimfeatures{f})(stim(p),1) 0];
                            case {'tilt'}
                                STIM.(allstimfeatures{f})(obs,:) = [grating.(allstimfeatures{f})(stim(p),1) NaN];
                            otherwise
                                STIM.(allstimfeatures{f})(obs,:) = (grating.(allstimfeatures{f})(stim(p),:));
                        end
                    end
                    % switch to make it more intuative 
                    swap = [-1 0] + obs;
                    fields = fieldnames(STIM);
                    for f = 1:length(fields)
                        if strcmp(fields{f},'header')
                            continue
                        end
                        STIM.(fields{f})(swap,:) = STIM.(fields{f})(fliplr(swap),:);
                     end
                    
                end
            end
            
        end
    end
    
    
end
    
    
    
    
    % add Filelist
    STIM.filelist  = filelist;
    STIM.filetime  = filetime;
    STIM.paradigm  = paradigm;
    STIM.fpath     = fpath;
    STIM.runtime   = now;
    
    
    %%
    %
    % clearvars -except filelist V1
    % STIM = getDiTPs(filelist,V1);
    % %%
    %
    % prefeye  = 2;
    % prefori = 120;
    %
    % I = STIM.eye == prefeye & STIM.tilt == prefori;
    % mI = any(I,2) & STIM.monocular;
    % bI = any(I,2) & STIM.dioptic;
    % dI = any(I,2) & STIM.tiltmatch == 0;
    
    
    
