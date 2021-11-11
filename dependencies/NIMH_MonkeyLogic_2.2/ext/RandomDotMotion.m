classdef RandomDotMotion < mlstimulus
    properties
        Position   % [x,y] in degrees
        Radius     % aperture radius in degrees
        Coherence  % 0 - 100
        Direction  % degree
        Speed      % degrees per second
        
        NumDot
        DotSize    % in degrees
        DotColor
        DotShape   % 'square' or 'circle'
        Interleaf  % number of alternating frames
        List
    end
    properties (Access = protected)
        DotID
        DotPosition
        ScrPosition
        ScrRadius
        ScrDisplacement
        NumMovingDot
        SymmetryMat
        Update
        PrevFrame
    end
    
    methods
        function obj = RandomDotMotion(varargin)
            obj = obj@mlstimulus(varargin{:});
            obj.List = { [0 0], 5, 100, 0, 5, 100, 0.15, [1 1 1], 'square', 3 };
        end
        function delete(obj), destroy_dots(obj); end

        function set.Position(obj,val), row = numchk(obj,val,'Position'); obj.Position = val; update_ScrPosition(obj,row); end %#ok<*MCSUP>
        function set.Radius(obj,val), row = numchk(obj,val,'Radius'); obj.Radius = val; update_DotPosition(obj,row); end
        function set.Coherence(obj,val), row = numchk(obj,val,'Coherence'); obj.Coherence = val; update_ScrDisplacement(obj,row); end
        function set.Direction(obj,val), row = numchk(obj,val,'Direction'); obj.Direction = val; update_ScrDisplacement(obj,row); update_SymmetryMat(obj,row); end
        function set.Speed(obj,val), row = numchk(obj,val,'Speed'); obj.Speed = val; update_ScrDisplacement(obj,row); end
        function set.NumDot(obj,val), row = numchk(obj,val,'NumDot'); obj.NumDot = val; update_DotID(obj,row); update_DotPosition(obj,row); update_ScrPosition(obj,row); update_ScrDisplacement(obj,row); end
        function set.DotSize(obj,val), row = numchk(obj,val,'DotSize'); obj.DotSize = val; update_DotSize(obj,row); end
        function set.DotColor(obj,val), row = numchk(obj,val,'DotColor'); obj.DotColor = val; update_DotColor(obj,row); end
        function set.DotShape(obj,val), [row,val] = strchk(obj,val,'DotShape'); obj.DotShape = val; update_DotID(obj,row); end
        function set.Interleaf(obj,val), row = numchk(obj,val,'Interleaf'); obj.Interleaf = val; update_DotPosition(obj,row); update_ScrDisplacement(obj,row); end
        function set.List(obj,val), obj.List = val; create_graphic(obj); end

        function init(obj,p)
            init@mladapter(obj,p);  % pass init@mlstimulus
            obj.Triggered = false;
            if ~obj.Trigger, obj.Triggered = true; activate_dots(obj,true); end
            obj.PrevFrame = NaN;
        end
        function fini(obj,p)
            fini@mladapter(obj,p);
            activate_dots(obj,false);
        end
        function continue_ = analyze(obj,p)
            continue_ = analyze@mladapter(obj,p);  % pass analyze@mlstimulus
            obj.Success = obj.Adapter.Success;     % because analyze@mlstimulus is skipped
            if ~obj.Triggered && obj.Success, obj.Triggered = true; activate_dots(obj,true); p.eventmarker(obj.EventMarker); end
        end
        function draw(obj,p)
            draw@mlstimulus(obj,p);

            CurrentFrame = p.scene_frame();
            if obj.PrevFrame==CurrentFrame, return, else, obj.PrevFrame = CurrentFrame; end  % draw only once in one frame
            
            if obj.Triggered
                for m=1:length(obj.DotID)
                    % draw dots for the current frame
                    interleaf = mod(CurrentFrame,obj.Interleaf(m,1)) + 1;
                    mglsetorigin(obj.DotID{m,1},obj.DotPosition{m,1}{interleaf}+obj.ScrPosition{m});

                    % pick dots to move coherently
                    random_order = randperm(obj.NumDot(m,1));
                    moving_dots = random_order(1:obj.NumMovingDot(m,1));
                    random_dots = random_order(obj.NumMovingDot(m,1)+1:obj.NumDot(m,1));

                    % move them to new position
                    new_position = obj.DotPosition{m,1}{interleaf}(moving_dots,:) + obj.ScrDisplacement{m};
                    escaping_dots = obj.ScrRadius(m,:)*obj.ScrRadius(m,:) < sum(new_position.^2,2);
                    new_position(escaping_dots,:) = obj.DotPosition{m,1}{interleaf}(moving_dots(escaping_dots),:) * obj.SymmetryMat{m,1};
                    obj.DotPosition{m,1}{interleaf}(moving_dots,:) = new_position;

                    % move the rest of the dots to random position
                    n = length(random_dots);
                    r = (1-rand(n,1).^2) * obj.ScrRadius(m);
                    t = rand(n,1) * 360;
                    obj.DotPosition{m,1}{interleaf}(random_dots,:) = [r.*cosd(t) r.*sind(t)];
                end
            end
        end
    end
    
    methods (Access = protected)
        function destroy_dots(obj), for m=1:length(obj.DotID), mgldestroygraphic(obj.DotID{m}); end, obj.DotID = []; end
        function activate_dots(obj,state), for m=1:length(obj.DotID), mglactivategraphic(obj.DotID{m},state); end, end
        function create_graphic(obj)
            destroy_dots(obj);
            
            [nobj,col] = size(obj.List);
            list = cell(nobj,10);
            list(:,1:col) = obj.List;
            obj.GraphicID = NaN(1,nobj);
            
            Position = zeros(nobj,2); %#ok<*PROP>
            Radius = 5*ones(nobj,1);
            Coherence = 100*ones(nobj,1);
            Direction = zeros(nobj,1);
            Speed = 5*ones(nobj,1);
            NumDot = 100*ones(nobj,1);
            DotSize = 0.15*ones(nobj,1);
            DotColor = ones(nobj,3);
            DotShape = repmat({'square'},nobj,1);
            Interleaf = 3*ones(nobj,1);
            for m=1:nobj
                if ~isempty(list{m,1}), Position(m,:) = list{m,1}; end
                if ~isempty(list{m,2}), Radius(m,:) = list{m,2}; end
                if ~isempty(list{m,3}), Coherence(m,:) = list{m,3}; end
                if ~isempty(list{m,4}), Direction(m,:) = list{m,4}; end
                if ~isempty(list{m,5}), Speed(m,:) = list{m,5}; end
                if ~isempty(list{m,6}), NumDot(m,:) = list{m,6}; end
                if ~isempty(list{m,7}), DotSize(m,:) = list{m,7}; end
                if ~isempty(list{m,8}), DotColor(m,:) = list{m,8}; end
                if ~isempty(list{m,9}), if ischar(list{m,9}), DotShape{m} = list{m,9}; else, Interleaf(m,:) = list{m,9}; end, end
                if ~isempty(list{m,10}), Interleaf(m,:) = list{m,10}; end
            end
            obj.Update = false;
            obj.Position = Position;
            obj.Radius = Radius;
            obj.Coherence = Coherence;
            obj.Direction = Direction;
            obj.Speed = Speed;
            obj.NumDot = NumDot;
            obj.DotSize = DotSize;
            obj.DotColor = DotColor;
            obj.DotShape = DotShape;
            obj.Interleaf = Interleaf;

            obj.DotID = cell(nobj,1);
            obj.DotPosition = cell(nobj,1);
            obj.ScrPosition = cell(nobj,1);
            obj.ScrRadius = zeros(nobj,1);
            obj.ScrDisplacement = cell(nobj,1);
            obj.NumMovingDot = zeros(nobj,1);
            obj.SymmetryMat = cell(nobj,1);

            obj.Update = true;
            update_DotID(obj,1:nobj);
            update_DotPosition(obj,1:nobj);
            update_ScrPosition(obj,1:nobj);
            update_ScrDisplacement(obj,1:nobj);
            update_SymmetryMat(obj,1:nobj);
            
            activate_dots(obj,false);
        end
        function update_DotSize(obj,row)  % DotSize
            if ~obj.Update, return, end
            for m=row, mglsetproperty(obj.DotID{m},'size',obj.Tracker.Screen.PixelsPerDegree*obj.DotSize(m,:)); end
        end
        function update_DotColor(obj,row)  % DotColor
            if ~obj.Update, return, end
            for m=row, mglsetproperty(obj.DotID{m},'color',obj.DotColor(m,:)); end
        end
        function update_DotID(obj,row)  % NumDot, DotShape
            if ~obj.Update, return, end
            for m=row
                mgldestroygraphic(obj.DotID{m});
                obj.DotID{m} = NaN(1,obj.NumDot(m,:));
                dotsize = obj.Tracker.Screen.PixelsPerDegree * obj.DotSize(m,:);
                for n=1:obj.NumDot(m,:)
                    switch lower(obj.DotShape{m}(1))
                        case 'c', obj.DotID{m}(n) = mgladdcircle([obj.DotColor(m,:); obj.DotColor(m,:)],dotsize);
                        otherwise, obj.DotID{m}(n) = mgladdbox([obj.DotColor(m,:); obj.DotColor(m,:)],dotsize);
                    end
                end
                mglactivategraphic(obj.DotID{m},false);
            end
        end
        function update_DotPosition(obj,row)  % Radius, NumDot, Interleaf
            if ~obj.Update, return, end
            for m=row
                obj.ScrRadius(m,:) = obj.Tracker.Screen.PixelsPerDegree * obj.Radius(m,:);
                obj.DotPosition{m} = cell(1,obj.Interleaf(m,:));
                for n=1:obj.Interleaf(m,:)
                    r = (1-rand(obj.NumDot(m,:),1).^2) * obj.ScrRadius(m,:);
                    t = rand(obj.NumDot(m,:),1) * 360;
                    obj.DotPosition{m}{n} = [r.*cosd(t) r.*sind(t)];
                end
            end
        end
        function update_ScrPosition(obj,row)  % Position, NumDot
            if ~obj.Update, return, end
            for m=row, obj.ScrPosition{m} = repmat(obj.Tracker.CalFun.deg2pix(obj.Position(m,:)),obj.NumDot(m,:),1); end            
        end
        function update_ScrDisplacement(obj,row)  % Coherence, Direction, Speed, NumDot, Interleaf
            if ~obj.Update, return, end
            for m=row
                direction = mod(-obj.Direction(m,:),360);
                obj.NumMovingDot(m,:) = round(obj.NumDot(m,:) * obj.Coherence(m,:) / 100);
                d = obj.Tracker.Screen.PixelsPerDegree * obj.Speed(m,:) * obj.Interleaf(m,:) / obj.Tracker.Screen.RefreshRate;
                obj.ScrDisplacement{m} = repmat([d*cosd(direction) d*sind(direction)],obj.NumMovingDot(m,1),1);
            end
        end
        function update_SymmetryMat(obj,row)  % Direction
            if ~obj.Update, return, end
            for m=row
                direction = mod(-obj.Direction(m,:),360);
                switch direction
                    case {0,180}, obj.SymmetryMat{m} = [-1 0; 0 1];
                    case {90,270}, obj.SymmetryMat{m} = [1 0; 0 -1];
                    otherwise, a = -1/tand(direction); b = 1+a*a; obj.SymmetryMat{m} = [(2-b)/b 2*a/b; 2*a/b (b-2)/b];
                end
            end
        end
    end
end
