classdef AudioSound < mlstimulus
    properties
        PlaybackPosition
        Source  % For backward compatibility, keep the Source property but use List
    end
    properties (Access = protected)
        Filepath
    end
    properties (Hidden)
        List
    end
    
    methods
        function obj = AudioSound(varargin)
            obj = obj@mlstimulus(varargin{:});
        end
        function set.PlaybackPosition(obj,val), row = numchk(obj,val,'PlaybackPosition',true); mglsetproperty(obj.SoundID(row),'seek',val(row,:)/1000); end
        function val = get.PlaybackPosition(obj), nobj = numel(obj.SoundID); val = NaN(nobj,1); for m=1:nobj, val(m) = mglgetproperty(obj.SoundID(m),'currentposition')*1000; end, end
        function set.Source(obj,val), if ~iscell(val), val = {val}; end, obj.Source = val; create_sound(obj); end
        function val = get.List(obj), val = obj.Source; end
        function set.List(obj,val), obj.Source = val; end %#ok<*MCSUP>
        
        function fini(obj,p), fini@mlstimulus(obj,p); p.stimfile(obj.Filepath); end
        function continue_ = analyze(obj,p)
            analyze@mladapter(obj,p);  % pass analyze@mlstimulus
            if obj.Triggered
                if 0<p.scene_frame()
                    isplaying = [];
                    for m=length(obj.SoundID):-1:1, isplaying(m) = mglgetproperty(obj.SoundID(m),'isplaying'); end
                    obj.Success = ~any(isplaying);
                end
            else
                if obj.Adapter.Success
                    obj.Triggered = true;
                    mglactivatesound(obj.SoundID,true);
                    p.eventmarker(obj.EventMarker);
                end
            end
            continue_ = ~obj.Success;
        end
    end
    methods (Access = protected)
        function create_sound(obj)
            destroy_sound(obj);
            obj.PlaybackPosition = [];
            obj.Filepath = [];
            
            [nobj,col] = size(obj.Source);
            list = cell(nobj,1);
            list(:,1:col) = obj.Source;
            obj.SoundID = NaN(1,nobj);
            
            for m=1:nobj
                if isempty(list{m,1}), continue, end
                switch class(list{m,1})
                    case 'char'
                        err = []; try [y,fs] = eval(list{m,1}); catch err, end
                        if ~isempty(err), obj.Filepath{end+1} = obj.Tracker.validate_path(list{m,1}); [y,fs] = load_waveform({'snd',obj.Filepath{end}}); end
                        if isscalar(y), obj.SoundID(m) = y; else, obj.SoundID(m) = mgladdsound(y,fs); end
                    case 'double'
                        if isscalar(list{m,1})
                            obj.SoundID(m) = list{m,1};
                        else
                            [y,fs] = load_waveform({'snd',list{m,1}(1)/1000,list{m,1}(2)});
                            obj.SoundID(m) = mgladdsound(y,fs);
                        end
                    otherwise, error('Unknown sound source in Row #%d!!!',m);
                end
            end
            obj.PlaybackPosition = zeros(nobj,1);
            
            mglactivatesound(obj.SoundID,false);
        end
    end
end
