function out_samps = triggerdetect(sig_in, mthd)

if nargin < 2; mthd = 'below0'; end

switch mthd
    case 'below0'
        out_samps = sig_in < 0;
end

end