
function [DAT, Labels] = f_sortDatbyLabelsBR(DAT,NeuralLabels,el)
clear ids Labels

% sort electrode contacts in ascending order:
ids = zeros(1,size(DAT,2));
for ch = 1:length(ids)
    chname = strcat(sprintf('%s',el),sprintf('%02d',ch));
    id = find(~cellfun('isempty',strfind(NeuralLabels,chname)));
    if ~isempty(id)
        ids(ch) = id;
        Labels{ch,:} = chname;
    end
end

% remove colums that do not have a match for the input electrode
DAT(:,ids == 0) = [];
ids(ids == 0) = [];

DAT = DAT(:,ids);