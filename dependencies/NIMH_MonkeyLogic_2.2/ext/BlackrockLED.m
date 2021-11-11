classdef BlackrockLED < mlstimulus
    properties
        MaxIntensity  % 0 to 1
    end
    properties (SetAccess = protected)
        ID
        Temperature
    end
    
    methods
        function obj = BlackrockLED(varargin)
            obj = obj@mlstimulus(varargin{:});
            try
                obj.SoundID = BlackrockLED_init;
            catch err
                if 0==obj.Tracker.DataSource, rethrow(err); else, obj.SoundID = NaN; end
            end
            mglactivatesound(obj.SoundID,false);

            obj.MaxIntensity = 0.5;
        end

        function set.MaxIntensity(obj,val), BlackrockLED_setmax(obj.SoundID,val); obj.MaxIntensity = val; end
        function val = get.ID(obj), val = obj.SoundID; end
        function val = get.Temperature(obj), val = BlackrockLED_temp(obj.SoundID); end

        function setmax(obj,intensity), obj.MaxIntensity = intensity; end
        function load(obj,intensity,duration), BlackrockLED_load(obj.SoundID,intensity,duration); end
        function temperature = temp(obj,ver), temperature = BlackrockLED_temp(obj.SoundID,ver); end

        function continue_ = analyze(obj,p)
            analyze@mlstimulus(obj,p);
            obj.Success = obj.Triggered;
            continue_ = ~obj.Success;
        end
    end
end
