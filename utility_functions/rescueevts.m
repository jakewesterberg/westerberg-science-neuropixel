function [adj_evt_stamps, adj_evt_inds, good_triggers] ...
    = rescueevts(evt_stamps, trigger_stamps)

if numel(trigger_stamps) > numel(evt_stamps)
    error('MORE EVENTS THAN DETECTED TRIGGERS!!!');
end

adj_evt_stamps = nan(1,numel(evt_stamps));
adj_evt_inds = nan(1,numel(evt_stamps));
good_triggers = zeros(1, numel(trigger_stamps));

norm_trigger = (trigger_stamps - trigger_stamps(1)) ...
    ./ (trigger_stamps(end) - trigger_stamps(1));
norm_evt = (evt_stamps - evt_stamps(1)) ...
    ./ (evt_stamps(end) - evt_stamps(1));

diff_evt = diff(norm_evt);

n_evt = numel(norm_evt);

for i = 1 : n_evt
    [t_val_1, t_ind_1] = min(abs(norm_evt(i) - norm_trigger));
    if t_val_1 > min(diff_evt)
        warning('SUSPECTED MISMATCH BETWEEN EVT AND TRIGGER!!!')
    end
    adj_evt_stamps(i) = trigger_stamps(t_ind_1);
    adj_evt_inds(i) = t_ind_1;
    good_triggers(t_ind_1) = 1; 
end

end