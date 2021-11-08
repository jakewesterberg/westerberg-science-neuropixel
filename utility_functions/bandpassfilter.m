function data_through = bandpassfilter( data_through, fs, band, varargin )

% along first dim

filt_order = 4;
filt_type = 'butter';

varStrInd = find(cellfun(@ischar,varargin));
for iv = 1:length(varStrInd)
    switch varargin{varStrInd(iv)}
        case {'-o', 'filter_order'}
            filt_order = varargin{varStrInd(iv)+1};
        case {'-t', 'filter_type'}
            filt_order = varargin{varStrInd(iv)+1};
    end
end

hWn = band(1) / (fs/2);

if strcmp('butter', filt_type)
    [ bwb, bwa ] = butter( filt_order, hWn, 'high' );
end

data_through = filtfilt( bwb, bwa, data_through );

lWn = band(2) / (fs/2);

if strcmp('butter', filt_type)
    [ bwb, bwa ] = butter( filt_order, lWn, 'low' );
end

data_through = filtfilt( bwb, bwa, data_through );

end