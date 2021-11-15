function [adj_evt_stamps, adj_evt_inds, good_triggers] ...
    = rescueevts(evt_stamps, trigger_stamps)

if numel(trigger_stamps) < numel(evt_stamps)
    error('MORE EVENTS THAN DETECTED TRIGGERS!!!');
end

diff_evt = diff(evt_stamps);
diff_trigger = diff(trigger_stamps);

adj_evt_stamps = nan(1,numel(evt_stamps));
adj_evt_inds = nan(1,numel(evt_stamps));
good_triggers = zeros(1, numel(trigger_stamps));

norm_trigger = (trigger_stamps - trigger_stamps(1)) ...
    ./ min(diff_trigger);
norm_evt = (evt_stamps - evt_stamps(1)) ...
    ./ min(diff_evt);

i_ctr = 0;
i_vec = 0.95:0.00001:1.05;
for i = i_vec

    i_ctr = i_ctr + 1;
    t_norm_evt = norm_evt .* i;
    for j = 1 : numel(t_norm_evt)
        [t_val_1(j), t_ind_1(j)] = min(abs(t_norm_evt(j)-norm_trigger));
    end
    if any(abs(t_val_1) > 1); mismatch(i_ctr) = true; 
    else mismatch(i_ctr) = false; end

end

clear -regexp ^t_

multip = mean(i_vec(find(~mismatch)));
for j = 1 : numel(norm_evt)
    [t_val_1(j), t_ind_1(j)] = min(abs(norm_evt(j)*multip-norm_trigger));
    adj_evt_stamps(j) = trigger_stamps(t_ind_1(j));
    adj_evt_inds(j) =  t_ind_1(j);
    good_triggers(t_ind_1(j)) = 1;
end

good_triggers = find(good_triggers);

end