didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Sep23/';

 list = dir([didir '*eD.mat']);
 list(end+1) = dir([didir '*eB.mat']);
ct = 0; 
clear session
for i = 1:length(list)
%%
dispname = strcat('dirloop, i=', num2str(i));
disp(dispname)

% load session STIM
load([didir list(i).name],'STIM')


I = ...
    STIM.adapted &...
    all(STIM.contrast > .5,2) &...
    STIM.tiltmatch == 0 & ...
    STIM.soa == 800 &...
    ~STIM.blank;
    
supressor = find(I);
addaptor  = find(I) +1;

eyes        = STIM.eyes;
contrasts   = STIM.contrast;
tilts       = STIM.tilt;

[eyes,sortidx] = sort(eyes,2,'ascend');
for w = 1:length(eyes)
    contrasts(w,:)  = contrasts(w,sortidx(w,:));
    tilts(w,:)      = tilts(w,sortidx(w,:));
end; clear w


ori = nanunique(tilts(I,:));

for o = 1:2
    if o == 1
        II = I & ...
            tilts(:,1) == ori(1) &    tilts(:,2) == ori(2) ;
    else
        II = I & ...
            tilts(:,1) == ori(2) &    tilts(:,2) == ori(1) ;
    end
    a = tilts(find(II)+1,:);
    condition = nanunique(a); 
    if length(condition) > 1
        ct = ct + 1; 
        session{ct,1} = STIM.penetration; 
    end

end
end
