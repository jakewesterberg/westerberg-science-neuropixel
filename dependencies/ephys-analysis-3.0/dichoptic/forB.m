I = ...
    STIM.adapted & ...
    all(STIM.contrast > .5,2) &...
    STIM.tiltmatch == 0 & ...
    STIM.soa == 800 & ...
    ~STIM.blank & ...
    (...
    (STIM.tilt(:,1) == X.dipref(2) & STIM.eyes(:,1) == X.dipref(1)) |...
    (STIM.tilt(:,2) == X.dipref(2) & STIM.eyes(:,2) == X.dipref(1)));
    
II = find(I) + 1; 

pref stim is adapted
non preffered stimulus is a




    

clear prefeye prefori nulleye nullori
prefeye = X.dipref(1);
nulleye = X.dinull(1);
prefori = X.dipref(2);
nullori = X.dinull(2);

% sort data so that they are [prefeye nulleye]
clear eyes sortidx contrasts tilts
eyes      = STIM.eyes;
contrasts = STIM.contrast;
tilts     = STIM.tilt;
if prefeye == 2
    [eyes,sortidx] = sort(eyes,2,'ascend');
else
    [eyes,sortidx] = sort(eyes,2,'descend');
end
for w = 1:length(eyes)
    contrasts(w,:) = contrasts(w,sortidx(w,:));
    tilts(w,:)     = tilts(w,sortidx(w,:));
end; clear w



I = ...
    STIM.adapted & ...
    all(STIM.contrast > .5,2) &...
    STIM.tiltmatch == 0 & ...
    STIM.soa == 800 & ...
    ~STIM.blank; 