classdef TouchTracker < mltracker
    properties (SetAccess = protected)
        NumTouch
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
        function obj = TouchTracker(MLConfig,TaskObject,CalFun,DataSource)
            obj = obj@mltracker(MLConfig,TaskObject,CalFun,DataSource);
            if 0==DataSource && ~MLConfig.DAQ.touch_present, error('Enable Touch first!!!'); end
            obj.Signal = 'Touch';
            obj.NumTouch = MLConfig.Touchscreen.NumTouch;  % This has to be above the other properties for create_tracer
        end

        function tracker_fini(obj,~)
            mglactivategraphic(obj.Screen.TouchCursor,false);
        end
        function acquire(obj,p)
            switch obj.DataSource
                case 0
                    data = p.DAQ.Touch; if ~isempty(data), obj.XYData = obj.CalFun.subject2pix(data); end
                    obj.LastSamplePosition = p.DAQ.LastSamplePosition;
                case 1
                    [mouse,button] = getsample(p.Mouse);
                    if ~isempty(mouse)
                        obj.XYData = repmat(obj.CalFun.control2pix(mouse),1,2);
                        obj.XYData(~button(1),1:2) = NaN;
                        obj.XYData(~button(2),3:4) = NaN;
                    end
                    obj.LastSamplePosition = floor(p.trialtime()-1);
                case 2
                    data = p.DAQ.Touch; if ~isempty(data), obj.XYData = obj.CalFun.deg2pix(data); end
                    obj.LastSamplePosition = p.DAQ.LastSamplePosition;
                otherwise, error('Unknown data source!!!');
            end
            
            obj.Success = ~isempty(obj.XYData);
            if obj.Success
                xy = reshape(obj.XYData(end,:),2,[])';
                nxy = size(xy,1);
                status = ~isnan(xy(:,1));
                mglactivategraphic(obj.Screen.TouchCursor(1:nxy),status);
                mglsetorigin(obj.Screen.TouchCursor(1:nxy),xy);
                obj.Success = any(status);
            end
        end
    end
end
