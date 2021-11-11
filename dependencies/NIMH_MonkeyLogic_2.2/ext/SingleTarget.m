classdef SingleTarget < mladapter
    properties
        Target
        Threshold
        Color
    end
    properties (SetAccess = protected)
        Running
        Position
        In
        Time
        TouchID
    end
    properties (Access = protected)
        LastData
        LastCrossingTime
        FixWindowID
        ThresholdInPixels
    end
    
    methods
        function obj = SingleTarget(varargin)
            obj = obj@mladapter(varargin{:});
            obj.Threshold = 3;
            obj.Color = [0 1 0];
        end
        function delete(obj)
            destroy_fixwindow(obj);
        end
        
        function set.Target(obj,target)
            if isscalar(target)
                modality = obj.Tracker.TaskObject.Modality(target);
                if 1~=modality && 2~=modality, error('Target #%d is not visual',target); end
                obj.Target = target;
                obj.Position = obj.Tracker.TaskObject.Position(obj.Target,:); %#ok<*MCSUP>
            elseif 2==numel(target)
                obj.Target = target(:)';
                obj.Position = obj.Target;
            elseif ~isempty(target)
                error('Target must be a scalar or a 2-element vector');
            end
            create_fixwindow(obj);
        end
        function set.Threshold(obj,threshold)
            if 0==numel(threshold) || 2<numel(threshold), error('Threshold must be a scalar or a 1-by-2 vector'); end
            threshold = threshold(:)';
            if ~isempty(obj.Threshold) && all(size(threshold)==size(obj.Threshold)) && all(threshold==obj.Threshold), return, end
            obj.Threshold = threshold;
            create_fixwindow(obj);
        end
        function set.Color(obj,color)
            if 3~=numel(color), error('Color must be a 1-by-3 vector'); end
            color = color(:)';
            if ~isempty(obj.Color) && all(color==obj.Color), return, end
            obj.Color = color;
            create_fixwindow(obj);
        end
        
        function init(obj,p)
            init@mladapter(obj,p);
            obj.Running = true;
            obj.Time = [];
            obj.TouchID = [];  % for touch
            obj.LastData = [];
            if ~isempty(obj.FixWindowID), mglactivategraphic(obj.FixWindowID,true); end
        end
        function fini(obj,p)
            fini@mladapter(obj,p);
            if ~isempty(obj.FixWindowID), mglactivategraphic(obj.FixWindowID,false); end
        end
        function continue_ = analyze(obj,p)
            analyze@mladapter(obj,p);
            if ~obj.Running, continue_ = false; return, end
            
            data = obj.Tracker.XYData;
            [a,b] = size(data); b = b/2;
            if 0==a, continue_ = true; return, end  % early exit, if there is no data
            
            if isempty(obj.Target), obj.Position = obj.Adapter.Position; end
            ScrPosition = obj.Tracker.CalFun.deg2pix(obj.Position);
            mglsetorigin(obj.FixWindowID,ScrPosition);
            
            % determine 'in' or 'out'
            idx = 1;
            obj.In = false(a,b);
            for m=1:b
                xy = data(:,idx:idx+1);
                if isscalar(obj.ThresholdInPixels)
                    obj.In(:,m) = sum((xy-repmat(ScrPosition,a,1)).^2,2) < obj.ThresholdInPixels;
                else
                    rc = [ScrPosition ScrPosition] + obj.ThresholdInPixels;
                    obj.In(:,m) = rc(1)<xy(:,1) & xy(:,1)<rc(3) & rc(2)<xy(:,2) & xy(:,2)<rc(4);
                end
                idx = idx + 2;
            end
            
            % check crossing
            if isempty(obj.LastData)
                obj.LastData = obj.In(1,:);
                obj.LastCrossingTime = repmat(obj.Tracker.LastSamplePosition,1,b);
            end
            c = diff([obj.LastData; obj.In]);  % 0: no crossing, 1: cross in, -1: cross out
            obj.LastData = obj.In(end,:);  % keep the last 'in' state for next cycle

            % calculate crossing time
            switch obj.Tracker.Signal
                case 'Touch'
                    touched = any(obj.In,1);
                    for m=1:b
                        d = find(1==c(:,m),1);
                        if ~isempty(d)
                            obj.LastCrossingTime(m) = obj.Tracker.LastSamplePosition + d;
                        end
                    end
                    on = find(touched,1);
                    if ~isempty(on)
                        obj.Success = true;
                        obj.Time = obj.LastCrossingTime(on);
                        obj.TouchID = on;
                    else
                        obj.Success = false;
                        if ~isempty(obj.TouchID), obj.Time = obj.Tracker.LastSamplePosition; obj.TouchID = []; end
                    end
                otherwise
                    stable = false(1,b);
                    for m=1:b
                        d = find(0~=c(:,m),1,'last');
                        if isempty(d)
                            stable(m) = true;
                        else
                            obj.LastCrossingTime(m) = obj.Tracker.LastSamplePosition + d;  % update the last crossing time
                        end
                    end
                    on = find(stable & obj.LastData,1);  % stable 'in'
                    if ~isempty(on)  % any stable 'in' indicates success
                        obj.Success = true;
                        obj.Time = obj.LastCrossingTime(on);
                    elseif all(stable)  % this being true indicates all stable 'out', since there is no 'on', and hence no success
                        obj.Success = false;
                    end
            end

            continue_ = ~obj.Success;
        end
        function stop(obj)
            if ~isempty(obj.FixWindowID), mglactivategraphic(obj.FixWindowID,false); end
            obj.Running = false;
        end
    end
    
    methods (Access = protected)
        function create_fixwindow(obj)
            if isempty(obj.Threshold) || isempty(obj.Color), return, end
            destroy_fixwindow(obj);
            
            threshold_in_pixels = obj.Threshold * obj.Tracker.Screen.PixelsPerDegree;
            if isscalar(obj.Threshold)
                if threshold_in_pixels < min(obj.Tracker.Screen.SubjectScreenHalfSize)
                    obj.FixWindowID = mgladdcircle(obj.Color,threshold_in_pixels*2,10);
                end
                obj.ThresholdInPixels = threshold_in_pixels^2;
            else
                if all(threshold_in_pixels < obj.Tracker.Screen.SubjectScreenFullSize)
                    obj.FixWindowID = mgladdbox(obj.Color,threshold_in_pixels,10);
                end
                obj.ThresholdInPixels = 0.5*[-threshold_in_pixels threshold_in_pixels];  % [left bottom right top]
            end
            if ~isempty(obj.FixWindowID), mglactivategraphic(obj.FixWindowID,false); end
        end
        function destroy_fixwindow(obj)
            if ~isempty(obj.FixWindowID), mgldestroygraphic(obj.FixWindowID); obj.FixWindowID = []; end
        end
    end
end
