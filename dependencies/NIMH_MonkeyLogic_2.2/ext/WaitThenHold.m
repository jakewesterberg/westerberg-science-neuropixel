classdef WaitThenHold < mladapter
    properties
        WaitTime = 0  % time to wait for fixation
        HoldTime = 0  % time to hold fixation
    end
    properties (SetAccess = protected)
        Running       % whether we are still tracking. true or false
        Waiting       % whether we are still waiting for fixation. true or false
        AcquiredTime  % trialtime when fixation was acquired
        RT
    end
    properties (Access = protected)
        EndTime
    end
    
    methods
        function obj = WaitThenHold(varargin)
            obj = obj@mladapter(varargin{:});
        end
        function init(obj,p)
            init@mladapter(obj,p);
            obj.Running = true;
            obj.Waiting = true;
            obj.AcquiredTime = NaN;
        end
        function fini(obj,p)
            fini@mladapter(obj,p);
            obj.RT = obj.AcquiredTime - p.FirstFlipTime;
            if obj.RT<0, obj.RT = 0; end  % RT can be negative if fixation was acquired already before the scene start
            if obj.Success && isa(obj.Adapter,'SingleTarget')  % for auto drift correction
                p.eyetargetrecord(obj.Tracker.Signal,[obj.Adapter.Position [obj.AcquiredTime 0]+obj.HoldTime*0.5]);
            end
        end
        function continue_ = analyze(obj,p)
            analyze@mladapter(obj,p);
            if ~obj.Running, continue_ = false; return, end  % If we are not tracking, return early.

            % The child adapter (obj.Adapter) of this adapter is SingleTarget
            % and its Success property is set to true when fixation is acquired.
            good = obj.Adapter.Success;  % whether fixation was acquired during the last frame. true or false
            elapsed = p.scene_time();    % time elapsed from the scene start

            % If we were waiting for fixation and it is not acquired yet,
            % check if the wait time has passed. If so, stop tracking and end the scene.
            if obj.Waiting && ~good
                obj.Running = elapsed < obj.WaitTime;
                continue_ = obj.Running;
                return
            end
            
            % If we were waiting for fixation and it is acquired,
            % set Waiting to false and calculate when the hold time should end.
            if obj.Waiting && good
                if isprop(obj.Adapter,'Time'), obj.AcquiredTime = obj.Adapter.Time; end
                obj.Waiting = false;
                obj.EndTime = elapsed + obj.HoldTime;
            end
            
            % If the subject fixated but not anymore (i.e., broke the fixation),
            % then stop tracking and end the scene.
            if ~obj.Waiting && ~good
                obj.Running = false;
                continue_ = obj.Running;
                return
            end
            
            % If the subject fixated and is maintaining it,
            % check if the hold time has passed. If so, set Success to true and end the scene.
            if ~obj.Waiting && good
                if obj.EndTime <= elapsed
                    obj.Success = true;
                    obj.Running = false;
                    continue_ = obj.Running;
                    return
                end
            end
            
            % If none of the above things happened, keep tracking to the next frame.
            continue_ = true;
        end
        function stop(obj)
            obj.Running = false;
        end
    end
end
