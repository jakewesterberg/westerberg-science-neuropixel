classdef BackgroundColorChanger < mladapter
    properties
        DurationUnit = 'frame'  % or 'msec'
        List
    end
    properties (SetAccess = protected)
        Time
    end
    properties (Access = protected)
        InitColor
        ColorSchedule
        ColorIndex
        PrevColorIndex
        bColorChanged
        PrevFrame
    end
    
    methods
        function obj = BackgroundColorChanger(varargin)
            obj = obj@mladapter(varargin{:});
        end
        function set.List(obj,val)
            sz = size(val);
            if ~isnumeric(val) || sz(2)<4, error('List must be an n-by-4 or n-by-5 numeric matrix.'); end
            obj.List = NaN(sz(1),5);
            obj.List(:,1:sz(2)) = val;
        end
        
        function init(obj,p)
            init@mladapter(obj,p);
            obj.Time = NaN(size(obj.List,1),1);
            obj.InitColor = obj.Tracker.Screen.BackgroundColor;
            if strcmpi(obj.DurationUnit,'frame')
                obj.ColorSchedule = cumsum(obj.List(:,4));
            else
                obj.ColorSchedule = cumsum(round(obj.List(:,4) / obj.Tracker.Screen.FrameLength));
            end
            obj.ColorIndex = NaN;
            obj.PrevColorIndex = NaN;
            obj.bColorChanged = false;
            obj.PrevFrame = NaN;
        end
        function continue_ = analyze(obj,p)
            analyze@mladapter(obj,p);
            CurrentFrame = p.scene_frame();
            if obj.PrevFrame==CurrentFrame, continue_ = ~obj.Success; return, else, obj.PrevFrame = CurrentFrame; end  % draw only once in one frame
            
            if obj.bColorChanged, obj.Time(obj.ColorIndex) = p.LastFlipTime; end
            obj.ColorIndex = find(CurrentFrame < obj.ColorSchedule,1);
            obj.Success = isempty(obj.ColorIndex);
            continue_ = ~obj.Success;

            obj.bColorChanged = continue_ && obj.PrevColorIndex~=obj.ColorIndex;
            if obj.bColorChanged
                obj.PrevColorIndex = obj.ColorIndex;
                obj.Tracker.Screen.BackgroundColor = obj.List(obj.ColorIndex,1:3);
                p.eventmarker(obj.List(obj.ColorIndex,5));
            elseif obj.Success
                obj.Tracker.Screen.BackgroundColor = obj.InitColor;
            end
        end
    end
end
