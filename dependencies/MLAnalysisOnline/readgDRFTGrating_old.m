function grating = readgDRFTGrating(filename, startRow, endRow)

%% output is structure array describing stimuli on each trial

% THIS FILE, new Oct 10 2016
% my MAC for gMCOSINTEROCDRFTGrating_di ONLY at this point

% MAC, DEC 2014
% Made with help from MATLAB import data
% modified by Kacie for analyzing dot mapping code
% additional revisions Jan 2016 to add more features / corrections, make
% backwards compatable

%% Check Input
[~,~,ext] = fileparts(filename);
if ~any(strcmp(ext,{'.gMCOSINTEROCDRFTGrating_di'}));
    error('wrong filetype for this function')
end
% if ~any(strcmp(ext,{'.gDISPARITYDRFTGrating_di','.gBWFLICKERDRFTGrating_di','.gCOLORFLICKERDRFTGrating_di','.gTFSFDRFTGrating_di','.gSFDRFTGrating_di','.gRFORIDRFTGrating_di','.gCINTEROCDRFTGrating_di','.gCOSINTEROCDRFTGrating_di','.gRFSIZEDRFTGrating_di','.gCINTEROCORIDRFTGrating_di','.gMCOSINTEROCDRFTGrating_di','.gCPATCHDRFTGrating_di','.gCOLORFLICKERGrating_di'}));
%     error('wrong filetype for this function')
% end

% Initialize variables.
delimiter = '\t';
if nargin<=2
    startRow = 2;
    endRow = inf;
end

%% Format string for each line of text:
% For more information, see the TEXTSCAN documentation.
fields = {...
    'trial'...
    'horzdva'...
    'vertdva'...
    'xpos'...
    'ypos'...
    'other_xpos'...
    'other_ypos'...
    'tilt'...
    'sf'...
    'contrast'...
    'fixedc'...
    'diameter'...
    'eye'...
    'varyeye'...
    'oridist'....
    'gaborfilter_on'...
    'gabor_std'...
    'header'...
    'phase'...
    'timestamp'...
    'squarewave_on'...
    'temporal_freq'...
    'disparity'...
    'fix_x'...
    'fix_y'...
    'motion'...
    };

    formatSpec = '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%s\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\r\n';
    

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Allocate imported array to structure column variable names
if length(fields) ~= size(dataArray,2)
    error('bad formatSpec or structure fields for %s',filename)
end

st = 1;
by = 2;
en = length(dataArray{1});
for f = 1:length(fields)
    if isnumeric(dataArray{:, f})
        grating.(fields{f}) = double(dataArray{f}(st:by:en));
    else
        grating.(fields{f}) = dataArray{f}(st:by:en);
    end
end

ntrls          = max(grating.trial); % total trials
npres          = mode(histc(grating.trial,1:max(grating.trial))); % number of "gen" calls written / trial, may be diffrent from RECORD & what was actually shown
grating.pres   = repmat([1:npres]',ntrls,1);

grating.filename = filename;
grating.startRow = startRow;
grating.endRow = endRow;


%% CORRECTIONS FOR SPECIFIC FILES / FILE TYPES GO BELOW

