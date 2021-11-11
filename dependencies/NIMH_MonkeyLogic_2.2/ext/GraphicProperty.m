classdef GraphicProperty < mlaggregator
    properties
        Target = []  % TaskObject number or graphic adapter
        Property
        Value
        Step = 1     % every n frames
        StepUnit = 'frame'  % or 'msec'
    end
    properties (Access = protected)
        CountByFrame
        MaxValueIdx
        PrevValueIdx
        NextValueIdx
    end
    
    methods
        function obj = GraphicProperty(varargin)
            obj = obj@mlaggregator(varargin{:});
        end
        function set.Target(obj,val)  % Don't call setTarget(). It will create an infinite loop.
            if isobject(val), obj.Adapter{2} = val; obj.Target = 1; else, obj.Target = val; end
        end
        function setTarget(obj,val,idx)
            obj.Target = val;
            if isobject(val) && exist('idx','var'), obj.Target = idx;  end
        end
        function set.Property(obj,val)
            switch class(val)
                case 'cell', for m=1:numel(val), val{m} = namechk(obj,val{m}); end
                case 'char', val = {namechk(obj,val)};
                otherwise, error('Property must be cell or char.');
            end
            obj.Property = val;
        end
        function set.Value(obj,val)
            obj.MaxValueIdx = 0; %#ok<*MCSUP>
            if iscell(val)
                if ~any(1==size(val)), error('Value must be a 1-by-n cell array.'); end
                val = val(:)';
                for m=1:length(val), obj.MaxValueIdx = max(obj.MaxValueIdx,size(val{m},1)); end
            else
                obj.MaxValueIdx = size(val,1);
            end
            obj.Value = val;
        end
        
        function init(obj,p)
            init@mlaggregator(obj,p);
            obj.CountByFrame = strcmpi(obj.StepUnit,'frame');
            obj.PrevValueIdx = 0;
            obj.NextValueIdx = 0;
        end
        function continue_ = analyze(obj,p)
            analyze@mlaggregator(obj,p);

            if obj.CountByFrame, t = p.scene_frame(); else, t = p.scene_time(); end
            obj.NextValueIdx = floor(t/obj.Step) + 1;
            obj.Success = obj.MaxValueIdx < obj.NextValueIdx;
            continue_ = ~obj.Success;

            if ~obj.Success && obj.PrevValueIdx~=obj.NextValueIdx
                obj.PrevValueIdx = obj.NextValueIdx;
                for m=1:numel(obj.Property)
                    if iscell(obj.Value)
                        if size(obj.Value{m},1) < obj.NextValueIdx, continue, end
                        val = obj.Value{m}(obj.NextValueIdx,:);
                    else
                        if 1<numel(obj.Property)
                            val = obj.Value(obj.NextValueIdx,m);
                        else
                            val = obj.Value(obj.NextValueIdx,:);
                        end
                    end
                    if 1<length(obj.Adapter)
                        obj.Adapter{2}.(obj.Property{m})(obj.Target,:) = val;
                    else
                        obj.Tracker.TaskObject.(obj.Property{m})(obj.Target,:) = val;
                    end
                end
            end
        end
    end
    
    methods (Access = protected)
        function val = namechk(~,val)
            switch lower(val)
                case 'edgecolor', val = 'EdgeColor';
                case 'facecolor', val = 'FaceColor';
                case 'size', val = 'Size';
                case 'position', val = 'Position';
                case 'scale', val = 'Scale';
                case 'angle', val = 'Angle';
                case 'zorder', val = 'Zorder';
                otherwise, error('%s is not a property of graphic objects',val);
            end
        end
    end
end
