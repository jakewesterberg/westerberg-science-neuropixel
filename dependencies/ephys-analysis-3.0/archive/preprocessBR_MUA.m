% July 2014, December 2015
% simple filtering of BR data (NS6) into  MUA signal
% decimated to 1kHz
% MAC

function preprocessBR_MUA(fileinput,savepath)

% get NPMK on path
setupNPMK

% get filename
if nargin == 2
    [datapath,datafile,~] = fileparts(fileinput); % will ignore extension and query below
else
    currentFolder = pwd;
    cd('/Volumes/DROBO/DATA/NEUROPHYS')
    [fileinput, pathinput] = uigetfile('*.*');
    [datapath,datafile,~] = fileparts([pathinput '/' fileinput]);
    cd(currentFolder);
end

filename = fullfile(datapath,datafile);


fprintf('\nmaking analog MUA %s\n',filename)


% check if file exist and load NEV w/o spiking data
if exist(strcat(filename,'.nev'),'file') == 2;
    NEV = openNEV(strcat(filename,'.nev'),'noread','nomat','nosave');
else
    error('the following file does not exist\n%s.nev',filename);
end

% check for continious file NS#
queryuser = 0;
if exist(strcat(filename,'.ns6'),'file') == 2;
    extension = 'ns6';
elseif exist(strcat(filename,'.ns5'),'file') == 2;
    % read in header info and see if data was filtered at collection
    NS = openNSx(strcat(filename,'.ns5'),'noread','precision','double');
    if mode([NS.ElectrodesInfo.HighFreqCorner]) == 300 && mode([NS.ElectrodesInfo.HighFreqCorner]) == 500000
        % N5 is unfiltered
        extension = 'ns5';
    else
        % NS is filtered
        queryuser = 1;
    end
    clear NS
else
    queryuser = 1;
end
% if the continius data was not NS6 or unfiltered NS5, ask user if they want to proceede
if queryuser
    prompt = 'We typically run this code on an unfiltered 30kHz signal (.ns6 or .ns5 file).\nProvide file extension (ns#, no ".") to continue or any other value to abort:\n';
    answer = input(prompt,'s');
    answer = lower(answer);
    if  strfind(answer,'ns')
        extension = answer;
    else
        return
    end
end

% get event codes from NEV, then clear
EventCodes = NEV.Data.SerialDigitalIO.UnparsedData - 128;
EventTimes = NEV.Data.SerialDigitalIO.TimeStampSec * 1000; %ms, to match 1kHz
clear NEV

% Read in NS Header
NS_Header = openNSx(strcat(filename,'.',extension),'noread');
% get basic info about recorded data
neural = ~strcmp('E',{NS_Header.ElectrodesInfo.ConnectorBank}); % bank E is the BNCs on the fron of the NSP
N.electrodes = length(neural);
N.neural = sum( neural);
N.analog = sum(~neural);
%get labels
NeuralLabels = {NS_Header.ElectrodesInfo(neural).Label};
NeuralInfo = NS_Header.ElectrodesInfo(neural);

% get sampeling frequnecy
Fs = NS_Header.MetaTags.SamplingFreq;

% counters
clear act nct
nct = 0;

% process data electrode by electrode
for e = 1:N.electrodes
    
    
    if neural(e) == 1
        nct = nct+1;
        % analyze neural data only
        % don't care about BNC data
        
        clear NS DAT
        electrode = sprintf('c:%u',e);
        NS = openNSx(strcat(filename,'.',extension),electrode,'read','uV','precision','double');
        if iscell(NS.Data)
            DAT = cell2mat(NS.Data); 
        else
            DAT = NS.Data;
        end
        NS.Data = [];
                        
        % f_calcMUA
        mua = f_calcMUA(DAT,Fs,'extralp');
        %preallocation
        if nct == 1
            N.samples = length(mua); %samples in header diffrent from actual data length???
            clear MUA
            MUA = zeros(N.samples,N.neural);
        end
        MUA(:,nct) = mua;
        clear mua
        
        % save and clear when all channels have been read in
        if nct == N.neural
            fprintf('\nsaving MUA...\n')
            savefile = sprintf('%s/%s.mua',savepath,datafile);
            save(savefile,'MUA','NeuralLabels','NeuralInfo','EventCodes','EventTimes','-mat')
            clear MUA
        end
        
    end
    
end





