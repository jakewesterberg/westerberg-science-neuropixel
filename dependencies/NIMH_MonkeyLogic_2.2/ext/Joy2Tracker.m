classdef Joy2Tracker < mltracker
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
        function obj = Joy2Tracker(MLConfig,TaskObject,CalFun,DataSource)
            obj = obj@mltracker(MLConfig,TaskObject,CalFun,DataSource);
            if 0==DataSource && ~MLConfig.DAQ.joystick2_present, error('Joystick2 not assigned!!!'); end
            obj.Signal = 'Joystick2';
        end
        
        function tracker_init(obj,p)
            mglactivategraphic(obj.Screen.Joystick2Cursor,p.ShowJoy2Cursor);
        end
        function tracker_fini(obj,~)
            mglactivategraphic(obj.Screen.Joystick2Cursor,false);
        end
        function acquire(obj,p)
            switch obj.DataSource
                case 0, data = p.DAQ.Joystick2;          if ~isempty(data), obj.XYData = obj.CalFun.sig2pix(data,p.Joy2Offset); end, obj.LastSamplePosition = p.DAQ.LastSamplePosition;
                case 1, data = p.DAQ.SimulatedJoystick2; if ~isempty(data), obj.XYData = obj.CalFun.deg2pix(data); end, obj.LastSamplePosition = floor(p.trialtime()-1);
                case 2, data = p.DAQ.Joystick2;          if ~isempty(data), obj.XYData = obj.CalFun.deg2pix(data); end, obj.LastSamplePosition = p.DAQ.LastSamplePosition;
                otherwise, error('Unknown data source!!!');
            end
            
            obj.Success = ~isempty(obj.XYData);
            if obj.Success, mglsetorigin(obj.Screen.Joystick2Cursor,obj.XYData(end,:)); end
        end
    end
end
