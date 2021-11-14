function [adj_evt_diffs, adj_evt_stamps, adj_evt_inds] = ...
    matchevt2trigger(evt_stamps, trigger_stamps)

adj_evt_stamps = nan(1,numel(trigger_stamps));
adj_evt_inds = nan(1,numel(trigger_stamps));
adj_evt_diffs = nan(1,numel(trigger_stamps));
for i = 1 : numel(evt_stamps)

    stamp_diff = abs(trigger_stamps - evt_stamps(i));
    [adj_evt_diffs(i), min_ind] = min(stamp_diff);

    adj_evt_stamps(i) = trigger_stamps(min_ind);
    adj_evt_inds(i) = min_ind;
end
end