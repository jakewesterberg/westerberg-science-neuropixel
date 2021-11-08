function data_out = smoothinspace(data_in, adj, mthd)

if strcmp(mthd, 'ave'); mthd = @mean; 
elseif strcmp(mthd, 'med'); mthd = @median;
end

data_out = nan(size(data_in));

data_in = cat(1, nan(adj, size(data_in, 2), size(data_in, 3)), ...
    data_in, nan(adj, size(data_in, 2), size(data_in, 3)));

for i = 1 : size(data_out, 1)
    data_out(i,:,:) = mthd(data_in(i+adj-adj:i+adj+adj,:,:),1,'omitnan');
end

end