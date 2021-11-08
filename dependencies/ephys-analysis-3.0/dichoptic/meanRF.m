function [uRF, xcord, ycord, elabel]= meanRF(RF,datatype)

if nargin < 2
    datatype = 'mua_zsr';
end

nobs = length(RF.x);
nel  = size(RF.(datatype),1);

if strcmp(datatype(1:3),'kls') && ...
        any(strcmp(fieldnames(RF),'klabel'))
    elabel = RF.klabel; 
else
    elabel = RF.elabel; 
end

% spatial map of RFs
clear X Y Z iZ uZ zRF N
res = 0.05; % dva per pix in matrix
dd = max(RF.d);
[X,Y] = meshgrid(min(RF.x)-dd:res:max(RF.x)+dd, min(RF.y)-dd:res:max(RF.y)+dd);
Z = NaN(nel,size(X,1),size(X,2),nobs);
N = zeros(size(X,1),size(X,2),nobs);
for obs = 1:nobs
    
    xx = RF.x(obs);
    yy = RF.y(obs);
    dd = RF.d(obs);
    fill = sqrt(abs(X-xx).^2 + abs(Y-yy).^2) < dd/2;
    if ~any(any(fill))
        error('check matrix')
    end
    N(:,:,obs) = double(fill); 
    
    for i = 1:nel
        trldat = Z(i,:,:,obs);
        trldat(fill) = RF.(datatype)(i,obs);
        Z(i,:,:,obs) = trldat;
    end
    
end

% mean RF
uRF   = nanmean(Z,4); %nRF   = sum(~isnan(Z),4);

% remove portions of map with low N
nmap  = sum(N,3); 
n     = unique(reshape(nmap,1,[])); n(n==0) = []; 
ncrit = ceil(quantile(n,[.1]));
nmap   = nmap<=ncrit; 
for i = 1:nel
    dat = uRF(i,:,:);
    dat(nmap) = NaN;
    uRF(i,:,:) = dat;
end
xcord = X(1,:);
ycord = Y(:,1);

% remove locations with all NaN
rmvx = all(nmap,1); 
rmvy = all(nmap,2); 
uRF(:,rmvy,:)=[]; 
uRF(:,:,rmvx)=[]; 
xcord(rmvx) = []; 
ycord(rmvy) = [];

% % get locations ouside visual qad of intreste
% if diff(abs([min(X(1,:)) max(X(1,:))])) < 0
%     % mapping in negative visual quad, remove positive 
%     xremove = X>0; 
% else
%     % mapping positive visual quad, remove negative
%     xremove = X<0; 
% end
% % always in the bottom for Y
% yremove = Y>0; 
% 
% % remove pts outside visual quad
% uRF(:,yremove | xremove) = NaN; 


