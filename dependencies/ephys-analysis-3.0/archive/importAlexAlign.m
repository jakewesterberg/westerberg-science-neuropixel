function aAlign = importAlexAlign
% Feb 27, 2017
% MAC

%% Import the data
[~, ~, raw] = xlsread('/Users/coxm/Dropbox (MLVU)/Shared with Jake/DataLog.xlsx','alexalign');
raw = raw(2:end,:);

%% Allocate imported data to "aAlign" 
aAlign = cell(size(raw,1),4);
for i = 1:size(raw,1)
    
    clear sortdirection
    switch raw{i,7}(1)
        case {'N' 'n'}
            sortdirection = 'descending'; %  descending (NN)
            nel = 32;
            el_array = [nel:-1:1];
        case {'U' 'u'}
            sortdirection = 'ascending'; %  ascending (Uprobe)
            nel = 24;
            el_array = [1:nel] ;
    end
    
    aAlign{i,1} = ...
        [num2str(raw{i,2}) '_' raw{i,1} '_' raw{i,3}]; % session and probe ID
    aAlign{i,2} = sortdirection;
    aAlign{i,3} = [raw{i,3} num2str(raw{i,5})]; % L4 bottom in str
    aAlign{i,4} = find(el_array == raw{i,5});   % L4 bottom in idx from most superfical channel
    
end

if length(unique(aAlign(:,1))) ~= length((aAlign(:,1)))
    error('repeat entry')
end

