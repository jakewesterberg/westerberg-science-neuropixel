function STIM = BRextractevt(paradigm, gratingfile)

if strcmp(paradigm, 'dotmapping')

    dots = readgDotsXY(gratingfile); % read in text file with stim parameters
    NEV = openNEV();
    % get event codes from NEV
    EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
    EventSampels = double(NEV.Data.SerialDigitalIO.TimeStamp);
    [STIM.pEvC, STIM.pEvT] = parsEventCodesML(EventCodes,EventSampels);

    trls = find(cellfun(@(x) sum(x == 23) == sum(x == 24),STIM.pEvC));
    obs = 0;
    for tr = 1:length(trls)
        t = trls(tr);

        %if ~any(STIM.pEvC{t} == 96)
        %    continue
        %end

        stimon  =  STIM.pEvC{t} == 23 | STIM.pEvC{t} == 25  | STIM.pEvC{t} == 27   | STIM.pEvC{t} == 29  | STIM.pEvC{t} == 31;
        stimoff =  STIM.pEvC{t} == 24 | STIM.pEvC{t} == 26  | STIM.pEvC{t} == 28   | STIM.pEvC{t} == 30  | STIM.pEvC{t} == 32;
        start = STIM.pEvT{t}(stimon);
        finish = STIM.pEvT{t}(stimoff);
        stim =  find(dots.trial == t);

        maxpres = min([length(start) length(finish) length(stim)]);

        for p = 1:maxpres
            obs = obs + 1;
            STIM.x(1,obs)     = dots.dot_x(stim(p));
            STIM.y(1,obs)     = dots.dot_y(stim(p));
            STIM.d(1,obs)     = dots.diameter(stim(p));
            STIM.eye(1,obs)   = dots.dot_eye(stim(p));
        end
    end

else

    V1 = 'RV1';

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

    NEV = openNEV();
    Fs = double(NEV.MetaTags.TimeRes);

    % Event Codes from NEV
    EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
    EventSamples = NEV.Data.SerialDigitalIO.TimeStamp;
    [pEvC, pEvT] = parsEventCodesML(single(EventCodes),single(EventSamples));

    % stimulus text file
    switch paradigm
        case {'rfori', 'rfsf', 'rfsize','cosinteroc','mcosinteroc','bminteroc'} % my task should go here
            grating = readgGrating(gratingfile);

        case {'drfori','rfsfdrft','dmcosinteroc'}
            grating = readgDRFTGrating(gratingfile);
    end

    % check that all is good between NEV and grating text file;
    switch paradigm
        otherwise
            n = length(grating.trial);
            [allpass, message] =  checkTrMatch(grating,NEV); % 2021 problems arise here when we don't have the event code sequencing triplets OR ML and BR timestamp misalignment
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

    switch paradigm

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

    obs = 0;

    % sort trials , get TPs
    for t = 1:length(pEvC)

        % examin presentations ONLY if there is a off event marker (not a break fixation)
        stim =  find(grating.trial == t); if any(diff(stim) ~= 1); error('check stim file'); end
        nstim = sum(pEvC{t} == 24 | pEvC{t} == 26  | pEvC{t} == 28   | pEvC{t} == 30  | pEvC{t} == 32); if nstim == 0; continue; end

        for p = 1:nstim
            obs = obs + 1;
            STIM.('task'){obs,:}  =  paradigm;
            STIM.('filen')(obs,:) = 1;
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
                STIM.('task'){obs,:}  =  paradigm;
                STIM.('filen')(obs,:) = 1;
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