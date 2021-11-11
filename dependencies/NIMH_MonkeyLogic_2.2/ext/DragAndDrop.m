classdef DragAndDrop < mlaggregator
    properties
        Destination        % [x y] in degrees
        Gravity = 5        % degrees per second
        GravityWindow = 3  % radius in degrees; [width height] for a rectangular window
        Color = [0 1 0]    % color of the gravity window
        Target = 1         % Target should be settable, for replay
    end
    properties (SetAccess = protected)
        DropTime
        DroppedDestination
    end
    properties (Access = protected)
        nDestination
        TargetID
        WindowID
        ScrInitPosition
        ScrDestination
        ScrDestinationOnDrop
        ScrGravity
        ScrGravityWindow
        Dropped
    end
    
    methods
        function obj = DragAndDrop(varargin)
            obj = obj@mlaggregator(varargin{:});
        end
        function set.Target(obj,val)  % Don't call setTarget() in this function. It will create an infinite loop.
            if isobject(val), obj.Adapter{2} = val; obj.Target = 1; else, obj.Target = val; end
        end
        function setTarget(obj,val,idx)
            obj.Target = val;
            if isobject(val) && exist('idx','var'), obj.Target = idx;  end
        end
        function reset(obj)
            if isempty(obj.TargetID), return, end
            mglsetorigin(obj.TargetID,obj.ScrInitPosition);
        end

        function init(obj,p)
            init@mlaggregator(obj,p);
            
            if 1<length(obj.Adapter), obj.TargetID = obj.Adapter{2}.GraphicID(obj.Target); else, obj.TargetID = obj.Tracker.TaskObject.ID(obj.Target); end
            obj.ScrInitPosition = mglgetproperty(obj.TargetID,'origin');
            obj.ScrDestination = round(obj.Tracker.CalFun.deg2pix(obj.Destination));
            obj.ScrDestinationOnDrop = obj.ScrInitPosition;
            obj.ScrGravity = obj.Gravity * p.Screen.PixelsPerDegree;  % pixels per second
            obj.ScrGravityWindow = obj.GravityWindow * p.Screen.PixelsPerDegree;

            obj.nDestination = size(obj.ScrDestination,1);
            obj.WindowID = NaN(1,obj.nDestination);
            if isscalar(obj.ScrGravityWindow)
                for m=1:obj.nDestination, obj.WindowID(m) = mgladdcircle(obj.Color,2*obj.ScrGravityWindow,10); end
                mglsetorigin(obj.WindowID,obj.ScrDestination);
                obj.ScrGravityWindow = obj.ScrGravityWindow^2;
            else
                for m=1:obj.nDestination, obj.WindowID(m) = mgladdbox(obj.Color,obj.ScrGravityWindow,10); end
                mglsetorigin(obj.WindowID,obj.ScrDestination);
                d = repmat(0.5*obj.ScrGravityWindow,obj.nDestination,1);
                obj.ScrGravityWindow = [obj.ScrDestination-d obj.ScrDestination+d];
            end
            
            obj.Dropped = false;
            obj.DropTime = 0;
            obj.DroppedDestination = 0;
            mglactivategraphic(obj.TargetID,true);
        end
        function fini(obj,p)
            fini@mlaggregator(obj,p);
            mglactivategraphic(obj.TargetID,false);
            mgldestroygraphic(obj.WindowID);
            deg = obj.Tracker.CalFun.pix2deg(mglgetproperty(obj.TargetID,'origin'));
            if 1<length(obj.Adapter), obj.Adapter{2}.Position(obj.Target,:) = deg; else, obj.Tracker.TaskObject.Position(obj.Target,:) = deg; end
        end
        function continue_ = analyze(obj,p)
            analyze@mlaggregator(obj,p);
            xy = obj.Tracker.XYData(end,1:2);
            if ~obj.Dropped && isnan(xy(1))
                obj.Dropped = true;
                obj.DropTime = obj.Tracker.LastSamplePosition + find(isnan(obj.Tracker.XYData(:,1)),1) - 1;
            end
            
            pos = mglgetproperty(obj.TargetID,'origin');
            if ~obj.Dropped
                mglsetorigin(obj.TargetID,xy);
                if isscalar(obj.ScrGravityWindow)
                    hover = find(sum((obj.ScrDestination-repmat(xy,obj.nDestination,1)).^2,2) < obj.ScrGravityWindow,1);
                else
                    rc = obj.ScrGravityWindow;
                    hover = find(rc(:,1)<xy(1) & xy(1)<rc(:,3) & rc(:,2)<xy(2) & xy(2)<rc(:,4),1);
                end
                if isempty(hover)
                    obj.ScrDestinationOnDrop = obj.ScrInitPosition;
                    obj.DroppedDestination = 0;
                else
                    obj.ScrDestinationOnDrop = obj.ScrDestination(hover,:);
                    obj.DroppedDestination = hover;
                end
            elseif any(pos~=obj.ScrDestinationOnDrop)
                d = obj.ScrDestinationOnDrop - pos;
                theta = atan2(d(2),d(1)) * 180 / pi;  % atan2d is introduced in R2012b
                elapsed = (p.trialtime() - obj.DropTime) / 1000;  % in seconds
                delta = obj.ScrGravity * elapsed;
                if sum(d.^2) < delta*delta
                    mglsetorigin(obj.TargetID,obj.ScrDestinationOnDrop);
                else
                    mglsetorigin(obj.TargetID,pos+[cosd(theta) sind(theta)]*delta);
                end
            end
            
            obj.Success = any(all(repmat(pos,obj.nDestination,1)==obj.ScrDestination,2));
            continue_ = ~obj.Dropped || ~all(pos==obj.ScrDestinationOnDrop);
        end
    end
end
