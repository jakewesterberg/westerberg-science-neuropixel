classdef ImageStabilizer < mlaggregator
    properties
        Target = []
        FixPoint = [0 0]
        Axis = 3  % 0: none, 1: X axis, 2: Y axis, 3: X & Y
    end

    methods
        function obj = ImageStabilizer(varargin)
            obj = obj@mlaggregator(varargin{:});
        end
        function set.Target(obj,val)  % Don't call setTarget(). It will create an infinite loop.
            if isobject(val), obj.Adapter{2} = val; obj.Target = 1:length(val.GraphicID); else, obj.Target = val; end
        end
        function setTarget(obj,val,idx)
            obj.Target = val;
            if isobject(val) && exist('idx','var'), obj.Target = idx;  end
        end
        
        function continue_ = analyze(obj,p)
            continue_ = obj.Adapter{1}.analyze(p);
            for m=2:length(obj.Adapter), obj.Adapter{m}.analyze(p); end
            obj.Success = obj.Adapter{1}.Success;

            data = obj.Tracker.XYData;
            if isempty(data), return, end
            
            displacement = obj.Tracker.CalFun.pix2deg(median(data(:,1:2),1)) - obj.FixPoint;
            switch obj.Axis
                case 0, displacement(1:2) = 0;
                case 1, displacement(2) = 0;
                case 2, displacement(1) = 0;
            end
            
            if 1<length(obj.Adapter)
                img_pos = obj.Adapter{2}.Position(obj.Target,:);
            else
                if isempty(obj.Target)
                    img_pos = obj.Adapter{1}.Position;
                else
                    img_pos = obj.Tracker.TaskObject.Position(obj.Target,:);
                end
            end
            img_pos = img_pos + repmat(displacement,size(img_pos,1),1);
            if 1<length(obj.Adapter)
                obj.Adapter{2}.Position(obj.Target,:) = img_pos;
            else
                if isempty(obj.Target)
                    obj.Adapter{1}.Position = img_pos;
                else
                    obj.Tracker.TaskObject.Position(obj.Target,:) = img_pos;
                end
            end
        end
    end
end
