% updated 10/24/17
% focusing on CRFs

didir   = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Oct18/';
load([didir 'matlab.mat'],'IDX')

%%

clearvars -except IDX

klstype  = 'kls only';

KEY = IDX(1).diKEY(:,:);
dilim = find(KEY(:,1)>0,1):find(KEY(:,4)==0,1,'last');
mplim  = find(KEY(:,1)  == 0);
allcontrasts = unique(KEY(:,2)); allcontrasts(allcontrasts==0) = [];
step = length(allcontrasts);
clear KEY


%% setup contrast group
goodc = [.2250,.4500,.9000];


%%

for u = 1:3
    
    if u == 1
        unittype = 'effect of ori and eye';
    elseif u == 2
        unittype = 'effect of ori but not eye';
    else
        unittype = 'effect of ori';
    end
    alpha = 0.05;
    occular = [IDX.occ];
    tuning  = [IDX.ori];
    dianov  = [IDX.dianov];
    kls     = [IDX.kls];
    
    clear I
    switch unittype
        case 'effect of ori but not eye'
            oI = (dianov(2,:)<alpha) | (tuning(1,:) < alpha & min(abs([tuning(2,:); tuning(2,:)+180] - [IDX.prefori;IDX.prefori])) <= 20);
            eI = (dianov(1,:)>=alpha) | occular(1,:) >= alpha;
            I  = oI & eI;
        case 'effect of ori and eye'
            oI = (dianov(2,:)<alpha) | (tuning(1,:) < alpha & min(abs([tuning(2,:); tuning(2,:)+180] - [IDX.prefori;IDX.prefori])) <= 20);
            eI = (dianov(1,:)<alpha) | occular(1,:) < alpha;
            I  = oI & eI;
        case 'effect of ori'
            I = (dianov(2,:)<alpha) | (tuning(1,:) < alpha & min(abs([tuning(2,:); tuning(2,:)+180] - [IDX.prefori;IDX.prefori])) <= 20);
        otherwise
            error('bad unittype')
    end
    
    switch klstype
        case 'kls only'
            I = I & kls;
            unittype = [unittype ', kls only'];
        case 'auto only'
            I = I & ~kls;
            unittype = [unittype ', auto only'];
    end
    
    figure('Unit','Inches','Position',[0 0 7 10]);
    for w = 1:3
        
        crfct = 0; clear CRF
        for i = 1:length(I)
            
            % check for main conditions
            [dicond,diidx] = intersect(IDX(i).dicond,dilim);
            [mcond ,midx]  = intersect(IDX(i).dicond,mplim); % monocular pref
            if ~I(i) || isempty(dicond) || isempty(mcond)
                continue
            end
            
            clear temp crf soa0
            temp = nan(length(IDX(i).diKEY),1);
            temp(IDX(i).dicond) = IDX(i).rCRF(:,w);
            soa0  = IDX(i).diKEY(:,4) == 0;
            temp  = temp(soa0,:);
            crf   = reshape(temp,step,[]);
            % determin max contrast monocular
            idx = find(~isnan(crf(:,4)),1,'last');
            val = crf(idx,4);
            
            crfct = crfct + 1;
            CRF(:,:,crfct) = crf ./ val;
            
        end
        
        clear stim ndec
        stim  = reshape(IDX(i).diKEY(soa0,1),step,[]);
        ndec  = reshape(IDX(i).diKEY(soa0,3),step,[]);
        clear uCRF nCRF
        uCRF  = nanmean(CRF,3);
        nCRF  = sum(~isnan(CRF),3);
        
        %%
        
        for s = 1:size(uCRF,2)
            
            [x,idx]=intersect(allcontrasts,goodc);
            y = uCRF(idx,s);
            if all(isnan(y))...
                    || (stim(1,s) > 0 && ~ismember(ndec(1,s),goodc))
                continue
            end
            x(isnan(y)) = [];
            y(isnan(y)) = [];
            
            switch stim(1,s)
                case {-3,-2};
                    if stim(1,s) == -2
                        subplot(3,2,1-2+(w*2))
                    else
                        subplot(3,2,2-2+(w*2))
                    end
                    h = plot(x,y,'-o'); hold on;
                    set(h,'color',[.5 .5 .5])
                case 0
                    for p = 1:2
                        subplot(3,2,p-2+(w*2))
                        h = plot(x,y,'-o'); hold on;
                        set(h,'color',[0 0 0],'LineWidth',2)
                    end
                case 1
                    subplot(3,2,1-2+(w*2))
                    h = plot(x,y,'-o'); hold on;
                    colors = flipud(winter(step));
                    cidx = s - find(stim(1,:)==1,1) + 1;
                    set(h,'color',colors(cidx,:))
                case 2
                    subplot(3,2,2-2+(w*2))
                    h = plot(x,y,'-o'); hold on;
                    colors = flipud(autumn(step));
                    cidx = s - find(stim(1,:)==2,1) + 1;
                    set(h,'color',colors(cidx,:))
            end
        end
        
        
        for p = 1:2
            subplot(3,2,p-2+(w*2))
            set(gca,'Box','off','TickDir','out')
            xlabel('Contrast')
            ylabel('Norm. Resp')
            xlim(goodc([1 end]) + [-0.1 0.1])
            if p == 1 && w == 1
                title(sprintf('%s\nwin = %0.2f to %0.2f',unittype,IDX(1).statwin(w,1),IDX(1).statwin(w,2)))
            elseif p ==1
                title(sprintf('win = %0.2f to %0.2f',IDX(1).statwin(w,1),IDX(1).statwin(w,2)))
            end
            
        end
        
    end
end
