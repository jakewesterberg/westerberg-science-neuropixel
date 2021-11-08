% setup depth / alignment
function  STIM = diV1Lim(STIM,penN,aligndir)

if nargin < 3
    global ALIGNDIR
    if ~isempty(ALIGNDIR)
        aligndir = ALIGNDIR;
    else
        aligndir = '/Volumes/LaCie/Dichoptic Project/vars/V1Limits_Aug18/';
    end
end
if nargin < 2 || ~exist('penN','var') || isempty(penN)
    error('must pass penetration number')
end

TuneList = importTuneList();
idx = find(strcmp(TuneList.Datestr,STIM.header(1:6)));
idx = idx(penN);



clear penetration
penetration =  TuneList.Penetration{idx};
if ~strcmp(STIM.penetration,penetration)
    error('check penetrations')
end

clear elabel v1lim
try % BM added this try/catch. 
    load([aligndir penetration ,'.mat'],'elabel','v1lim','fRF')
catch
    warning('Could not find ALIGN data for this penetration.')
    return
end

clear  l4c l4l
l4c = TuneList.SinkBtm(strcmp(TuneList.Penetration,penetration));
l4l = sprintf('e%s%02u',penetration(end),l4c);

clear rflim
rflim = v1lim(1:2);
if any(isnan(rflim)) || diff(rflim) < 10
    v1lim = v1lim(3:4);
else
    v1lim = [...
        ceil( nanmean(v1lim(1:2:3)))...
        floor(nanmean(v1lim(2:2:4)))...
        ];
end

% remove bad channels (listed in TuneList)
rmch = STIM.rmch;
if rmch ~= 0
    v1lim(v1lim>=rmch) = rmch-1;
end
STIM.rmch = rmch;

clear el_labels l4_idx ninside depths
el_labels = elabel(v1lim(1):v1lim(2));
l4_idx    = find(strcmp(el_labels,l4l));
ninside   = length(el_labels);
depths    = [0:ninside-1; -1*((1:ninside) - l4_idx); ninside-1:-1:0]';

%add a RF / stim check
stim_xyr = [STIM.xpos STIM.ypos STIM.diameter./2];
rf_xyr = [nanmedian(fRF(v1lim(1):v1lim(2),1:2),1) nanmedian(mean(fRF(v1lim(1):v1lim(2),3:4),2))/2];
STIM.rf_xyr = rf_xyr;
STIM.overlap = nan(length(stim_xyr),1);
if ~any(isnan(rf_xyr))
    for j = 1:length(stim_xyr)
        clear m c
        [m, c] = area_intersect_circle_analytical([stim_xyr(j,:);rf_xyr]);
        if c == 1
            STIM.overlap(j) = 0;
        elseif c == 2
            STIM.overlap(j) = 1;
        else
            STIM.overlap(j) = m(1,2)/m(2,2);
        end
    end
end


STIM.el_labels    =  el_labels;
STIM.depths       =  depths;
STIM.v1lim         = [v1lim(1) find(strcmp(elabel,l4l)) v1lim(2)];


