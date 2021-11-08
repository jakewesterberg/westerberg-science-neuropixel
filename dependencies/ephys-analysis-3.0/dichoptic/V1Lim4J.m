clear

flag_checkforexisting = true;
TuneList = importTuneList();

% setup save path
varsavepath = '/Volumes/LaCie/Dichoptic Project/vars/V1Limits_Aug18/';
if ~exist(varsavepath,'dir')
    mkdir(varsavepath);
end

paradigm = {'dotmapping','rfori'};
clear ALIGN

for s=1:length(TuneList.Penetration)
 
    
    clear header el
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
    
    
    clearvars -except paradigm flag_* sortdirection ALIGN analysis errct filelist varsavepath header el TuneList s
    
    if flag_checkforexisting ...
            && exist([varsavepath header '_' el '.mat'],'file')
        
        load([varsavepath header '_' el '.mat'],'v1lim','elabel')
        
        
    else
        s
        TuneList.Penetration{s}
        
        dots = cellfun(@(x) ~isempty(strfind(x,'dotmapping')),filelist);
        
        EV = getEvoked(filelist(~dots),el,sortdirection,'nev',1);
        nev_sig = EV.nev_sig; 
        
        RF = getRF(filelist(dots),el,sortdirection,{'auto'});
        
        rfdatatype = 'nev_zsr';
        crit0 = 1;
        dthresh = 0.5;
        flag_nev = 1;
        if ~any(nev_sig)
            I = [];
        else
            I = find(EV.nev_sig(:,1),1,'first') - 1 : find(EV.nev_sig(:,1),1,'last') + 1;
            I(I<1 | I>length(EV.elabel)) = [];
        end
        
        [uRF, xcord, ycord, elabel]= meanRF(RF,rfdatatype);
        [fRF, dRF, rflim]   = fitRF(uRF,xcord,ycord,I,crit0,dthresh,flag_nev);
        
        %save([varsavepath header '_' el '.mat'],'EV','RF','rfdatatype','uRF','xcord','ycord','elabel','fRF','dRF','I','dthresh','crit0','-v7.3')
        %save([varsavepath header '_' el '.mat'],'nev_sig','rflim','elabel','I','dthresh','crit0','-v7.3')
        save([varsavepath header '_' el '.mat'],...
            'nev_sig','rflim','elabel',...
            'rfdatatype','uRF','xcord','ycord','elabel',...
            'fRF','dRF','I','dthresh','crit0',...
            '-v7.3')
        
        clear v1lim
        if ~any(EV.nev_sig)
            v1lim = [rflim NaN NaN];
        else
            v1lim = [rflim...
                find(EV.nev_sig(:,1),1,'first') ...
                find(EV.nev_sig(:,1),1,'last') ];
        end
        save([varsavepath header '_' el '.mat'],'v1lim','-append')
        
        
        close all
        plotRF
        h(3) = figure('Position',[0 0 601 874]);
        imagesc(EV.nevtm,1:length(EV.elabel),nanmean(EV.nev_dif,3)'); hold on
        plot(xlim,[v1lim(3) v1lim(3)]-.5,'m')
        plot(xlim,[v1lim(4) v1lim(4)]+.5,'m')
        plot([0 0],ylim,'k');
        set(gca,'TickDir','out','Box','off')
        xlabel('Time (ms)')
        ylabel('Contact from Most Superfical')
        title([header '_' el],'interpreter','none')
        y = colorbar;
        ylabel(y,'Mean Delta Resp. (dMUA in imp./s)')
        saveas(h(1),[varsavepath header '_' el '--rfplot.png'])
        saveas(h(2),[varsavepath header '_' el '--rfsumry.png'])
        saveas(h(3),[varsavepath header '_' el '--dmuaresp.png'])
        %
        clear EV RF
    end
    
        
    % ALIGN VAR
    ALIGN(s).name  = [header '_' el];
    ALIGN(s).date  = header(1:6);
    ALIGN(s).monk  = header(end);
    ALIGN(s).el    =  el;
    
    
    ALIGN(s).rftop = v1lim(1);
    ALIGN(s).rfbtm = v1lim(2);
    
    ALIGN(s).stimtop = v1lim(3);
    ALIGN(s).stimbtm = v1lim(4);
    
        % organize vertical demension of data relative to markers
    clear y elnum L4
    L4 = TuneList.SinkBtm(s);
    elnum = cellfun(@(x) str2double(x(3:4)),elabel);
    switch sortdirection
        case 'ascending'
            y = L4 - elnum;
        case 'descending'
            y = elnum - L4;
    end
    L4 = find(y==0);
    
    ALIGN(s).l4i    = L4;
    ALIGN(s).l4l    = elabel(L4);
    
    ALIGN(s).elabel = elabel;
    
    
end
save([varsavepath 'ALIGN.mat'],'ALIGN','TuneList')


%%
clf; clear x
x = [[ALIGN.rftop]' [ALIGN.rfbtm]' [ALIGN.l4i]' [ALIGN.stimtop]' [ALIGN.stimbtm]'];
x = -1 * bsxfun(@minus,x,x(:,3));
plot(x); hold on
set(gca,'ColorOrderIndex',1)
plot(xlim,[nanmean(x); nanmean(x)],':')
set(gca,'Box','off');
legend('RF','RF','L4','Evoked','Evoked')

saveas(gcf,[varsavepath 'ALIGN.fig'])