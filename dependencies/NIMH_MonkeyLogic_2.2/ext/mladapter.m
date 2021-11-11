classdef mladapter < handle
    properties (SetAccess = protected)
        Success
    end
    properties (Access = protected)
        Adapter
        Tracker
    end
    properties (Hidden)
        AdapterID
    end
    methods
        function obj = mladapter(adapter)
            if isa(obj,'mltracker') || isa(obj,'mlaggregator'), return, end
            if ~exist('adapter','var') || ~isa(adapter,'mladapter'), error('The 1st argument must be mladapter'); end
            obj.Adapter = adapter;
            obj.Tracker = obj.tracker();
            obj.AdapterID = tic;
        end
        
        function init(obj,p)
            obj.Adapter.init(p);
            obj.Success = false;
        end
        function fini(obj,p)
            obj.Adapter.fini(p);
        end
        function continue_ = analyze(obj,p)
            continue_ = obj.Adapter.analyze(p);
        end
        function draw(obj,p)
            obj.Adapter.draw(p);
        end
        
        function o = get_adapter(obj,name)
            if isa(obj,name), o = obj; else, o = obj.Adapter.get_adapter(name); end
        end
        function o = tracker(obj)
            o = obj.Adapter.tracker();
        end
        function val = export(obj)
            val = [fieldnames(obj); 'AdapterID'];
            for m=1:size(val,1), val{m,2} = obj.(val{m,1}); end
        end
        function import(obj,val)
            if isempty(val), return, end
            fn = [fieldnames(obj); 'AdapterID'];
            for m=size(fn,1):-1:1
                idx = strcmp(fn(m),val(:,1));
                if ~any(idx), continue, end
                obj.(fn{m}) = val{idx,2};
            end
        end
        function info(obj,s)
            obj.Adapter.info(s);
            s.AdapterList{end+1} = class(obj);
            s.AdapterArgs{end+1} = obj.export();
        end
        function val = fieldnames(obj)
            val = properties(obj); l = length(val); s = false(l,1);
            for m=1:l, s(m) = strcmp(obj.findprop(val{m}).SetAccess,'public'); end
            val = val(s);
        end
    end
end
