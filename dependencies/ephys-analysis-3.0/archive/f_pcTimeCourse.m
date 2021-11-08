function pcDAT = f_pcTimeCourse(DAT,basewin)

baseline = mean(DAT(basewin,:,:),1); %[1 x ch x tr]
sub = bsxfun(@minus,   DAT, baseline);
pcDAT  = bsxfun(@rdivide, sub, baseline)*100;
