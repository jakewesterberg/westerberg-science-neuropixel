%%% import_script.m
%%% Jacob A. Westerberg
%%% Vanderbilt University
%%% Created 21-11-07

% start fresh
clear; clc;
fclose all;
format long % my preference

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DEFINE BASIC INFO

% where is the np data located?
np_dir = 'D:\data_transfer\';

% specify... 1) the exact dir
rec_dir = []; % leave blank

% or... 2) the recording data header info
rec_task = 'rom'; %'evp';
rec_subj = 'B52';
rec_date = '2021-11-06';
rec_titt = 1;
rec_expt = 1;
rec_numb = 1;
rec_bank = 'B'; % uncessary currently
rec_node = [106];
adc_node = [119]; % leave empty if same as rec

% evt code location?
evt_form = 'nev'; % 'opep'

% which data?
rec_AP = true;
rec_LF = true;

% recordings params
AP_fs = 30000;
LF_fs = 2500;
AD_fs = 30000;

% common ave ref?
rec_car = true;

% median offset?
rec_moc = true;

% baseline correct?
rec_blc = true;

% AD channels
AD_chs = 1:8;
AD_map.TRIG = 1;
AD_map.LE_X = 2;
AD_map.LE_Y = 3;
AD_map.LE_P = 4;
AD_map.RE_X = 5;
AD_map.RE_Y = 6;
AD_map.RE_P = 7;
AD_map.SYNC = 8;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FILL IN SOME BLANKS

% rec ch vector
chs = 1:384;
chs_no = numel(chs);

% units (by default - might want to extract if things change)
AP_units = 'uV';
LF_units = 'uV';
AD_units = 'V';

% sync ch
chs_sync = 385;

