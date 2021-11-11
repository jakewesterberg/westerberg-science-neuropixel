p = [fileparts(which('monkeylogic')) filesep];
addpath(p,[p 'mgl']);
cd(fileparts(mfilename('fullpath')));

MLConfig = mlconfig;
MLConfig.SubjectScreenDevice = mglgetadaptercount;  % change this to the Subject screen device number
param = [0,20; 180 20; 0 40; 180 40];

for m=1:size(param,1)
    deg = param(m,1);
    coh = param(m,2);

    TrialRecord.CurrentConditionInfo.deg = deg - 90;
    TrialRecord.CurrentConditionInfo.coh = coh;

    [imdata,info] = make_rdm(TrialRecord,MLConfig);

    filename = sprintf('rdm_d%d_c%d.avi',deg,coh);
    v = VideoWriter(filename);
    set(v,'FrameRate',MLConfig.Screen.RefreshRate);
    open(v);
    nframe = size(imdata,4);
    for n=1:nframe
        writeVideo(v,permute(imdata(:,:,2:4,n),[2 1 3]));
    end
    close(v);
end
