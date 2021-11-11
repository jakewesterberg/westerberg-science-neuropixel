classdef mldaq < handle
    properties (Dependent)
        Eye
        Eye2
        EyeExtra
        Joystick
        Joystick2
        PhotoDiode
        Button
        General
        HighFrequency
        Touch
        Mouse
        MouseButton
        KeyInput
        Voice
    end
    properties (SetAccess = protected)
        Stimulation
        TTL
        Webcam
        goodmonkey
        eventmarker
        nSampleFromMarker

        nJoystick
        nButton
        nGeneral
        nHighFrequency
        nStimulation
        nTTL
        nWebcam
        nKey
    end
    properties (SetAccess = protected, Hidden)
        Reward
        BehavioralCodes
        StrobeBit

        LastSamplePosition
        SimulatedEye2
        SimulatedJoystick
        SimulatedJoystick2
        SimulatedButton

        WebcamTimer
        WebcamOffset
        VoiceSampleRate
    end
    properties (Access = protected)
        DAQ         % compact list of DAQ tasks
        Type        % 1:AI, 2:AO, 3:DIO, 4:pointer, 5:webcam, 6:voice, 7:high_freq
        Startable   % AI, DI, pointer, voice, high_freq
        Map         % device & channel mapping
        Data        % recently acquired data
        LastAcquisition  % 1:one sample, 2: continuous

        IO          % config variables related to DAQ
        StrobeTrigger
    end
    properties (Constant, Hidden)
        MLConfigFields = {'StrobeTrigger'};
    end

    methods
        function obj = mldaq(MLConfig)
            if exist('MLConfig','var') && isa(MLConfig,'mlconfig'), create(obj,MLConfig); end
        end
        function delete(obj), destroy(obj); end
        function destroy(obj)
            if isempty(obj.DAQ), return, end  % To prevent the DAQ tasks from being destroyed by an instance that didn't create them.
            init(obj);
        end

        function val = eye_present(obj), val = 0~=obj.Map.Eye(1); end
        function val = eye2_present(obj), val = 0~=obj.Map.Eye2(1); end
        function val = joystick_present(obj), val = 0~=obj.Map.Joystick(1); end  % true for USB joysticks as well
        function val = joystick2_present(obj), val = 0~=obj.Map.Joystick2(1); end  % true for USB joysticks as well
        function val = button_present(obj), val = any(0~=obj.Map.Button(:,1)) | 0<obj.nButton(2) | 0<obj.nButton(3); end
        function val = touch_present(obj), val = 0~=obj.Map.Touch; end
        function val = mouse_present(obj), val = 0~=obj.Map.Mouse; end
        function val = voice_present(obj), val = 0~=obj.Map.Voice; end
        function val = usbjoystick_present(obj), val = 0~=obj.Map.USBJoystick(1); end
        function val = usbjoystick2_present(obj), val = 0~=obj.Map.USBJoystick(2); end
        function val = buttons_available(obj), val = [find(0~=obj.Map.Button(:,1))' (1:obj.nButton(2))+obj.nButton(1) (1:obj.nButton(3))+(obj.nButton(1)+obj.nButton(2))]; end
        function val = general_available(obj), val = find(0~=obj.Map.General(:,1))'; end
        function val = highfrequency_available(obj), val = find(0~=obj.Map.HighFrequency(:,1))'; end
        function val = ttl_available(obj), if isempty(obj.TTL), val = []; else, val = find(0==cellfun(@isempty,obj.TTL)); end, end
        function val = stimulation_available(obj), if isempty(obj.Stimulation), val = []; else, val = find(0==cellfun(@isempty,obj.Stimulation)); end, end
        function val = reward_present(obj), val = ~strcmp(func2str(obj.goodmonkey),func2str(@obj.dummy_goodmonkey)); end
        function val = strobe_present(obj), val = ~strcmp(func2str(obj.eventmarker),func2str(@obj.dummy_eventmarker)); end
        function val = eyetracker_present(obj), val = 0~=obj.Map.EyeTracker; end
        function button_threshold(obj,button,val), if isempty(val), obj.Map.Button(button,3) = obj.Map.Button(button,4); else obj.Map.Button(button,3) = val; end, end
        function [val,val2] = get_device(obj,type)
            val = []; val2 = [];
            switch lower(type)
                case {'eye',1}, if 0~=obj.Map.Eye(1), val = obj.DAQ{obj.Map.Eye(1)}; val2 = obj.Map.Eye(:,2)'; end %#ok<*SEPEX>
                case 'eye2', if 0~=obj.Map.Eye2(1), val = obj.DAQ{obj.Map.Eye2(1)}; val2 = obj.Map.Eye2(:,2)'; end
                case {'joystick','joy',2}, if 0~=obj.Map.Joystick(1), val = obj.DAQ{obj.Map.Joystick(1)}; val2 = obj.Map.Joystick(:,2)'; end
                case {'joystick2','joy2'}, if 0~=obj.Map.Joystick2(1), val = obj.DAQ{obj.Map.Joystick2(1)}; val2 = obj.Map.Joystick2(:,2)'; end
                case 'photodiode', if 0~=obj.Map.PhotoDiode(1), val = obj.DAQ{obj.Map.PhotoDiode(1)}; val2 = obj.Map.PhotoDiode(2); end
                case 'button', val = cell(obj.nButton(1),1); for m=find(obj.Map.Button(:,1))', val{m} = obj.DAQ{obj.Map.Button(m,1)}; end, val2 = obj.Map.Button(:,2)';
                case 'general', val = cell(obj.nGeneral,1); for m=find(obj.Map.General(:,1))', val{m} = obj.DAQ{obj.Map.General(m,1)}; end, val2 = obj.Map.General(:,2)';
                case 'highfrequency', idx = find(0~=obj.Map.HighFrequency(:,1),1); val = obj.DAQ{obj.Map.HighFrequency(idx,1)}; val2 = obj.Map.HighFrequency(:,2)';
                case 'touch', if 0~=obj.Map.Touch, val = obj.DAQ{obj.Map.Touch}; end
                case 'mouse', if 0~=obj.Map.Mouse, val = obj.DAQ{obj.Map.Mouse}; end
                case 'usbjoystick', if 0~=obj.Map.USBJoystick(1), val = obj.DAQ{obj.Map.USBJoystick(1)}; end
                case 'usbjoystick2', if 0~=obj.Map.USBJoystick(2), val = obj.DAQ{obj.Map.USBJoystick(2)}; end
                case 'eyetracker', if 0~=obj.Map.EyeTracker, val = obj.DAQ{obj.Map.EyeTracker}; end
                case 'voice', if 0~=obj.Map.Voice, val = obj.DAQ{obj.Map.Voice}; end
            end
        end

        function obj = create(obj,MLConfig)
            obj.nJoystick = 2;
            obj.nButton = [sum(strncmpi('Button',MLConfig.IOList(:,1),6)) zeros(1,obj.nJoystick)];
            obj.nGeneral = sum(strncmpi('General',MLConfig.IOList(:,1),7));
            obj.nHighFrequency = sum(strncmpi('High Frequency',MLConfig.IOList(:,1),14));
            obj.nStimulation = sum(strncmpi('Stimulation',MLConfig.IOList(:,1),11));
            obj.nTTL = sum(strncmpi('TTL',MLConfig.IOList(:,1),3));
            obj.nWebcam = length(MLConfig.Webcam);
            obj.nKey = length(MLConfig.MouseKey.KeyCode);
            init(obj);

            high_frequency_dev = 0;
            obj.IO = MLConfig.IO;  % store IO as unsorted so that we can compare it with MLConfig's IO
            if ~isempty(MLConfig.IO)
                eye = strncmp({MLConfig.IO.SignalType},'Eye ',4);
                if 1==sum(eye), error('Either Eye X or Y is not assigned. They both should be assigned together.'); end
                if 2==length(unique_subsystem(obj,MLConfig.IO(eye))), error('Both Eye X and Y should be on the same DAQ device.'); end
                eye = strncmp({MLConfig.IO.SignalType},'Eye2',4);
                if 1==sum(eye), error('Either Eye2 X or Y is not assigned. They both should be assigned together.'); end
                if 2==length(unique_subsystem(obj,MLConfig.IO(eye))), error('Both Eye2 X and Y should be on the same DAQ device.'); end
                joy = strncmp({MLConfig.IO.SignalType},'Joystick ',9);
                if 1==sum(joy), error('Either Joystick X or Y is not assigned. They both should be assigned together.'); end
                if 2==length(unique_subsystem(obj,MLConfig.IO(joy))), error('Both Joystick X and Y should be on the same DAQ device.'); end
                joy = strncmp({MLConfig.IO.SignalType},'Joystick2',9);
                if 1==sum(joy), error('Either Joystick2 X or Y is not assigned. They both should be assigned together.'); end
                if 2==length(unique_subsystem(obj,MLConfig.IO(joy))), error('Both Joystick2 X and Y should be on the same DAQ device.'); end

                analog = MLConfig.IO(strcmp({MLConfig.IO.Subsystem},'AnalogInput') | strcmp({MLConfig.IO.Subsystem},'AnalogOutput'));
                if isempty(analog), ia1 = []; ic1 = []; else [~,ia1,ic1] = unique_subsystem(obj,analog); end
                digital = MLConfig.IO(strcmp({MLConfig.IO.Subsystem},'DigitalIO'));
                if isempty(digital)
                    din = []; dout = []; ia2 = []; ic2 = [];
                else
                    dioinfo = cell(length(digital),1);
                    for m=1:length(digital), dioinfo{m} = digital(m).DIOInfo{1,2}; end
                    in = strcmp(dioinfo,'in');
                    din = digital(in); dout = digital(~in);
                    if isempty(din), ia2 = []; ic2 = []; else [~,ia2,ic2] = unique_subsystem(obj,din); end
                end
                if isempty(analog), analog = []; end  % make it sure that all demensions are 0
                if isempty(din), din = []; end
                if isempty(dout), dout = []; end

                IO = [analog; din; dout]; %#ok<*PROPLC> % original list
                daq = [analog(ia1); din(ia2); dout];    % compact list
                map = [ic1; ic2+length(ia1); (1:length(dout))'+length(ia1)+length(ia2)];  % original-to-compact map

                ndaq = length(daq);
                obj.DAQ = cell(ndaq,1);
                obj.Type = zeros(ndaq,1);
                for m=1:ndaq
                    switch daq(m).Subsystem
                        case 'AnalogInput'
                            obj.DAQ{m} = analoginput(daq(m).Adaptor,daq(m).DevID); %#ok<*TNMLP>
                            obj.DAQ{m}.SamplesPerTrigger = Inf;
                            obj.DAQ{m}.InputType = MLConfig.AIConfiguration;
                            obj.Type(m) = 1;
                            obj.Startable(end+1) = m;
                            if strcmpi(daq(m).Adaptor,MLConfig.HighFrequencyDAQ.Adaptor) && strcmpi(daq(m).DevID,MLConfig.HighFrequencyDAQ.DevID)
                                obj.DAQ{m}.SampleRate = MLConfig.HighFrequencyDAQ.SampleRate;
                                obj.Type(m) = 7;
                                high_frequency_dev = m;
                            end
                        case 'AnalogOutput'
                            obj.DAQ{m} = analogoutput(daq(m).Adaptor,daq(m).DevID);
                            obj.DAQ{m}.TriggerType = 'Manual';
                            obj.Type(m) = 2;
                        case 'DigitalIO'
                            obj.DAQ{m} = digitalio(daq(m).Adaptor,daq(m).DevID);
                            obj.Type(m) = 3;
                            if strcmpi(daq(m).DIOInfo{1,2},'in'), obj.Startable(end+1) = m; end
                    end
                end

                for m=1:length(IO)
                    d = map(m);
                    if strncmp(IO(m).SignalType,'High Frequency',14)
                        if d~=high_frequency_dev, error('%s must be assigned to High Frequency DAQ Device',IO(m).SignalType); end
                    else
                        if d==high_frequency_dev, error('%s cannot be assigned to High Frequency DAQ Device',IO(m).SignalType); end
                    end

                    o = obj.DAQ{d};
                    switch IO(m).SignalType
                        case 'Eye X', addchannel(o,IO(m).Channel,'EyeX'); obj.Map.Eye(1,:) = [d length(o.Channel)];
                        case 'Eye Y', addchannel(o,IO(m).Channel,'EyeY'); obj.Map.Eye(2,:) = [d length(o.Channel)];
                        case 'Eye2 X', addchannel(o,IO(m).Channel,'Eye2X'); obj.Map.Eye2(1,:) = [d length(o.Channel)];
                        case 'Eye2 Y', addchannel(o,IO(m).Channel,'Eye2Y'); obj.Map.Eye2(2,:) = [d length(o.Channel)];
                        case 'Joystick X', addchannel(o,IO(m).Channel,'JoystickX'); obj.Map.Joystick(1,:) = [d length(o.Channel)];
                        case 'Joystick Y', addchannel(o,IO(m).Channel,'JoystickY'); obj.Map.Joystick(2,:) = [d length(o.Channel)];
                        case 'Joystick2 X', addchannel(o,IO(m).Channel,'Joystick2X'); obj.Map.Joystick2(1,:) = [d length(o.Channel)];
                        case 'Joystick2 Y', addchannel(o,IO(m).Channel,'Joystick2Y'); obj.Map.Joystick2(2,:) = [d length(o.Channel)];
                        case 'Reward'
                            obj.Reward = o;
                            switch class(o)
                                case 'analogoutput', addchannel(o,IO(m).Channel,'Reward');
                                case 'digitalio', for n=1:length(IO(m).Channel), addline(o,IO(m).DIOInfo{n,1},IO(m).Channel(n),IO(m).DIOInfo{n,2},'Reward'); end
                            end
                        case 'Behavioral Codes', obj.BehavioralCodes = o; for n=1:length(IO(m).Channel), addline(o,IO(m).DIOInfo{n,1},IO(m).Channel(n),IO(m).DIOInfo{n,2},'BehavioralCodes'); end
                        case 'Strobe Bit', obj.StrobeBit = o; for n=1:length(IO(m).Channel), addline(o,IO(m).DIOInfo{n,1},IO(m).Channel(n),IO(m).DIOInfo{n,2},'StrobeBit'); end
                        case 'PhotoDiode', addchannel(o,IO(m).Channel,'PhotoDiode'); obj.Map.PhotoDiode = [d length(o.Channel)];
                        otherwise
                            n = str2double(regexp(IO(m).SignalType,'\d+','match'));
                            switch IO(m).SignalType(1:3)
                                case 'But'
                                    switch class(o)
                                        case 'analoginput', addchannel(o,IO(m).Channel,sprintf('Button%d',n)); obj.Map.Button(n,:) = [d length(o.Channel) 3 3];
                                        case 'digitalio', addline(o,IO(m).DIOInfo{1},IO(m).Channel,IO(m).DIOInfo{2},sprintf('Button%d',n)); obj.Map.Button(n,:) = [d length(o.Line) 0.5 0.5];
                                    end
                                case 'Gen', addchannel(o,IO(m).Channel,sprintf('General%d',n)); obj.Map.General(n,:) = [d length(o.Channel)];
                                case 'Sti', obj.Stimulation{n} = o; addchannel(o,IO(m).Channel,sprintf('Stimulation%d',n));
                                case 'TTL', obj.TTL{n} = o; addline(o,IO(m).DIOInfo{1},IO(m).Channel,IO(m).DIOInfo{2},sprintf('TTL%d',n));
                                case 'Hig', addchannel(o,IO(m).Channel,sprintf('HighFrequency%d',n)); obj.Map.HighFrequency(n,:) = [d length(o.Channel)];
                            end
                    end
                end
            end

            if MLConfig.MouseKey.Mouse
                obj.DAQ{end+1,1} = pointingdevice('mouse','0'); obj.Type(end+1,1) = 4;
                m = length(obj.DAQ); obj.Startable(end+1) = m; obj.Map.Mouse = m;
                obj.DAQ{end}.setProperty('KeyCode',MLConfig.MouseKey.KeyCode);
            end
            if MLConfig.Touchscreen.On
                obj.DAQ{end+1,1} = pointingdevice('mouse','1'); obj.Type(end+1,1) = 4;
                m = length(obj.DAQ); obj.Startable(end+1) = m; obj.Map.Touch = m;
                obj.DAQ{end}.NumInput = MLConfig.Touchscreen.NumTouch;
                mglsetnumtouch(obj.DAQ{end}.NumInput);
            end
            for m=1:length(MLConfig.USBJoystick)
                if ~isempty(MLConfig.USBJoystick(m).ID) && ~strcmpi('None',MLConfig.USBJoystick(m).ID)
                    try
                        obj.DAQ{end+1,1} = pointingdevice('joystick',MLConfig.USBJoystick(m).ID); obj.Type(end+1,1) = 4;
                        k = length(obj.DAQ); obj.Startable(end+1) = k;
                        switch m
                            case 1, obj.Map.Joystick = [k 1; k 2];
                            case 2, obj.Map.Joystick2 = [k 1; k 2];
                        end
                        obj.Map.USBJoystick(m) = k;
                        obj.DAQ{end}.NumInput = MLConfig.USBJoystick(m).NumButton;
                        obj.DAQ{end}.setProperty('IP_address',MLConfig.USBJoystick(m).IP_address);
                        obj.DAQ{end}.setProperty('Port',MLConfig.USBJoystick(m).Port);
                        obj.nButton(m+1) = obj.DAQ{end}.NumInput;
                        for n=(obj.nButton(m+1):-1:1) + sum(obj.nButton(1:m)), obj.Map.Button(n,:) = [0 0 0.5 0.5]; end
                    catch err
                        if ~isempty(strfind(err.identifier,'NotFound')), warning('Cannot find USB Joystick #%d.',m); else rethrow(err); end
                    end
                end
            end
            for m=1:obj.nWebcam
                if ~isempty(MLConfig.Webcam(m).ID) && ~strcmpi('None',MLConfig.Webcam(m).ID)
                    try
                        cam = videocapture('webcam',MLConfig.Webcam(m).ID);
                        cam.import(MLConfig.Webcam(m).Property);
                        cam.TriggerType = 'Manual';
                        obj.DAQ{end+1,1} = cam; obj.Type(end+1,1) = 5;
                        obj.Webcam{m} = cam;
                    catch err
                        if ~isempty(strfind(err.identifier,'NotFound')), warning('Cannot find Webcam #%d.',m'); else rethrow(err); end
                    end
                end
            end
            if ~isempty(MLConfig.EyeTracker.ID) && ~strcmpi('None',MLConfig.EyeTracker.ID)
                try
                    eye = eyetracker(MLConfig.EyeTracker.ID);
                    switch MLConfig.EyeTracker.ID
                        case 'myeye'
                            eye.setProperty('Protocol',MLConfig.EyeTracker.MyEyeTracker.Protocol);
                            eye.setProperty('Port',MLConfig.EyeTracker.MyEyeTracker.Port);
                            eye.IP_address = MLConfig.EyeTracker.MyEyeTracker.IP_address;
                            eye.Source = MLConfig.EyeTracker.MyEyeTracker.Source;
                        case 'viewpoint'
                            eye.setProperty('Port',MLConfig.EyeTracker.ViewPoint.Port);
                            eye.IP_address = MLConfig.EyeTracker.ViewPoint.IP_address;
                            eye.Source = MLConfig.EyeTracker.ViewPoint.Source;
                        case 'eyelink'
                            [width,height] = mglgetadapterdisplaymode(MLConfig.SubjectScreenDevice);
                            eye.setProperty('ScreenSize',[width height]);
                            eye.setProperty('Filter',MLConfig.EyeTracker.EyeLink.Filter);
                            eye.setProperty('PupilSize',MLConfig.EyeTracker.EyeLink.PupilSize);
                            eye.IP_address = MLConfig.EyeTracker.EyeLink.IP_address;
                            eye.Source = MLConfig.EyeTracker.EyeLink.Source;
                        case 'iscan'
                            eye.setProperty('Port',str2double(MLConfig.EyeTracker.ISCAN.Port));
                            eye.IP_address = MLConfig.EyeTracker.ISCAN.IP_address;
                            eye.Source = MLConfig.EyeTracker.ISCAN.Source;
                        case 'tomrs'
                            eye.setProperty('Port','65534');
                            eye.setProperty('CameraProfile',MLConfig.EyeTracker.TOMrs.CameraProfile);
                            eye.IP_address = MLConfig.EyeTracker.TOMrs.IP_address;
                            eye.Source = MLConfig.EyeTracker.TOMrs.Source;
                        otherwise, error('Unknown TCP/IP eye tracker type!!!');
                    end
                    obj.DAQ{end+1,1} = eye; obj.Type(end+1,1) = 1;
                    m = length(obj.DAQ); obj.Startable(end+1) = m; obj.Map.Eye = [m 1; m 2]; obj.Map.EyeTracker = m;
                    switch MLConfig.EyeTracker.ID
                        case 'myeye', if 0<eye.Source(1,1), obj.Map.Eye2 = [m 3; m 4]; end
                        case {'viewpoint','eyelink'}, if 1~=eye.Source(3,2), obj.Map.Eye2 = [m 3; m 4]; end
                        case 'iscan', if MLConfig.EyeTracker.ISCAN.Binocular, obj.Map.Eye2 = [m 3; m 4]; end
                    end
                catch err
                    if ~isempty(strfind(err.identifier,'NotFound')), warning('Cannot find the TCP/IP eyetracker, %s',MLConfig.EyeTracker.ID); else rethrow(err); end
                end
            end
            if ~isempty(MLConfig.SerialPort.Port) && ~strcmpi('None',MLConfig.SerialPort.Port)
                try
                    o = SerialPort(MLConfig.SerialPort.Port);
                    o.BaudRate = MLConfig.SerialPort.BaudRate;
                    o.ByteSize = MLConfig.SerialPort.ByteSize;
                    o.StopBits = MLConfig.SerialPort.StopBits;
                    o.Parity   = MLConfig.SerialPort.Parity;
                    open(o);
                    obj.Reward = o;
                catch err
                    if ~isempty(strfind(err.identifier,'NotFound')), warning('Cannot find the serial port, %s.',MLConfig.SerialPort.Port); else rethrow(err); end
                end
            end
            if ~isempty(MLConfig.VoiceRecording.ID) && ~strcmpi('None',MLConfig.VoiceRecording.ID)
                try
                    voice = analoginput('wasapi',MLConfig.VoiceRecording.ID);
                    voice.SamplesPerTrigger = Inf;
                    if MLConfig.VoiceRecording.Exclusive
                        voice.SampleRate = MLConfig.VoiceRecording.SampleRate;
                    else
                        info = daqhwinfo(voice); voice.setProperty('Format',length(info.SupportedFormat));
                    end
                    obj.VoiceSampleRate = voice.SampleRate;  % verify if the sound board supports the sample rate
                    addchannel(voice,1);
                    try if strcmpi(MLConfig.VoiceRecording.Stereo,'Stereo'), addchannel(voice,2); end, catch warning('This voice recording device does not support stereo.'); end
                    obj.DAQ{end+1,1} = voice; obj.Type(end+1,1) = 6;
                    m = length(obj.DAQ); obj.Startable(end+1) = m; obj.Map.Voice = m;
                catch err
                    if ~isempty(regexp(err.identifier,'NotFound$','once')), warning('Cannot find any voice recording device.'); else rethrow(err); end
                end
            end

            for m=obj.MLConfigFields, obj.(m{1}) = MLConfig.(m{1}); end
            mdqmex(42,102,obj.StrobeTrigger,MLConfig.StrobePulseSpec.T1,MLConfig.StrobePulseSpec.T2);
            for m=1:length(obj.DAQ)
                switch lower(class(obj.DAQ{m}))
                    case {'analoginput','pointingdevice','eyetracker','videocapture'}, register(obj.DAQ{m});
                    case 'digitalio', if strcmpi(obj.DAQ{m}.Line(1).Direction,'in'), register(obj.DAQ{m}); end
                end
            end
            init_eventmarker(obj);
            init_goodmonkey(obj,MLConfig);
        end

        function val = get.Eye(obj)
            if 0==obj.Map.Eye(1) || isempty(obj.Data{obj.Map.Eye(1),1}), val = []; return, end
            val = obj.Data{obj.Map.Eye(1),1}(:,obj.Map.Eye(:,2));
            if 3==obj.LastAcquisition, obj.LastSamplePosition = obj.nSampleFromMarker(obj.Map.Eye(1)); end
        end
        function val = get.Eye2(obj)
            if 0==obj.Map.Eye2(1) || isempty(obj.Data{obj.Map.Eye2(1),1}), val = []; return, end
            val = obj.Data{obj.Map.Eye2(1),1}(:,obj.Map.Eye2(:,2));
            if 3==obj.LastAcquisition, obj.LastSamplePosition = obj.nSampleFromMarker(obj.Map.Eye2(1)); end
        end
        function val = get.EyeExtra(obj)
            if 0==obj.Map.EyeTracker || isempty(obj.Data{obj.Map.EyeTracker,1}), val = []; return, end
            if 0==obj.Map.Eye2(1), val = obj.Data{obj.Map.EyeTracker,1}(:,3:end); else val = obj.Data{obj.Map.EyeTracker,1}(:,5:end); end
            if 3==obj.LastAcquisition, obj.LastSamplePosition = obj.nSampleFromMarker(obj.Map.EyeTracker); end
        end
        function val = get.Joystick(obj)
            if 0==obj.Map.Joystick(1) || isempty(obj.Data{obj.Map.Joystick(1),1}), val = []; return, end
            if 0==obj.Map.USBJoystick(1)
                val = obj.Data{obj.Map.Joystick(1),1}(:,obj.Map.Joystick(:,2));
            else
                val = obj.Data{obj.Map.Joystick(1),1}(:,obj.Map.Joystick(:,2)) ./ 1000;
                val(:,2) = -val(:,2);
            end
            if 3==obj.LastAcquisition, obj.LastSamplePosition = obj.nSampleFromMarker(obj.Map.Joystick(1)); end
        end
        function val = get.Joystick2(obj)
            if 0==obj.Map.Joystick2(1) || isempty(obj.Data{obj.Map.Joystick2(1),1}), val = []; return, end
            if 0==obj.Map.USBJoystick(2)
                val = obj.Data{obj.Map.Joystick2(1),1}(:,obj.Map.Joystick2(:,2));
            else
                val = obj.Data{obj.Map.Joystick2(1),1}(:,obj.Map.Joystick2(:,2)) ./ 1000;
                val(:,2) = -val(:,2);
            end
            if 3==obj.LastAcquisition, obj.LastSamplePosition = obj.nSampleFromMarker(obj.Map.Joystick2(1)); end
        end
        function val = get.PhotoDiode(obj)
            if 0==obj.Map.PhotoDiode(1) || isempty(obj.Data{obj.Map.PhotoDiode(1),1}), val = []; return, end
            val = obj.Data{obj.Map.PhotoDiode(1),1}(:,obj.Map.PhotoDiode(:,2));
            if 3==obj.LastAcquisition, obj.LastSamplePosition = obj.nSampleFromMarker(obj.Map.PhotoDiode(1)); end
        end
        function val = get.Button(obj)
            btn = find(0~=obj.Map.Button(:,1))';  % 10 hardware buttons
            nbtn = sum(obj.nButton);
            switch obj.LastAcquisition
                case 1
                    val = false(1,nbtn);
                    for m=btn
                        if isempty(obj.Data{obj.Map.Button(m,1),1}), continue, end
                        val(m) = obj.Map.Button(m,3) < obj.Data{obj.Map.Button(m,1),1}(:,obj.Map.Button(m,2));
                    end
                    for m=1:obj.nJoystick
                        a = obj.Map.USBJoystick(m);
                        if 0==a || isempty(obj.Data{a,2}), continue, end
                        b = sum(obj.nButton(1:m));
                        val((1:obj.nButton(m+1))+b) = obj.Data{a,2};
                    end
                case 2
                    val = cell(1,nbtn);
                    for m=btn
                        if isempty(obj.Data{obj.Map.Button(m,1),1}), continue, end
                        val{m} = obj.Map.Button(m,3) < obj.Data{obj.Map.Button(m,1),1}(:,obj.Map.Button(m,2));
                    end
                    for m=1:obj.nJoystick
                        a = obj.Map.USBJoystick(m);
                        if 0==a || isempty(obj.Data{a,2}), continue, end
                        b = sum(obj.nButton(1:m));
                        for n=1:obj.nButton(m+1), val{n+b} = obj.Data{a,2}(:,n); end
                    end
                case 3
                    val = cell(1,nbtn);
                    for m=btn
                        if isempty(obj.Data{obj.Map.Button(m,1),1}), continue, end
                        val{m} = obj.Map.Button(m,3) < obj.Data{obj.Map.Button(m,1),1}(:,obj.Map.Button(m,2));
                    end
                    obj.LastSamplePosition = NaN(1,nbtn); obj.LastSamplePosition(btn) = obj.nSampleFromMarker(obj.Map.Button(btn,1));
                    for m=1:obj.nJoystick
                        a = obj.Map.USBJoystick(m);
                        if 0==a || isempty(obj.Data{a,2}), continue, end
                        b = sum(obj.nButton(1:m));
                        for n=1:obj.nButton(m+1), val{n+b} = obj.Data{a,2}(:,n); end
                        obj.LastSamplePosition((1:obj.nButton(m+1))+b) = obj.nSampleFromMarker(obj.Map.USBJoystick(m));
                    end
                otherwise, val = [];
            end
        end
        function val = get.General(obj)
            gen = find(0~=obj.Map.General(:,1))';
            switch obj.LastAcquisition
                case 1
                    val = NaN(1,obj.nGeneral);
                    for m=gen
                        if isempty(obj.Data{obj.Map.General(m,1),1}), continue, end
                        val(m) = obj.Data{obj.Map.General(m,1),1}(:,obj.Map.General(m,2));
                    end
                case 2
                    val = cell(1,obj.nGeneral);
                    for m=gen
                        if isempty(obj.Data{obj.Map.General(m,1),1}), continue, end
                        val{m} = obj.Data{obj.Map.General(m,1),1}(:,obj.Map.General(m,2));
                    end
                case 3
                    val = cell(1,obj.nGeneral);
                    for m=gen
                        if isempty(obj.Data{obj.Map.General(m,1),1}), continue, end
                        val{m} = obj.Data{obj.Map.General(m,1),1}(:,obj.Map.General(m,2));
                    end
                    obj.LastSamplePosition = NaN(1,obj.nGeneral); obj.LastSamplePosition(gen) = obj.nSampleFromMarker(obj.Map.General(gen,1));
                otherwise, val = [];
            end
        end
        function val = get.HighFrequency(obj)
            hfreq = find(0~=obj.Map.HighFrequency(:,1))';
            switch obj.LastAcquisition
                case 1
                    val = NaN(1,obj.nHighFrequency);
                    for m=hfreq
                        if isempty(obj.Data{obj.Map.HighFrequency(m,1),1}), continue, end
                        val(m) = obj.Data{obj.Map.HighFrequency(m,1),1}(:,obj.Map.HighFrequency(m,2));
                    end
                case 2
                    val = cell(1,obj.nHighFrequency);
                    for m=hfreq
                        if isempty(obj.Data{obj.Map.HighFrequency(m,1),1}), continue, end
                        val{m} = obj.Data{obj.Map.HighFrequency(m,1),1}(:,obj.Map.HighFrequency(m,2));
                    end
                case 3
                    val = cell(1,obj.nHighFrequency);
                    for m=hfreq
                        if isempty(obj.Data{obj.Map.HighFrequency(m,1),1}), continue, end
                        val{m} = obj.Data{obj.Map.HighFrequency(m,1),1}(:,obj.Map.HighFrequency(m,2));
                    end
                    obj.LastSamplePosition = NaN(1,obj.nHighFrequency); obj.LastSamplePosition(hfreq) = obj.nSampleFromMarker(obj.Map.HighFrequency(hfreq,1));
                otherwise, val = [];
            end
        end
        function val = get.Touch(obj)
            if 0==obj.Map.Touch || isempty(obj.Data{obj.Map.Touch,1}), val = []; return, end
            val = obj.Data{obj.Map.Touch,1};
            if 3==obj.LastAcquisition, obj.LastSamplePosition = obj.nSampleFromMarker(obj.Map.Touch); end
        end
        function val = get.Mouse(obj)
            if 0==obj.Map.Mouse || isempty(obj.Data{obj.Map.Mouse,1}), val = []; return, end
            val = obj.Data{obj.Map.Mouse,1};
            if 3==obj.LastAcquisition, obj.LastSamplePosition = obj.nSampleFromMarker(obj.Map.Mouse); end
        end
        function val = get.MouseButton(obj)
            if 0==obj.Map.Mouse || isempty(obj.Data{obj.Map.Mouse,2}), val = []; return, end
            val = obj.Data{obj.Map.Mouse,2}(:,1:2);
            if 3==obj.LastAcquisition, obj.LastSamplePosition = obj.nSampleFromMarker(obj.Map.Mouse); end
        end
        function val = get.KeyInput(obj)
            if 0==obj.Map.Mouse || isempty(obj.Data{obj.Map.Mouse,2}) || 2==size(obj.Data{obj.Map.Mouse,2},2), val = []; return, end
            val = obj.Data{obj.Map.Mouse,2}(:,3:end);
            if 3==obj.LastAcquisition, obj.LastSamplePosition = obj.nSampleFromMarker(obj.Map.Mouse); end
        end
        function val = get.Voice(obj)
            if 0==obj.Map.Voice || isempty(obj.Data{obj.Map.Voice,1}), val = []; return, end
            val = obj.Data{obj.Map.Voice,1};
            if 3==obj.LastAcquisition, obj.LastSamplePosition = obj.nSampleFromMarker(obj.Map.Voice); end
        end

        function start(~), mdqmex(41,0); end
        function stop(~), mdqmex(41,1); end
        function val = isrunning(~), val = mdqmex(41,2); end
        function flushdata(~), mdqmex(41,3); end
        function flushmarker(~), mdqmex(41,4); end
        function frontmarker(~), mdqmex(41,5); end
        function backmarker(~), mdqmex(41,6); end
        function val = MinSamplesAcquired(~), val = mdqmex(41,7); end
        function val = MinSamplesAvailable(~), val = mdqmex(41,8); end
        function getsample(obj)
            if isempty(obj.DAQ), return, end
            obj.Data = cell(length(obj.DAQ),2);
            for m=obj.Startable
                switch obj.Type(m)  % 1:AI, 2:AO, 3:DIO, 4:pointer, 5:webcam, 6:voice, 7:high_freq
                    case 1, obj.Data{m,1} = getsample(obj.DAQ{m});
                    case 3, obj.Data{m,1} = getvalue(obj.DAQ{m});
                    case 4, [obj.Data{m,1},obj.Data{m,2}] = getsample(obj.DAQ{m});
                    case 6, try obj.Data{m,1} = getsample(obj.DAQ{m}); catch, end
                    case 7, obj.Data{m,1} = getsample(obj.DAQ{m});
                end
            end
            obj.LastAcquisition = 1;
        end
        function peekfront(obj)
            obj.Data = cell(length(obj.DAQ),2);
            obj.nSampleFromMarker = NaN(length(obj.DAQ),1);
            for m=obj.Startable
                switch obj.Type(m)
                    case 1, [obj.Data{m,1},obj.nSampleFromMarker(m)] = peekfront(obj.DAQ{m});
                    case 3, if 0<obj.DAQ{m}.SamplesAvailable, [obj.Data{m,1},obj.nSampleFromMarker(m)] = peekfront(obj.DAQ{m}); end
                    case 4, [obj.Data{m,1},obj.Data{m,2},~,obj.nSampleFromMarker(m)] = peekfront(obj.DAQ{m});
                end
            end
            obj.LastAcquisition = 3;
        end
        function getback(obj)
            obj.Data = cell(length(obj.DAQ),2);
            for m=obj.Startable
                switch obj.Type(m)
                    case {1,6,7}, obj.Data{m,1} = getback(obj.DAQ{m});
                    case 3, if 0<obj.DAQ{m}.SamplesAvailable, obj.Data{m,1} = getback(obj.DAQ{m}); end
                    case 4, [obj.Data{m,1},obj.Data{m,2}] = getback(obj.DAQ{m});
                end
            end
            obj.LastAcquisition = 2;
        end
        function getdata(obj,varargin)
            obj.Data = cell(length(obj.DAQ),2);
            for m=obj.Startable
                switch obj.Type(m)
                    case {1,6,7}, obj.Data{m,1} = getdata(obj.DAQ{m},varargin{:});
                    case 3, if 0<obj.DAQ{m}.SamplesAvailable, obj.Data{m,1} = getdata(obj.DAQ{m},varargin{:}); end
                    case 4, [obj.Data{m,1},obj.Data{m,2}] = getdata(obj.DAQ{m},varargin{:});
                end
            end
            obj.LastAcquisition = 2;
        end
        function peekdata(obj,nsample)
            obj.Data = cell(length(obj.DAQ),2);
            for m=obj.Startable
                switch obj.Type(m)
                    case 1, obj.Data{m,1} = peekdata(obj.DAQ{m},nsample);
                    case 3, if 0<obj.DAQ{m}.SamplesAcquired, obj.Data{m,1} = peekdata(obj.DAQ{m},nsample); end
                    case 4, [obj.Data{m,1},obj.Data{m,2}] = peekdata(obj.DAQ{m},nsample);
                end
            end
            obj.LastAcquisition = 2;
        end
    end

    methods (Hidden)
        function n = nIO(obj), n = length(obj.IO); end
        function init_timer(~,start,offset), mdqmex(42,101,start,offset); end
        function strobe_function(~,code), mdqmex(42,1,code); end
        function dummy_eventmarker(~,code), mdqmex(42,1,code); end
        function reward_count = dummy_goodmonkey(~,Duration,varargin)
            reward_count = 0;
            persistent PauseTime TriggerVal %#ok<PUSE>
            JuiceLine = 1; %#ok<*NASGU>
            NonBlocking = 0;
            NumReward = 1;

            if ischar(Duration), varargin = [Duration varargin]; Duration = 0; end
            if Duration < 0
                MLConfig = varargin{2};
                r = MLConfig.RewardFuncArgs;
                PauseTime = r.PauseTime;
                TriggerVal = r.TriggerVal;
                return
            end

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
                    end
                end
            end
            switch length(code)
                case 0, code = NaN(1,NumReward);
                case 1, code = repmat(code,1,NumReward);
                otherwise, code(end+1:NumReward) = code(end);
            end
            if 0==Duration, return, end

            switch NonBlocking
                case 0
                    for m = 1:NumReward
                        mdqmex(43,2,Duration,code(m));
                        mdqmex(43,3);
                        if m < NumReward, mdqmex(42,103,PauseTime); end
                    end
                case {1,2}
                    mdqmex(43,1,NumReward,Duration,code,PauseTime,NonBlocking);
                otherwise
                    error('Unknown NonBlocking Mode!!!');
            end
            reward_count = NumReward;
        end
        function simulated_input(obj,action,varargin)
            switch action
                case -1 % reset
                    obj.SimulatedEye2 = zeros(1,2);
                    obj.SimulatedJoystick = zeros(1,2);
                    obj.SimulatedJoystick2 = zeros(1,2);
                case 0  % update buttons
                    obj.SimulatedButton = mglgetkeystate([49:57 48]); % key 1-9 & 0, see https://msdn.microsoft.com/en-us/library/windows/desktop/dd375731(v=vs.85).aspx
                case 1  % displacement type
                    obj.SimulatedJoystick(varargin{1}) = obj.SimulatedJoystick(varargin{1}) + varargin{2};
                case 2  % displacement type
                    obj.SimulatedJoystick2(varargin{1}) = obj.SimulatedJoystick2(varargin{1}) + varargin{2};
                case 3  % displacement type
                    obj.SimulatedEye2(varargin{1}) = obj.SimulatedEye2(varargin{1}) + varargin{2};
            end
        end
        function simulated_output(obj)
            ao = analogoutput_playback;
            for m=1:obj.nStimulation
                addchannel(ao,m-1,sprintf('Stimulation%d',m));
            end
            for m=1:obj.nStimulation
                if isempty(obj.Stimulation{m}), obj.Stimulation{m} = ao; end
            end

            dio = digitalio_playback;
            for m=1:obj.nTTL
                addline(dio,m-1,0,'Out',sprintf('TTL%d',m));
            end
            for m=1:obj.nTTL
                if isempty(obj.TTL{m}), obj.TTL{m} = dio; end
            end
        end
        function add_mouse(obj)
            if ~obj.mouse_present()
                obj.DAQ{end+1,1} = pointingdevice; obj.Type(end+1,1) = 4;
                register(obj.DAQ{end}); m = length(obj.DAQ); obj.Startable(end+1) = m; obj.Map.Mouse = m;
            end
        end

        function start_cam(obj)
            obj.WebcamTimer = zeros(1,obj.nWebcam,'uint64');
            for m=1:obj.nWebcam
                if ~isempty(obj.Webcam{m})
                    max_frame = 20;
                    latency = NaN(max_frame,1);
                    obj.WebcamTimer(m) = tic;
                    start(obj.Webcam{m});
                    trigger(obj.Webcam{m});
                    count = obj.Webcam{m}.SamplesAvailable;
                    while count < max_frame
                        nsample = obj.Webcam{m}.SamplesAvailable;
                        if count < nsample
                            latency(nsample) = toc(obj.WebcamTimer(m));
                            count = nsample;
                        end
                    end
                    stop(obj.Webcam{m});  % stop logging only
                    video = getdata(obj.Webcam{m});
                    latency = latency(1:max_frame) - video.Time(1:max_frame);
                    latency = latency(11:end);
                    obj.WebcamOffset(m) = mean(latency(~isnan(latency)));
                end
            end
        end
        function stop_cam(obj)
            for m=1:obj.nWebcam
                if ~isempty(obj.Webcam{m})
                    if islogging(obj.Webcam{m}), stop(obj.Webcam{m}); end
                    stop(obj.Webcam{m});
                end
            end
        end
        function calculate_cam_offset(obj)
            for m=1:obj.nWebcam
                if ~isempty(obj.Webcam{m}) && isrunning(obj.Webcam{m})
                    obj.WebcamOffset(m) = obj.WebcamOffset(m) - toc(obj.WebcamTimer(m));
                end
            end
        end
        function tf = pause_cam(obj)
            tf = false; for m=1:obj.nWebcam, if ~isempty(obj.Webcam{m}) && islogging(obj.Webcam{m}), tf = true; stop(obj.Webcam{m}); end, end
        end
        function resume_cam(obj)
            for m=1:obj.nWebcam, if ~isempty(obj.Webcam{m}), trigger(obj.Webcam{m}); end, end
        end
    end

    methods (Access = protected)
        function init(obj)
            mdqmex(40,2,0); mdqmex(40,2,1); mdqmex(40,2,2);  % unregister all
            for m=1:length(obj.DAQ), try delete(obj.DAQ{m}); catch, end, end
            mdqmex(20,4);

            obj.DAQ = [];
            obj.Type = [];
            obj.Reward = [];
            obj.BehavioralCodes = [];
            obj.StrobeBit = [];
            obj.Stimulation = cell(1,obj.nStimulation);
            obj.TTL = cell(1,obj.nTTL);
            obj.Webcam = cell(1,obj.nWebcam);
            obj.SimulatedEye2 = zeros(1,2);
            obj.SimulatedJoystick = zeros(1,2);
            obj.SimulatedJoystick2 = zeros(1,2);
            obj.SimulatedButton = false(1,obj.nButton(1));
            obj.Map = struct('Eye',zeros(2,2),'Eye2',zeros(2,2),'Joystick',zeros(2,2),'Joystick2',zeros(2,2),'PhotoDiode',zeros(1,2),'Button',zeros(obj.nButton(1),4), ...
                'General',zeros(obj.nGeneral,2),'Touch',0,'Mouse',0,'USBJoystick',[0 0],'EyeTracker',0,'Voice',0,'HighFrequency',zeros(obj.nHighFrequency,2));
            obj.Startable = [];
            obj.LastAcquisition = 0;
        end
        function init_eventmarker(obj)
            mdqmex(40,2,1);  % unregister behavioralcodes
            obj.eventmarker = @obj.dummy_eventmarker;
            if isempty(obj.BehavioralCodes), return, end
            if (1==obj.StrobeTrigger||2==obj.StrobeTrigger) && isempty(obj.StrobeBit), return, end
            obj.BehavioralCodes.register('BehavioralCodes');
            if ~isempty(obj.StrobeBit), obj.StrobeBit.register('StrobeBit'); end
            obj.eventmarker = @obj.strobe_function;
        end
        function init_goodmonkey(obj,MLConfig)
            if isempty(obj.Reward)
                obj.goodmonkey = @obj.dummy_goodmonkey;
                mdqmex(40,2,2);  % unregister reward
            else
                obj.goodmonkey = get_function_handle(MLConfig.MLPath.RewardFunction);
                obj.Reward.register('Reward');
            end
            obj.goodmonkey(-1,obj,MLConfig);
        end
        function [subsystem,ia,ic] = unique_subsystem(~,IO)
            if isempty(IO), subsystem = []; ia = []; ic = []; return, end
            um = zeros(length(IO),3);
            [~,~,um(:,1)] = unique({IO.Adaptor});
            [~,~,um(:,2)] = unique({IO.DevID});
            [~,~,um(:,3)] = unique({IO.Subsystem});
            [~,ia,ic] = unique(um,'rows');
            subsystem = IO(ia);
        end
    end
end
