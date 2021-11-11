classdef SineGrating < mlstimulus
    properties
        Position               % [x,y] in degrees
        Radius                 % degrees, scalar
        Direction              % degrees
        SpatialFrequency       % cycles per deg
        TemporalFrequency      % cycles per sec
        Phase                  % degrees
        Color1
        Color2
        WindowType             % https://en.wikipedia.org/wiki/Window_function
        WindowSize             % sigma for the Gaussian window
        List
    end
    properties (SetAccess = protected)
        Size
    end
    properties (Access = protected)
        Imdata
        GridX
        GridY
        Mask1
        Mask2
        InitFrame
        Update
        PrevFrame
    end
    methods
        function obj = SineGrating(varargin)
            obj = obj@mlstimulus(varargin{:});
            obj.List = { [0 0], 1, 0, 1, 1, 0, [1 1 1], [0 0 0], 'none', 0 };
        end

        function set.Position(obj,val), row = numchk(obj,val,'Position'); mglsetorigin(obj.GraphicID(row),obj.Tracker.CalFun.deg2pix(val(row,:))); obj.Position = val; end
        function set.Radius(obj,val), row = numchk(obj,val,'Radius'); obj.Radius = val; resize(obj,row); end
        function set.Direction(obj,val), cntchk(obj,val,'Direction'); obj.Direction = val; end
        function set.SpatialFrequency(obj,val), cntchk(obj,val,'SpatialFrequency'); obj.SpatialFrequency = val; end
        function set.TemporalFrequency(obj,val), cntchk(obj,val,'TemporalFrequency'); obj.TemporalFrequency = val; end
        function set.Phase(obj,val), cntchk(obj,val,'Phase'); obj.Phase = val; end
        function set.Color1(obj,val), cntchk(obj,val,'Color1'); obj.Color1 = val; end
        function set.Color2(obj,val), cntchk(obj,val,'Color2'); obj.Color2 = val; end
        function set.WindowType(obj,val)
            [row,val] = strchk(obj,val,'WindowType');
            for m=row
                val{m} = lower(val{m});
                switch val{m}
                    case {'none','circular','triangular','sine','cosine','hann','hamming','gaussian'}
                    otherwise, error('Unknown window type!!!');
                end
            end
            obj.WindowType = val;
            resize(obj,row);
        end
        function set.WindowSize(obj,val), row = numchk(obj,val,'WindowSize'); obj.WindowSize = val; resize(obj,row); end
        function set.List(obj,val), obj.List = val; create_graphic(obj); end
        function val = get.Size(obj)
            nobj = length(obj.GraphicID);
            val = zeros(nobj,2);
            for m=1:nobj, val(m,:) = mglgetproperty(obj.GraphicID(m),'size'); end
            val = val ./ obj.Tracker.Screen.PixelsPerDegree;
        end
        
        function init(obj,p)
            init@mlstimulus(obj,p);
            obj.InitFrame = 0;
            obj.PrevFrame = NaN;
        end
        function continue_ = analyze(obj,p)
            continue_ = analyze@mlstimulus(obj,p);
            if ~obj.Triggered && obj.Success, obj.InitFrame = p.scene_frame(); end
        end
        function draw(obj,p)
            draw@mlstimulus(obj,p);
            
            CurrentFrame = p.scene_frame();
            if obj.PrevFrame==CurrentFrame, return, else, obj.PrevFrame = CurrentFrame; end  % draw only once in one frame
            
            if obj.Triggered
                bgcolor = obj.Tracker.Screen.BackgroundColor;
                for m=1:length(obj.GraphicID)
                    direction = mod(-obj.Direction(m,1),360);
                    t = (CurrentFrame - obj.InitFrame) * p.Screen.FrameLength / 1000;  % in seconds
                    amp1 = (sind(360*(obj.SpatialFrequency(m,1)*(obj.GridX{m,1}*cosd(direction) + obj.GridY{m,1}*sind(direction)) - obj.TemporalFrequency(m,1)*t) + obj.Phase(m,1)) + 1) / 2;
                    amp2 = 1 - amp1;
                    obj.Imdata{m,1}(:,:,2) = (amp1.*obj.Color1(m,1) + amp2.*obj.Color2(m,1)).*obj.Mask1{m,1} + obj.Mask2{m,1}.*bgcolor(1);
                    obj.Imdata{m,1}(:,:,3) = (amp1.*obj.Color1(m,2) + amp2.*obj.Color2(m,2)).*obj.Mask1{m,1} + obj.Mask2{m,1}.*bgcolor(2);
                    obj.Imdata{m,1}(:,:,4) = (amp1.*obj.Color1(m,3) + amp2.*obj.Color2(m,3)).*obj.Mask1{m,1} + obj.Mask2{m,1}.*bgcolor(3);
                    mglsetproperty(obj.GraphicID(m),'bitmap',obj.Imdata{m,1});
                end
            end
        end
    end
    
    methods (Access = protected)
        function cntchk(obj,val,prop), if length(obj.GraphicID)~=size(val,1), error('The size of %s doesn''t match the number of graphic objects.',prop); end, end
        function create_graphic(obj)
            destroy_graphic(obj);
            obj.Position = [];  % To ensure new property values are applied to all newly created graphics

            [nobj,col] = size(obj.List);
            list = cell(nobj,10);
            list(:,1:col) = obj.List;
            obj.GraphicID = NaN(1,nobj);

            Position = zeros(nobj,2); %#ok<*PROP>
            Radius = ones(nobj,1);
            Direction = zeros(nobj,1);
            SpatialFrequency = ones(nobj,1);
            TemporalFrequency = ones(nobj,1);
            Phase = zeros(nobj,1);
            Color1 = ones(nobj,3);
            Color2 = zeros(nobj,3);
            WindowType = repmat({'none'},nobj,1);
            WindowSize = zeros(nobj,1);
            for m=1:nobj
                if ~isempty(list{m,1}), Position(m,:) = list{m,1}; end
                if ~isempty(list{m,2}), Radius(m,:) = list{m,2}; end
                if ~isempty(list{m,3}), Direction(m,:) = list{m,3}; end
                if ~isempty(list{m,4}), SpatialFrequency(m,:) = list{m,4}; end
                if ~isempty(list{m,5}), TemporalFrequency(m,:) = list{m,5}; end
                if ~isempty(list{m,6}), Phase(m,:) = list{m,6}; end
                if ~isempty(list{m,7}), Color1(m,:) = list{m,7}; end
                if ~isempty(list{m,8}), Color2(m,:) = list{m,8}; end
                if ~isempty(list{m,9}), WindowType{m} = list{m,9}; end
                if ~isempty(list{m,10}), WindowSize(m,:) = list{m,10}; end
                
                obj.GraphicID(m) = mgladdbitmap(1);
            end
            obj.Update = false;
            obj.Position = Position;
            obj.Radius = Radius;
            obj.Direction = Direction;
            obj.SpatialFrequency = SpatialFrequency;
            obj.TemporalFrequency = TemporalFrequency;
            obj.Phase = Phase;
            obj.Color1 = Color1;
            obj.Color2 = Color2;
            obj.WindowType = WindowType;
            obj.WindowSize = WindowSize;

            obj.Imdata = cell(nobj,1);
            obj.GridX = cell(nobj,1);
            obj.GridY = cell(nobj,1);
            obj.Mask1 = cell(nobj,1);
            obj.Mask2 = cell(nobj,1);

            obj.Update = true;
            resize(obj,1:nobj);

            mglactivategraphic(obj.GraphicID,false);
        end
        function resize(obj,row)
            if ~obj.Update, return, end
            
            ppd = obj.Tracker.Screen.PixelsPerDegree;
            for m=row
                z = 0:1/ppd:obj.Radius(m,1);
                z = [-z(end:-1:2) z]; %#ok<AGROW>
                [obj.GridX{m,1},obj.GridY{m,1}] = meshgrid(z,z);
                sz = size(obj.GridX{m,1});
                obj.Imdata{m,1} = ones([sz 4]);
                
                if strcmp(obj.WindowType{m,1},'none')
                    obj.Mask1{m,1} = obj.Imdata{m,1}(:,:,1);
                else
                    mask = 1 - sqrt(obj.GridX{m,1}.^2 + obj.GridY{m,1}.^2) ./ obj.Radius(m,1);
                    obj.Imdata{m,1}(:,:,1) = double(0<mask);
                    switch obj.WindowType{m,1}
                        case 'circular', obj.Mask1{m,1} = obj.Imdata{m,1}(:,:,1);
                        case 'triangular', obj.Mask1{m,1} = mask;
                        case {'sine','cosine'}, obj.Mask1{m,1} = sind(90*mask);
                        case 'hann', a0 = 0.5; obj.Mask1{m,1} = a0 - (1-a0).*cosd(180*mask);
                        case 'hamming', a0 = 25/46; obj.Mask1{m,1} = a0 - (1-a0).*cosd(180*mask);
                        case 'gaussian', obj.Mask1{m,1} = exp((obj.GridX{m,1}.^2 + obj.GridY{m,1}.^2)./(-2*obj.WindowSize(m,1)^2));
                    end
                end
                obj.Mask2{m,1} = 1 - obj.Mask1{m,1};
            end
        end
    end
end
