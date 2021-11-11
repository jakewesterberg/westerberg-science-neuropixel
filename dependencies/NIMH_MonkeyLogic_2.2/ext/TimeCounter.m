classdef TimeCounter < mladapter
    properties
        Duration = 0
    end
    properties (Access = protected)
        EndTime
    end
    methods
        function obj = TimeCounter(varargin)
            obj = obj@mladapter(varargin{:});
        end
        function init(obj,p)
            init@mladapter(obj,p);
            obj.EndTime = obj.Duration - 2*obj.Tracker.Screen.FrameLength;
        end
        function continue_ = analyze(obj,p)
            analyze@mladapter(obj,p);
            obj.Success = obj.EndTime < p.trialtime() - p.FirstFlipTime;  % p.FirstFlipTime is NaN at Frame 0, which makes Success false.
            continue_ = ~obj.Success;
        end
    end
end
