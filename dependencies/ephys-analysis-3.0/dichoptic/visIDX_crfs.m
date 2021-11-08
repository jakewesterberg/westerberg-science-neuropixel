% updated 10/24/17
% focusing on CRFs
% works w/ diKEY version of IDX

didir   = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Oct18/';
load([didir 'IDX_Oct25.mat'],'IDX')

%%

clearvars -except IDX

signaltype  = 'kls';

KEY = IDX(1).diKEY(:,:);
dilim = find(KEY(:,1)>0,1):find(KEY(:,4)==0,1,'last');
mplim  = find(KEY(:,1)  == 0);
allcontrasts = unique(KEY(:,2)); allcontrasts(allcontrasts==0) = [];
step = length(allcontrasts);
clear KEY


%% setup contrast group
%goodc = [.2250,.4500,.9000];

flag_grpc = 1;
clear cnt cgrp clevel
cnt = allcontrasts;
cgrp = nan(size(cnt));
cgrp(cnt < 0.2) = 1;
cgrp(cnt >= 0.2 & cnt <= 0.3) = 2;
cgrp(cnt >= 0.4 & cnt <= 0.6) = 3;
cgrp(cnt >= 0.8 & cnt <= 1.0) = 4;
clevel = [0.1 0.2 0.5 0.9];


%%

for u = 3
    
    clear unittype
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
    nev     = [IDX.nev];
    csd     = [IDX.csd];
    depth   = [IDX.depth];
    
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
    
    switch signaltype
        case 'kls'
            I = I & kls;
            unittype = [unittype ', KLS'];
        case {'auto','nev'}
            I = I & nev;
            unittype = [unittype ', dMUA'];
        case 'spiking'
            I = I & ~csd;
            unittype = [unittype ', Spiking'];
        case 'csd'
            I = I & csd;
            unittype = [unittype ', CSD'];
        case 'l4csd'
            I = I & csd & depth(3,:) <= 5 & depth(3,:) >= 0;
            unittype = [unittype ', L4 CSD'];
        otherwise
            error('need to specify signal type')
    end
    
    figure('Unit','Inches','Position',[0 0 7 10]);
    for w = 1:3
        
        crfct = 0; clear CRF
        for i = 1:length(I)
            
            if ~I(i)
                continue
            end
            
            % check for main conditions
            [dicond,diidx] = intersect(IDX(i).dicond,dilim);
            [mcond ,midx]  = intersect(IDX(i).dicond,mplim); % monocular pref
            if isempty(dicond) || isempty(mcond)
                continue
            end
            
            clear temp crf soa0
            temp = nan(length(IDX(i).diKEY),1);
            temp(IDX(i).dicond) = IDX(i).rCRF(:,w);
            soa0  = IDX(i).diKEY(:,4) == 0;
            temp  = temp(soa0,:);
            crf   = reshape(temp,step,[]);
            clear stim ndec
            stim  = reshape(IDX(i).diKEY(soa0,1),step,[]);
            ndec  = reshape(IDX(i).diKEY(soa0,3),step,[]);
            
            % group contrasts
            if flag_grpc
                clear mcrf* bicrf* dicrf*
                mcrf  = crf(:,1:4);
                bicrf = crf(:,5:step+4);
                dicrf = crf(:,step+4+1:end);
                for c1 = 1:length(clevel)
                    mcrf2(c1,: ) = nanmean(mcrf(cgrp == c1,:));
                    for c2 = 1:length(clevel)
                        bicrf2(c1,c2) = nanmean(reshape(bicrf(cgrp == c1,cgrp == c2),1,[]));
                        dicrf2(c1,c2) = nanmean(reshape(dicrf(cgrp == c1,cgrp == c2),1,[]));
                    end
                end
                clear crf
                crf = cat(2,mcrf2,bicrf2,dicrf2);
                stim = [-3 -2 -1 0 1 1 1 1 2 2 2 2];
                ndec = [NaN NaN NaN NaN clevel clevel];
            end
            
            % determin max contrast monocular
            idx = find(~isnan(crf(:,4)),1,'last');
            val = crf(idx,4);
            
            crfct = crfct + 1;
            CRF(:,:,crfct) = crf ./ val;
            
            
        end
        CRF(isinf(CRF)) = NaN;
        
        
        clear uCRF nCRF
        uCRF  = nanmean(CRF,3);
        nCRF  = sum(~isnan(CRF),3);
        
        %%
        
        clear N
        for s = 4:size(uCRF,2)
                        
            if flag_grpc
                x = clevel;
                y = uCRF(:,s);
                n = nCRF(:,s);
                ncolors = length(clevel);
            else
                [x,idx]=intersect(allcontrasts,goodc);
                y = uCRF(idx,s);
                n = nCRF(idx,s);
                ncolors = step;
                if (stim(1,s) > 0 && ~ismember(ndec(1,s),goodc))
                    continue
                end
            end
            
            if all(isnan(y))
                continue
            end
            x(isnan(y)) = [];
            n(isnan(y)) = [];  N{s} = n';
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
                    colors = flipud(winter(ncolors));
                    cidx = s - find(stim(1,:)==1,1) + 1;
                    set(h,'color',colors(cidx,:))
                case 2
                    subplot(3,2,2-2+(w*2))
                    h = plot(x,y,'-o'); hold on;
                    colors = flipud(autumn(ncolors));
                    cidx = s - find(stim(1,:)==2,1) + 1;
                    set(h,'color',colors(cidx,:))
            end
        end
        
        N = cell2mat(N);
        for p = 1:2
            subplot(3,2,p-2+(w*2))
            set(gca,'Box','off','TickDir','out',...
                'xscale','log')
            axis tight; ylim([0.2 1.3]);
            xlabel('Contrast')
            ylabel('Norm. Resp')
            %xlim(x([1 end]) + [-0.1 0.1])
            if p == 1 && w == 1
                title(sprintf('%s, n~%u\nwin = %0.2f to %0.2f',unittype,round(median(N)),IDX(1).statwin(w,1),IDX(1).statwin(w,2)))
            elseif p ==1
                title(sprintf('win = %0.2f to %0.2f',IDX(1).statwin(w,1),IDX(1).statwin(w,2)))
            end
            
        end
        
    end
