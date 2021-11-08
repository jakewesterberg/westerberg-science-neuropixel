% analyze grid mapping data
clear all;

%cd('y:/151125_E'); 
cd('c:/users/maier  lab/documents/MLAnalysisOnline/151201_I'); 
fkey = '151201_I_dotmapping006.gDotsXY_di'; % key elements in file name
fname = dir(sprintf('%s',fkey));
filename = fname.name; 

dots = readgDotsXY(filename); % read in text file with stim parameters
dots.trial(1) = 1; 

drname = 'z:/151201_I'; 
cd(drname);
BRdatafile = '151201_I_dotmapping006';

theseelectrodes = {'eC07';'eC08';'eC09';'eC10';'eC11';'eC12'; 'eC13';'eC14';'eC15';'eC16';'eC17'}; 
signals = {'mua'}; 

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

% get codes and remove presentations on aborted trls from structure
findcodes = [23:32]; % onset/offset codes
[evcodes evtimes evtrials] = getMLcodes(NEV,findcodes);
maxpres = [5]; 
[dots] = removeNotPres(dots,evtrials,maxpres); 

% get neural data
[LFP,MUA] = getNeuralData(signals,theseelectrodes,filename); 
[spikes]  = getSpikeData(signals,theseelectrodes,NEV); 
%%
for chan = 1:size(MUA,2)
pre = 35; post = 130; 
for p = 1:length(dots.dot_x)
    x(p) = dots.dot_x(p); 
    y(p) = dots.dot_y(p); 
    r(p,:) = (nanmean(MUA(evtimes(p)+pre:evtimes(p)+post,chan),1) - nanmean(MUA(evtimes(p)-10:evtimes(p)+pre+10,chan),1))./nanmean(MUA(evtimes(p)-10:evtimes(p)+pre+10,chan),1)*100; 
end

figure,
map = [(r*.2)  (r*.4) (r*.8)]; 
scatter3(x,y,r,30,map,'LineWidth',1.5); 

colorbar

figure,
fitstr = 'cubicinterp';
f = fit([x; y]',r,fitstr);
h = plot(f,[x; y]',r);
xlabel('horz. cord.')
ylabel('vertical cord.')
set(h(1),'FaceAlpha',1,'EdgeColor','none')
set(h(2),'Marker','none')
set(gca,'box','off','view',[0 90])
c = colorbar('Location','NorthOutside');
xlabel(c,sprintf('fit (%s)',fitstr))
title(gca,sprintf('mua chan %s',theseelectrodes{chan})); 
axis equal
end


%%
clear x y r
for chan = 1:size(LFP,2)
pre = 40; post = 140; 
for p = 1:length(dots.dot_x)
    x(p) = dots.dot_x(p); 
    y(p) = dots.dot_y(p); 
    r(p,:) = nanmean(LFP(evtimes(p)+pre:evtimes(p)+post,chan),1); 
end

figure,
map = [(r*.2)  (r*.4) (r*.8)]; 
scatter3(x,y,r,30,map,'LineWidth',1.5); 
colorbar

figure,
fitstr = 'cubicinterp';
f = fit([x; y]',r,fitstr);
h = plot(f,[x; y]',r);
xlabel('horz. cord.')
ylabel('vertical cord.')
set(h(1),'FaceAlpha',1,'EdgeColor','none')
set(h(2),'Marker','none')
set(gca,'box','off','view',[0 90])
c = colorbar('Location','NorthOutside');
xlabel(c,sprintf('fit (%s)',fitstr))
title(gca,sprintf('lfp chan %s',theseelectrodes{chan})); 
axis equal
end
    
    
%%
% trigger SPIKE data
[tSpikes] = triggerNeuralData(spikes,pres,pre,post,evcodes,evtimes);


