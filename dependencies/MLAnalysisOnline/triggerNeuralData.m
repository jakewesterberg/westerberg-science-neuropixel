function [data data2] = triggerNeuralData(neural,pres,pre,post,evcodes,evtimes)

if iscell(neural)
    type = 'spikes';
else
    type = 'analog';
end
switch type
    
    case 'analog'
        tnum = numel(pres);
        ct = 0;
        data = nan(length(pre:post),size(neural,2),length(evcodes)./2,length(pres)); % time X channels X presentation # x condition
        for i = 1:tnum
            
            if ~isempty(pres{i})
                
                for p = 1:length(pres{i})
                    ct = ct + 1;
                    tref = floor(evtimes(pres{i}(p)) + pre) : floor(evtimes(pres{i}(p)) + post);
                    data(:,:,ct,i) = neural(tref,:);
                    
                end
                
            end
            
        end
        data2 = []; 
    case 'spikes'
        
        spkvec = [];
        spktr  = [];
        tnum = numel(pres);
        
        for i = 1:tnum            
            if ~isempty(pres{i})
                
                for p = 1:length(pres{i})
                    tref = stimON + pre : stimON + post;
                    these = find(spkt{ch} >= tref(1) & spkt{ch} <= tref(end));
                    if any(these)
                        [~,id] = find(ismember(tref, neural{ch}(these)));
                        spkvec = [spkvec tvec(id)]; % collect snippets of signal for these trs at this pos
                        spktr  = [spktr repmat(p,length(these),1)'];
                    end
                    clear tref
                end
                
            end
        end
        
        data = spkvec; data2 = spktr; 
        
end