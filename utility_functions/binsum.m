function [logi_out, ind_out] = binsum(data_in, bin, direc)

logi_out = [];

if strcmp('pre', direc)
    for i = bin:numel(data_in)
        logi_out(i) = sum(data_in(i-bin+1:i));
    end
    logi_out = (logi_out == 1) & data_in;
end

if strcmp('post', direc)
    for i = 1:numel(data_in)-bin
        logi_out(i) = sum(data_in(i:i+bin-1));
    end
    logi_out = ([logi_out zeros(1, bin)] == 1) & data_in;
end

ind_out = find(logi_out);

end