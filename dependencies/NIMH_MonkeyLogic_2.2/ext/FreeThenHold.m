classdef FreeThenHold < mladapter
    properties
        MaxTime = 0;
        HoldTime = 0;
    end
    properties (SetAccess = protected)
        Running
        BreakCount
        AcquiredTime
        RT
    end
    properties (Access = protected)
        WasGood
        EndTime
    end
    
    methods
        function obj = FreeThenHold(varargin)
            obj = obj@mladapter(varargin{:});
        end
        function init(obj,p)
            init@mladapter(obj,p);
            obj.Running = true;
            obj.BreakCount = 0;
            obj.WasGood = false;
            obj.EndTime = 0;
			obj.AcquiredTime = NaN;
        end
        function fini(obj,p)
            fini@mladapter(obj,p);
            obj.RT = obj.AcquiredTime - p.FirstFlipTime; if obj.RT<0, obj.RT = 0; end
            if obj.Success && isa(obj.Adapter,'SingleTarget')
                p.eyetargetrecord(obj.Tracker.Signal,[obj.Adapter.Position [obj.AcquiredTime 0]+obj.HoldTime*0.5]);
            end
        end
        function continue_ = analyze(obj,p)
            analyze@mladapter(obj,p);
            if ~obj.Running, continue_ = false; return, end

            good = obj.Adapter.Success;
            elapsed = p.scene_time();

            if ~good && ~obj.WasGood
                obj.Running = elapsed < obj.MaxTime;
                continue_ = obj.Running;
                return
            end
            
            if ~good && obj.WasGood
                obj.BreakCount = obj.BreakCount + 1;
                obj.WasGood = false;
                obj.Running = elapsed < obj.MaxTime;
                continue_ = obj.Running;
                return
            end
            
            if good && ~obj.WasGood
                if isprop(obj.Adapter,'Time'), obj.AcquiredTime = obj.Adapter.Time; end
                obj.WasGood = true;
                obj.EndTime = elapsed + obj.HoldTime;
            end
            
            if good && obj.WasGood
                if obj.EndTime <= elapsed
                    obj.Success = true;
                    obj.Running = false;
                    continue_ = obj.Running;
                    return
                end
            end
            
            continue_ = true;
        end
    end
end
