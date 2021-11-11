classdef NullTracker < mltracker
    properties (SetAccess = protected)
        XYData
        ClickData
        KeyInput
        LastSamplePosition
    end
    methods
        function obj = NullTracker(MLConfig,TaskObject,CalFun,DataSource)
            obj = obj@mltracker(MLConfig,TaskObject,CalFun,DataSource);
            obj.Signal = 'Null';
        end
    end
end
