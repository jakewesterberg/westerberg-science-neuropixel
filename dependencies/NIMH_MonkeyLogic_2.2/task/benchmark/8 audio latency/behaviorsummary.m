function behaviorsummary(filename)
tic;

[data,MLConfig,~,filename] = mlread(filename);
sample_rate = MLConfig.HighFrequencyDAQ.SampleRate;

ntrial = length(data);
signal = cell(ntrial,1);       % raw recorded data
latency = zeros(ntrial,1);     % time to signal onset
duration = zeros(ntrial,1);    % signal duration
pulsecount = zeros(ntrial,1);  % number of pulses

[~,name] = fileparts(filename);
wb = waitbar(0,'Processing...','name',name);
is_playback = isempty(regexp(name,'[Rr]ecording','once')) || ~isempty(regexp(name,'^NI','once'));
for m=1:ntrial
    waitbar(m/ntrial,wb,sprintf('Processing...(%d/%d)',m,ntrial));
    if is_playback
        signal{m} = mlreadsignal('high1',m,filename);
    else
        signal{m} = mlreadsignal('voice',m,filename);
    end
    
    idx = round(data(m).BehavioralCodes.CodeTimes(10==data(m).BehavioralCodes.CodeNumbers) * 0.001 * sample_rate);
    signal{m} = signal{m}(idx:end);
    signal{m} = signal{m} - signal{m}(1);
    x = (0:length(signal{m})-1) / sample_rate * 1000;  % in milliseconds
    
    % auto thresholding
    for n=0.9:-0.1:0.1
        half_height = n*max(signal{m});
        rising_edge = find(1==diff(half_height<[0; signal{m}]));
        pulsecount(m) = length(rising_edge);
        if 100<=pulsecount(m), break, end
    end
    pulse_interval = median(diff(rising_edge));
    
    threshold = 0.05 * max(abs(signal{m}));  % 0.05 of max height
    from = find(signal{m}(1:rising_edge(1))<threshold,1,'last')+1;
    to = find(signal{m}(1:rising_edge(end)+pulse_interval)<-threshold,1,'last');
    latency(m) = x(from);
    duration(m) = x(to) - latency(m);
end
close(wb);

figure;

subplot(1,2,1); cla;
plot(x,signal{m});
set(gca,'xlim',[0 200]);
xlabel('Time (msec)');
ylabel('Volts');
title(sprintf('Duration: %.2f ms, Pulse: %.2f',mean(duration),mean(pulsecount)));
% hold on;
% plot(x(rising_edge),half_height*ones(length(rising_edge),1),'o');
% plot([0 200],[0.05 0.05]);
% plot([0 200],[-0.05 -0.05]);
% plot(x(from),signal{m}(from),'x');
% plot(x(to),signal{m}(to),'x');

subplot(1,2,2); cla;
hold on;
hist(latency,0:2:150); %#ok<HIST>
plot(repmat(mean(latency),1,2),[0 ntrial],':r');
set(gca,'xlim',[0 150],'ylim',[0 ntrial]);
xlabel('Time (msec)');
ylabel(sprintf('Counts (out of %d trials)',ntrial));
title(sprintf('Latency: %.2f ms',mean(latency)));

save([name '.mat'],'signal','latency','duration','pulsecount');
toc

end
