function s = time2samp(t, fs, u)

if nargin < 3; u = 'ms'; end

switch u
    case 'ms'
        s = round(t * fs / 1000);
    case 's'
        s = round(t * fs);
end

end