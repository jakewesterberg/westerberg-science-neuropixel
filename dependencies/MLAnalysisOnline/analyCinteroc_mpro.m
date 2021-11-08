clear all; 

% analyze cinteroc files
addpath(genpath('C:\Users\Maier  Lab\documents\MLAnalysisOnline'))


BRdatafile = '151229_I_cinteroc007'; 
brdrname = sprintf('Z:\\%s',BRdatafile(1:8));
mldrname = sprintf('Y:\\%s',BRdatafile(1:8));
 cd(mldrname)
fkey = sprintf('%s.gCINTEROCGrating_di',BRdatafile); % key elements in file name
fname = dir(sprintf('%s',fkey));
filename = fname.name; 
theseelectrodes = {'eC15'}; 
signals = {'MUA'}; 
grating = readgGrating(filename); % read in text file with stim parameters

% load digital codes and neural data: 
% BRdatafile = '151314_I_cinteroc001'; 
filename = fullfile(brdrname,BRdatafile);
savepath = brdrname; 

% load NEV
if exist(strcat(filename,'.nev'),'file') == 2;
    NEV = openNEV(strcat(filename,'.nev'),'nomat','nosave');
else
    error('the following file does not exist\n%s.nev',filename);
end


% get codes and remove presentations on aborted trls from structure
findcodes = [23:28]; % onset/offset codes
[evcodes evtimes evtrials] = getMLcodes(NEV,findcodes);
vec = 1:length(evtimes); 
evens = mod(vec,2) == 0; 
evon  = evtimes(vec(evens == 0)); 
evoff = evtimes(vec(evens)); 
maxpres = [3]; 
[grating] = removeNotPres(grating,evtrials,maxpres); 

