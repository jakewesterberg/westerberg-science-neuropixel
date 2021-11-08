function data_out = computepower(data_in, fs, lpc)

filt_order = 4;

data_out = abs( data_in );

lWn = lpc / (fs/2);
[ bwb, bwa ] = butter( filt_order, lWn, 'low' );
data_out = filtfilt( bwb, bwa, data_out );

end