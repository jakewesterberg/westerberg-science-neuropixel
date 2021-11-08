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
drname = 'C:\Users\Maier  Lab\Documents\drobodatadrop\151218_I'; 

BRdatafiles = {'151218_I_evp005';'151218_I_evp006';'151218_I_evp007'; '151218_I_evp008'; '151218_I_evp009';'151218_I_evp010'; '151218_I_evp011'; '151218_I_evp012';...
    '151218_I_evp013';'151218_I_evp014';'151218_I_evp015';'151218_I_evp016';'151218_I_evp017';'151218_I_evp018';'151218_I_evp019'}; 

for b = 1:length(BRdatafiles)
   
    BRdatafile = BRdatafiles{b};



theseelectrodes = {'eD02';'eD03';'eD04';'eD05';'eD06';'eD07';'eD08';'eD09';'eD10';'eD11'; 'eD12';'eD13';'eD14';'eD15';'eD16';'eD17';'eD18';'eD19';'eD20';'eD21';'eD22';'eD23';'eD24'}; 
signals = {'mua'}; 

cd(drname); 

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

meanresp{b} = mat; 
clear mat; 

end

figure,
for b = 1:length(meanresp)-1
    
    mx(b)  = max(meanresp{b}); 
     
end
plot(1:length(mx),med,'-o'); 
ylabel('max resp'); 
xlabel('file');

%