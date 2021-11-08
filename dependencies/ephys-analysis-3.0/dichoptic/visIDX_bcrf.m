didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Aug24/';
cd(didir);
load('IDX_Oct7a.mat');

%%
clearvars -except IDX

klstype  = 'kls only';
alpha = 0.05;

unittype = 'effect of ori but not eye';

occular = [IDX.occ];
bioccu  = [IDX.bio];
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
    case 'effect of ori & sig BF'
        oI = (dianov(2,:)<alpha) | (tuning(1,:) < alpha & min(abs([tuning(2,:); tuning(2,:)+180] - [IDX.prefori;IDX.prefori])) <= 20);
        I = oI & bioccu(2,:) > 0 & bioccu(1,:) < alpha ;
    case 'effect of ori & BF'
        oI = (dianov(2,:)<alpha) | (tuning(1,:) < alpha & min(abs([tuning(2,:); tuning(2,:)+180] - [IDX.prefori;IDX.prefori])) <= 20);
        I  = oI & bioccu(2,:) > 0;
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
%%

clear *CRF
sCRF = nan(length(IDX),4,3);
lCRF = nan(length(IDX),4,3);
rCRF = nan(length(IDX),13,3);
goodcrf = zeros(1,length(IDX)); 
for i = 1:length(IDX);
    
    if ~isempty(IDX(i).CRF)
      %note: NDE is ROWS
      
      % get contrasts / group
      clear cnt cgrp
      cnt = IDX(i).CRF(1,:);
      cgrp = nan(size(cnt)); 
      cgrp(cnt >= 0.1 & cnt <= 0.3) = 1;
      cgrp(cnt >= 0.4 & cnt <= 0.6) = 2;
      cgrp(cnt >= 0.8 & cnt <= 1.0) = 3;
      clevel = [0.2 0.5 0.9];
      
      if any(cgrp == 1) && any(cgrp == 2) && any(cgrp == 3)
          
          % get monocular data
          clear nde de
          nde = grpstats(IDX(i).CRF(2,:),{cgrp})';
          de  = grpstats(IDX(i).CRF(3,:),{cgrp})';
          
          % get binocular data
          clear crftemp cnttemp
          crftemp  = IDX(i).CRF(4:end,:);
          if all(all(isnan(crftemp)))
              continue
          end
          dectemp  = repmat(cgrp,size(crftemp,1),1);
          ndectemp = repmat(cgrp',1,length(cgrp));
          clear crf
          for ndec = 1:3
              for dec = 1:3
                  clear m x
                  m = dectemp == dec & ndectemp == ndec;
                  x = crftemp(m); 
                  if ~isvector(x)
                      x = reshape(crftemp(m),[],1);
                  end
                   crf(ndec,dec) = nanmean(x);
              end
          end
          % add NDE Contrast = 0
          crf = cat(1,de,crf); 
                  
          % get predicitons
          clear *pcrf
          for c = 0:3
              if c == 0
                  spcrf(c+1,:) = sqrt(de.^2 + 0^2);
                  lpcrf(c+1,:) = de + 0;
              else
                  spcrf(c+1,:) = sqrt(de.^2 + nde(c)^2);
                  lpcrf(c+1,:) = de + nde(c);
              end
          end
          
          % normalize to predictions
          clear nS nL nR
          nS = 100*( (crf - spcrf)   ./ spcrf   );
          nL = 100*( (crf - lpcrf)   ./ lpcrf   );
          
          % add nde to crf 
          crf = cat(1,nde,crf); 
          % add predictions to crf
          crf = cat(1,crf,spcrf,lpcrf); 
          % and normalize to max DE
          nR  = crf ./ de(end);
          
          sCRF(i,:,:) = nS;
          lCRF(i,:,:) = nL;
          rCRF(i,:,:) = nR;
         
          
          goodcrf(1,i) = 1; 
           
      end
    end
end
clear keep 
keep = goodcrf & I;
%%
figure('Unit','Inches','Position',[0 0 8.5 11]); clf
porder = [1 3 2 4];
for z = 1:4
    subplot(2,2,porder(z)); cla
    clear eh ph
    for ndec = 1:4
        
        clear dat nde
        if z == 1 || z == 2
            nde = squeeze(rCRF(keep,1,:));
            dat = squeeze(rCRF(keep,ndec+1,:));
            ystr = 'CRF (normalized to DE max contrast)';
        elseif z == 3
            dat = squeeze(lCRF(keep,ndec,:));
            ystr = sprintf('%%\\Delta from Linear Model');
        elseif z == 4
            dat = squeeze(sCRF(keep,ndec,:));
            ystr = sprintf('%%\\Delta from Root-Squared Model');
        end
        
        clear n y x s
        n = sum(~isnan(dat));
        
        y = nanmean(dat,1);
        s = nanstd(dat,[],1) ./ sqrt(n);
        x = clevel;
                
        if (z == 1 || z == 2) && ndec == 1
           
            clear *2
            n2 = sum(~isnan(nde));
            y2 = nanmean(nde,1);
            s2 = nanstd(nde,[],1) ./ sqrt(n2);
            
            eh(ndec) = errorbar(x,y2,s2,'d'); hold on
            plot(x,y2,'-','color',get(eh(ndec),'color')); hold on
            
            eh(ndec+1) = errorbar(x,y,s,'d'); hold on
            plot(x,y,'-','color',get(eh(ndec+1),'color')); hold on
            
        elseif  (z == 1 || z == 2) && ndec == 4
            
            eh(ndec+1) = errorbar(x,y,s,'d'); hold on
            plot(x,y,'-','color',get(eh(ndec+1),'color')); hold on
            
            colors = get(eh(2:end),'Color'); 
            for cc = 2:4
                clear dat y
                if z == 1
                    dat = squeeze(rCRF(keep,5+cc+4,:));
                else
                    dat = squeeze(rCRF(keep,5+cc+0,:));
                end
                y = nanmean(dat,1);
                ph(cc)=plot(x,y,'--','color',colors{cc}); hold on
            end
            
        elseif (z == 1 || z == 2)
            
            eh(ndec+1) = errorbar(x,y,s,'d'); hold on
            plot(x,y,'-','color',get(eh(ndec+1),'color')); hold on
                        
        elseif  z > 2 && ndec == 1
            ax = gca; hold on
            ax.ColorOrderIndex = 3; 
            eh(ndec) = plot(x,y,'-'); hold on
            ax.ColorOrderIndex = 1 + ax.ColorOrderIndex;
        elseif z > 2
            eh(ndec) = errorbar(x,y,s,'d'); hold on
            plot(x,y,'-','color',get(eh(ndec),'color')); hold on
        end
    end
    ylabel(ystr)
    xlabel(sprintf('Contrast in DE\nColored Lines Indicate contrast in NDE'))
    if z == 1 
        legend([eh ph(2)],{'NDE = 0','DE = 0',...
            num2str(clevel(1),'%0.2f'),...
            num2str(clevel(2),'%0.2f'),...
            num2str(clevel(3),'%0.2f'),...
            'Linear Model'},...
            'Location','Best')
    elseif z == 2
        legend([eh ph(2)],{'NDE = 0','DE = 0',...
            num2str(clevel(1),'%0.2f'),...
            num2str(clevel(2),'%0.2f'),...
            num2str(clevel(3),'%0.2f'),...
            'Root-Square Model'},...
            'Location','Best')
        
    else
         legend(eh,{'Prediction',...
            num2str(clevel(1),'%0.2f'),...
            num2str(clevel(2),'%0.2f'),...
            num2str(clevel(3),'%0.2f')},...
            'Location','Best')
    end
    set(gca,'TickDir','out','Box','off')
    
    title(sprintf('win = 0.05 to 250 s\n%s\nn = %uU over %uS in %uM',unittype,sum(keep),length(unique({IDX(keep).penetration})), length(unique({IDX(keep).monkey}))))

    
end