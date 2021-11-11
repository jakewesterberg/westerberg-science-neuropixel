classdef mltracker < mladapter
    properties (SetAccess = protected)
        Signal = ''
        Screen
        DAQ
        TaskObject
        CalFun
        DataSource
    end
    properties (SetAccess = protected,Hidden)
        SearchPath
    end
    
    methods
        function obj = mltracker(MLConfig,TaskObject,CalFun,DataSource)
            obj.Screen = MLConfig.Screen;
            obj.DAQ = MLConfig.DAQ;
            obj.TaskObject = TaskObject;
            obj.CalFun = CalFun;
            obj.DataSource = DataSource;
            obj.Success = true;
            obj.SearchPath = {MLConfig.MLPath.ExperimentDirectory,MLConfig.MLPath.BaseDirectory};
        end
        function newpath = validate_path(obj,filepath)
            if isempty(filepath), newpath = ''; return, end
            [newpath,filename] = mlsetpath(filepath,obj.SearchPath);
            if isempty(newpath), error('Cannot find %s. If the file is not in the ML search path, run mlsetpath and add the directory.',filename); end
        end
        
        function tracker_init(~,~), end
        function tracker_fini(~,~), end
        function acquire(~,~), end
        
        function init(~,~), end
        function fini(~,~), end
        function continue_ = analyze(~,~), continue_ = true; end
        function draw(~,~), end

        function o = get_adapter(obj,name)
            if isa(obj,name), o = obj; else, o = []; end
        end
        function o = tracker(obj)
            o = obj;
        end
        function info(obj,s)
            s.AdapterList{end+1} = class(obj);
            s.AdapterArgs{end+1} = obj.export();
        end
    end
end
