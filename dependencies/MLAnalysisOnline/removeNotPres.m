function [structure] = removeNotPres(structure,evtrials,maxpres)

if nargin == 2
    maxpres = 5;
end

rem = [];
for tr = 1:max(structure.trial)
    id = find(evtrials == tr);
    structureid = find(structure.trial == tr);
    
    ran = length(id)./2;
    rem = [rem; structureid((ran+1):end)];
    
end

fields = fieldnames(structure);
fieldleng = structfun(@numel,structure);
for i = 1:length(fields)
    if fieldleng(i) == fieldleng(1)
        structure = setfield(structure,{1},fields{i},{rem},[]);
    end
end

end
