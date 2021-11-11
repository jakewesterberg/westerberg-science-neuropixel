function [C,timingfile,userdefined_trialholder] = LBC_fMRI2_userloop(MLConfig,TrialRecord)

% This is the same task as LBC_fMRI, but just written as a userloop version.
% This version pre-creates all image stimuli and re-uses them so that you
% can save ITI and video memory. This script replaces the conditions file.

C = [];
timingfile = 'LBC_fMRI2.m';
userdefined_trialholder = '';

persistent TaskObject RunTime
if isempty(TaskObject)
    % TaskObject strings
    filenames = {'A.bmp','B.bmp','C.bmp','D.bmp'};
    stim = cell(5,1);
    stim{1} = 'fix(0,0)';
    for m=1:length(filenames)
        stim{m+1} = sprintf('pic(%s,0,0)',filenames{m});
    end
    
    % create Taskobjects and runtime files
    TaskObject = mltaskobject(stim,MLConfig,TrialRecord);
    RunTime = get_function_handle(embed_timingfile(MLConfig,timingfile,userdefined_trialholder));
    
    % additional information
    TrialRecord.User.filename = filenames';
    TrialRecord.User.nfile = length(filenames);
    return
end

C = TaskObject;        % return the pre-created stimuli
timingfile = RunTime;  % return the pre-parsed timing file.
