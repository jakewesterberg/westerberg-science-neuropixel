function [cue cuedD cuedS uncuedD uncuedS] = loadRSVPdata(fdir,fname)

exceptions = {'151125'};

if any(strcmp(fname(1:6),exceptions))
    date = fname(1:6);
else
    date = 0 ;
end

switch date
    case 0
        cue = readgRSVP([fdir filesep fname '.gCue_di']); % read in text file with stim parameters
        cuedLE = readgRSVP([fdir filesep fname '.gLeftStim_di']); % read in text file with stim parameters
        cuedRE = readgRSVP([fdir filesep fname '.gRightStim_di']); % read in text file with stim parameters
        uncuedLE = readgRSVP([fdir filesep fname '.gLeftDStim_di']); % read in text file with stim parameters
        uncuedRE = readgRSVP([fdir filesep fname '.gRightDStim_di']); % read in text file with stim parameters
        
    case '151125'
        
        % load short files first:
        scue = readgRSVP([fdir filesep 'short_' fname '.gCue_di']); % read in text file with stim parameters
        sCrsvpL = readgRSVP([fdir filesep  'short_' fname '.gLeftStim_di']); % read in text file with stim parameters
        sCrsvpR = readgRSVP([fdir filesep  'short_' fname '.gRightStim_di']); % read in text file with stim parameters
        sUrsvpL = readgRSVP([fdir filesep  'short_' fname '.gLeftDStim_di']); % read in text file with stim parameters
        sUrsvpR = readgRSVP([fdir filesep  'short_' fname '.gRightDStim_di']); % read in text file with stim parameters
        
        % load long files next:
        lcue = readgRSVP([fdir filesep fname '.gCue_di']); % read in text file with stim parameters
        lCrsvpL = readgRSVP([fdir filesep fname '.gLeftStim_di']); % read in text file with stim parameters
        lCrsvpR = readgRSVP([fdir filesep fname '.gRightStim_di']); % read in text file with stim parameters
        lUrsvpL = readgRSVP([fdir filesep fname '.gLeftDStim_di']); % read in text file with stim parameters
        lUrsvpR = readgRSVP([fdir filesep fname '.gRightDStim_di']); % read in text file with stim parameters
        
        fields = fieldnames(lcue);
        unqtr = unique(scue.trial);
        cue = struct([]);
        for i = 1:length(unqtr)
            punqtr = unqtr(i);
            if punqtr == 1
                for ii = 1:length(fields)-3
                    addthis = ([getfield(scue,fields{ii}); getfield(lcue,fields{ii})]);
                    cue = setfield(cue,{1},fields{ii},{[1:length(addthis)]},addthis);
                    clear addthis;
                end
            else
                
            end
        end
        % 1st or 2nd presentation on trial 2 of cue missing.
        % delete trial 2:
        cue.trial(3) = [];
        cue.horzdva(3) = [];
        cue.vertdva (3) = [];
        cue.xpos(3) = [];
        cue.ypos(3) = [];
        cue.theta(3) = [];
        cue.eccentricity(3) = [];
        cue.tilt(3) = [];
        cue.sf(3) = [];
        cue.contrast(3) = [];
        cue.diameter(3) = [];
        cue.dominanteye(3) = [];
        cue.gaborfilteron(3) = [];
        cue.gabor_std(3) = [];
        cue.header(3) = [];
        
        
        
        fields = fieldnames(lCrsvpL);
        cuedLE = struct([]);
        cuedRE = struct([]);
        uncuedLE = struct([]);
        uncuedRE = struct([]);
        
        for ii = 1:length(fields)-3
            addthis = ([getfield(sCrsvpL,fields{ii}); getfield(lCrsvpL,fields{ii})]);
            cuedLE = setfield(cuedLE,{1},fields{ii},{[1:length(addthis)]},addthis);
            clear addthis;
            
            addthis = ([getfield(sCrsvpR,fields{ii}); getfield(lCrsvpR,fields{ii})]);
            cuedRE = setfield(cuedRE,{1},fields{ii},{[1:length(addthis)]},addthis);
            clear addthis;
            
            addthis = ([getfield(sUrsvpL,fields{ii}); getfield(lUrsvpL,fields{ii})]);
            uncuedLE = setfield(uncuedLE,{1},fields{ii},{[1:length(addthis)]},addthis);
            clear addthis;
            
            addthis = ([getfield(sUrsvpR,fields{ii}); getfield(lUrsvpR,fields{ii})]);
            uncuedRE = setfield(uncuedRE,{1},fields{ii},{[1:length(addthis)]},addthis);
            clear addthis;
        end
        
        if isempty(sUrsvpR.trial)
            % using grating record to replace missing data points from
            % trial 1 for the uncued stream
            % note: gratingrecord includes 2 presentations per trial, though
            % only one/tr was actually run
            load([fdir '\short_' fname '_RSVPRECORD1.mat']);
            uncuedLE.trial   = [1 uncuedLE.trial];
            uncuedLE.horzdva = [RSVPRECORD(unqtr).rf_xpos uncuedLE.horzdva];
            uncuedLE.vertdva = [RSVPRECORD(unqtr).rf_ypos uncuedLE.vertdva];
            uncuedLE.xpos = [RSVPRECORD(unqtr).rf_xpos uncuedLE.xpos];
            uncuedLE.ypos = [RSVPRECORD(unqtr).rf_ypos uncuedLE.ypos];
            [theta,eccentricity] = cart2pol(RSVPRECORD(unqtr).rf_xpos, RSVPRECORD(unqtr).rf_ypos);
            uncuedLE.theta = [rad2deg(theta) uncuedLE.theta];
            uncuedLE.eccentricity = [eccentricity uncuedLE.eccentricity];
            uncuedLE.tilt = [RSVPRECORD(unqtr).uncuedstream_ori(1,1)' uncuedLE.tilt];
            uncuedLE.cued_con = RSVPRECORD(1).uncued_stimcond(1);
            uncuedLE.sf = [RSVPRECORD(unqtr).uncuedstream_sf(1) uncuedLE.sf];
            uncuedLE.contrast = [uncuedLE.contrast(1) uncuedLE.contrast]; %assuming it's the same as the other tirals
            uncuedLE.diameter = [uncuedLE.diameter(1) uncuedLE.diameter]; %assuming it's the same as the other trials
            uncuedLE.dominanteye = [uncuedLE.dominanteye uncuedLE.dominanteye]; %assuming it's the same as the other trials
            uncuedLE.gaborfilteron = [uncuedLE.gaborfilteron(1) uncuedLE.gaborfilteron];%assuming it's the same as the other trials
            uncuedLE.gabor_std = [uncuedLE.gabor_std(1) uncuedLE.gabor_std]; %assuming it's the same as the other trials
            uncuedLE.header = [RSVPRECORD(unqtr).header uncuedLE.header];
            
            
            
            uncuedRE.trial   = [1 uncuedRE.trial];
            uncuedRE.horzdva = [RSVPRECORD(unqtr).rf_xpos uncuedRE.horzdva];
            uncuedRE.vertdva = [RSVPRECORD(unqtr).rf_ypos uncuedRE.vertdva];
            uncuedRE.xpos = [RSVPRECORD(unqtr).rf_xpos uncuedRE.xpos];
            uncuedRE.ypos = [RSVPRECORD(unqtr).rf_ypos uncuedRE.ypos];
            [theta,eccentricity] = cart2pol(RSVPRECORD(unqtr).rf_xpos, RSVPRECORD(unqtr).rf_ypos);
            uncuedRE.theta = [rad2deg(theta) uncuedRE.theta];
            uncuedRE.eccentricity = [eccentricity uncuedRE.eccentricity];
            
            uncuedRE.tilt = [RSVPRECORD(unqtr).uncuedstream_ori(2,1)' uncuedRE.tilt];
            uncuedRE.cued_con = RSVPRECORD(1).uncued_stimcond(1);
            uncuedRE.sf = [RSVPRECORD(unqtr).uncuedstream_sf(1) uncuedRE.sf];
            uncuedRE.contrast = [uncuedRE.contrast(1) uncuedRE.contrast]; %assuming it's the same as the other tirals
            uncuedRE.diameter = [uncuedRE.diameter(1) uncuedRE.diameter]; %assuming it's the same as the other trials
            uncuedRE.dominanteye = [uncuedRE.dominanteye uncuedRE.dominanteye]; %assuming it's the same as the other trials
            uncuedRE.gaborfilteron = [uncuedRE.gaborfilteron(1) uncuedRE.gaborfilteron];%assuming it's the same as the other trials
            uncuedRE.gabor_std = [uncuedRE.gabor_std(1) uncuedRE.gabor_std]; %assuming it's the same as the other trials
            uncuedRE.header = [RSVPRECORD(unqtr).header uncuedRE.header];
            
        end
        
        uncued_stimcond = [RSVPRECORD.uncued_stimcond];
        uncuedLE.stimcond = uncued_stimcond(1,:);
        uncuedRE.stimcond = uncued_stimcond(1,:);
        uncuedLE = rmfield(uncuedLE,'cued_cond');
        uncuedRE = rmfield(uncuedRE,'cued_cond');
        
        cuedLE.stimcond = cuedLE.cued_cond;
        cuedRE.stimcond = cuedRE.cued_cond;
        cuedLE = rmfield(cuedLE,'cued_cond');
        cuedRE = rmfield(cuedRE,'cued_cond');
        
end

switch cue.dominanteye(1)
    case 2 % RE is dominant
        cuedD = cuedRE;
        cuedS = cuedLE;
        uncuedD = uncuedRE;
        uncuedS = uncuedLE;
    case 3 % LE is dominant
        cuedD = cuedLE;
        cuedS = cuedRE;
        uncuedD = uncuedLE;
        uncuedS = uncuedRE;
end





end



