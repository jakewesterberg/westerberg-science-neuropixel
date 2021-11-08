function [error] = BMNakaRushton_crmodel(params)

% Moradi and Heeger (2009)
% a = 0.98; %multiplicative response gain factor (=highest response amplitude)
% K = 3.6;  %normalization pool (determines x position)
% n = 1.7;   %exponent that determines rise and saturation


global Data 

a = params(1); 
K = params(2); 
n  = params(3); 
b  = params(4); 

contrasts = Data(1,:); 
for ci = 1:length(contrasts)
 
    c = contrasts(ci); 
    prd(ci) = a*[(c^n)/((c^n) + (K^n))+b]; % prediction 
    
end


sse = sum((Data(2,:) - prd).^2);
error = sse; 

% don't let negative values through (set the error high):
if (sum(params<0) >= 1) || ~isreal(sse)
    error = 9999999; 
end

