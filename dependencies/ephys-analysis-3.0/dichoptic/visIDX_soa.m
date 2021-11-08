% updated 10/24/17
% focusing on SOA

didir   = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Oct18/';
load([didir 'IDX_Oct25.mat'],'IDX')

%%
clearvars -except IDX
signaltype  = 'spiking';

for u = 3
    
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
        case 'csd'
            I = I & csd;
            unittype = [unittype ', CSD'];
    end
    
    
   % SOA ANA
   soact = 0; clear SDF
   for i = 1:length(I)
       
       
       clear dicond maxcontrast 
       dicond = IDX(i).dicond; 
       if ~I(i) || all(isnan(dicond)) || isempty(dicond)
           continue
       end
       contrasts    = IDX(i).diKEY(dicond,2);
       maxcontrast = max(contrasts);
       [~, mi] = min(abs(contrasts - maxcontrast/2));
       halfcontrast = contrasts(mi);
      
       soacond = [...
           find(IDX(i).diKEY(:,1) == 0 & IDX(i).diKEY(:,2) == maxcontrast) ...
           find(IDX(i).diKEY(:,1) == 2 & IDX(i).diKEY(:,2) == maxcontrast & IDX(i).diKEY(:,3) == maxcontrast & IDX(i).diKEY(:,4) == 0) ...
           find(IDX(i).diKEY(:,1) == 2 & IDX(i).diKEY(:,2) == maxcontrast & IDX(i).diKEY(:,3) == maxcontrast & IDX(i).diKEY(:,4) == 800 & IDX(i).diKEY(:,5) == 1) ...
           find(IDX(i).diKEY(:,1) == 2 & IDX(i).diKEY(:,2) == maxcontrast & IDX(i).diKEY(:,3) == maxcontrast & IDX(i).diKEY(:,4) == 800 & IDX(i).diKEY(:,5) == 0) ...
           ];
       
       if  ~all(ismember(soacond,dicond))
           continue
       end
       
       soact = soact + 1;
       [~,idx] = intersect(dicond,soacond);
       SDF(:,:,soact) = IDX(i).diSDF(idx,:);
              
   end
   
   
    tm = IDX(i).tm;
%    figure('Unit','Inches','Position',[0 0 7 10]);
%    for p = 1:size(SDF,1)
%        subplot(4,2,(p*2)-1)
%        plot(tm,squeeze(SDF(p,:,:)));
%        axis tight
%        box off
%    end
subplot(2,1,1)
plot(tm,mean(SDF,3)); axis tight; box off
legend({'M','BI','AdaptNull','AdaptPref'},'Location','Best')
subplot(2,1,2)
plot(tm,mean(bsxfun(@minus,SDF,SDF(1,:,:)),3));
axis tight
legend({'M','BI','AdaptNull','AdaptPref'},'Location','Best')
   
size(SDF,3)

end

%%
       