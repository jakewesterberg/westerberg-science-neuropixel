classdef FrameCounter < mladapter
    properties
        NumFrame = 0
    end
    properties (Access = protected)
        EndFrame
    end
    properties (Hidden)
        Duration
    end
    methods
        function obj = FrameCounter(varargin)
            obj = obj@mladapter(varargin{:});
        end
        function set.Duration(obj,val)
            obj.Duration = val;
            obj.NumFrame = ceil(val/obj.Tracker.Screen.FrameLength);  %#ok<MCSUP>
        end
        function init(obj,p)
            init@mladapter(obj,p);
            obj.EndFrame = obj.NumFrame - 2;
        end
        function continue_ = analyze(obj,p)
            analyze@mladapter(obj,p);
            obj.Success = obj.EndFrame < p.scene_frame();
            continue_ = ~obj.Success;
        end
    end
end
