function dot = readgDotsXY_np(filename)
 
%% output is structure array describing stimuli on each trial

% MAC, DEC 2014
% Made with help from MATLAB import data
% modified by Kacie for analyzing dot mapping code 

%% Check Input
[~,BRdatafile,ext] = fileparts(filename); 
if ~any(strcmp(ext,{'.gDotsXY_di'}));
    error('wrong filetype for this function')
end

%% Initialize variables.
delimiter = '\t';
endRow = inf;

n = datenum(BRdatafile(1:6),'yymmdd');

% CORRECTIONS for File-Specific Issues
if n == datenum('01/28/2016','mm/dd/yyyy');
    startRow = 2;
elseif n < datenum('01/29/2016','mm/dd/yyyy');
    startRow = 12; % for files that have weird starts 
else
    startRow = 2;
end

%% Format string for each line of text:
% For more information, see the TEXTSCAN documentation.

fields = {...
    'trial'...
    'horzdva'...
    'vertdva'...
    'dot_x'...
    'dot_y'...
    'dot_eye'...
    'diameter'...
    };

if n < datenum('01/29/2016','mm/dd/yyyy');
    formatSpec = '%u\t%f\t%f\t%f\t%f\t%f\t%f\r\n';
elseif n > datenum('11/05/2021','mm/dd/yyyy');
    formatSpec = '%u\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\r\n';
    fields = horzcat(fields,'contrast','fix_x', 'fix_y', 'timestamp');
else
    formatSpec = '%u\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\r\n';
    fields = horzcat(fields,'contrast','timestamp');
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

st = 1;
en = length(dataArray{1});

for f = 1:length(fields)
    if isnumeric(dataArray{f})
        dot.(fields{f}) = double(dataArray{f}(st:en));
    else
        dot.(fields{f}) = dataArray{f}(st:en);
    end
end

dot.filename = filename;

