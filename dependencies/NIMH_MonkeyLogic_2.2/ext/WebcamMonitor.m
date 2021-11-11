classdef WebcamMonitor < mladapter
    properties
        CamNumber = 1               % Webcam #
        Position = [0.6 0 0.4 0.4]  % [left top width height]
        UpdateInterval = 2          % update intervals in frames
    end
    properties (SetAccess = protected)
        Graphic
    end
    properties (Access = protected)
        Replaying
        ScrPos
    end

    methods
        function obj = WebcamMonitor(varargin)
            obj = obj@mladapter(varargin{:});
            obj.Replaying = 2==obj.Tracker.DataSource;
        end
        function delete(obj)
            if ~isempty(obj.Graphic), mgldestroygraphic(obj.Graphic); obj.Graphic = []; end
        end
        
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
            if isempty(obj.Graphic), obj.Graphic = mgladdbitmap([0 0],4); end
            mglsetproperty(obj.Graphic,'active',true,'origin',obj.ScrPos(1:2) + obj.ScrPos(3:4)/2);
        end
        function fini(obj,~)
            mglactivategraphic(obj.Graphic,false);
        end
        function continue_ = analyze(obj,p)
            continue_ = analyze@mladapter(obj,p);
            obj.Success = obj.Adapter.Success;
            if obj.Replaying, return, end
            if 0~=mod(p.scene_frame(),obj.UpdateInterval), return, end
            if isempty(obj.Tracker.DAQ.Webcam{obj.CamNumber}), return, end

            bitmap = getsample(obj.Tracker.DAQ.Webcam{obj.CamNumber});
            if isempty(bitmap.Frame), return, end

            sz = size(bitmap.Frame);
            if obj.ScrPos(3)/obj.ScrPos(4) < sz(2)/sz(1), scale = obj.ScrPos(3)/sz(2); else, scale = obj.ScrPos(4)/sz(1); end
            mglsetproperty(obj.Graphic,'bitmap',rgb16to24(bitmap),'scale',scale);
        end
    end
end
