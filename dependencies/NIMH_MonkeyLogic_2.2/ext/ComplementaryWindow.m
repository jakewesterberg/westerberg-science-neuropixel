classdef ComplementaryWindow < mlaggregator
    properties
        Target
        Threshold
    end
    properties (Access = protected)
        ScreenPosition
        ThresholdInPixels
    end
    
    methods
        function obj = ComplementaryWindow(varargin)
            obj = obj@mlaggregator(varargin{:});
            if ~strcmpi(obj.Tracker.Signal,'Touch'), error('ComplementaryWindow requires TouchTracker (touch_)!'); end
        end
        
        function set.Target(obj,val)
            if isempty(val), return, else, obj.Adapter = obj.Adapter(1); end  % Target of SingleTarget is empty when importing
            switch class(val)
                case 'SingleTarget', obj.Adapter{2} = val;  % the object should be used for the moving window
                case 'MultiTarget'
                    [m,n] = size(val.Target);
                    if 1==m || 2~=n
                        obj.Target = obj.Tracker.TaskObject.Position(val.Target,:);  % TaskObject#
                    else
                        obj.Target = val.Target;  % n-by-2 matrix
                    end
                    obj.ScreenPosition = obj.Tracker.CalFun.deg2pix(obj.Target);
                    obj.Threshold = val.Threshold;
                otherwise  % MultiTarget will come to this line when importing
                    if isscalar(val), obj.Target = obj.Tracker.TaskObject.Position(val,:); else, obj.Target = val; end
                    obj.ScreenPosition = obj.Tracker.CalFun.deg2pix(obj.Target);
            end
        end
        function set.Threshold(obj,val)
            obj.Threshold = val;
            threshold_in_pixels = val * obj.Tracker.Screen.PixelsPerDegree;
            if isscalar(threshold_in_pixels)
                obj.ThresholdInPixels = threshold_in_pixels * threshold_in_pixels; %#ok<*MCSUP>
            else
                obj.ThresholdInPixels = 0.5*threshold_in_pixels;
            end
        end
        function setTarget(obj,val), obj.Target = val; end
        
        function continue_ = analyze(obj,p)
            analyze@mlaggregator(obj,p);

            if 1<length(obj.Adapter)
                obj.Success = obj.Tracker.Success && ~obj.Adapter{2}.Success;
            else
                if isempty(obj.Tracker.XYData), continue_ = true; return, end
                data = reshape(obj.Tracker.XYData(end,:)',2,[])';

                obj.Success = true;
                for m=1:size(obj.ScreenPosition,1)
                    if isscalar(obj.ThresholdInPixels)
                        out = obj.ThresholdInPixels < sum((data-repmat(obj.ScreenPosition(m,:),size(data,1),1)).^2,2);
                    else
                        rc = [obj.ScreenPosition(m,:)-obj.ThresholdInPixels obj.ScreenPosition(m,:)+obj.ThresholdInPixels];
                        out = rc(1)>data(:,1) | data(:,1)>rc(3) | rc(2)>data(:,2) | data(:,2)>rc(4);
                    end
                    obj.Success = obj.Success & any(out);
                end
            end
            continue_ = ~obj.Success;
        end
    end
end
