function [fRF, dRF, v1lim]= fitRF(uRF,X,Y,I,crit0,dthresh,flag_zscore)
 
if  nargin < 5 || isempty(I)
    I = ones(size(uRF,1),1); 
end

if  nargin < 5 || isempty(crit0)
    if flag_zscore
        crit0 = 1;
    else
        crit0 = 0.5; 
    end
end

if nargin < 6 || isempty(dthresh)
    dthresh = 1; % dva of devation b/t RFs
end

if nargin < 7
    flag_zscore = 1;
end

% fit RFs
fRF = NaN(size(uRF,1),6);
res = diff(X(1:2));
for i = 1:size(uRF,1)
    
    clear dat *Map 
    dat = squeeze( uRF(i,:,:,:) );
    
    % determin boundary of RF using imagetoobox, same as PNAS
    % assuming an excitatory RF    
    
    if flag_zscore
        if ~(nanmedian(reshape(dat,1,[])) <= 0)
            continue 
        end
        crit = crit0;
    else
        crit = crit0 * max(max(dat));
    end
    
    ExtrMap     = dat == max(max(dat));
    CritMap     = dat >= crit ;
   
    clear width centroid center
    if any(any(CritMap)) && ~isempty(CritMap)
        
        % center from MaxMap
        clear STATS CC index
        CC = bwconncomp(ExtrMap);
        [~, index] = max(cellfun('size',CC.PixelIdxList,1)); %the number of squares that surpass criteria and arein the largest connected patch
        STATS = regionprops(CC,'BoundingBox','Centroid');
        
        centermax = round(STATS(index).Centroid);
        centermax = [X(centermax(1)) Y(centermax(2))];
        
        
        % centrolid and size from CritdMap
        clear STATS CC index
        CC = bwconncomp(CritMap);
        [~, index] = max(cellfun('size',CC.PixelIdxList,1)); %the number of squares that surpass criteria and arein the largest connected patch
        STATS = regionprops(CC,'BoundingBox','Centroid');
        width = (STATS(index).BoundingBox(3:4) .* res) ;
        centroid = round(STATS(index).Centroid);
        centroid = [X(centroid(1)) Y(centroid(2))];
                                  
        fRF(i,1:6) = [centroid width centermax];
        
    end
    
end

% position of centroild relative to putativeRF
putativeRF = nanmedian([fRF(I,1),fRF(I,2)]); 
x = fRF(I,1);
y = fRF(I,2);
z = 1:size(uRF,1);
z = z(I);

dxy = abs(bsxfun(@minus, [x y], putativeRF));
goodRF = all(dxy <= dthresh,2);
if any(goodRF)
    v1lim(1) = z(find(goodRF,1,'first'));
    v1lim(2) = z(find(goodRF,1,'last'));
else
    v1lim = [NaN NaN];
end

dRF(:,1)   = z;
dRF(:,2:3) = dxy; 
dRF(:,4)   = goodRF;

% % derivitive across channels based on centroid
% x = fRF(:,1);
% y = fRF(:,2);
% z = 1:size(uRF,1); % INDEXES, need RF.elarray to recover chanel labels
% remove = isnan(x) | isnan(y) | fRF(:,7) == -1; 
% x(remove) = []; 
% y(remove) = []; 
% z(remove) = []; 
% 
% dxy = abs([diff(x),diff(y)]);
% dz  = mean([z(1:end-1);z(2:end)]);
% 
% goodRF = all(dxy < dthresh,2); 
% st0 = round(mean(find(goodRF)));
% idx = [st0 st0]; 
% search = true; 
% while search
%     idx(1) = idx(1) - 1;
%     if idx(1) > 0
%         search = goodRF(idx(1)) == 1;
%     else
%         search = false;
%     end
% end
% search = true; 
% while search
%     idx(2) = idx(2) + 1; 
%     if idx(2) < length(goodRF)
%         search = goodRF(idx(2)) == 1;
%     else
%         search = false;
%     end
% end
% idx    = idx + [1 -1];
% v1lim    = sort(dz(idx)); 
% v1lim(1) = floor(v1lim(1));  
% v1lim(2) = ceil(v1lim(2));  
%
% dRF(:,1) = dz;
% dRF(:,2:3) = dxy; 
% dRF(:,4) = goodRF;