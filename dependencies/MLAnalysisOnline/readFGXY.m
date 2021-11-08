function grating = readFGXY(filename, startRow, endRow)
% reads .gFSG, .gFTG, .gFDG (generted by gfTargetGratingXY, etc.) 
% output is structure array describing stimuli on each trial

% MAC, DEC 2014
% Made with help from MATLAB import data


%% Check Input
[~,~,ext] = fileparts(filename); 
if ~any(strcmp(ext,{'.gFSG','.gFTG','.gFDG','.gGratingXY','.gDotsXY'}));
    error('wrong filetype for this function')
end

%% Initialize variables.
delimiter = '\t';
if nargin<=2
    startRow = 2;
    endRow = inf;
end

%% Format string for each line of text:
%   column1: double (%f) trial
%	column2: double (%f) horzdva
%   column3: double (%f) vertdva
%	column4: double (%f) theta
%   column5: double (%f) eccentricity
%	column6: double (%f) tilt
%   column7: double (%f) sf
%	column8: double (%f) contrast
%   column9: double (%f) diameter
%   column10: text  (%s) colors
%   column11: double(%f) timestamp
% For more information, see the TEXTSCAN documentation.
formatSpec =  '%f%f%f%f%f%f%f%f%f%s%f\r\n';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Allocate imported array to column variable names
grating.trial = dataArray{:, 1};
grating.horzdva = dataArray{:, 2};
grating.vertdva = dataArray{:, 3};
grating.theta = dataArray{:, 4};
grating.eccentricity = dataArray{:, 5};
grating.tilt = dataArray{:, 6};
grating.sf = dataArray{:, 7};
grating.contrast = dataArray{:, 8};
grating.diameter = dataArray{:, 9};
grating.colors = [dataArray{:,10}]; grating.colors = cellfun(@eval,grating.colors,'UniformOutput',0);
grating.timestamp = dataArray{:, 11};
grating.filename = filename;
grating.startRow = startRow;
grating.endRow = endRow;


