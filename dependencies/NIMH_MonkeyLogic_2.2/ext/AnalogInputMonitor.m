classdef AnalogInputMonitor < mladapter
    properties
        Channel = 1                 % General #
        Position = [580 20 200 50]  % [left top width height]
        YLim = [-10 10]             % [ymin ymax]
        Title = ''
        Color = [1 1 0]
        UpdateInterval = 1          % update intervals in frames
    end
    properties (SetAccess = protected)
        Graphic
    end
    properties (Access = protected)
        Replaying
        ScrPos
        PrevFrame
    end
    properties (Hidden)
        Modulus
    end
    
    methods
        function obj = AnalogInputMonitor(varargin)
            obj = obj@mladapter(varargin{:});
            obj.Replaying = 2==obj.Tracker.DataSource;
        end
        function delete(obj)
            if ~isempty(obj.Graphic), mgldestroygraphic(obj.Graphic); obj.Graphic = []; end
        end
        function set.Modulus(obj,val), obj.UpdateInterval = val; end %#ok<MCSUP>
        function val = get.Modulus(obj), val = obj.UpdateInterval; end
        
        function init(obj,p)
            init@mladapter(obj,p);
            if obj.Replaying, return, end
            if max(obj.Position)<=1
                rect = mglgetscreeninfo(2,'Rect');
                sz = rect(3:4) - rect(1:2);
                obj.ScrPos = obj.Position.*sz([1 2 1 2]);
            else
                obj.ScrPos = obj.Position;
            end
            if isempty(obj.Graphic)
                obj.Graphic(1) = mgladdline(obj.Color,obj.ScrPos(3),1,4);
                obj.Graphic(2) = mgladdbox(obj.Color/2,obj.ScrPos(3:4),4);
                obj.Graphic(3) = mgladdtext(sprintf('%g',obj.YLim(2)),4);
                obj.Graphic(4) = mgladdtext(sprintf('%g',obj.YLim(1)),4);
                obj.Graphic(5) = mgladdtext(obj.Title,4);
            end
            mglsetorigin(obj.Graphic(2),obj.ScrPos(1:2) + obj.ScrPos(3:4)/2);
            mglsetproperty(obj.Graphic(3),'color',obj.Color,'right','middle','origin',obj.ScrPos(1:2)+[-5 0]);
            mglsetproperty(obj.Graphic(4),'color',obj.Color,'right','middle','origin',obj.ScrPos(1:2)+[-5 obj.ScrPos(4)]);
            mglsetproperty(obj.Graphic(5),'color',obj.Color,'center','bottom','origin',obj.ScrPos(1:2)+[obj.ScrPos(3)/2 -3]);
            obj.PrevFrame = NaN;
        end
        function continue_ = analyze(obj,p)
            continue_ = analyze@mladapter(obj,p);
            obj.Success = obj.Adapter.Success;
        end
        function draw(obj,p)
            draw@mladapter(obj,p);
            if obj.Replaying, return, end

            CurrentFrame = p.scene_frame();
            if obj.PrevFrame==CurrentFrame, return, else, obj.PrevFrame = CurrentFrame; end  % draw only once in one frame
            if 0~=mod(CurrentFrame,obj.UpdateInterval), return, end

            data = obj.Tracker.DAQ.General{obj.Channel};
            if isempty(data), return, end
            
            x = mglgetproperty(obj.Graphic(1),'size');
            y = (obj.YLim(2)-max(obj.YLim(1),min(obj.YLim(2),data(end)))) * obj.ScrPos(4) / (obj.YLim(2)-obj.YLim(1));
            mglsetproperty(obj.Graphic(1),'addpoint',obj.ScrPos(1:2) + [x y]);
            
            if obj.ScrPos(3) <= x+1, mglsetproperty(obj.Graphic(1),'clear'); end
        end
    end
end
