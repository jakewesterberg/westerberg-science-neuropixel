function [allpass, message] =  checkTrMatch(grating,NEV)
% grating is the output of the function that reads the textfles written by the gen functions
% NEV is the matching nev file, nust be NEV because NSx timestamp is file stop time

message = cell(3,1);
pass    = ones(3,1);

% extract info from NEV
EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
EventTimes = floor(NEV.Data.SerialDigitalIO.TimeStampSec .* 1000); %ms, to match 1kHz
[pEvC, ~] = parsEventCodesML(EventCodes,EventTimes);

% TEST 1 -- check that trial numbers as recorded in the text file are sequnetial
if any(unique(abs(diff(grating.trial))) > 1 )
    message{1} = 'FAIL: trial numbers as recorded in gTextFile are not sequential';
    pass(1)    = 0;
elseif sum(grating.trial==1) ~= sum(grating.trial==grating.trial(end))
    if sum(grating.trial==1) == 0
        message{1} = 'PASS, *BUT* trial 1 is missing from in gTextFile read-in (ok for early dates)';
        pass(1)    = 1;
    elseif sum(grating.trial==2) ~= sum(grating.trial==grating.trial(end))
        message{1} = 'FAIL: prez numbers as recorded in gTextFile are not consistent across files';
        pass(1)    = 0;
    else
        message{1} = 'FAIL: trail 1 presentations are missing';
        pass(1)    = 0;
    end
else
    message{1} = 'PASS: gTextFile trial numbers sequential';
end

% TEST 2 -- check that trial numbers as recorded in the event codes are sequnetial
if mode(cellfun(@(x) sum(x >= 116),pEvC)) == 3
    % this file sent block, condition number, and last diget of
    % trial number after the inital 999 trial start
    
    trlnums = double(cellfun(@(x) x(find(x >= 116 & x < 128 ,1,'last')) - 116, pEvC));
    if length(trlnums) == 1
        message{2} = 'NULL: could not test b/c only 1 trial recorded';
        pass(2)    = NaN;
    else
        
        if ~isequal(unique(diff(trlnums)),[-9 1]) % this is a clever way to check if the trials are sequential. 
            if length(trlnums) <= 9 && isequal(unique(diff(trlnums)),[1]) % special case for when there's 9 trials or less
                message{2} = 'PASS: Event Codes trial numbers sequential';
            else
                message{2} = 'FAIL: trial numbers as recorded in Event Codes are not sequential';
                pass(2)    = 0;
            end
        else
            message{2} = 'PASS: Event Codes trial numbers sequential';
        end
    end
else
    message{2} = 'NULL: could not test';
    pass(2)    = NaN;
end

% TEST 3 --  compare timestamps between ML and BR files
fields = fieldnames(grating);
if any(strcmp(fields,'timestamp'))
    mlstart = grating.timestamp(1);
    brstart = datenum(NEV.MetaTags.DateTime,'dd-mmm-yyyy HH:MM:SS');
    if mlstart < brstart
        t = etime(datevec(brstart),datevec(mlstart)); % seconds
        n = datenum(NEV.MetaTags.DateTime,'dd-mmm-yyyy');
        if (n >= datenum('160922','yymmdd') && n <= datenum('161012','yymmdd')) && t < 10
            message{3} = sprintf('PASS, *BUT* 1st ML timestamp is %0.3fs before BR record time, OK for select dates',t);
            pass(3)    = 1;
        elseif t < 1
            message{3} = sprintf('PASS, *BUT* 1st ML timestamp is %0.3fs before BR record time',t);
            pass(3)    = 1;
        else
            message{3} = sprintf('FAIL: 1st ML timestamp is %0.3fs before BR record time',t);
            pass(3)    = 0;
        end
    else
        message{3} = 'PASS: BR record time precedes ML timstamps';
    end
else
    message{3} = 'NULL: could not test';
    pass(3)    = NaN;
end



pass(isnan(pass)) = [];
if all(pass)
    allpass = true;
else
    allpass = false;
end




