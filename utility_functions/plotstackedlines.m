function plotstackedlines(data_in)
   
t_min = min(min(data_in));
t_max = max(max(data_in));
    
sep = max(t_max - t_min)*1.1;
hold on;
for i_ch = 1 : size( data_in, 1)
    
    plot(data_in(i_ch,:) - (sep*(i_ch-1)), ...
        'linewidth', 2, 'color', 'k')
    
end

set(gca, 'xlim', [1, length(data_in(1,:))], ...
    'ylim', [-sep*(i_ch), 0 + sep], ...
    'linewidth', 2, ...
    'ytick', [])

box off;

end