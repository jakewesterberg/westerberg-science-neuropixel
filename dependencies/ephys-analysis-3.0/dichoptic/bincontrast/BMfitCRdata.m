function [a ,K ,n ,b, fbest] = BMfitCRdata

% can increase number of starting points or 'maxiter' for possibly better fits
options = optimset('display', 'off', 'MaxIter', 5000);
nstarting_pts = 500; 

fbest = 999;

% Moradi and Heeger (2009)
% a = 0.98; %multiplicative response gain factor (=highest response amplitude)
% K = 3.6;  %normalization pool (determines x position)
% n = 1.7;   %exponent that determines rise and saturation
% b = 0;    %baseline offset w/o stim

for i = 1:nstarting_pts
    
    % initial starting paramaters for a K n b: 
    
    %parInit(1) =  rand(1); % for normalized data
    parInit(1) =  randi([1 50],1,1); % for normalized data
    parInit(2) =  randi([1 50],1,1); % K
    parInit(3)   = randi([1 50],1,1); %rand(1).*10; %n
    parInit(4)   = 0;   %b
   
    [xret,fret,exitflag,output] = fminsearch(@BMNakaRushton_crmodel, parInit, options);
    if i == 1
        xbest = xret; 
    end
    if fret < fbest
        fbest = fret;
        xbest = xret;
    end
    
end

a = xbest(1);    %multiplicative response gain factor (=highest response amplitude)
K = xbest(2);  %normalization pool (determines x position)
n  = xbest(3);    %exponent that determines rise and saturation
b  = xbest(4);    %baseline

end