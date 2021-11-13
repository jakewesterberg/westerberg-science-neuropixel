function btvc = extractbtvc(info, ch)
% extract bitvolts and units
t_ind_1 = strfind(info, ch);
t_ind_2 = strfind(info, '"bit_volts": ');
t_ind_3 = find(t_ind_2 > t_ind_1(1), 1);
t_ind_4 = t_ind_2(t_ind_3);
t_ind_5 = strfind(info, ',');
[~, t_ind_6] = min(abs(t_ind_4 - t_ind_5));
if isnan(str2double(info(t_ind_4+13:t_ind_5(t_ind_6)-1)))
    btvc = str2double(info(t_ind_4+13:t_ind_5(t_ind_6+1)-1));
else
    btvc = str2double(info(t_ind_4+13:t_ind_5(t_ind_6)-1));
end
end