function fs = extractfs(info, proc)

% Ex. proc = Neuropix-PXI-104.0, NI-DAQmx-126.0

% extract bitvolts and units
t_ind_1 = strfind(info, proc);
t_ind_2 = strfind(info, '"sample_rate": ');
t_ind_3 = find(t_ind_2 > t_ind_1(1), 1);
t_ind_4 = t_ind_2(t_ind_3);
t_ind_5 = strfind(info, ',');
[~, t_ind_6] = min(abs(t_ind_4 - t_ind_5));
if isnan(str2double(info(t_ind_4+14:t_ind_5(t_ind_6)-1)))
    fs = str2double(info(t_ind_4+14:t_ind_5(t_ind_6+1)-1));
else
    fs = str2double(info(t_ind_4+14:t_ind_5(t_ind_6)-1));
end
end