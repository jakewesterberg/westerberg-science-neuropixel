clear
close all

didir = '/Volumes/LaCie/Dichoptic Project/vars/diSTIM_Aug24/';
load([didir 'IDX_Oct3b.mat']);
PEN = unique({IDX.penetration});
aligndir = '/Volumes/LaCie/Dichoptic Project/vars/V1Limits_Aug18/';
TuneList = importTuneList;

hdva = meshgrid(-8.5:0.1:8.5);
vdva = hdva';
RFM1 = nan(length(hdva),length(hdva),length(PEN));
RFM2 = RFM1;

PEN = fliplr(PEN);
for i = 1:length(PEN)
    
    penetration = PEN{i};
    
    clear STIM
    load([didir penetration '.mat'],'STIM');
    
    clear align
    align = matfile([aligndir penetration '.mat']);
    rflim = align.rflim;
    
    % RFM1
    rf_xyr = STIM.rf_xyr;
    xx = abs(rf_xyr(1));
    yy = rf_xyr(2);
    rr = rf_xyr(3);
    if rr < 0.1
        continue
    end
    fill = sqrt(abs(hdva-xx).^2 + abs(vdva-yy).^2) < rr;
    RFM1(:,:,i) = fill;
    
    % RFM2
    fRF = align.fRF; clear temp
    for rf = rflim(1):rflim(end);
        centroid = fRF(rf,1:2);
        width    = fRF(rf,3:4);
%         rfboundary = [centroid(1)-width(1)/2,centroid(2)-width(2)/2, width(1), width(2)];
%         if ~any(isnan(rfboundary))
%             rectangle('Position',rfboundary,'Curvature',[1,1]); hold on
%         end
        xx = abs(centroid(1));
        yy = centroid(2);
        rr = mean(width./2);
        fill = sqrt(abs(hdva-xx).^2 + abs(vdva-yy).^2) < rr;
        temp(:,:,rf- rflim(1) + 1) = fill;
    end
    temp = nanmean(temp,3);
    temp = temp ./ max(max(temp));
    temp(temp==0) = NaN;
    RFM2(:,:,i) = temp;
    
end

%%

figure('Unit','Inches','Position',[0 0 10 7]);
%%
clf
for p = 2:3
    subplot(1,3,p); hold on
    imagesc(hdva(1,:),vdva(:,1),nanmean(RFM2,3)); hold on
end


for i = 1:length(PEN)
    
    penetration = PEN{i};
    
    clear STIM
    load([didir penetration '.mat'],'STIM');
    
    rf_xyr = STIM.rf_xyr;
    xx = abs(rf_xyr(1));
    yy = rf_xyr(2);
    rr = rf_xyr(3);
    th = 0:pi/50:2*pi;
    xunit = rr * cos(th) + xx;
    yunit = rr * sin(th) + yy;
    
    for p = 1:2:3
        subplot(1,3,p)
        plot(xunit, yunit,'color',[0 0 1]); hold on
    end
end


m = gray;
colormap(flipud(m))

for p = 1:3
    subplot(1,3,p)
    set(gca,'TickDir','out','Box','off')
    axis equal
    set(gca,'TickDir','out','Box','off')
    axis equal
    plot([0 0],ylim,'y');
    plot(xlim,[0 0],'y');
    set(gca,'ydir','normal');
    
    axis([-1 9 -5 3])
    
end
figure(gcf)


%%



