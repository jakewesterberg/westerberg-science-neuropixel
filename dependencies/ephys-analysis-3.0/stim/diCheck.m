function [pass, message] = diCheck(STIM)

pass = true; message = {'cleared diCheck() without message'};


% 1: check for correct tasks
I = STIM.motion==0 & STIM.cued==0 & ~STIM.blank; 
if ~any(STIM.ditask(I))
    if any(STIM.dioptic(I)) && any(STIM.monocular(I))
        message{1} = 'no dichoptic stimuli, BUT dioptic and monocular present';
    else
        message{1} = 'no dichoptic, dioptic, or monocular stimuli';
        pass = false;
    end
elseif all(STIM.cued(STIM.ditask == 1 & STIM.motion==0 & ~STIM.blank) ~=0)
    %4 : check for non-attention di tasks
    message{1} = 'only dichoptic task was the attention task';
    pass = false;
end

% 2: check params
diori = nanunique(STIM.tilt(STIM.ditask==1 & STIM.motion==0,:));
if length(diori) ~= 2
    pass = false;
    message{2} = 'length(diori) ~= 2';
    return
end


% 3: check for monocular conditions in dioptic tasks
% (will cause early sessions to fail)
clear M
for eye = 2:3
    for ori = 1:2
        M(eye-1,ori) = sum(...
            STIM.eye == eye & ...
            STIM.tilt(:,1) == diori(ori) & ...
            STIM.ditask & ~STIM.adapted & STIM.monocular & STIM.motion==0);
    end
end
if any(M < 5)
    message{3} = 'di tasks does not contain enough monocular trials';
    return
end

empty = cellfun(@isempty,message); 
message = message(~empty); 