% get neural data
[LFP,MUA] = getNeuralData(signals,theseelectrodes,filename);
binsz   = 30; %ms
k = normpdf(fix([-1*binsz*1.5:binsz*1.5]),0,binsz); % GAUSSIAN KERNEL
hMUA = doConv(MUA',k);

%[spikes]  = getSpikeData(signals,theseelectrodes,NEV);
%spikes = spikes{1};

preMUA = MUA; clear MUA
MUA = hMUA'; 


clear muar meanresp varresp 
pre = -30; post = 150; 
for p = 1:length(grating.trial)
    dC(p)  = grating.contrast(p); 
    ndC(p) = grating.fixedc(p); 
    refwin = evon(p) + pre : evon(p) + post; 
    muar(:,p) = MUA(refwin); 
end

%%
% Time course 
clear meanresp bcmeanresp varresp legendInfo 
unqc = unique(dC);
lw = 2; 
tvec =pre:post;
% %%
% for i = 2:length(unqc)
%     
%     figure, set(gcf,'Color','w')
%     ct = 0;
%     
%     for ii = 1:length(unqc)
%         ct = ct + 1;
%         idx = intersect(find(dC == unqc(i)),find(ndC == unqc(ii)));
%         
%         meanresp(:,i,ii)   = nanmean(muar(:,idx),2);
%         bsidx = tvec>=-40 & tvec<=-10; 
%         bcmeanresp(:,i,ii) = nanmean((muar(:,idx) - repmat(nanmean(muar(bsidx,idx),1),size(muar,1),1))./(repmat(nanmean(muar(bsidx,idx),1),size(muar,1),1)).*100,2);
%         varresp(:,i,ii)  = std(muar(:,idx),0,2)./sqrt(repmat(length(idx),1));
%         bcvarresp(:,i,ii) = std((muar(:,idx) - repmat(nanmean(muar(bsidx,idx),1),size(muar,1),1))./(repmat(nanmean(muar(bsidx,idx),1),size(muar,1),1)).*100,0,2)./sqrt(repmat(length(idx),1));
%         plot(tvec,bcmeanresp(:,i,ii),'Color',getColor(ii+2),'LineWidth',2);
%         hold on
%         errorbar(tvec(1:10:end),bcmeanresp(1:10:end,i,ii),varresp(1:10:end,i,ii),'Color',getColor(ii+2),'LineStyle','none');
%         hold on
%         legendInfo{ct} = num2str(unqc(ii));
%         ct = ct + 1;
%         legendInfo{ct} = '';
%     end
%     
%     set(gca,'Box','off','FontSize',14,'TickDir','out');
%     xlabel('t (ms)')
%     title(sprintf('RESP DE %0.2f contrast',unqc(i)));
%     xlim([pre post]);
%     legend(legendInfo,'Location','Northeastoutside')
%     
% end
% 
% % Contrast Response DE eye vs. ND
% figure,set(gcf,'Color','w')
% [monocular,midx] = max(bcmeanresp(:,:,1));
% for i = 1:length(midx)
%     
%     sempt(i) = bcvarresp(midx(i),i,1); 
%     
% end
% plot(unqc*100,monocular,'-o','Color',getColor(1),'LineWidth',lw);
% hold on 
% errorbar(unqc*100,monocular,sempt,'-o','Color',getColor(1),'LineStyle','none')
% 
% legendInfo{1} = 'ND contrast 0%'; 
% legendInfo{2} = ''; 
% hold on; 
% ct = 2; 
% for i = 2:length(unqc)
%     ct = ct + 1; 
%     clear sempt
%     hold on;
%     [binocular,bidx]  = max(bcmeanresp(:,:,i));
%     for v = 1:length(bidx)
%         sempt(v) = bcvarresp(bidx(v),v,i); 
%             end
%     plot(unqc*100,binocular,'-o','Color',getColor(i+2),'LineWidth',lw);
%     legend(gca,'monocular',sprintf('ND %0.2f',unqc(i)));
%     set(gca,'Box','off','TickDir','out')
%     hold on;
%     errorbar(unqc*100,binocular,sempt,'-o','Color',getColor(i+2),'LineStyle','none')
% 
%     legendInfo{ct} = sprintf('ND contrast %0.1f %',unqc(i)*100); 
%     ct = ct + 1; 
%     legendInfo{ct} = ''; 
% end
% set(gca,'Box','off','TickDir','out'); 
% legend(legendInfo,'Location','NortheastOutside')
% xlabel('dominant eye contrast (%)'); 
% ylabel('max % change'); 
% xlim([0 unqc(end)*100+10]); 
% title(gca,sprintf('chan %s',theseelectrodes{1})); 
%%
clear meanresp bcmeanresp varresp bcvarresp 
% choose specific contrast levels:
thesec = find(ismember(unqc,[0 .05 .10 .25 .5]));
for i = 2:length(thesec)
    
    figure, set(gcf,'Color','w')
    ct = 0;
    
    for ii = 1%:length(thesec)
        
        clear idx; 
        ct = ct + 1;
        idx = intersect(find(dC == unqc(thesec(i))),find(ndC == unqc(thesec(ii))));
        
        meanresp(:,i,ii) = nanmean(muar(:,idx),2);
        bsidx = tvec>=-40 & tvec<=-10; 
        bcmeanresp(:,i,ii) = nanmean((muar(:,idx) - repmat(nanmean(muar(bsidx,idx),1),size(muar,1),1))./(repmat(nanmean(muar(bsidx,idx),1),size(muar,1),1)).*100,2);
        varresp(:,i,ii)  = std(muar(:,idx),0,2)./sqrt(repmat(length(idx),1));
        bcvarresp(:,i,ii) = std((muar(:,idx) - repmat(nanmean(muar(bsidx,idx),1),size(muar,1),1))./(repmat(nanmean(muar(bsidx,idx),1),size(muar,1),1)).*100,0,2)./sqrt(repmat(length(idx),1));
        plot(tvec,bcmeanresp(:,i,ii),'Color',getColor(ii+2),'LineWidth',2);
        hold on
        errorbar(tvec(1:10:end),bcmeanresp(1:10:end,i,ii),bcvarresp(1:10:end,i,ii),'Color',getColor(ii+2),'LineStyle','none');
        hold on
        legendInfo{ct} = num2str(unqc(thesec(ii)));
        ct = ct + 1;
        legendInfo{ct} = '';
    end
    
    set(gca,'Box','off','FontSize',14,'TickDir','out');
    xlabel('t (ms)')
    title(sprintf('RESP DE %0.2f contrast',unqc(thesec(i))));
    xlim([pre post]);
    legend(legendInfo,'Location','Northeastoutside')
    
end

% Contrast Response DE eye vs. ND
clear sempt
figure,set(gcf,'Color','w')
[monocular,midx] = max(bcmeanresp(:,:,1));
for i = 1:length(midx)
    
    sempt(i) = bcvarresp(midx(i),i,1); 
    
end
plot(unqc(thesec)*100,monocular,'-o','Color',getColor(1),'LineWidth',lw);
hold on 
errorbar(unqc(thesec)*100,monocular,sempt,'-o','Color',getColor(1),'LineStyle','none')

legendInfo{1} = 'ND contrast 0%'; 
legendInfo{2} = ''; 
set(gca,'Box','off','TickDir','out'); 
legend(legendInfo,'Location','NortheastOutside')
xlabel('dominant eye contrast (%)'); 
ylabel('max % change'); 
xlim([0 unqc(thesec(end))*100+10]); 
title(gca,sprintf('chan %s',theseelectrodes{1})); 
dfdfd
%%
hold on; 
ct = 2; 
for i = 2:length(thesec)
    ct = ct + 1; 
    clear sempt
    hold on;
    [binocular,bidx]  = max(bcmeanresp(:,:,i));
    for v = 1:length(bidx)
        sempt(v) = bcvarresp(bidx(v),v,i); 
            end
    plot(unqc(thesec)*100,binocular,'-o','Color',getColor(i+2),'LineWidth',lw);
    legend(gca,'monocular',sprintf('ND %0.2f',unqc(i)));
    set(gca,'Box','off','TickDir','out')
    hold on;
    errorbar(unqc(thesec)*100,binocular,sempt,'-o','Color',getColor(i+2),'LineStyle','none')

    legendInfo{ct} = sprintf('ND contrast %0.1f %',unqc(thesec(i))*100); 
    ct = ct + 1; 
    legendInfo{ct} = ''; 
end
set(gca,'Box','off','TickDir','out'); 
legend(legendInfo,'Location','NortheastOutside')
xlabel('dominant eye contrast (%)'); 
ylabel('max % change'); 
xlim([0 unqc(thesec(end))*100+10]); 
title(gca,sprintf('chan %s',theseelectrodes{1})); 



% Contrast Response DE eye vs. ND
% mean value across window:
clear sempt
theseid = tvec>80 & tvec<150;
figure,set(gcf,'Color','w')
[monocular] = mean(bcmeanresp(theseid,:,1));
for i = 1:length(midx)
    
    sempt(i) = mean(bcvarresp(theseid,i,1)); 
    
end
plot(unqc(thesec)*100,monocular,'-o','Color',getColor(1));
hold on 
errorbar(unqc(thesec)*100,monocular,sempt,'-o','Color',getColor(1),'LineStyle','none')

legendInfo{1} = 'ND contrast 0%'; 
legendInfo{2} = ''; 
hold on; 
ct = 2; 
for i = 2:length(thesec)
    ct = ct + 1; 
    clear sempt
    hold on;
    [binocular]  = mean(bcmeanresp(theseid,:,i));
    for v = 1:length(bidx)
        sempt(v) = mean(bcvarresp(theseid,v,i)); 
            end
    plot(unqc(thesec)*100,binocular,'-o','Color',getColor(i+2));
    legend(gca,'monocular',sprintf('ND %0.2f',unqc(i)));
    set(gca,'Box','off','TickDir','out')
    hold on;
    errorbar(unqc(thesec)*100,binocular,sempt,'-o','Color',getColor(i+2),'LineStyle','none')

    legendInfo{ct} = sprintf('ND contrast %0.1f %',unqc(thesec(i))*100); 
    ct = ct + 1; 
    legendInfo{ct} = ''; 
end
set(gca,'Box','off','TickDir','out'); 
legend(legendInfo,'Location','NortheastOutside')
xlabel('dominant eye contrast (%)'); 
ylabel('max % change'); 
xlim([0 unqc(thesec(end))*100+10]); 
title(gca,sprintf('chan %s',theseelectrodes{1})); 

%% 

% average monocular CRFs from two files together:" 
load('007data'); 
[monocular,midx] = max(bcmeanresp(:,:,1));
for i = 1:length(midx)
    
    sempt2(i) = bcvarresp(midx(i),i,1); 
    
end
monocular2 = monocular; 

clearvars -except monocular2 sempt2

load('009data')
[monocular,midx] = max(bcmeanresp(:,:,1));
for i = 1:length(midx)
    
    sempt1(i) = bcvarresp(midx(i),i,1); 
    
end
monocular1 = monocular; 

monocular = mean([monocular1; monocular2],1); 
sempt = mean([sempt1; sempt2],1); 

figure,set(gcf,'Color','w')
plot(unqc(thesec)*100,monocular,'-o','Color',getColor(1),'LineWidth',lw);
hold on 
errorbar(unqc(thesec)*100,monocular,sempt,'-o','Color',getColor(1),'LineStyle','none')

legendInfo{1} = 'ND contrast 0%'; 
legendInfo{2} = ''; 
set(gca,'Box','off','TickDir','out'); 
legend(legendInfo,'Location','NortheastOutside')
xlabel('dominant eye contrast (%)'); 
ylabel('max % change'); 
xlim([0 unqc(thesec(end))*100+10]); 
title(gca,sprintf('chan %s',theseelectrodes{1})); 


