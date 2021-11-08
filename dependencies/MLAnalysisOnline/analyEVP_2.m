% analyze tuning
clear all;
%%
drname = 'y:/160127_I'; 
cd(drname);
BRdatafile = '160127_I_evp004';

theseelectrodes = {'White'}; %'eD03';'eD04';'eD05';'eD06';'eD07';'eD08';'eD09';'eD10';'eD11'; 'eD12';'eD13';'eD14';'eD15';'eD16';'eD17';'eD18';'eD19';'eD20';'eD21';'eD22';'eD23';'eD24'}; 
signals = {'lfp';'mua'}; 

cd(drname); 

%%
% load digital codes and neural data: 
filename = fullfile(drname,BRdatafile);
savepath = drname; 

% load NEV
if exist(strcat(filename,'.nev'),'file') == 2;
    NEV = openNEV(strcat(filename,'.nev'),'nomat','nosave');
else
    error('the following file does not exist\n%s.nev',filename);
end
%%
% get codes and remove presentations on aborted trls from structure
findcodes = [23:24]; % onset/offset codes
[evcodes evtimes evtrials] = getMLcodes(NEV,findcodes);

%%
% get neural data
[LFP,MUA] = getNeuralData(signals,theseelectrodes,filename); 

%%
vec = 1:length(evcodes); 
evon = evtimes(vec(mod(vec,2) ~= 0)); 
pre = -25; post = 300; 
tvec = pre:post; 
bsl = tvec>=pre & tvec<=0; 
clear muar bcmuar
for p = 1:length(evon)
    
    muar(:,:,p) = MUA(evon(p)+pre:evon(p)+post,:); 
    bcmuar(:,:,p) = ((muar(:,:,p) - repmat(nanmean(muar(bsl,:,p),1),length(tvec),1))./(repmat(nanmean(muar(bsl,:,p),1),length(tvec),1))) .*100; 
 
end
   varbcmuar = std(bcmuar,0,3)./sqrt(repmat(size(muar,3),length(tvec),size(muar,2))); 

figure, 
set(gcf,'Color','w'); 
mat = nanmean(nanmean(muar,2),3); 
plot(tvec,mat,'Color',[0.2 0.2 0.2],'LineWidth',2); 
xlim([pre post]); 
[p,f] = fileparts(filename);
title(gca,sprintf('MUA %s',f)); 
set(gca,'Box','off'); 
xlabel('t(ms) from onset'); 


ylabel('% change');
figure, 
set(gcf,'Color','w'); 
mat = nanmean(nanmean(bcmuar,2),3); 
plot(tvec,mat,'Color',[0.2 0.2 0.2],'LineWidth',2); 
hold on; 
errorbar(tvec(1:30:end),mat(1:30:end,:),nanmean(varbcmuar(1:30:end,:),2),'Color',[0.2 0.2 0.2],'LineWidth',2,'LineStyle','none'); 
xlim([pre post]); 
[p,f] = fileparts(filename);
title(gca,sprintf('MUA %s',f)); 
set(gca,'Box','off'); 
xlabel('t(ms) from onset'); 
ylabel('% change'); 
%%
vec = 1:length(evcodes); 
evon = evtimes(vec(mod(vec,2) ~= 0)); 
pre = -25; post = 300; 
tvec = pre:post; 
bsl = tvec>=pre & tvec<=0; 
clear muar bcmuar
for p = 1:length(evon)
    
    lfpr(:,:,p) = LFP(evon(p)+pre:evon(p)+post,:); 
    bclfpr(:,:,p) = ((lfpr(:,:,p) - repmat(nanmean(lfpr(bsl,:,p),1),length(tvec),1))./(repmat(nanmean(lfpr(bsl,:,p),1),length(tvec),1))) .*100; 
 
end
   varbclfpr = std(bclfpr,0,3)./sqrt(repmat(size(lfpr,3),length(tvec),size(lfpr,2))); 
  
figure, 
set(gcf,'Color','w'); 
mat = nanmean(nanmean(bclfpr,2),3); 
plot(tvec,mat,'Color',[0.2 0.2 0.2],'LineWidth',2); 
hold on; 
errorbar(tvec(1:30:end),mat(1:30:end,:),nanmean(varbclfpr(1:30:end,:),2),'Color',[0.2 0.2 0.2],'LineWidth',2,'LineStyle','none'); 
xlim([pre post]); 
[p,f] = fileparts(filename);
title(gca,sprintf('LFP: %s',f)); 
set(gca,'Box','off'); 
xlabel('t(ms) from onset'); 
ylabel('% change'); 
