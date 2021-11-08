function crf = fmsCRF(x,y,p,crfstr)
% mod from Kacie's fitCRdata
% December 2017

% check x var
if all( x <= 1) % make sure x is ranged 0-100 (not 0 to 1)
    x = x * 100; 
end

% check crfstr
if  ~exist('crfstr','var') || isempty(crfstr)
    crfstr = 'CRF';
end

% setup p
switch crfstr
    case 'CRF'
        if  ~exist('p','var') || isempty(p)
            if ~any(x == 0)
                error('need baseline response of neuron when p is not passed')
            end
            p(1)  = max(y) .* 1.0 ;  % multiplicative response gain factor (=highest response amplitude)
            p(2)  = max(y) .* 0.5 ;  % normalization pool (c50, determines horz position)
            p(3)  = max(y) .* 0.1 ;  % exponent that determines rise and saturation
            p(4)  = y(x==0).* 1.0 ;  % baseline offset w/o stim (spontanious rate)
        end
        p0 = p;
        v = true(size(p0)); 
    case 'mCRF'
        if  ~exist('p','var') || isempty(p)
            error('need params')
        end
        p0  = max(y) .* 1.0 ;
        v = false(size(p)); 
        v(1) = true; 
    case 'cCRF'
        if  ~exist('p','var') || isempty(p)
            error('need params')
        end
        p0 = max(y) .* 0.5 ;
        v = false(size(p));
        v(2) = true;
end
            
% params: can increase 'npts' or 'maxiter' for possibly better fits
options = optimset('display', 'off', 'MaxIter', 500);
npts = 500; 

global DAT P
DAT = []; 
DAT(:,1) = x; 
DAT(:,2) = y;
P = p; 

xbest = []; fbest = [];
for i = 1:npts
    [xret,fret] = fminsearch(eval(['@' crfstr]), p0, options);
    if isempty(xbest)
        xbest = xret;
        fbest = fret;
    elseif fret < fbest
        fbest = fret;
        xbest = xret;
    end
end

p(v) = xbest; 

crf.x = x; 
crf.y = y; 
crf.name = {'rG' 'cG' 'q' 'b'}; 
crf.pram = p; 
crf.free = v; 
crf.sse = fbest;
crf.fun = @(fx)...
    p(1).* ( power(fx,p(3)) ./ (power(fx,p(3)) + power(p(2),p(3))) ) + p(4);

end


function sse = CRF(p0)% define CRF equation 

rG = p0(1);
cG = p0(2);
q  = p0(3); 
b  = p0(4); 

global DAT

rprd = rG .* ( power(DAT(:,1) ,q) ./ (power(DAT(:,1) ,q) + power(cG,q)) ) + b;
sse = sum(power(DAT(:,2) - rprd,2));

end

function sse = mCRF(p0)
% multiplicative gain fit

rG = p0(1);
global DAT P

cG = P(2);
q  = P(3);
b  = P(4);

rprd = rG .* ( power(DAT(:,1) ,q) ./ (power(DAT(:,1) ,q) + power(cG,q)) ) + b;
sse = sum(power(DAT(:,2) - rprd,2));

end

function sse = cCRF(p0)
% contrast gain fit

cG = p0(1);
global DAT P

rG = P(1);
q  = P(3);
b  = P(4);

rprd = rG .* ( power(DAT(:,1) ,q) ./ (power(DAT(:,1) ,q) + power(cG,q)) ) + b;
sse = sum(power(DAT(:,2) - rprd,2));

end




