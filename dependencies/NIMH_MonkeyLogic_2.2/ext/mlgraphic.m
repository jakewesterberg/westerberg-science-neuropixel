classdef mlgraphic < mlstimulus
    properties
        EdgeColor
        FaceColor
        Size
        Position
        Scale
        Angle
        Zorder
        List
    end
    methods (Abstract, Access = protected)
        create_graphic(obj)
    end
    
    methods
        function obj = mlgraphic(varargin)
            obj = obj@mlstimulus(varargin{:});
        end
        
        function set.EdgeColor(obj,val), row = numchk(obj,val,'EdgeColor'); mglsetproperty(obj.GraphicID(row),'edgecolor',val(row,:)); obj.EdgeColor = val; end
        function set.FaceColor(obj,val), row = numchk(obj,val,'FaceColor'); mglsetproperty(obj.GraphicID(row),'facecolor',val(row,:)); obj.FaceColor = val; end
        function set.Size(obj,val),      row = numchk(obj,val,'Size');      mglsetproperty(obj.GraphicID(row),'size',val(row,:)*obj.Tracker.Screen.PixelsPerDegree); obj.Size = val; end
        function set.Position(obj,val),  row = numchk(obj,val,'Position');  mglsetorigin(obj.GraphicID(row),obj.Tracker.CalFun.deg2pix(val(row,:))); obj.Position = val; end
        function set.Scale(obj,val),     row = numchk(obj,val,'Scale');     mglsetproperty(obj.GraphicID(row),'scale',val(row,:)); obj.Scale = val; end
        function set.Angle(obj,val),     row = numchk(obj,val,'Angle');     mglsetproperty(obj.GraphicID(row),'angle',val(row,:)); obj.Angle = val; end
        function set.Zorder(obj,val),    row = numchk(obj,val,'Zorder');    mglsetproperty(obj.GraphicID(row),'zorder',val(row,:)); obj.Zorder = val; end
        function set.List(obj,val), obj.List = val; create_graphic(obj); end
    end
end
