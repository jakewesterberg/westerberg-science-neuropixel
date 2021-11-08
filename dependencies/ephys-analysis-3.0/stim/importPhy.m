function [STIM,fileError] = importPhy(STIM)
%substitue for diNoClusters
fileError = false;

global SORTDIR
global tasks
sortdir = SORTDIR;

clear j count
count = 0;
warning(strcat('only Running importPhy on: ',tasks))
for j = length(STIM.filelist):-1:1 %reverse order to find first file on day 
    clear filecheck
    % substring ={'brfs'};
    filecheck = contains(STIM.filelist(j),tasks);    
    if filecheck
        count = count + 1;
        filelist = STIM.filelist(j); 
        filenum = j;
    end
end



clusterct = 0; clear kls

[~,BRdatafile,~] = fileparts(filelist{1});

cluster_info = tdfread([SORTDIR BRdatafile '\cluster_info.tsv']);    %loads it in
cd([SORTDIR BRdatafile])
    spike_clusters = readNPY('spike_clusters.npy');
    spike_times = readNPY('spike_times.npy');
    channel_map = readNPY('channel_map.npy');
    channel_positions = readNPY('channel_positions.npy');
    load('chanMap.mat')


clear clusterMap kls_* edNumber clusterMapLabels
clear j count
count = 0;
for j = 1:size(cluster_info.group,1)
    if contains(cluster_info.group(j,:), 'good') % using 'contains' instead of strcmp
        count = count + 1;
        clusterMap(count,1) = cluster_info.id(j);
        clusterMap(count,2) = cluster_info.fr(j);  %cluster map is (cluster# x firingRate)
        % cluster_info.ch lines up with chanMap0ind from chanMap.mat
            idx = find(chanMap0ind == cluster_info.ch(j));
            edNumber = chanMapLabels(idx);
            clusterMapLabels(count,:) = edNumber;
    end
end

% Cut out clusters that are outside of cortex (i.e. do not line up with STIM.el_labels)
clear lia locb
[lia,locb]=ismember(clusterMapLabels,STIM.el_labels);     % lia is a logical vector where data in kls_labels are also in STIM.el_labels, locb is where cluster map labels is found in STIM.elLabels
clusterMapLabels = clusterMapLabels(lia);                       % creates a subset of labels (lia)
kls_cluster = clusterMap(lia,1);
kls_rate = clusterMap(lia,2);
locb = locb(lia);
kls_depths  = STIM.depths(locb,:); % pulls out electrode depths for each sorted unit (locb). Dimension of columns are depth from top of probe, depth from SinBtm, depth from bottom of probe, 


for fn = 1:length(kls_cluster)
    filenum_full(fn) = filenum;
end


    % save required cluster info
    kls.filen           = filenum_full;
    kls.cluster         = kls_cluster;
    kls.depth           = kls_depths;
    kls.label           = clusterMapLabels;
    kls.rate            = kls_rate;

    phy.spike_clusters = spike_clusters;
    phy.spike_times = spike_times;




if ~exist('kls')
    fileError = true;
    return
end

kls.assigned = false(size(kls.cluster));


ud = unique(kls.depth(:,1)); 
unitct = 0; clear unit
for d = 1:length(ud) % create STIM.units
        unitct = unitct + 1;
        
        kls.assigned(d) = true;
        
        unit(unitct).fileclust = [kls.filen(d) kls.cluster(d)];
        unit(unitct).depth     =  kls.depth(d(1),:)';
        unit(unitct).rate      = kls.rate(d);
    
end

kls.runtime = now;

STIM.kls      = kls;
STIM.units    = unit;
STIM.phy      = phy;  