% put together the base dir name
if isempty(rec_dir); rec_dir = [np_dir rec_task '_' rec_subj '_' rec_date '_' num2str(rec_titt) '\']; end

% put together the relevant node dirs
rec_node_dir = [rec_dir 'Record Node ' num2str(rec_node) ...
    '\experiment' num2str(rec_expt) '\recording' num2str(rec_numb) '\'];
if isempty(adc_node)
    adc_node_dir = [rec_dir 'Record Node ' num2str(rec_node) ...
        '\experiment' num2str(rec_expt) '\recording' num2str(rec_numb) '\'];
else
    adc_node_dir = [rec_dir 'Record Node ' num2str(adc_node) ...
        '\experiment' num2str(rec_expt) '\recording' num2str(rec_numb) '\'];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LOAD DATA

% open info files
rec_inff = [rec_node_dir 'structure.oebin'];
rec_info = fileread(rec_inff);
adc_inff = [adc_node_dir 'structure.oebin'];
adc_info = fileread(adc_inff);

% define where the AD data is
AD_file = [adc_node_dir 'continuous\NI-DAQmx-118.0\continuous.dat'];

% open the AD file
AD_fid = fopen(AD_file, 'r');

% determine size of file
fseek(AD_fid, 0, 'eof');
AD_filesize = ftell(AD_fid);
fseek(AD_fid, 0, 'bof');

% determine matrix size
AD_samples = AD_filesize/numel(AD_chs);
if mod(AD_samples,1)~=0; error('Number of samples in AP file is not an integer!'); end
AD_size = [numel(AD_chs), AD_samples];

% load in AP data
AD = fread(AD_fid, AD_size, 'int16');

% close file
fclose all;
clear AP_fid

% extract bitvolts and units for AP
AD_btvc = extract_btvc(adc_info, 'AI1');

if rec_AP

    % define where the AP data is
    AP_file = [rec_node_dir 'continuous\Neuropix-PXI-104.0\continuous.dat'];

    % open the AP file
    AP_fid = fopen(AP_file, 'r');

    % determine size of file
    fseek(AP_fid, 0, 'eof');
    AP_filesize = ftell(AP_fid);
    fseek(AP_fid, 0, 'bof');

    % determine matrix size
    AP_samples = AP_filesize/385;
    if mod(AP_samples,1)~=0; error('Number of samples in AP file is not an integer!'); end
    AP_size = [385, AP_samples];

    % load in AP data
    AP = fread(AP_fid, AP_size, 'int16');
    AP_sync = AP(385, :);
    AP = AP(1:384, :);

    % close file
    fclose all;
    clear AP_fid

    % extract bitvolts and units for AP
    AP_btvc = extract_btvc(rec_info, 'AP1');

    % extract bitvolts and units for AP_sync
    AP_sync_btvc = extract_btvc(rec_info, 'AP_SYNC');

    % convert signals to proper units
    AP = AP .* AP_btvc;
    AP_sync = AP_sync .* AP_sync_btvc;

end

if rec_LF

    % define where the LF data is
    LF_file = [rec_node_dir 'continuous\Neuropix-PXI-104.1\continuous.dat'];

    % open the LF file
    LF_fid = fopen(LF_file, 'r');

    % determine size of file
    fseek(LF_fid, 0, 'eof');
    LF_filesize = ftell(LF_fid);
    fseek(LF_fid, 0, 'bof');

    % determine matrix size
    LF_samples = LF_filesize/385;
    if mod(LF_samples,1)~=0; error('Number of samples in LF file is not an integer!'); end
    LF_size = [385, LF_samples];

    % load in LF data
    LF = fread(LF_fid, LF_size, 'int16');
    LF_sync = LF(385, :);
    LF = LF(1:384, :);

    % close file
    fclose all;
    clear LF_fid

    % extract bitvolts and units for LF
    LF_btvc = extract_btvc(rec_info, 'LFP1');

    % extract bitvolts and units for LF_sync
    LF_sync_btvc = extract_btvc(rec_info, 'LFP_SYNC');

    % convert signals to proper units
    LF = LF .* LF_btvc;
    LF_sync = LF_sync .* LF_sync_btvc;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EVENT CODES

if strcmp(evt_form, 'nev')

    if strcmp(rec_task, 'rom')
        [t_file, t_path] = uigetfile;
        STIM = BRextractevt('rfori', [t_path t_file]);
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PREPROCESS

% downsample adc data
AD = resample(AD', 1, 30); AD = AD';

% find photo triggers on and off
TRIG_on_ind = AD(AD_map.TRIG, :) < ...
    (mean(AD(AD_map.TRIG, :)) - 3 * std(AD(AD_map.TRIG, :)));
[~, TRIG_on_ind] = binsum(TRIG_on_ind, 16, 'pre');
TRIG_off_ind = AD(AD_map.TRIG, :) < ...
    (mean(AD(AD_map.TRIG, :)) - 3 * std(AD(AD_map.TRIG, :)));
[~, TRIG_off_ind] = binsum(TRIG_off_ind, 16, 'post');

% correction to V1 ML tasks as they do not save stim info from incorrect
% trials
if strcmp(rec_task, 'rom')
    bad_ind = TRIG_off_ind - TRIG_on_ind < 250;
    TRIG_on_ind = TRIG_on_ind(~bad_ind);
    TRIG_off_ind = TRIG_off_ind(~bad_ind);
end

% get the adc sync times
adc_sync = AD(AD_map.SYNC, :);

% get the data sync times
if rec_LF; rec_sync = resample(LF_sync, 2, 5);
elseif rec_AP; rec_sync = resample(rec_sync, 1, 30); end

% compute xcorr - note that the lag seems to change over the course of a
% session. need to accomodate by making adjustments in bins...
sync_lag = nan(1,numel(adc_sync));
for i = 100 : 100 : numel(adc_sync) - 5500
    [t_rvl_1, t_lag_1] = xcorr(rec_sync(i:i+4999), adc_sync(i:i+4999), 250);
    [t_max_1, t_ind_1] = max(t_rvl_1);
    sync_lag(i-99:i+99) = t_lag_1(t_ind_1);
    clear -regexp ^t_
    if mod(i, 10000) == 0 
        disp([num2str(i) '/' num2str(numel(adc_sync))])
    end
end
sync_lag(isnan(sync_lag)) = sync_lag(find(~isnan(sync_lag),1,'last'));

% initialize the timing vecs
adc_TIME = 1:numel(adc_sync);
rec_TIME = 1:numel(rec_sync);

% adjust times
adc_TIME = adc_TIME + sync_lag;

% convert ind to times
TRIG_on_time = adc_TIME(TRIG_on_ind);
TRIG_off_time = adc_TIME(TRIG_off_ind);

% apply common average reference
if rec_car
    if rec_AP; AP = comaveref(AP); end;
    if rec_LF; LF = comaveref(LF); end;
end

if rec_moc
    if rec_AP; AP = AP - median(AP, 2); end;
    if rec_LF; LF = LF - median(LF, 2); end;
end

if rec_LF

    LF = resample(LF', 2, 5); LF = LF';

    % compute evp task matrices
    if strcmp('evp', rec_task) | strcmp('rom', rec_task)
        LF_mat = nan(chs_no, 500, numel(TRIG_on_time));
        for i = 1:numel(TRIG_on_time)
            LF_mat(:,:,i) = LF(chs, ...
                find(TRIG_on_time(i)==rec_TIME)-99 : ...
                find(TRIG_on_time(i)==rec_TIME)+400);
        end
        if rec_blc; LF_mat = LF_mat - repmat(mean(LF_mat(:,1:100,:),2), 1, 500, 1); end
    end

    if strcmp('rom', rec_task)

    end

end

if rec_AP

    ME = nan(chs_no, size(AP,2));
    for i = chs; ME(i,:) = computepower(AP(i,:), 30000, 250); end
    ME = resample(ME', 1, 30); ME = ME'; ME = ME(:,1:numel(rec_sync));

    MR = AP < mean(AP,2) - (2.5*std(AP,[],2));
    for i = chs; MR_times{i} = round(find(MR(i,:)) ./ 30); end
    MR = zeros(chs_no, numel(rec_sync));
    for i = chs; MR(i,MR_times{i}) = 1; end
    MC = rasterconvolution(MR, defkernel('psp', 0.02, 1000), 1000);

    if strcmp('evp', rec_task) | strcmp('rom', rec_task)
        MC_mat = nan(chs_no, 500, numel(TRIG_on_time));
        ME_mat = nan(chs_no, 500, numel(TRIG_on_time));
        for i = 1:numel(TRIG_on_time)
            MC_mat(:,:,i) = MC(chs, ...
                find(TRIG_on_time(i)==rec_TIME)-99 : ...
                find(TRIG_on_time(i)==rec_TIME)+400);
            ME_mat(:,:,i) = ME(chs, ...
                find(TRIG_on_time(i)==rec_TIME)-99 : ...
                find(TRIG_on_time(i)==rec_TIME)+400);
        end
        
        if rec_blc
            MC_mat = MC_mat - repmat(mean(MC_mat(:,1:100,:),2), 1, 500, 1);
            ME_mat = ME_mat - repmat(mean(ME_mat(:,1:100,:),2), 1, 500, 1);
        end

    end
end





