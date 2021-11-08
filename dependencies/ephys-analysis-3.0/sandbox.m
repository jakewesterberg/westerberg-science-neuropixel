% I = STIM.filen == 7 & ...
%     STIM.soa == 800 & ...
%     all(STIM.contrast(:,:) >= .45,2);
% st = floor(STIM.tp_pt(I,1) ./ 30); 
chans = ismember(elLabelsOut , STIM.el_labels); 


% get monocular conditions: 
for eye = 2:3
    for ori = 1:2
        oris = [30 120];
        
        I = STIM.filen == 7 & ...
            STIM.contrast(:,2) == 0 & ...
            STIM.tilt(:,1) == oris(ori) & ...
            STIM.contrast(:,1) == .45 & ...
            STIM.eye == eye;
        
        clear st DAT
        st = floor(STIM.tp_pt(I,1) ./ 30);
        
        for i = 1:length(st)
            DAT(:,:,i) = aMUAdown(chans,(st(i) - 500) : (st(i) + 800));
            tm = -500:800; 
        end
        
        if (eye == 2 && oris(ori) == 120) || (eye == 3 && oris(ori) == 30)
            plot(tm,mean(mean(DAT,3),1)); hold on
        end
        
    end
end
prefeye = 2;
prefori = 120; 
nulleye = 3; 
nullori = 30; 


I = STIM.filen == 7 & ...
    STIM.soa == 800 & ...
    STIM.contrast(:,1) ~= 0 & ... % adaptor
    STIM.contrast(:,2) ~= 0 & ...; %... % supressor
    STIM.eyes(:,1) == nulleye & ...;
    STIM.eyes(:,2) == prefeye;

clear st DAT
st = floor(STIM.tp_pt(I,1) ./ 30);
for i = 1:length(st)
    DAT(:,:,i) = aMUAdown(chans,(st(i) - 1200) : (st(i) + 1200));
    tm = -1200:1200;
end


I = STIM.filen == 7 & ...
    STIM.soa == 800 & ...
    STIM.contrast(:,1) ~= 0 & ... % adaptor
    STIM.contrast(:,2) ~= 0 & ...; %... % supressor
    STIM.eyes(:,1) == nulleye & ...; % adaptor
    STIM.tilts(:,1) == nullori; %& ...; % adaptor


I = STIM.filen == 7 & ...
    STIM.soa == 0 & ...
    STIM.contrast(:,1) ~= 0 & ... 
    STIM.contrast(:,2) ~= 0 & ...
    (    (STIM.eyes(:,1) == nulleye & ... 
        STIM.tilts(:,1) == nullori)...
    ||  (STIM.eyes(:,2) == nulleye & ...
        STIM.tilts(:,2) == nullori) ); 