end


%%
figure('Unit','Inches','Position',[0 0 7 10]);
for u = 1:2
    
    clear unittype
    if u == 1
        unittype = 'effect of ori and eye';
    elseif u == 2
        unittype = 'effect of ori but not eye';
    end
    alpha = 0.05;
    occular = [IDX.occ];
    tuning  = [IDX.ori];
    dianov  = [IDX.dianov];
    kls     = [IDX.kls];
    nev     = [IDX.nev];
    csd     = [IDX.csd];
    depth   = [IDX.depth];
    
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
       otherwise
            error('bad unittype')
    end
    
    switch signaltype
        case 'kls'
            I = I & kls;
            unittype = [unittype ', KLS'];
        case {'auto','nev'}
            I = I & nev;
            unittype = [unittype ', dMUA'];
        case 'spiking'
            I = I & ~csd;
            unittype = [unittype ', Spiking'];
        case 'csd'
            I = I & csd;
            unittype = [unittype ', CSD'];
        case 'l4csd'
            I = I & csd & depth(3,:) <= 5 & depth(3,:) >= 0;
            unittype = [unittype ', L4 CSD'];
        otherwise
            error('need to specify signal type')
    end
    
    I = find(I);
    for i = 1:length(I)
        
        diKEY = diKEY
        
        
            % check for main conditions
            [dicond,diidx] = intersect(IDX(i).dicond,dilim);
            [mcond ,midx]  = intersect(IDX(i).dicond,mplim); % monocular pref
            if ~I(i) || isempty(dicond) || isempty(mcond)
                continue
            end
           
    end
    
    
end





