function reward_count = reward_function(Duration, varargin)
% This function is used to trigger external reward devices when goodmonkey()
% function is called.
%
% If you want to customize this file for a particular task, make a copy of
% this file to the task directory and edit the copy.  The reward_function.m
% in the task directory has priority over the one in the main ML directory.
reward_count = 0;  % return value

% Define user variables here. To change their values, call goodmonkey() like
% the following.  Variable names are case-sensitive.
%
%   goodmonkey(DURATION, 'VARIABLE_NAME1',NEW_VALUE1, 'VARIABLE_NAME2',NEW_VALUE2);
%
% Unless they are defined as persistent, all changes are temporary.
persistent Reward Channel Polarity RewardOn RewardOff PauseTime TriggerVal
JuiceLine = 1;
NonBlocking = 0;
NumReward = 1;

% Define what should be done to turn on and off your reward device in
% reward_on() and reward_off(), respectively.  You can use your own variables
% if you defined them above.  The customization of reward_on() and reward_off()
% is not supported in the non-blocking mode.
    function reward_on()
        switch class(Reward)
            case 'analogoutput', putsample(Reward,RewardOn);
            case 'digitalio', putvalue(Reward,RewardOn);
        end
    end
    function reward_off()
        switch class(Reward)
            case 'analogoutput', putsample(Reward,RewardOff);
            case 'digitalio', putvalue(Reward,RewardOff);
        end
    end

%
% The rest of the function below hardly needs modification. Do not touch.
%
if ischar(Duration), varargin = [Duration varargin]; Duration = 0; end
if Duration < 0
    DAQ = varargin{1};
    MLConfig = varargin{2};
    Reward = DAQ.Reward;
    
    Polarity = 1==MLConfig.RewardPolarity;
    r = MLConfig.RewardFuncArgs;
    PauseTime = r.PauseTime;
    TriggerVal = r.TriggerVal;
    try eval(r.Custom); catch, end
    
    switch class(Reward)
        case 'analogoutput'
            Channel = strcmp(Reward.Channel.ChannelName,'Reward');
            RewardOn = zeros(1,length(Reward.Channel));
            RewardOff = RewardOn;
        case 'digitalio'
            nLine = length(Reward.Line);
            RewardOff = logical(true(1,nLine) .* ~Polarity);
        case 'SerialPort'
            read(Reward);  % empty the buffer
            write(Reward,sprintf('R\n')); readln(Reward);
            write(Reward,sprintf('Q\n')); if ~strcmp('READY',readln(Reward)), error('goodmonkey:reward_serial','Device not ready'); end
        otherwise
            error('Unknown reward object!!!');
    end
    return
end

% parameters
code = [];
if ~isempty(varargin)
    nargs = length(varargin);
    if mod(nargs,2), error('goodmonkey() requires all arguments beyond the first to come in parameter/value pairs'); end
    for m = 1:2:nargs
        val = varargin{m+1};
        switch lower(varargin{m})
            case 'duration', Duration = val;
            case 'eventmarker', code = val;
            case 'juiceline', JuiceLine = val;
            case 'nonblocking', NonBlocking = val;
            case 'numreward', NumReward = val;
            case 'pausetime', PauseTime = val;
            case 'triggerval', TriggerVal = val;
            case 'eval', try eval(val); catch, end
            otherwise, try eval(sprintf('%s=%f;',varargin{m},val)); catch, end
        end
    end
end
switch length(code)
    case 0, code = NaN(1,NumReward);
    case 1, code = repmat(code,1,NumReward);
    otherwise, code(end+1:NumReward) = code(end);
end
if 0==Duration, return, end

% trigger
switch class(Reward)
    case 'analogoutput'
        RewardOn(Channel) = TriggerVal * Polarity;
        RewardOff(Channel) = TriggerVal * ~Polarity;
    case 'digitalio'
        RewardOn = RewardOff;
        RewardOn(JuiceLine) = Polarity;
    case 'SerialPort'
        NonBlocking = NonBlocking + 3;
end
switch NonBlocking
    case 0
        for m = 1:NumReward
            reward_on(); mdqmex(43,2,Duration,code(m));
            reward_off(); mdqmex(43,3);
            if m < NumReward, mdqmex(42,103,PauseTime); end
        end
    case {1,2}
        mdqmex(43,1,NumReward,Duration,code,PauseTime,NonBlocking,RewardOn,RewardOff);
        
    case 3
        read(Reward);  % empty the buffer
        mdqmex(43,2,0,code(1));
        write(Reward,sprintf('Y%d,%d,%d,%d\n',JuiceLine,Duration,NumReward,PauseTime));
        response = readln(Reward, (Duration*NumReward+PauseTime*(NumReward-1))/1000 + 1);
        mdqmex(43,3);
        switch response
            case 'OK'  % we are good
            otherwise
                switch response
                    case 'P1', warning('goodmonkey:reward_serial','Command not understood');
                    case 'P2', warning('goodmonkey:reward_serial','Solenoid does not exist');
                    case 'P3', warning('goodmonkey:reward_serial','Parameter error');
                    case 'P4', warning('goodmonkey:reward_serial','Solenoid is off line');
                    otherwise, warning('goodmonkey:reward_serial','Unknown error');
                end
                close(Reward); open(Reward);  % reset the serial port
                write(Reward,sprintf('R\n')); readln(Reward);  % reset the reward device
                write(Reward,sprintf('Q\n')); if ~strcmp('READY',readln(Reward)), error('goodmonkey:reward_serial','Device not ready'); end
        end
    case {4,5}
        mdqmex(43,2,0,code(1));
        write(Reward,sprintf('Y%d,%d,%d,%d\n',JuiceLine,Duration,NumReward,PauseTime));  % e.g., 'Y1,150,3,300'
        mdqmex(43,3);
        read(Reward);  % just read out the buffer
        
    otherwise
        error('Unknown NonBlocking Mode!!!');
end

reward_count = NumReward;

end
