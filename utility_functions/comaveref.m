function data_out = comaveref(data_in, varargin)

varStrInd = find(cellfun(@ischar,varargin));
for iv = 1:length(varStrInd)
    switch varargin{varStrInd(iv)}
        case {'-c','chs'}
            chs = varargin{varStrInd(iv)+1};
    end
end

if ~exist('chs', 'var'); chs = size(data_in,1); end

data_out = data_in - repmat(mean(data_in(chs,:,:),1), ...
    size(data_in,1), 1, 1);

end