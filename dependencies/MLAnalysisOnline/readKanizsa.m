function kanizsa = readKanizsa(filename)
% MAC, DEC 2015
% Made with help from MATLAB import data


%% Check Input
[~,fname,ext] = fileparts(filename);
if ~(strcmp(ext,'.gKanizsa'));
    error('wrong filetype for this function')
end

% Import the file
data = importdata(filename);
dataArray = data.textdata;

switch  fname(1:8)
    case '151206_E'
        % %% Allocate imported array to column variable names
        kanizsa.trial = str2double(dataArray(2:end, 1));
        kanizsa.stimidx = str2double(dataArray(2:end, 2));
        kanizsa.figure_value = str2double(dataArray(2:end, 3));
        kanizsa.figure_string = dataArray(2:end, 4);
        kanizsa.color_value = str2double(dataArray(2:end, 5));
        kanizsa.color_string = dataArray(2:end, 6);
        kanizsa.dioptic_value = str2double(dataArray(2:end, 7));
        kanizsa.dioptic_string = dataArray(2:end, 8);
        kanizsa.contour_value = str2double(dataArray(2:end, 9));
        kanizsa.contour_string = dataArray(2:end, 10);
        kanizsa.rfX = [];
        kanizsa.rfY = [];
        kanizsa.inducer_diameter = [];
        kanizsa.inducer_spacing = [];
        kanizsa.timestamp = data.data;
        kanizsa.filename = filename;
    otherwise
        
        % %% Allocate imported array to column variable names
        kanizsa.trial = str2double(dataArray(2:end, 1));
        kanizsa.stimidx = str2double(dataArray(2:end, 2));
        kanizsa.figure_value = str2double(dataArray(2:end, 3));
        kanizsa.figure_string = dataArray(2:end, 4);
        kanizsa.color_value = str2double(dataArray(2:end, 5));
        kanizsa.color_string = dataArray(2:end, 6);
        kanizsa.dioptic_value = str2double(dataArray(2:end, 7));
        kanizsa.dioptic_string = dataArray(2:end, 8);
        kanizsa.contour_value = str2double(dataArray(2:end, 9));
        kanizsa.contour_string = dataArray(2:end, 10);
        kanizsa.rfX = data.data(:,1);
        kanizsa.rfY = data.data(:,2);
        kanizsa.inducer_diameter = data.data(:,3);
        kanizsa.inducer_spacing = data.data(:,4);
        kanizsa.timestamp = data.data;
        kanizsa.filename = filename;
end

%

