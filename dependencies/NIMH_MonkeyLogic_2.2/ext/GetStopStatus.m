classdef GetStopStatus < mladapter
    methods
        function obj = GetStopStatus(varargin)
            obj = obj@mladapter(varargin{:});
        end
        function continue_ = analyze(obj,p)
            continue_ = analyze@mladapter(obj,p);
            obj.Success = ~continue_;
        end
    end
end
