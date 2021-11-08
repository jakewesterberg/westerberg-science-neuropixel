function [varargout] = loadRSVPdata(fdir,fname,n)
%clearvars -except fdir fname

% deals with the early sessions that need some TLC for the analysis


splitdata = {'151120','151121','151125'};
baduncued = {'151120','151121','151125'};

if nargin < 3
    % get datenum from fdir
    session = fdir(end-7:end-2);
    n = datenum(session,'yymmdd');
else
    session = datestr(n,'yymmdd');
end
   

if n < datenum('160324','yymmdd');
    extenstions = {'.gCue_di','.gLeftStim_di','.gRightStim_di','.gLeftDStim_di','.gRightDStim_di'};
else
    extenstions = {'.gCue_di','.gLeftStim_di','.gRightStim_di','.gLeftDStim_di','.gRightDStim_di','.gLeftTarg_di','.gRightTarg_di'};
end


%check variable output
if nargout == 8 && ~any(strcmp(extenstions,'.gLeftTarg_di'))
    error('no gTarget_di for this file')
end

for e = 1:length(extenstions)
    if ~exist([fdir filesep fname extenstions{e}],'file')
            error('file "%s" not found',[fdir filesep fname extenstions{e}])
    end
    
    if any(strcmp(splitdata,session))
        % need to fix these files!
        fdir = 'Y:\Early RSVP Data';
        
        
        % read "short" files first
        short = readgRSVP([fdir filesep fname extenstions{e}]); % read in text file with stim parameters
        long =  readgRSVP([fdir filesep fname ' (2)' extenstions{e}]); % read in text file with stim parameters
        
        fields = fieldnames(long);
        if strcmp(extenstions{e},'.gCue_di')
            fmax = 14;
        else
            fmax = 15;
        end
        
        clear temp trialarray presarray RSVP
        for f = 1:fmax
            temp.(fields{f}) = [short.(fields{f}); long.(fields{f})];
        end
        total = max(temp.trial); % total trials
        npres = mode(histc(temp.trial,1:max(temp.trial))); % number of "gen" calls written / trial, may be diffrent from RECORD & what was actually shown
        for g = 1:npres
            trialarray(g,:)=1:total;
        end
        trialarray = sort(reshape(trialarray,numel(trialarray),1));
        presarray = repmat([1:npres]',total,1);
        for f = 1:fmax
            RSVP.(fields{f})=nan(size(trialarray));
        end
        
        for tr = 1:total
            trprez = find(temp.trial == tr);
            for p = 1:npres
                idx = find(trialarray == tr & presarray == p);
                for f = 1:fmax
                    if isempty(trprez) || length(trprez) ~= npres
                        % RSVP.('trial')(idx,1) = tr;
                        continue
                    else
                        RSVP.(fields{f})(idx,1) = temp.(fields{f})(trprez(p));
                    end
                end
            end
            
        end
        
        % ~~NEEDS DEVELOPMENT~~
        %         % use RSVP record to fill in missing trials if they are < 70
        %         missing = find(isnan(RSVP.horzdva));
        %         missingtrials = trialarray(missing);
        %         missingpreses   = presarray(missing);
        %
        %         if ~isempty(missing) && all(missingtrials) <= 70;
        %             clear RSVPRECORD
        %             load([fdir filesep fname '_RSVPRECORD1.mat']);
        %             for m = 1:length(missing)
        %                 idx = missing(m);
        %                 mt = missingtrials(m);
        %                 mp = missingpreses(m);
        %                 ahah
        %                 RSVP.horzdva(idx) = RSVPRECORD(mt).rf_xpos;
        %                 RSVP.vertdva(idx) = RSVPRECORD(mt).rf_ypos;
        %                 RSVP.xpos(idx) = RSVPRECORD(mt).rf_xpos;
        %                 RSVP.ypos(idx) = RSVPRECORD(mt).rf_ypos;
        %                 [theta,eccentricity] = cart2pol(RSVPRECORD(unqtr).rf_xpos, RSVPRECORD(unqtr).rf_ypos);
        %                 RSVP.theta(idx) = [rad2deg(theta) RSVP.theta];
        %                 RSVP.eccentricity(idx) = [eccentricity RSVP.eccentricity];
        %                 RSVP.tilt(idx) = [RSVPRECORD(unqtr).uncuedstream_ori(1,1)' RSVP.tilt];
        %                 RSVP.sf(idx) = [RSVPRECORD(unqtr).uncuedstream_sf(1) RSVP.sf];
        %                 RSVP.contrast(idx) = [RSVP.contrast(1) RSVP.contrast]; %assuming it's the same as the other tirals
        %                 RSVP.diameter(idx) = [RSVP.diameter(1) RSVP.diameter]; %assuming it's the same as the other trials
        %                 RSVP.dominanteye(idx) = [RSVP.dominanteye RSVP.dominanteye]; %assuming it's the same as the other trials
        %                 RSVP.gaborfilteron(idx) = [RSVP.gaborfilteron(1) RSVP.gaborfilteron];%assuming it's the same as the other trials
        %                 RSVP.gabor_std(idx) = [RSVP.gabor_std(1) RSVP.gabor_std]; %assuming it's the same as the other trials
        %
        %                 if ~isempty(strfind(extenstions{e},'DStim_di'))
        %                     % uncued
        %                 elseif ~isempty(strfind(extenstions{e},'Stim_di'))
        %                     % cued
        %                 end
        
    else
        clear RSVP
        RSVP = readgRSVP([fdir filesep fname extenstions{e}]); % read in text file with stim parameters
        if ~strcmp(extenstions{e},'.gCue_di')
            npres = mode(histc(RSVP.trial,1:max(RSVP.trial))); % number of "gen" calls written / trial, may be diffrent from RECORD & what was actually shown
        end
    end
    
    
    switch extenstions{e}
        case  '.gCue_di'
            cue = RSVP; clear RSVP
        case '.gLeftStim_di'
            cuedLE = RSVP; clear RSVP
        case '.gRightStim_di'
            cuedRE = RSVP; clear RSVP
        case '.gLeftDStim_di'
            uncuedLE = RSVP; clear RSVP
        case '.gRightDStim_di'
            uncuedRE = RSVP; clear RSVP
        case '.gLeftTarg_di'
            targetLE = RSVP; clear RSVP
        case '.gRightTarg_di'
            targetRE = RSVP; clear RSVP
    end
    
end

% change output to be re: dominant eye instead of LE and RE
% first, have to figure out dominant eye assignment
fields = fieldnames(cuedRE);
if any(strcmp(fields,'dominanteye'))
    dominanteye = cuedRE.dominanteye(1);
else
    listing = dir([fdir filesep fname '_RSVPRECORD*']);
    if ~isempty(listing)
        clear RSVPRECORD
        load([fdir filesep listing(1).name],'-MAT');
        dominanteye = RSVPRECORD(1).eye;
        clear RSVPRECORD
    else
        dominanteye = [];
        
        if any(isnan([cuedRE.grating_tilt; uncuedRE.grating_tilt])) && ~any(isnan([cuedLE.grating_tilt; uncuedLE.grating_tilt]))
            dominanteye = 3;
        elseif any(isnan([cuedLE.grating_tilt; uncuedLE.grating_tilt])) && ~any(isnan([cuedRE.grating_tilt; uncuedRE.grating_tilt]))
            dominanteye = 2;
        end
        
        if isempty(dominanteye)
            dominanteye = 2;
        end
    end
end
switch  dominanteye
    case 2 % RE is dominant
        cuedD = cuedRE;
        cuedS = cuedLE;
        uncuedD = uncuedRE;
        uncuedS = uncuedLE;
        if any(strcmp(extenstions,'.gLeftTarg_di'))
            targetD = targetRE;
            targetS = targetLE;
        end
    case 3 % LE is dominant
        cuedD = cuedLE;
        cuedS = cuedRE;
        uncuedD = uncuedLE;
        uncuedS = uncuedRE;
        if any(strcmp(extenstions,'.gLeftTarg_di'))
            targetD = targetLE;
            targetS = targetRE;
        end
end

% fix uncued stim cond issue (wrong one written in text file during save)
if any(strcmp(baduncued,session))
    
    if strcmp('151121',session)
        prefori = 135; % from notes
    elseif strcmp('151120',session)
        fn = str2double(fname(end-2:end)); 
        if fn < 7 
            error('bad file, see notes')
        else
            prefori = 90; % from notes
        end
    else
        load([fdir filesep fname '_RSVPRECORD1.mat']);
        prefori = RSVPRECORD(1).rf_prefori; clear RSVPRECORD
    end
    nullori =  uCalcTilts0to179(prefori,90);
    
    distim = [uncuedD.tilt, uncuedS.tilt];
    clear stimcond
    for s = 1:length(distim)
        stim = distim(s,:);
        stim(isnan(stim)) = 9999; % isequal does not work on NAN
        if isequal(stim, [prefori nullori])
            stimcond(s,1) = 1;
        elseif isequal(stim, [prefori 9999])
            stimcond(s,1) = 2;
        elseif isequal(stim, [nullori 9999])
            stimcond(s,1) = 3;
        elseif isequal(stim, [prefori prefori])
            stimcond(s,1) = 4;
        elseif isequal(stim, [nullori nullori])
            stimcond(s,1) = 5;
        else
            stimcond(s,1) = NaN;
        end
    end
    uncuedD.stimcond = stimcond;
    uncuedS.stimcond = stimcond;
end


% set varialb output
if nargout == 8
    varargout = {cue, cuedD, cuedS, uncuedD, uncuedS, targetD, targetS, npres};
elseif nargout == 6 
    varargout = {cue, cuedD, cuedS, uncuedD, uncuedS, npres};
end


%             % cue file
%             cue = struct([]);
%             for i = 1:length(unqtr)
%                 punqtr = unqtr(i);
%                 if punqtr == 1
%                     for ii = 1:length(fields)-3
%                         addthis = ([getfield(short,fields{ii}); getfield(long,fields{ii})]);
%                         cue = setfield(cue,{1},fields{ii},{[1:length(addthis)]},addthis);
%                         clear addthis;
%                     end
%                 end
%             end
%         else

%
% else
%     date = 0 ;
% end
%
% switch date
%     case 0
%         cue = readgRSVP([fdir filesep fname '.gCue_di']); % read in text file with stim parameters
%         cuedLE = readgRSVP([fdir filesep fname '.gLeftStim_di']); % read in text file with stim parameters
%         cuedRE = readgRSVP([fdir filesep fname '.gRightStim_di']); % read in text file with stim parameters
%         uncuedLE = readgRSVP([fdir filesep fname '.gLeftDStim_di']); % read in text file with stim parameters
%         uncuedRE = readgRSVP([fdir filesep fname '.gRightDStim_di']); % read in text file with stim parameters
%
%     case '151125'
%
%         % load short files first:
%         %         scue = readgRSVP([fdir filesep 'short_' fname '.gCue_di']); % read in text file with stim parameters
%         %         sCrsvpL = readgRSVP([fdir filesep  'short_' fname '.gLeftStim_di']); % read in text file with stim parameters
%         %         sCrsvpR = readgRSVP([fdir filesep  'short_' fname '.gRightStim_di']); % read in text file with stim parameters
%         %         sUrsvpL = readgRSVP([fdir filesep  'short_' fname '.gLeftDStim_di']); % read in text file with stim parameters
%         %         sUrsvpR = readgRSVP([fdir filesep  'short_' fname '.gRightDStim_di']); % read in text file with stim parameters
%         scue = readgRSVP([fdir filesep fname '.gCue_di']); % read in text file with stim parameters
%         sCrsvpL = readgRSVP([fdir filesep fname '.gLeftStim_di']); % read in text file with stim parameters
%         sCrsvpR = readgRSVP([fdir filesep fname '.gRightStim_di']); % read in text file with stim parameters
%         sUrsvpL = readgRSVP([fdir filesep fname '.gLeftDStim_di']); % read in text file with stim parameters
%         sUrsvpR = readgRSVP([fdir filesep fname '.gRightDStim_di']); % read in text file with stim parameters
%
%
%         % load long files next:
%         lcue = readgRSVP([fdir filesep fname ' (2).gCue_di']); % read in text file with stim parameters
%         lCrsvpL = readgRSVP([fdir filesep fname ' (2).gLeftStim_di']); % read in text file with stim parameters
%         lCrsvpR = readgRSVP([fdir filesep fname ' (2).gRightStim_di']); % read in text file with stim parameters
%         lUrsvpL = readgRSVP([fdir filesep fname ' (2).gLeftDStim_di']); % read in text file with stim parameters
%         lUrsvpR = readgRSVP([fdir filesep fname ' (2).gRightDStim_di']); % read in text file with stim parameters
%
%         fields = fieldnames(lcue);
%         unqtr = unique(scue.trial);
%         cue = struct([]);
%         for i = 1:length(unqtr)
%             punqtr = unqtr(i);
%             if punqtr == 1
%                 for ii = 1:length(fields)-3
%                     addthis = ([getfield(scue,fields{ii}); getfield(lcue,fields{ii})]);
%                     cue = setfield(cue,{1},fields{ii},{[1:length(addthis)]},addthis);
%                     clear addthis;
%                 end
%             else
%
%             end
%         end
%         % 1st or 2nd presentation on trial 2 of cue missing.
%         % delete trial 2:
%         cue.trial(3) = [];
%         cue.horzdva(3) = [];
%         cue.vertdva (3) = [];
%         cue.xpos(3) = [];
%         cue.ypos(3) = [];
%         cue.theta(3) = [];
%         cue.eccentricity(3) = [];
%         cue.tilt(3) = [];
%         cue.sf(3) = [];
%         cue.contrast(3) = [];
%         cue.diameter(3) = [];
%         cue.dominanteye(3) = [];
%         cue.gaborfilteron(3) = [];
%         cue.gabor_std(3) = [];
%         cue.header(3) = [];
%
%
%
%         fields = fieldnames(lCrsvpL);
%         cuedLE = struct([]);
%         cuedRE = struct([]);
%         uncuedLE = struct([]);
%         uncuedRE = struct([]);
%
%         for ii = 1:length(fields)-3
%             addthis = ([getfield(sCrsvpL,fields{ii}); getfield(lCrsvpL,fields{ii})]);
%             cuedLE = setfield(cuedLE,{1},fields{ii},{[1:length(addthis)]},addthis);
%             clear addthis;
%
%             addthis = ([getfield(sCrsvpR,fields{ii}); getfield(lCrsvpR,fields{ii})]);
%             cuedRE = setfield(cuedRE,{1},fields{ii},{[1:length(addthis)]},addthis);
%             clear addthis;
%
%             addthis = ([getfield(sUrsvpL,fields{ii}); getfield(lUrsvpL,fields{ii})]);
%             uncuedLE = setfield(uncuedLE,{1},fields{ii},{[1:length(addthis)]},addthis);
%             clear addthis;
%
%             addthis = ([getfield(sUrsvpR,fields{ii}); getfield(lUrsvpR,fields{ii})]);
%             uncuedRE = setfield(uncuedRE,{1},fields{ii},{[1:length(addthis)]},addthis);
%             clear addthis;
%         end
%
%         if isempty(sUrsvpR.trial)
%             % using grating record to replace missing data points from
%             % trial 1 for the uncued stream
%             % note: gratingrecord includes 2 presentations per trial, though
%             % only one/tr was actually run
%             load([fdir '\short_' fname '_RSVPRECORD1.mat']);
%             uncuedLE.trial   = [1 uncuedLE.trial];
%             uncuedLE.horzdva = [RSVPRECORD(unqtr).rf_xpos uncuedLE.horzdva];
%             uncuedLE.vertdva = [RSVPRECORD(unqtr).rf_ypos uncuedLE.vertdva];
%             uncuedLE.xpos = [RSVPRECORD(unqtr).rf_xpos uncuedLE.xpos];
%             uncuedLE.ypos = [RSVPRECORD(unqtr).rf_ypos uncuedLE.ypos];
%             [theta,eccentricity] = cart2pol(RSVPRECORD(unqtr).rf_xpos, RSVPRECORD(unqtr).rf_ypos);
%             uncuedLE.theta = [rad2deg(theta) uncuedLE.theta];
%             uncuedLE.eccentricity = [eccentricity uncuedLE.eccentricity];
%             uncuedLE.tilt = [RSVPRECORD(unqtr).uncuedstream_ori(1,1)' uncuedLE.tilt];
%             uncuedLE.cued_con = RSVPRECORD(1).uncued_stimcond(1);
%             uncuedLE.sf = [RSVPRECORD(unqtr).uncuedstream_sf(1) uncuedLE.sf];
%             uncuedLE.contrast = [uncuedLE.contrast(1) uncuedLE.contrast]; %assuming it's the same as the other tirals
%             uncuedLE.diameter = [uncuedLE.diameter(1) uncuedLE.diameter]; %assuming it's the same as the other trials
%             uncuedLE.dominanteye = [uncuedLE.dominanteye uncuedLE.dominanteye]; %assuming it's the same as the other trials
%             uncuedLE.gaborfilteron = [uncuedLE.gaborfilteron(1) uncuedLE.gaborfilteron];%assuming it's the same as the other trials
%             uncuedLE.gabor_std = [uncuedLE.gabor_std(1) uncuedLE.gabor_std]; %assuming it's the same as the other trials
%             uncuedLE.header = [RSVPRECORD(unqtr).header uncuedLE.header];
%
%
%
%             uncuedRE.trial   = [1 uncuedRE.trial];
%             uncuedRE.horzdva = [RSVPRECORD(unqtr).rf_xpos uncuedRE.horzdva];
%             uncuedRE.vertdva = [RSVPRECORD(unqtr).rf_ypos uncuedRE.vertdva];
%             uncuedRE.xpos = [RSVPRECORD(unqtr).rf_xpos uncuedRE.xpos];
%             uncuedRE.ypos = [RSVPRECORD(unqtr).rf_ypos uncuedRE.ypos];
%             [theta,eccentricity] = cart2pol(RSVPRECORD(unqtr).rf_xpos, RSVPRECORD(unqtr).rf_ypos);
%             uncuedRE.theta = [rad2deg(theta) uncuedRE.theta];
%             uncuedRE.eccentricity = [eccentricity uncuedRE.eccentricity];
%
%             uncuedRE.tilt = [RSVPRECORD(unqtr).uncuedstream_ori(2,1)' uncuedRE.tilt];
%             uncuedRE.cued_con = RSVPRECORD(1).uncued_stimcond(1);
%             uncuedRE.sf = [RSVPRECORD(unqtr).uncuedstream_sf(1) uncuedRE.sf];
%             uncuedRE.contrast = [uncuedRE.contrast(1) uncuedRE.contrast]; %assuming it's the same as the other tirals
%             uncuedRE.diameter = [uncuedRE.diameter(1) uncuedRE.diameter]; %assuming it's the same as the other trials
%             uncuedRE.dominanteye = [uncuedRE.dominanteye uncuedRE.dominanteye]; %assuming it's the same as the other trials
%             uncuedRE.gaborfilteron = [uncuedRE.gaborfilteron(1) uncuedRE.gaborfilteron];%assuming it's the same as the other trials
%             uncuedRE.gabor_std = [uncuedRE.gabor_std(1) uncuedRE.gabor_std]; %assuming it's the same as the other trials
%             uncuedRE.header = [RSVPRECORD(unqtr).header uncuedRE.header];
%
%         end
%
%         uncued_stimcond = [RSVPRECORD.uncued_stimcond];
%         uncuedLE.stimcond = uncued_stimcond(1,:);
%         uncuedRE.stimcond = uncued_stimcond(1,:);
%         uncuedLE = rmfield(uncuedLE,'cued_cond');
%         uncuedRE = rmfield(uncuedRE,'cued_cond');
%
%         cuedLE.stimcond = cuedLE.cued_cond;
%         cuedRE.stimcond = cuedRE.cued_cond;
%         cuedLE = rmfield(cuedLE,'cued_cond');
%         cuedRE = rmfield(cuedRE,'cued_cond');
%
% end

% switch RSVP.dominanteye(1)
%     case 2 % RE is dominant
%         cuedD = cuedRE;
%         cuedS = cuedLE;
%         uncuedD = uncuedRE;
%         uncuedS = uncuedLE;
%     case 3 % LE is dominant
%         cuedD = cuedLE;
%         cuedS = cuedRE;
%         uncuedD = uncuedLE;
%         uncuedS = uncuedRE;
% end
%
%
%
%
%
% end



