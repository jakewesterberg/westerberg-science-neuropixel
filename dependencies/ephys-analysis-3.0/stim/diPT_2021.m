function [STIM,fails] = diPT_2021(STIM,trigger)

photoTP  = nan(size(STIM.tp_sp));
fails    = 0;

filelist = STIM.filelist; 
for filen = 1:length(filelist)
    
    clear filename BRdatafile
    filename  = STIM.filelist{filen};
    
    clear I newTP 
    I = STIM.filen == filen;
    if sum(I) == 0
        continue
    end
    [newTP,message] = photoReTriggerSTIM_2021(...
        STIM.tp_sp(I,:),...
        filename,...
        STIM.ypos(I,:),...
        trigger);
    if isempty(newTP)
        message
        fails = fails+1;
        continue
    else
        photoTP(I,:) = newTP;
    end
end
STIM.tp_pt = photoTP;


