classdef mlstimulus < mladapter
    properties
        Trigger
        EventMarker
    end
    properties (SetAccess = protected)
        GraphicID
        SoundID
    end
    properties (Access = protected)
        Triggered
    end
    
    methods
        function obj = mlstimulus(varargin)
            obj = obj@mladapter(varargin{:});
            obj.Trigger = false;
            obj.EventMarker = [];
        end
        function delete(obj), destroy_graphic(obj); destroy_sound(obj); end
        
        function init(obj,p)
            init@mladapter(obj,p);
            obj.Triggered = false;
            if ~obj.Trigger
                obj.Triggered = true;
                mglactivategraphic(obj.GraphicID,true);
                mglactivatesound(obj.SoundID,true);
            end
        end
        function fini(obj,p)
            fini@mladapter(obj,p);
            mglactivategraphic(obj.GraphicID,false);
            mglactivatesound(obj.SoundID,false);
        end
        function continue_ = analyze(obj,p)
            continue_ = analyze@mladapter(obj,p);
            obj.Success = obj.Adapter.Success;
            if ~obj.Triggered && obj.Success
                obj.Triggered = true;
                mglactivategraphic(obj.GraphicID,true);
                mglactivatesound(obj.SoundID,true);
                p.eventmarker(obj.EventMarker);
            end
        end
    end
    
    methods (Access = protected)
        function destroy_graphic(obj), mgldestroygraphic(obj.GraphicID); obj.GraphicID = []; end
        function destroy_sound(obj), mgldestroysound(obj.SoundID); obj.SoundID = []; end
        function row = numchk(obj,val,prop,issound)
            if isempty(val), row = []; return, end
            if ~exist('issound','var'), issound = false; end
            sz = size(val);
            if ~issound&&numel(obj.GraphicID)~=sz(1) || issound&&numel(obj.SoundID)~=sz(1), error('The size of %s doesn''t match the number of objects.',prop); end
            if any(size(obj.(prop))~=sz), row = 1:sz(1); else, row = find(any(obj.(prop)~=val,2))'; end
        end
        function [row,val] = cellnumchk(obj,val,prop)
            if ~iscell(val), val = {val}; end
            if isempty(val{1}), row = []; return, end
            sz = size(val);
            if numel(obj.GraphicID)~=sz(1), error('The size of %s doesn''t match the number of graphic objects.',prop); end
            d = true(1,sz(1));
            if all(size(obj.(prop))==sz), for m=1:sz(1), d(m) = any(size(obj.(prop){m})~=size(val{m})) || any(any(obj.(prop){m}~=val{m})); end, end
            row = 1:sz(1); row = row(d);
        end
        function [row,val] = strchk(obj,val,prop)
            if ~iscell(val), val = {val}; end
            if isempty(val{1}), row = []; return, end
            sz = size(val);
            if numel(obj.GraphicID)~=sz(1), error('The size of %s doesn''t match the number of graphic objects.',prop); end
            if any(size(obj.(prop))~=sz), row = 1:sz(1); else, row = find(~strcmp(obj.(prop),val))'; end
        end
    end
end
