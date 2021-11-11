classdef OnsetDetector < mladapter
    properties (SetAccess = protected)
        AcquiredTime
        RT
    end
    properties (Access = protected)
        LastSuccess
        bTracker
        bTime
    end
    properties (SetAccess = protected, Hidden)
        Time
    end
    
    methods
        function obj = OnsetDetector(varargin)
            obj = obj@mladapter(varargin{:});
            obj.bTracker = isa(obj.Adapter,'mltracker');
            obj.bTime = isprop(obj.Adapter,'Time');
        end
        function val = get.Time(obj), val = obj.AcquiredTime; end
        function init(obj,p)
            init@mladapter(obj,p);
            obj.AcquiredTime = NaN;
            obj.LastSuccess = [];
        end
        function fini(obj,p)
            fini@mladapter(obj,p);
            obj.RT = obj.AcquiredTime - p.FirstFlipTime; if obj.RT<0, obj.RT = 0; end
        end
        function continue_ = analyze(obj,p)
            continue_ = analyze@mladapter(obj,p);
            if isempty(obj.LastSuccess), obj.LastSuccess = obj.Adapter.Success & ~obj.bTracker; end
            if ~obj.Success && ~obj.LastSuccess && obj.Adapter.Success
                if obj.bTime, obj.AcquiredTime = obj.Adapter.Time(1); else, obj.AcquiredTime = p.scene_time(); end
                obj.Success = true;
            end
            obj.LastSuccess = obj.Adapter.Success;
        end
    end
end
