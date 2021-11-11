classdef SingleButton < mladapter
    properties
        Button
        TouchMode = false;
    end
    properties (SetAccess = protected)
        In
        Time
    end
    properties (Access = protected)
        LastData
        LastStateChange
    end
    
    methods
        function obj = SingleButton(varargin)
            obj = obj@mladapter(varargin{:});
            obj.Button = obj.Tracker.ButtonsAvailable(1);
        end
        function set.Button(obj,button)
            if ~isscalar(button), error('Please assign a single button'); end
            if ~ismember(button,obj.Tracker.ButtonsAvailable), error('Button #%d doesn''t exist',button); end %#ok<*MCSUP>
            obj.Button = button;
        end
        function init(obj,p)
            init@mladapter(obj,p);
            if isempty(obj.Button), error('No button is assigned'); end
            obj.Time = [];
            obj.LastData = [];
        end
        function continue_ = analyze(obj,p)
            analyze@mladapter(obj,p);
            
            obj.In = obj.Tracker.ClickData{obj.Button};
            if isempty(obj.In), continue_ = true; return, end
            idx = length(obj.Tracker.LastSamplePosition);
            if obj.Button < idx, idx = obj.Button; end
            
            if isempty(obj.LastData)
                obj.LastData = obj.In(1);
                obj.LastStateChange = obj.Tracker.LastSamplePosition(idx);
            end
            c = diff([obj.LastData; obj.In]);
            obj.LastData = obj.In(end);
            
            if obj.TouchMode
                d = find(1==c,1);
                if ~isempty(d)
                    obj.LastStateChange = obj.Tracker.LastSamplePosition(idx) + d;
                end
                if any(obj.In)
                    obj.Success = true;
                    obj.Time = obj.LastStateChange;
                else
                    obj.Success = false;
                end
            else
                d = find(0~=c,1,'last');
                if isempty(d)
                    obj.Success = obj.LastData;
                    obj.Time = obj.LastStateChange;
                else
                    obj.LastStateChange = obj.Tracker.LastSamplePosition(idx) + d;
                end
            end
            continue_ = ~obj.Success;
        end
    end
end