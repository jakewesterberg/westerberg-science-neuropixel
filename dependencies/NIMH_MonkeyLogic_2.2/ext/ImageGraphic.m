classdef ImageGraphic < mlstimulus
    properties
        Position
        Scale
        Angle
        Zorder
        List
    end
    properties (SetAccess = protected)
        Size
    end
    properties (Access = protected)
        Filepath
    end
    properties (Hidden)
        ImageList
    end
    
    methods
        function obj = ImageGraphic(varargin)
            obj = obj@mlstimulus(varargin{:});
        end
        function fini(obj,p), fini@mlstimulus(obj,p); p.stimfile(obj.Filepath); end
        
        function set.Position(obj,val), row = numchk(obj,val,'Position'); mglsetorigin(obj.GraphicID(row),obj.Tracker.CalFun.deg2pix(val(row,:))); obj.Position = val; end
        function set.Scale(obj,val), row = numchk(obj,val,'Scale'); mglsetproperty(obj.GraphicID(row),'scale',val(row,:)); obj.Scale = val; end
        function set.Angle(obj,val), row = numchk(obj,val,'Angle'); mglsetproperty(obj.GraphicID(row),'angle',val(row,:)); obj.Angle = val; end
        function set.Zorder(obj,val), row = numchk(obj,val,'Zorder'); mglsetproperty(obj.GraphicID(row),'zorder',val(row,:)); obj.Zorder = val; end
        function set.List(obj,val), obj.List = val; create_graphic(obj); end
        function val = get.Size(obj)
            nobj = length(obj.GraphicID);
            val = zeros(nobj,2);
            for m=1:nobj, val(m,:) = mglgetproperty(obj.GraphicID(m),'size'); end
            val = val ./ obj.Tracker.Screen.PixelsPerDegree;
        end
        function val = get.ImageList(obj), val = obj.List; end
        function set.ImageList(obj,val), obj.List = val; end %#ok<*MCSUP>
    end
    
    methods (Access = protected)
        function create_graphic(obj)
            destroy_graphic(obj);
            obj.Position = [];  % To ensure new property values are applied to all newly created graphics
            obj.Scale = [];
            obj.Angle = [];
            obj.Zorder = [];
            obj.Filepath = [];
            
            [nobj,col] = size(obj.List);
            list = cell(nobj,5);
            list(:,1:col) = obj.List;
            obj.GraphicID = NaN(1,nobj);

            Position = zeros(nobj,2); %#ok<*PROP>
            Scale = ones(nobj,1);
            Angle = zeros(nobj,1);
            for m=1:nobj
                if isempty(list{m,1}), continue, end
                if iscell(list{m,1})
                   if 1<length(list{m,1}), error('Too many images in Row #%d. Please put one image per row.',m); end
                   list{m,1} = list{m,1}{1};
                end                    
                scale = []; resize = []; colorkey = [];
                for n=3:4
                    switch numel(list{m,n})
                        case 1, scale = list{m,n};
                        case 2, resize = list{m,n};
                        case 3, colorkey = list{m,n};
                    end
                end
                if ~isempty(list{m,2}), Position(m,:) = list{m,2}; end
                if ~isempty(list{m,5}), Angle(m,:) = list{m,5}; end
                if ~isempty(scale), Scale(m,:) = scale; end
                
                switch class(list{m,1})
                    case {'double','uint8'}
                        if isscalar(list{m,1})
                            obj.GraphicID(m) = list{m,1};  % MGL ID
                        else
                            imdata = list{m,1};
                            if ~isempty(resize), imdata = mglimresize(imdata,resize([2 1])); end
                            if isempty(colorkey)
                                obj.GraphicID(m) = mgladdbitmap(imdata);
                            else
                                obj.GraphicID(m) = mgladdbitmap(imdata,colorkey);
                            end
                        end
                    case 'char'
                        err = []; try imdata = eval(list{m,1}); catch err, end
                        if ~isempty(err), obj.Filepath{end+1} = obj.Tracker.validate_path(list{m,1}); imdata = mglimread(obj.Filepath{end}); end
                        if ~isempty(resize), imdata = mglimresize(imdata,resize([2 1])); end
                        if isempty(colorkey)
                            obj.GraphicID(m) = mgladdbitmap(imdata);
                        else
                            obj.GraphicID(m) = mgladdbitmap(imdata,colorkey);
                        end
                    otherwise
                        error('Unknown input type!!!');
                end
            end
            obj.Position = Position;
            obj.Scale = Scale;
            obj.Angle = Angle;
            obj.Zorder = zeros(nobj,1);
            
            mglactivategraphic(obj.GraphicID,false);
        end
        function destroy_graphic(obj)
            if isempty(obj.GraphicID), return, end
            for m=1:size(obj.List,1)
                if isa(obj.List{m,1},'double') && isscalar(obj.List{m,1}), continue, end
                mgldestroygraphic(obj.GraphicID(m));
            end
            obj.GraphicID = [];
        end
    end
end
