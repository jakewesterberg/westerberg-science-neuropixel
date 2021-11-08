function [STIM,fileError] = diNoClusters(STIM)
fileError = false;

global SORTDIR
if isempty(SORTDIR)
    sortdir = '/Volumes/Drobo2/DATA/NEUROPHYS/KiloSort-ed/';
else
    sortdir = SORTDIR;
end

clear j count
count = 0;
for j = length(STIM.filelist):-1:1 %reverse order to find first file on day
    clear filecheck
    substring ={'brfs'};
    warning('only Running diNoClusters on BRFS')
    filecheck = contains(STIM.filelist(j),substring);    
    if filecheck
        count = count + 1;
        filelist = STIM.filelist(j); 
        filenum = j;
    end
end



clusterct = 0; clear kls

[~,BRdatafile,~] = fileparts(filelist{1});
    
ss = [];

if exist([sortdir BRdatafile '/ss.mat'],'file')  %checks and see if the ss is present
    load([sortdir BRdatafile '/ss.mat'],'ss')    %loads it in
    
    clear clusterMap kls_*
    clusterMap = ss.clusterMap(ss.clusterMap(:,3)==1,:); % pulls out cluster map for all instances where 3rd column == 1
    kls_labels = ss.chanIDs(clusterMap(:,2));            % and kilosorted channel labels
    
    clear lia locb
    [lia,locb]=ismember(kls_labels,STIM.el_labels);     % lia is a logical vector where data in kls_labels are also in STIM.el_labels
    if ~(any(lia))                                      
        clear ss
        % continue
    end
    kls_labels = kls_labels(lia);                       % creates a subset of labels (lia)
    kls_cluster = clusterMap(lia,1);
    locb = locb(lia);
    kls_depths  = STIM.depths(locb,:);                  % pulls out electrode depths for each sorted unit (locb). Again, not sure what
    
    
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
        
        kls.filen(clusterct,:)   = filenum;
        kls.cluster(clusterct,:) = kls_cluster(c,:);
        kls.depth(clusterct,:)   = kls_depths(c,:);
        kls.label(clusterct,:)   = kls_labels(c,:);
        kls.wave(clusterct,:)    = wave;
        kls.rate(clusterct,:)    = rate;
    end
    clear ss

end

if ~exist('kls')
    fileError = true;
    return
end

kls.wave = bsxfun(@minus,kls.wave,median(kls.wave,2));   
kls.assigned = false(size(kls.cluster));


ud = unique(kls.depth(:,1)); 
unitct = 0; clear unit
for d = 1:length(ud) % create STIM.units
        unitct = unitct + 1;
        
        kls.assigned(d) = true;
        
        unit(unitct).fileclust = [kls.filen(d) kls.cluster(d)];
        unit(unitct).depth     =  kls.depth(d(1),:)';
        unit(unitct).wave      =  kls.wave(d,:,:)';
        unit(unitct).rate      = kls.rate(d);
    
end

kls.runtime = now;

STIM.kls      = kls;
STIM.units    = unit;
