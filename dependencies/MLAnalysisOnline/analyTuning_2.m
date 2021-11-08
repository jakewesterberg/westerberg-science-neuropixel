% analyze tuning
clear all;

%cd('y:/151217_E'); 
% fkey = '151217_E_evp001'; % key elements in file name
% fname = dir(sprintf('%s',fkey));
% filename = fname.name; 
% 
% grating = readgGrating(filename); % read in text file with stim parameters
% grating.trial(1) = 1; 
%%
drname = 'z:/151218_I'; 
cd(drname);
BRdatafile = '151218_I_evp012';

theseelectrodes = {'eD02';'eD03';'eD04';'eD05';'eD06';'eD07';'eD08';'eD09';'eD10';'eD11'; 'eD12';'eD13';'eD14';'eD15';'eD16';'eD17';'eD18';'eD19';'eD20';'eD21';'eD22';'eD23';'eD24'}; 
signals = {'mua'}; 

cd(drname); 

% %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %does the first trial in the text file match first trial in GRATINGRECORD?
% load(sprintf('%s_GRATINGRECORD1',fkey(1:strfind(fkey,'.')-1))); 
% mat = []; 
% for i = 1:length(GRATINGRECORD)
%     mat = [mat GRATINGRECORD(i).grating_tilt]; 
% end
% 
% load(sprintf('%s_GRATINGRECORD12',fkey(1:strfind(fkey,'.')-1))); 
% for i = 1:length(GRATINGRECORD)
%     mat = [mat GRATINGRECORD(i).grating_tilt]; 
% end
% match = grating.tilt == mat(1:length(grating.trial))'; 
% 
% 
% if match == 1
%     fprintf('\nfiles match\n');
% else
%    error('\nfiles DO NOT match\n'); 
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
% %%
% maxpres = [5]; 
% [grating] = removeNotPres(grating,evtrials,maxpres); 
%%
% get neural data
[LFP,MUA] = getNeuralData(signals,theseelectrodes,filename); 
%[spikes]  = getSpikeData(signals,theseelectrodes,NEV); 

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
mat = nanmean(nanmean(bcmuar,2),3); 
plot(tvec,mat,'Color',[0.2 0.2 0.2],'LineWidth',2); 
hold on; 
errorbar(tvec(1:30:end),mat(1:30:end,:),nanmean(varbcmuar(1:30:end,:),2),'Color',[0.2 0.2 0.2],'LineWidth',2,'LineStyle','none'); 
xlim([pre post]); 
[p,f] = fileparts(filename);
title(gca,sprintf('%s',f)); 
set(gca,'Box','off'); 
xlabel('t(ms) from onset'); 
ylabel('% change'); 

adfdfdaf
%%
% use mua
pre = 40; post = 150; 
chan = 1; 
for p = 1:(length(evtimes)/2)

    resp(:,p) = MUA(pre+evtimes(p) :post +evtimes(p),chan); 
    ori(p) = grating.tilt(p); 
    sf(p) = grating.sf(p); 
    dc(p) = grating.contrast(p); 
    ndc(p) = grating.fixedc(p); 
    diameter(p) = grating.diameter(p);
       
end

[m,n,ci] = grpstats(squeeze(nanmean(resp,1)),ori,{'mean','numel','meanci'});

figure,
set(gcf,'Color','w','Position',[1 1 1000 800]); 
subplot(2,2,1)
plot(unique(ori),m,'o','Color',getColor(5),'MarkerFaceColor',getColor(5));
xlim([min(ori) max(ori)]); 
xlabel('orientation'); ylabel('|microVolts|'); 
set(gca,'Box','off','TickDir','out'); 
title(gca,sprintf('chan %s: mean',theseelectrodes{chan})); 

subplot(2,2,2)
plot(unique(ori),m,'o','Color',getColor(5),'MarkerFaceColor',getColor(5));
hold on;  
errorbar(unique(ori),m,ci(:,2) - ci(:,1)); 
xlim([min(ori) max(ori)]);
xlabel('orientation'); ylabel('|microVolts|'); 
set(gca,'Box','off','TickDir','out'); 
title(gca,sprintf('chan %s: mean and ci',theseelectrodes{chan})); 

subplot(2,2,3)
f = fit(ori',mean(resp,1)','smoothingspline'); 
h = plot(f,ori',mean(resp,1)); 
xlabel('orientation (deg)'); ylabel('|microVolts|'); 
set(gca,'Box','off','TickDir','out'); 
title(gca,sprintf('chan %s: fit with smoothing spline',theseelectrodes{chan})); 

subplot(2,2,4)
bar(unique(ori),n);
xlim([min(ori) max(ori)]);
xlabel('orientation'); ylabel('count');
set(gca,'Box','off','TickDir','out'); 
title(gca,sprintf('chan %s: number of presentations',theseelectrodes{chan})); 


%%
% use spikes
clear resp 
pre = 40; post = 150; 
chan = 1; 
for p = 1:(length(evtimes)/2)

    resp(:,p) = sum(spikes{chan}>=pre+evtimes(p) & spikes{chan}<=post +evtimes(p+1)); 
    ori(p) = grating.tilt(p); 
    sf(p) = grating.sf(p); 
    dc(p) = grating.contrast(p); 
    ndc(p) = grating.fixedc(p); 
    diameter(p) = grating.diameter(p);
       
end

unqori = unique(ori); 
for i = 1:length(unqori)
    ps = find(ori == unqori(i)); 
    tcnt(i) = sum(resp(:,ps)); 
end

figure,
set(gcf,'Color','w','Position',[1 1 1000 800]); 
bar(unqori,tcnt);
set(gca,'Box','off','TickDir','out'); 
ylabel('spk count'); xlabel('orientation (deg)'); 

[m,n,ci] = grpstats(squeeze(resp),ori,{'mean','numel','meanci'});

figure,
set(gcf,'Color','w','Position',[1 1 1000 800]); 
subplot(2,2,1)
plot(unique(ori),m,'o','Color',getColor(5),'MarkerFaceColor',getColor(5));
xlim([min(ori) max(ori)]); 
xlabel('orientation'); ylabel('avg count');   

subplot(2,2,2)
plot(unique(ori),m,'o','Color',getColor(5),'MarkerFaceColor',getColor(5));
hold on;  
errorbar(unique(ori),m,ci(:,2) - ci(:,1)); 
xlim([min(ori) max(ori)]);
xlabel('orientation'); ylabel('avg count'); 

subplot(2,2,3)
f = fit(ori',mean(resp,1)','smoothingspline'); 
h = plot(f,ori',mean(resp,1)); 
xlabel('orientation (deg)'); ylabel('avg count'); 

subplot(2,2,4)
bar(unique(ori),n);
xlim([min(ori) max(ori)]);
xlabel('orientation'); ylabel('count');
