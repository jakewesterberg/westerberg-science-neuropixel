function grating = readgGrating(filename, startRow, endRow)
 
%% output is structure array describing stimuli on each trial

% MAC, DEC 2014
% Made with help from MATLAB import data
% modified by Kacie for analyzing dot mapping code 
% additional revisions Jan 2016 to add more features / corrections, make backwards compatable

%% Check Input
[~,BRdatafile,ext] = fileparts(filename); 

%% Initialize variables.
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
    'tilt'...
    'sf'...
    'contrast'...
    'fixedc'...
    'diameter'...
    'eye'...
    'varyeye'...
    'oridist'...
    'gabor'...
    'gabor_std'...
    'header'...
    };

n = datenum(BRdatafile(1:6),'yymmdd');
if n < datenum('01/12/2016','mm/dd/yyyy');
    formatSpec = '%u\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%u\t%u\t%s\r\n';
elseif n < datenum('01/24/2016','mm/dd/yyyy')
    %added extra %f for phase on 1/12/2016
    formatSpec = '%u\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%u\t%u\t%s\t%f\r\n';
    fields = horzcat(fields,'phase');
elseif n < datenum('10/10/2016','mm/dd/yyyy')
    formatSpec = '%u\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%u\t%u\t%s\t%f\t%f\r\n';
    fields = horzcat(fields,'phase','timestamp');
elseif n<datenum('03/15/2017','mm/dd/yyyy') || (n==datenum('03/15/2017','mm/dd/yyyy') & ~isempty(strfind(BRdatafile,'conedrft')))    %kacie changes
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
        'oridist'...
        'gabor'...
        'gabor_std'...
        'header'...
        'phase'...
        'timestamp'
        };
    formatSpec = '%u\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%u\t%u\t%s\t%f\t%f\r\n';
    
else
    
    %kacie changes
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
        'oridist'...
        'gabor'...
        'gabor_std'...
        'header'...
        'phase'...
        'pathw'...
        'timestamp'
        };
      formatSpec = '%u\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%u\t%u\t%s\t%f\t%f\t%f\r\n';
    
end

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this code.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Allocate imported array to structure column variable names
if length(fields) ~= size(dataArray,2)
    error('bad formatSpec or structure fields for %s',filename)
end

% CORRECTIONS for File-Specific Issues
switch BRdatafile
    case {'160115_E_rom002','151125_E_rom003','160104_E_rom001'}
        st = 41;
        en = length(dataArray{1});
    case '160128_I_rom001'
        st = 296;
        en = length(dataArray{1});
    case '151205_E_rom006'
        st = 21;
        en = length(dataArray{1});
    case '151207_E_rom001'
        st = 76;
        en = length(dataArray{1});
    case '151217_E_rom001'
        st = 16; 
         en = length(dataArray{1});
    case '151221_E_rom001'
        st = 56; 
         en = length(dataArray{1});
    case {'151222_E_rom001','151231_E_rom001','151205_E_rom001'}
        st = 11;
        en = length(dataArray{1});
    case {'151211_E_rom001', '151212_E_rom002','160108_E_rom001'}
        st = 6;
        en = length(dataArray{1});
    otherwise
        st = 1;
        en = length(dataArray{1});
end

for f = 1:length(fields)
    if isnumeric(dataArray{:, f})
        grating.(fields{f}) = double(dataArray{f}(st:en));
    else
        grating.(fields{f}) = dataArray{f}(st:en);
    end
end

ntrls          = max(grating.trial); % total trials
npres          = mode(histc(grating.trial,1:max(grating.trial))); % number of "gen" calls written / trial, may be diffrent from RECORD & what was actually shown
grating.pres   = repmat([1:npres]',ntrls,1);

grating.filename = filename;
grating.startRow = startRow;
grating.endRow = endRow;


%% CORRECTIONS FOR SPECIFIC FILES / FILE TYPES

grating.contrast   = double(round( grating.contrast   .* 1000) / 1000);
grating.fixedc     = double(round( grating.fixedc .* 1000) / 1000);

if strcmp(ext,'.gCOSINTEROCGrating_di')
    grating.oridist =  repmat(90,size(grating.oridist));
    
    n = datenum(BRdatafile(1:6),'yymmdd');
    
    if n <= datenum('151207','yymmdd');
        % Email from Kacie on Mon, Dec 7, 2015 at 5:49 PM: "The problem was that the text file was being written every time a stimulus was made for the left side of the screen.
        % This is because it was basing the saves off of  DOMEYE and not the GRATINGRECORD(CurrentTrialNumber).grating_eye.
        % I changed the code so it bases it off of grating_eye instead of DOMEYE."
        grating.eye =  repmat(3,size(grating.eye));
    end
end



