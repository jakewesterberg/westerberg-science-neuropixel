function [ratio,freq, power] = ratio_ftf_f0(psth,Fs,tf)


% For matrices, the fft operation is applied to each column
% so you want time to run along the rows
[m,n] = size(psth);
if n > m
    psth = psth';
end
 

% FFT
L     = size(psth,1);
nfft  = 2^(nextpow2(L) + 1); % Next power of 2 from length of y, +1 for good measure
Y     = fft(psth,nfft)/L;
power = abs(Y(1:nfft/2+1,:));
freq  = Fs/2*linspace(0,1,nfft/2+1);


% ftf/f0
[~,fidx] = min(abs(freq-tf));
f1 = power(fidx,:);
f0 = power(freq==0,:);
ratio = mean(f1/f0);


