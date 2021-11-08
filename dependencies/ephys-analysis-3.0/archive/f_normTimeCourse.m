function normDAT = f_normTimeCourse(DAT,basewin,peakwin)

baseline = mean(DAT(basewin,:,:),1); %[1 x ch x tr]
DAT = bsxfun(@minus,   DAT, baseline); % baseline is now zero
peakresp = max(mean(DAT(peakwin,:,:),1),[],3); % get max for each ch, across trials
normDAT  = bsxfun(@rdivide, DAT, peakresp); %divide by max
