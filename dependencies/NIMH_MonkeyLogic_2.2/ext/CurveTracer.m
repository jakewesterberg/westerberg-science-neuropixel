classdef CurveTracer < mlaggregator
    properties
        Target = []         % TaskObject number or graphic adapter
        Trajectory          % [x y], n-by-2
        Step = 1            % every n frames
        DurationUnit = 'frame'  % or 'msec'
        List
    end
    properties (SetAccess = protected)
        Position
        Time
    end
    properties (Access = protected)
        PosSchedule
        PosIndex
        PrevPosIndex
        bPosChanged
        PrevFrame
    end
    
    methods
        function obj = CurveTracer(varargin)
            obj = obj@mlaggregator(varargin{:});
        end
        function set.Target(obj,val)  % Don't call setTarget(). It will create an infinite loop.
            if isobject(val), obj.Adapter{2} = val; obj.Target = 1; else, obj.Target = val; end
        end
        function setTarget(obj,val,idx)
            obj.Target = val;
            if isobject(val) && exist('idx','var'), obj.Target = idx;  end
        end

        function init(obj,p)
            init@mlaggregator(obj,p);
            if ~isempty(obj.List)
                sz = size(obj.List);
                obj.PosSchedule = NaN(sz(1),4);
                obj.PosSchedule(:,3) = 1;
                obj.PosSchedule(:,1:sz(2)) = obj.List;
            elseif ~isempty(obj.Trajectory)
                sz = size(obj.Trajectory);
                obj.PosSchedule = NaN(sz(1),4);
                obj.PosSchedule(:,1:2) = obj.Trajectory;
                obj.PosSchedule(:,3) = obj.Step;
            else
                error('Either List or Trajectory must not be empty.');
            end
            
            obj.Position = NaN(1,2);
            obj.Time = NaN(sz(1),1);
            if strcmpi(obj.DurationUnit,'frame')
                obj.PosSchedule(:,3) = cumsum(obj.PosSchedule(:,3));
            else
                obj.PosSchedule(:,3) = cumsum(round(obj.PosSchedule(:,3) / obj.Tracker.Screen.FrameLength));
            end
            obj.PosIndex = NaN;
            obj.PrevPosIndex = NaN;
            obj.bPosChanged = false;
            obj.PrevFrame = NaN;
        end
        function continue_ = analyze(obj,p)
            analyze@mlaggregator(obj,p);
            CurrentFrame = p.scene_frame();
            if obj.PrevFrame==CurrentFrame, continue_ = ~obj.Success; return, else, obj.PrevFrame = CurrentFrame; end  % draw only once in one frame
            
            if obj.bPosChanged, obj.Time(obj.PrevPosIndex) = p.LastFlipTime; end
            obj.PosIndex = find(CurrentFrame < obj.PosSchedule(:,3),1);
            obj.Success = isempty(obj.PosIndex);
            continue_ = ~obj.Success;

            obj.bPosChanged = continue_ && obj.PrevPosIndex~=obj.PosIndex;
            if obj.bPosChanged
                obj.PrevPosIndex = obj.PosIndex;
                obj.Position = obj.PosSchedule(obj.PosIndex,1:2);
                p.eventmarker(obj.PosSchedule(obj.PosIndex,4));
            end
            if ~isempty(obj.Target)
                if 1<length(obj.Adapter)
                    obj.Adapter{2}.Position(obj.Target,:) = obj.Position;
                else
                    obj.Tracker.TaskObject.Position(obj.Target,:) = obj.Position;
                end
            end
        end
    end
end
