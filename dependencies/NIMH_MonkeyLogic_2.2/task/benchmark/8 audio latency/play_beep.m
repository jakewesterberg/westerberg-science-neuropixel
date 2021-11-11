bhv_code(10,'sound on');
editable('max_trial');

max_trial = 10;
dashboard(1,sprintf('This task will end after %d trials.',max_trial));

toggleobject(1,'eventmarker',10);
pause(0.2);
set_iti(0);

if max_trial==TrialRecord.CurrentTrialNumber, TrialRecord.Quit = true; end
