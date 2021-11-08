function crf = fitCRF(x,y,w,p)

if ~any(x == 0)
    error('need baseline response of neuron')
end

if  ~exist('w','var') || isempty(w)
    w = ones(size(y));
end
if  ~exist('p','var') || isempty(p)
    % param values [start upper lower]
    p.rG = max(y) .* [1 2 0.5] ;  % multiplicative response gain factor (=highest response amplitude)
    p.cG = max(y) .* [0.5 1 0] ;  % normalization pool (c50, determines horz position)
    p.q  = max(y) .* [0.1 Inf 0]; % exponent that determines rise and saturation
    p.b  = y(x==0).* [1 2 0];     % baseline offset w/o stim (spontanious rate)
end
   
% make sure x is ranged 0-100 (not 0 to 1)
if all( x <= 1)
    x = x * 100;
end

% define CRF equation
CRF = @(rG,cG,q,b,x) ... x is contrast level
    rG.* ( power(x,q) ./ (power(x,q) + power(cG,q)) ) + b;
% Note, this is lacking the "s" param in the NakaRushton equation 


% setup output var
clear crf
crf.x = x;
crf.y = y;
crf.w = w;

% run fiting
[crf.fit, crf.gof, crf.info] = fit( x,y, CRF, ...
    'StartPoint', [p.rG(1), p.cG(1), p.q(1), p.b(1)],...
    'Upper',      [p.rG(2), p.cG(2), p.q(2), p.b(2)],...
    'Lower',      [p.rG(3), p.cG(3), p.q(3), p.b(3)],...
    'Weights',w,...
    'Robust','LAR',...
    'MaxIter',1000);








