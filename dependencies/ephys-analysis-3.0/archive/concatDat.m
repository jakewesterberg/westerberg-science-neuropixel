function [cDAT, corticaldepth] = concatDat(DAT,depth)

% October 2014
% revisions Summer 2016
% MAC

% DAT shoud a cell array with an entry for each file to be concatenated
    % each entry of DAT is a matrix that is samples x channels x trials with the most superficial channel as (:,1,:)
    % tr can == 1 for alignment of across-session means (sessions will be 3rd demension in that case)
% depth can be a scaler or a matrix
% if depth is a scaler:
    % shift in channel demension for the second file realitive to the first
    % positive is a upward shift
    % negative is a downard shift
% if depth is a martix:
    % files x channels, with depth(i,ch) = 0 indicating the channel at the bottom of the initial sink,
    % positive values indicating super, and negative values indicating deep
    % works best if you avoid fractions
% can use NaN in depth input to account for uneven channel numbers


nsamples = size(DAT{1},1);
nfiles  = length(DAT);
for f = 1:nfiles
    if nsamples == size(DAT{f},1);
        ntrls(f) = size(DAT{f},3);
        nchan(f) = size(DAT{f},2);
    else
        error('sample length across data not the same')
    end
end
flag_depthisscalar = isscalar(depth);
if flag_depthisscalar
    if numel(unique(nchan)) > 1
        error('cannot use scaler offset method when you have diffrent channel numbers')
    elseif nfiles > 2
        error('cannot use scaler offset method when you have more than 2 files')
    else
        d = depth; clear depth
        
        depth(1,:) = (nchan(1):-1:1);
        depth(2,:) = (nchan(2):-1:1) + d;
    end
    
end
corticaldepth = sort(nanunique(reshape(depth,1,[])),'descend');
ndepths = length(corticaldepth);


% preallocate
cDAT = NaN(nsamples,ndepths,sum(ntrls)); % sessions x samples x channes, will average across 1st dem before output

for i = 1:nfiles
    [~,I,~] = intersect(corticaldepth, depth(i,:),'stable');
    if i == 1
        st = 1;
        en = ntrls(i);
    else
        st = en+1;
        en = en + ntrls(i);
    end
    cDAT(:,I,st:en) = DAT{i};
end
