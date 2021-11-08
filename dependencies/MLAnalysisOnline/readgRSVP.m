function rsvp = readgRSVP(filename)

%% output is structure array describing stimuli on each trial

% MAC, DEC 2014
% Made with help from MATLAB import data
% modified by Kacie for di stimulus dev
% slight update by michele in Nov 2015
% major uodate March 1 to refelct changes in TXT file saves

% Check Input
[~,BRdatafile,ext] = fileparts(filename);
if ~any(strcmp(ext,{'.gCue_di','.gLeftDStim_di','.gLeftStim_di','.gRightDStim_di','.gRightStim_di','.gLeftTarg_di','.gRightTarg_di'}));
    error('wrong filetype for this function')
end

% Initialize variables.
delimiter = '\t';
startRow = 2;
endRow = inf;

%% date-depended read in to account for changes
if strcmp(BRdatafile(1:10),'Experiment')
    n = datenum(BRdatafile(16:25),'mm-dd-yyyy');
else
    n = datenum(BRdatafile(1:6),'yymmdd');
end

if n < datenum('02/29/2016','mm/dd/yyyy');
    
    % Format string for each line of text:
    if strcmp(ext,'.gCue_di');
        formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%s%[^\n\r]';
    else
        formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%s%[^\n\r]';
    end
    
    % Open the text file.
    fileID = fopen(filename,'r');
    
    % Read columns of data according to format string.
    dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
    
    % Close the text file.
    fclose(fileID);
    
    % Allocate imported array to column variable names
    
    if strcmp(ext,'.gCue_di')
        rsvp.trial    = dataArray{:, 1};
        rsvp.horzdva  = dataArray{:, 2};
        rsvp.vertdva  = dataArray{:, 3};
        rsvp.xpos    = dataArray{:, 4};
        rsvp.ypos    = dataArray{:, 5};
        rsvp.theta  = dataArray{:, 6};
        rsvp.eccentricity = dataArray{:,7};
        rsvp.tilt = dataArray{:,8};
        rsvp.sf   = dataArray{:,9};
        rsvp.contrast = dataArray{:,10};
        rsvp.diameter = dataArray{:,11};
        rsvp.dominanteye = dataArray{:,12};
        rsvp.gaborfilteron = dataArray{:,13};
        rsvp.gabor_std  = dataArray{:,14};
        rsvp.header  = dataArray{:,15};
        rsvp.filename = filename;
        rsvp.startRow = startRow;
        rsvp.endRow = endRow;
    else
        rsvp.trial    = dataArray{:, 1};
        rsvp.horzdva  = dataArray{:, 2};
        rsvp.vertdva  = dataArray{:, 3};
        rsvp.xpos    = dataArray{:, 4};
        rsvp.ypos    = dataArray{:, 5};
        rsvp.theta  = dataArray{:, 6};
        rsvp.eccentricity = dataArray{:,7};
        rsvp.tilt = dataArray{:,8};
        rsvp.sf   = dataArray{:,9};
        rsvp.contrast = dataArray{:,10};
        rsvp.diameter = dataArray{:,11};
        rsvp.dominanteye = dataArray{:,12};
        rsvp.gaborfilteron = dataArray{:,13};
        rsvp.gabor_std  = dataArray{:,14};
        rsvp.stimcond  = dataArray{:,15};
        rsvp.header     = dataArray{:,16};
        rsvp.filename = filename;
        rsvp.startRow = startRow;
        rsvp.endRow = endRow;
        
    end
    
else
    
    if n > datenum('03/03/2016','mm/dd/yyyy');
        if strcmp(ext,'.gCue_di');
            headerSpec =  '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t\r\n';
            formatSpec =  '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%s\t%s\t%f\t%f\t%f\t%f\r\n';
        else
            headerSpec =  '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\r\n';
            formatSpec = '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%s\t%s\t%f\t%f\t%f\t%f\t%f\r\n';
        end
    else
        if strcmp(ext,'.gCue_di');
            headerSpec =  '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t\r\n';
            formatSpec =  '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%s\t%s\t%f\t%f\t%f\r\n';
        else
            headerSpec =  '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\r\n';
            formatSpec = '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%s\t%s\t%f\t%f\t%f\t%f\r\n';
        end
    end
    
    % Open the text file.
    fileID = fopen(filename,'r');
    
    % Read columns of data according to format string.
    headerArray = textscan(fileID, headerSpec, 1);
    dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1);
    
    % Close the text file.
    fclose(fileID);
    
    % convert to structure
    fields = headerArray;
    for f = 1:length(fields)
        if isnumeric( dataArray{:,f})
            rsvp.(fields{f}{1}) = double(dataArray{:,f});
        else
            rsvp.(fields{f}{1}) = dataArray{:,f};
        end
    end  
    rsvp.filename = filename;
end



