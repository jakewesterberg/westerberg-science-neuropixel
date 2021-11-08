clear

didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Aug24/';
load([didir 'IDX_Oct7a.mat']);
PEN = unique({IDX.penetration});
aligndir = '/Volumes/LaCie/Dichoptic Project/vars/V1Limits_Aug18/';
TuneList = importTuneList;

aligndepth = fliplr([-20:1:20]); 
tmwin = [0 80] ./ 1000; 

clear ALIGN; MUA = [];
for i = 1:length(PEN)
    i
    penetration = PEN{i};
    
    clear STIM
    load([didir penetration '.mat'],'STIM');
    
    ALIGN(i,:) =  (mean(STIM.v1lim) - STIM.v1lim ) ;
 
    clear s header el 
    s = find(strcmp(TuneList.Penetration,penetration)); 
    header = TuneList.Penetration{s}(1:end-3);
    el     = TuneList.Penetration{s}(end-1:end);
    clear sortdirection
    sortdirection = TuneList.SortDirection{s};    
    clear drobo
    switch TuneList.Drobo(s)
        case 1
            drobo = 'Drobo';
        otherwise
            drobo = sprintf('Drobo%u',TuneList.Drobo(s));
    end
    paradigm = {'evp'};
    % build filelist
    ct = 0; filelist = {};
    for p = 1:length(paradigm)
        clear exp
        exp = TuneList.(paradigm{p}){s};
        for d = 1:length(exp)
            ct = ct + 1;
            filelist{ct,1} = sprintf('/Volumes/%s/Data/NEUROPHYS/rig%03u/%s_%s/%s_%s_%s%03u',...
                drobo,TuneList.Rig(s),TuneList.Datestr{s},TuneList.Monkey{s},TuneList.Datestr{s},TuneList.Monkey{s},paradigm{p},exp(d));
        end
    end
    
    if ~isempty(filelist)
        EV = getEvoked2(filelist,el,sortdirection);
        
        % evoked MUA
        tmlim = EV.nevtm >= tmwin(1) & EV.nevtm <= tmwin(2);
        mua   = nanmean(EV.nev_dif(tmlim,STIM.v1lim(1):STIM.v1lim(end),:),3);
        muatm = EV.nevtm(tmlim);
        
        % evoked lfp and csd
        evp   = nanmean(EV.lfp_uV(:,STIM.v1lim(1):STIM.v1lim(end),:),3);
        csd   = calcCSD(evp) .* 0.4;
        tmlim = EV.lfptm >= tmwin(1) & EV.lfptm <= tmwin(2);
        lfptm = EV.lfptm(tmlim);
        evp   = evp(tmlim,:);
        csd   = csd(:,tmlim)';
        
        depth = STIM.v1lim(2) - [STIM.v1lim(1):STIM.v1lim(end)];
        [~,ii]=intersect(aligndepth,depth,'stable');
        
        
        if isempty(MUA)
            MUA = nan(size(mua,1),length(aligndepth),length(PEN));
            EVP = nan(size(evp,1),length(aligndepth),length(PEN));
            CSD = nan(size(evp,1),length(aligndepth),length(PEN));
            DUR = nan(2,length(PEN)); 
        end
        
        MUA(:,ii,i) = mua;
        EVP(:,ii,i) = evp;
        CSD(:,ii(2:end-1),i) = csd;
        DUR(1,i) = mode(diff(EV.tp')./EV.evtFs)*1000;
        DUR(2,i) = median(diff(EV.tp')./EV.evtFs)*1000;
        
    end
            
end
%%

load('/Volumes/LaCie/Dichoptic Project/plots/vis_Align/matlab.mat')
%%
figure('Unit','Inches','Position',[0 0 11 8.5]);
clf
subplot(1,4,1); cla
ALIGN = ALIGN - mean(ALIGN(:,2));
si = [29;18;39;13;20;2;27;1;16;31;9;40;12;17;21;41;8;26;25;11;23;34;36;35;19;5;30;10;6;33;3;24;7;38;4;15;32;37;28;22;14];
plot(ALIGN(si,:),'-.'); hold on
set(gca,'TickDir','out','Box','off');
axis tight
ax = gca; 
ax.ColorOrderIndex = 1; 
plot(xlim,[1 1] * mean(ALIGN(:,1)),'-'); 
plot(xlim,[1 1] * mean(ALIGN(:,2)),'-'); 
plot(xlim,[1 1] * mean(ALIGN(:,3)),'-'); 
colorbar('northoutside')
ylimits = ylim; 


N = squeeze(sum(~isnan(MUA(1,:,(DUR(1,:) > 80))),3));
ncrit = 5;
npts = 10; 

subplot(1,4,2); cla

mua = bsxfun(@rdivide, MUA,(max(max(MUA,[],1),[],2))); 
mua = nanmean(mua,3); 
[zi, yi] = interpDepth(mua(:,(N > ncrit),:),aligndepth((N > ncrit)),npts);
imagesc(muatm,yi,zi);
set(gca,'ydir','normal');
set(gca,'TickDir','out','Box','off');
colorbar('northoutside')
ylim(ylimits);
set(gca,'Clim',[0 1]*max(abs(get(gca,'CLim'))))
xlim([.035 .08])

subplot(1,4,3); cla
evp = bsxfun(@rdivide, EVP,(max(max(abs(EVP),[],1),[],2))); 
evp = nanmean(evp,3); 
[zi, yi] = interpDepth(evp(:,(N > ncrit),:),aligndepth((N > ncrit)),npts);
imagesc(lfptm,yi,zi);
set(gca,'ydir','normal');
set(gca,'TickDir','out','Box','off');
colorbar('northoutside')
ylim(ylimits);
set(gca,'Clim',[-.5 .5]*max(abs(get(gca,'CLim'))))
xlim([.035 .08])

subplot(1,4,4); cla
csd = bsxfun(@minus,CSD,nanmean(CSD(lfptm < 0.01,:,:),1));
csd = nanmean(csd,3);
[zi, yi] = interpDepth(csd(:,(N > ncrit),:),aligndepth((N > ncrit)),npts);
imagesc(lfptm,yi,zi.*-1);
% csdf = filterCSD(csd(:,(N > ncrit),:)',0.01);
% imagesc(lfptm,aligndepth(N > ncrit),csdf.*-1);
set(gca,'ydir','normal');
set(gca,'TickDir','out','Box','off');
colorbar('northoutside')
ylim(ylimits);
set(gca,'Clim',[-.6 .6]*max(abs(get(gca,'CLim'))))
xlim([.035 .08])

colormap(jet)