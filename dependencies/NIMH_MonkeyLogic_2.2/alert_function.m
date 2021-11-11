function alert_function(hook,MLConfig,TrialRecord)
% This function executes pre-defined instructions, when a certain task flow
% event listed below occurs.  Possible instructions you can give are
% stopping/exiting the task, turning on/off external devices, sending
% notifications, etc.
%
% If you want to customize this file for a particular task, make a copy of
% this file to the task directory and edit the copy.  The alert_function.m
% in the task directory has priority over the one in the main ML directory.
%
% To make this alert_function executed, turn on the alert button on the
% task panel of the main menu.

% Email
%
% 1. Run these commands on the MATLAB command window. Change the email
%   address and password accordingly.
%
%   setpref('Internet','E_mail','my_email@example.com');
%   setpref('Internet','SMTP_Server','my_server.example.com');
%   props = java.lang.System.getProperties;
%   props.setProperty('mail.smtp.auth','true');
%   setpref('Internet','SMTP_Username','myaddress@example.com');
%   setpref('Internet','SMTP_Password','mypassword');
%
% 2. Add the following sendmail command in the switch statement below.
%
%   sendmail('my_email@example.com','Task done', ...
%       'This message is sent from ML2.');

% Slack
%
%  See 'alert_function.Slack.m' in the NIMH ML directory.

switch hook
    case 'task_start'   % when the task starts by '[Space] Start' from the pause menu
        
    case 'block_start'
        
    case 'trial_start'
        
    case 'trial_end'
        
    case 'block_end'
        
    case 'task_end'      % when the task finishes succesfully
        
    case 'task_aborted'  % when the task stops with an error
        
    case 'task_paused'   % when the task is paused with ESC during the task
        
    case 'task_resumed'  % when the task is resumed by '[Space] Resume' from the pause menu
        
end

end
