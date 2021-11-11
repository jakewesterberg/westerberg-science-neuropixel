classdef JoyTracker < mltracker
    properties (SetAccess = protected)
        XYData
        LastSamplePosition
    end
    properties (Hidden)
        TracerImage
        TracerShape
        TracerColor
        TracerSize
    end
    
    methods
        function obj = JoyTracker(MLConfig,TaskObject,CalFun,DataSource)
            obj = obj@mltracker(MLConfig,TaskObject,CalFun,DataSource);
            if 0==DataSource && ~MLConfig.DAQ.joystick_present, error('Joystick not assigned!!!'); end
            obj.Signal = 'Joystick';
        end
        
        function tracker_init(obj,p)
            mglactivategraphic(obj.Screen.JoystickCursor,p.ShowJoyCursor);
        end
        function tracker_fini(obj,~)
            mglactivategraphic(obj.Screen.JoystickCursor,false);
        end
        function acquire(obj,p)
            switch obj.DataSource
                case 0, data = p.DAQ.Joystick;          if ~isempty(data), obj.XYData = obj.CalFun.sig2pix(data,p.JoyOffset); end, obj.LastSamplePosition = p.DAQ.LastSamplePosition;
                case 1, data = p.DAQ.SimulatedJoystick; if ~isempty(data), obj.XYData = obj.CalFun.deg2pix(data); end, obj.LastSamplePosition = floor(p.trialtime()-1);
                case 2, data = p.DAQ.Joystick;          if ~isempty(data), obj.XYData = obj.CalFun.deg2pix(data); end, obj.LastSamplePosition = p.DAQ.LastSamplePosition;
                otherwise, error('Unknown data source!!!');
            end
            
            obj.Success = ~isempty(obj.XYData);
            if obj.Success, mglsetorigin(obj.Screen.JoystickCursor,obj.XYData(end,:)); end
        end
    end
end
