function crf = fminCRF(x,y,p)
% mod from Kacie's fitCRdata
% December 2017

if ~any(x == 0)
    error('need baseline response of neuron')
end
if  ~exist('p','var') || isempty(p)
    % param values [start upper lower]
    p(1)  = max(y) .* 1.0 ;  % multiplicative response gain factor (=highest response amplitude)
    p(2)  = max(y) .* 0.5 ;  % normalization pool (c50, determines horz position)
    p(3)  = max(y) .* 0.1 ;  % exponent that determines rise and saturation
    p(4)  = y(x==0).* 1.0 ;  % baseline offset w/o stim (spontanious rate)
end





% make sure x is ranged 0-100 (not 0 to 1)
if all( x <= 1)
    x = x * 100;
end
% define CRF equation 
CRF = @(rG,cG,q,b,x) ... x is contrast level
    rG.* ( power(x,q) ./ (power(x,q) + power(cG,q)) ) + b;

% can increase number of starting points or 'maxiter' for possibly better fits
options = optimset('display', 'off', 'MaxIter', 500);
npts = 500; 

xbest = []; fbest = []; 
for i = 1:npts
    [xret,fret,exitflag] = fminsearch(CRF, p, options);
    if exitflag == 1
        if isempty(xbest)
            xbest = xret;
            fbest = fret;
        elseif fret < fbest
            fbest = fret;
            xbest = xret;
        end
    end
end

Gr = xbest(1);    %multiplicative response gain factor (=highest response amplitude)
Gc = xbest(2);    %normalization pool (determines x position)
q  = xbest(3);    %exponent that determines rise and saturation
s  = 0 ;          %exponent that determines rise and saturation---not varying here
b  = xbest(4);    %baseline offset w/o stim

end



