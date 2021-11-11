classdef Sequential < mlaggregator
    properties
        EventMarker
        ContinueOnFailure = false
    end
    properties (SetAccess = protected)
        CurrentChain
    end
    properties (Access = protected)
        Param
        Update
        UpdateFirstFlip
    end
    methods
        function obj = Sequential(varargin)
            obj = obj@mlaggregator(varargin{:});
        end
        
        function init(obj,p)
            obj.Success = false;
            obj.CurrentChain = 0;
            obj.Param = copy(p);
            obj.Update = true;
            obj.UpdateFirstFlip = false;
        end
        function fini(obj,p)
            obj.Adapter{obj.CurrentChain}.fini(obj.Param);
            p.eyetargetrecord('Eye',obj.Param.EyeTargetRecord(p.EyeTargetIndex+1:obj.Param.EyeTargetRecord,:));
            p.eyetargetrecord('Eye2',obj.Param.Eye2TargetRecord(p.Eye2TargetIndex+1:obj.Param.Eye2TargetRecord,:));
            for m=fieldnames(obj.Param.User)', p.User.(m{1}) = obj.Param.User.(m{1}); end
        end
        function continue_ = analyze(obj,p)
            if obj.UpdateFirstFlip, obj.Param.FirstFlipTime = p.LastFlipTime; obj.UpdateFirstFlip = false; end
            if obj.Update
                if 0<obj.CurrentChain, obj.Adapter{obj.CurrentChain}.fini(obj.Param); end
                obj.CurrentChain = obj.CurrentChain + 1;
                obj.Param.reset();
                obj.Adapter{obj.CurrentChain}.init(obj.Param);
                obj.Param.SceneStartTime = p.trialtime();
                obj.Param.SceneStartFrame = p.FrameNum;
                obj.Update = false;
                obj.UpdateFirstFlip = true;
                if obj.CurrentChain<=length(obj.EventMarker), p.eventmarker(obj.EventMarker(obj.CurrentChain)); end
            end
            obj.Param.FrameNum = p.FrameNum;
            obj.Param.LastFlipTime = p.LastFlipTime;

            continue_ = true;
            if ~obj.Adapter{obj.CurrentChain}.analyze(obj.Param)
                if length(obj.Adapter)==obj.CurrentChain
                    obj.Success = true;
                    continue_ = false;
                else
                    if obj.Adapter{obj.CurrentChain}.Success || obj.ContinueOnFailure
                        obj.Update = true;
                    else
                        continue_ = false;
                    end
                end
            end
        end
        function draw(obj,p)
            obj.Adapter{obj.CurrentChain}.draw(obj.Param);
            p.eventmarker(obj.Param.EventMarker); clearmarker(obj.Param);
        end
    end
end
