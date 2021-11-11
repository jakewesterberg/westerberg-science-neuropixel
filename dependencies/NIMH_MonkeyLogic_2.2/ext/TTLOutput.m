classdef TTLOutput < mlstimulus
    properties
        Port
    end
    
    methods
        function obj = TTLOutput(varargin)
            obj = obj@mlstimulus(varargin{:});
        end
        
        function set.Port(obj,val)
            if ~isvector(val), error('TTL Port must be a vector'); end
            non_ttl = ~ismember(val,obj.Tracker.DAQ.ttl_available);
            if any(non_ttl), error('TTL #%d is not assigned',val(find(non_ttl,1))); end
            obj.Port = val;
        end
        
        function init(obj,p)
            init@mladapter(obj,p);  % pass init@mlstimulus
            obj.Triggered = false;
            if ~obj.Trigger
                obj.Triggered = true;
                register([p.DAQ.TTL{obj.Port}],'TTL');
                mglactivategraphic(obj.Tracker.Screen.TTL(:,obj.Port),true);
            end
        end
        function fini(obj,p)
            fini@mladapter(obj,p);  % pass fini@mlstimulus
            mglactivategraphic(obj.Tracker.Screen.TTL(:,obj.Port),false);
        end
        function continue_ = analyze(obj,p)
            continue_ = analyze@mladapter(obj,p);  % pass analyze@mlstimulus
            obj.Success = obj.Adapter.Success;
            if ~obj.Triggered && obj.Success
                obj.Triggered = true;
                register([p.DAQ.TTL{obj.Port}],'TTL');
                p.eventmarker(obj.EventMarker);
                mglactivategraphic(obj.Tracker.Screen.TTL(:,obj.Port),true);
            end
        end
    end
end
