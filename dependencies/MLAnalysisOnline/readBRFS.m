function brfs = readBRFS(filename)
% MAC, DEC 2015
% Made with help from MATLAB import data


%% Check Input
[~,BRdatafile,ext] = fileparts(filename);
if ~(strcmp(ext,'.gBrfsGratings'));
    error('wrong filetype for this function')
end

% Import the file
data = importdata(filename);
if  isstruct(data)
    data = data.data;
end

% CORRECTIONS for File-Specific Issues
switch BRdatafile
    case '151222_E_brfs001'
        st = 4;
        en = size(data,1);
    case '160104_E_brfs001'
        st = 2;
        en = size(data,1);
    otherwise
        st = 1;
        en = size(data,1);
end

% switch for changes to BRFS textfile
n = datenum(BRdatafile(1:6),'yymmdd');
if n < datenum('01/15/2016','mm/dd/yyyy');
    fields = {...
        'trial',...
        'grating_xpos',...
        'grating_ypos',...
        'grating_tilt',...
        'grating_sf',...
        'grating_diameter',...
        'grating_eye',...
        'eye_contrast',...
        'other_contrast',...
        'oridist',...
        'gaborfilter_on',...
        'gabor_std',...
        'total_stim_dur',...
        'soa_dur',...
        'isi_dur',...
        'timestamp'};
else
    fields = {...
        'trial',...
        'grating_xpos',...
        'grating_ypos',...
        'grating_tilt',...
        'grating_sf',...
        'grating_phase',... % added phase on Jan 15, 2016 (change logged in git), MAC
        'grating_diameter',...
        'grating_eye',...
        'eye_contrast',...
        'other_contrast',...
        'oridist',...
        'gaborfilter_on',...
        'gabor_std',...
        'total_stim_dur',...
        'soa_dur',...
        'isi_dur',...
        'timestamp'};
end

for f = 1:length(fields)
    if isnumeric( data(:,f))
        brfs.(fields{f}) = double(data(st:en,f));
    else
        brfs.(fields{f}) = data(st:en,f);
    end
end

brfs.eye_contrast   = double(round( brfs.eye_contrast   .* 1000) / 1000);
brfs.other_contrast = double(round( brfs.other_contrast .* 1000) / 1000);

% extracted params to make analysis easier
% added Jan 2016
s1_eye = brfs.grating_eye;
s2_eye = zeros(size(s1_eye));
s2_eye(s1_eye == 2) = 3; s2_eye(s1_eye == 3) = 2;

oridist = brfs.oridist;
s1_tilt = brfs.grating_tilt;
s2_tilt = uCalcTilts0to179(s1_tilt, oridist);

s1_contrast  = brfs.eye_contrast;
s2_contrast  = brfs.other_contrast;

brfs.s1_eye      = s1_eye;
brfs.s2_eye      = s2_eye;
brfs.s1_tilt     = s1_tilt;
brfs.s2_tilt     = s2_tilt;
brfs.s1_contrast = s1_contrast;
brfs.s2_contrast = s2_contrast;
brfs.soa         = brfs.soa_dur; brfs = rmfield(brfs,'soa_dur');

stim = cell(size(brfs.soa));
stim(s2_contrast == 0) = {'Monocular'}; % s1 should never have contrast == 0 in this task
stim(oridist == 90 & s2_contrast ~= 0) = {'dCOS'};
stim(oridist == 0  & s2_contrast ~= 0) = {'Binocular'};

brfs.stim = stim;

ntrls       = max(brfs.trial); % total trials
npres       = mode(histc(brfs.trial,1:max(brfs.trial))); % number of "gen" calls written / trial, may be diffrent from RECORD & what was actually shown
brfs.pres   = repmat([1:npres]',ntrls,1);



