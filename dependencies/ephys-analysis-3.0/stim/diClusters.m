function STIM = diClusters(STIM)


global SORTDIR
if isempty(SORTDIR)
    sortdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';
else
    sortdir = SORTDIR;
end
filelist = STIM.filelist;

clusterct = 0; clear kls
for f = 1:length(filelist)
    
    [~,BRdatafile,~] = fileparts(filelist{f});
    
    ss = [];
    if exist([sortdir BRdatafile '/ss.mat'],'file')  %checks and see if the ss is present for each file
        load([sortdir BRdatafile '/ss.mat'],'ss')    %loads it in
        
        clear clusterMap kls_*
        clusterMap = ss.clusterMap(ss.clusterMap(:,3)==1,:); % pulls out cluster map
        kls_labels = ss.chanIDs(clusterMap(:,2));            % and kilosorted channel labels
        
        clear lia locb
        [lia,locb]=ismember(kls_labels,STIM.el_labels);     % lia is a logical vector where data in kls_labels are also in STIM.el_labels
        if ~(any(lia))                                      % locb are specific but if there's not any lia, it clears the ss
            clear ss
            continue
        end
        kls_labels = kls_labels(lia);                       % creates a subset of labels (lia)
        kls_cluster = clusterMap(lia,1);
        locb = locb(lia);
        kls_depths  = STIM.depths(locb,:);                  % pulls out electrode depths for each sorted unit (locb). Again, not sure what
                                                            % this is. 
                
        for c = 1:length(kls_cluster)            
            
            clear clust chans remove wave;
            clust = kls_cluster(c);
            chan = clusterMap(clusterMap(:,1) == clust,2);
            if isempty(ss.spikeWaves)
                clear matobj
                matobj = matfile([sortdir BRdatafile '/ss.mat']);
                wave = matobj.WAVE(chan,:,:);
                wave = wave(:,:,ss.spikeClusters == clust);
            else
                wave = ss.spikeWaves(chan,:,ss.spikeClusters == clust);
            end
            rate = size(wave,3) ./ (range(ss.spikeTimes) / ss.Fs);
            wave = nanmean(wave,3) - wave(1);
            
            % save required cluster info
            clusterct = clusterct + 1;
           
            kls.filen(clusterct,:)   = f;
            kls.cluster(clusterct,:) = kls_cluster(c,:);
            kls.depth(clusterct,:)   = kls_depths(c,:);
            kls.label(clusterct,:)   = kls_labels(c,:);
            kls.wave(clusterct,:)    = wave;
            kls.rate(clusterct,:)    = rate;
        end
        clear ss
        
    end
    
end
kls.wave = bsxfun(@minus,kls.wave,median(kls.wave,2));   % why the second column here?

kls.assigned = false(size(kls.cluster));
ud = unique(kls.depth(:,1)); 
unitct = 0; clear unit
for d = 1:length(ud)
    % collect all units at this depth across all files
    clear candidates
    candidates   = find(...
        kls.depth(:,1) == ud(d));
   
    % correlate and group waveforms
    X     = kls.wave(candidates,:); 
    F     = kls.filen(candidates,:);
    eva   = evalclusters(X,'kmeans','gap','KList',1:length(candidates));
    kn    = eva.OptimalK;
    group = kmeans(X,kn);
       
    for g = 1:kn
        unitct = unitct + 1;
        
        thisgroup = candidates(group == g);
        kls.assigned(thisgroup) = true;
        
        unit(unitct).fileclust = [kls.filen(thisgroup) kls.cluster(thisgroup)];
        unit(unitct).depth     =  kls.depth(thisgroup(1),:)';
        unit(unitct).wave      =  kls.wave(thisgroup,:,:)';
        unit(unitct).rate      = kls.rate(thisgroup);
    end
    
end

% assign any remianing units
if ~all(kls.assigned)
    clear idx
    candidates = find(kls.assigned==0);
    for k = 1:length(candidates)
        kls.assigned(candidates(k)) = true;
        unitct = unitct + 1;
        unit(unitct).fileclust = [kls.filen(candidates(k)) kls.cluster(candidates(k))];
        unit(unitct).depth     =  kls.depth(candidates(k),:)';
        unit(unitct).wave      =  kls.wave(candidates(k),:,:)';
        unit(unitct).rate      = kls.rate(candidates(k));
    end
end
kls.runtime = now;

% % reorganize data to match historic approch
% dd = [unit.depth]; 
% dd = dd(1,:); 
% nn = max(histc(dd(1,:),unique(dd(1,:)))); 
% 
% STIM.clusters = nan(length(STIM.el_labels),length(filelist),nn);
STIM.kls      = kls;
STIM.units    = unit;

% for u = 1:length(unit)
%     clear d
%     d =  unit(u).depth(1);
%     clear f c n 
%     for v = 1:size(unit(u).fileclust,1)
%         f = unit(u).fileclust(v,1);
%         c = unit(u).fileclust(v,2);
%         n = sum((dd(1:u) == d)); 
%         STIM.clusters(d+1,f,n)=c;
%     end
% end



% colors = lines(max(group));
% for j = 1:max(group)
%     
%   plot(kls.wave(candidates(group==j),:)','color',colors(j,:)); hold on
% end
%         
%         
%     %%
%     
%    for j = 1:length(STIM.units)
%     plot(STIM.units(j).wave)
%     title(STIM.units(j).depth(1))
%     pause
%    end
%     
%    
%    
%    
%    for j = 1:size(X,1)
%        I = F ~= F(j);
%        I(j) = true;
%        x = X(I,:); 
%        eva   = evalclusters(x,'kmeans','gap','KList',1:size(x,1));
%        
%        
%    end

