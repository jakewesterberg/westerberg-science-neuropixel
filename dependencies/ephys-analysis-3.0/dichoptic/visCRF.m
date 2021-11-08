didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Mar14/';
cd(didir);
load('CRF_April02b.mat');

clearvars -except CRF

tunenot = '0';    % 0 to get stats after subtracting baseline
deltaO  = 25; % dva orientaion diffrence allowed between tuning and main experement params
alpha   = 0.05; % sig threshold for tuning
%%
tunestr = 'main effects in di task'; % see below

condition = 1; % 1 = pref pref
window    = 3;
cI        = [CRF.dicond];
cI        = cI(condition,:);

% get tuning info
occular = [CRF.(['occ' tunenot])];
tuning  = [CRF.(['ori' tunenot])];
dianov  = [CRF.(['dianov' tunenot])];
prefori = [CRF(:).prefori];
peakori = nansum(tuning(2:3,:));
deltaori = min(abs(wrapTo180([prefori-peakori; prefori-peakori+180])));


clear tI oI eI
switch tunestr
    case 'main effects in di task'
        tI = all(dianov(1:2,:)<alpha);
    case 'ori effect in di task but not eye'
        tI = (dianov(2,:)<alpha) & (dianov(1,:)>=alpha);
    case 'effect of ori but not eye'
        oI = (dianov(2,:)<alpha)  | tuning(1,:)  < alpha ;
        eI = (dianov(1,:)>=alpha) | occular(1,:) >= alpha;
        tI  = oI & eI;
    case 'effect of ori and eye'
        oI = dianov(2,:)<alpha | tuning(1,:)  < alpha ;
        eI = dianov(1,:)<alpha | occular(1,:) < alpha;
        tI  = oI & eI;
    case 'effect of ori'
        oI = dianov(2,:)<alpha | tuning(1,:)  < alpha ;
        tI = oI;
    otherwise
        error('bad tunestr')
end
tI = tI & deltaori <= deltaO & cI;

switch condition
    case 1
        cstr = '[pref pref]';
    case 2
        cstr = '[pref null]';
    case 3
        cstr = '[null null]';
    case 4
        cstr = '[null pref]';
end
if strcmp (tunenot,'0')
    tunestr = sprintf('%s (tune0), deltaOri = %u\ncondition = %s, window = [%u %u] ms',tunestr,deltaO,cstr, CRF(1).win(window,1), CRF(1).win(window,2));
else
    tunestr = sprintf('%s, deltaOri = %u\ncondition = %s, window = [%u %u] ms',tunestr,deltaO,cstr, CRF(1).win(window,1), CRF(1).win(window,2));
end
%%
CRF = CRF(tI); 
dicontrast = nanunique([CRF.dicontrast]);
fx = 0:5:100;
fR = nan(length(dicontrast) + 1,length(fx),length(CRF));
rR = nan(length(dicontrast) + 1,length(fx),length(CRF));
for i = 1:length(CRF);
    
    
    clear c r 
    c = CRF(i).dicontrast;
    r = CRF(i).RESP(:,:,condition,window); % RESP(eye2,eye1,condition, window) 
    % r(1,:) = monocular dominant; r(:,1) = monocular non dominant; plot(r')
    if isnan(r(1,1))
       r(1,1) = CRF(i).bl;
    end
    
    clear fY
    for ndec = 1:length(c)+1
        clear x y
        x = c;
        if ndec > length(c)
            y = r(:,1);
        else
            y = r(ndec,:);
        end
        x(isnan(y)) = [];
        y(isnan(y)) = [];
      
        clear crf 
        if isempty(y) || length(y) < 3 || ~any(x==0); 
            fY(ndec,:) = nan(size(fx)); 
        else
            crf = fmsCRF(x,y);
            fY(ndec,:) = feval(crf.fun,fx);
        end
        
    end
    
       [~,ia,~]=intersect(dicontrast,c,'stable');
       fR(ia,:,i)  = fY(1:end-1,:); 
       fR(end,:,i) = fY(end,:); 
       [~,ia,~]=intersect(dicontrast,c,'stable');
       
    
end
DEPTH = [CRF(:).depth]';
%%
clf
c = [dicontrast NaN]; 

n = sum(~isnan(fR(:,1,:)),3); 
crf     = fR(n>20,:,:); 
c       = c(n>20);

%allcond = squeeze(all(~isnan(crf(:,1,:)),1)); 
%crf     = crf(:,:,allcond);

r = (crf(c == 0,end,:));
b = (crf(c == 0,1,:));


subplot(2,1,1)
plot(fx,nanmean(crf,3)','-')
axis tight
box off
xlabel('Contrast in Dom Eye')
ylabel('Resp (spk./s)')
%title(tunestr)
set(gca,'xscale','log')


crf = bsxfun(@minus,crf, b);
crf = bsxfun(@rdivide,crf,r);
subplot(2,1,2)
plot(fx,nanmean(crf,3)')
axis tight
box off
xlabel('Contrast in Dom Eye')
ylabel('Norm. Resp')
title(tunestr)
set(gca,'xscale','log')

%%