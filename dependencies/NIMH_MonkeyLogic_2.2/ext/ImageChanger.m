classdef ImageChanger < mladapter
    properties
        DurationUnit = 'frame'  % or 'msec'
        List
    end
    properties (Hidden)
        ImageList
        OnsetTime
    end
    properties (SetAccess = protected)
        GraphicID
        ScrPosition
        Time
    end
    properties (Access = protected)
        ImageSchedule
        ImageIndex
        PrevImageIndex
        bImageChanged
        Filepath
        PrevFrame
    end
    
    methods
        function obj = ImageChanger(varargin)
            obj = obj@mladapter(varargin{:});
        end
        function delete(obj)
            destroy_graphic(obj);
        end
        function set.List(obj,val)
            ncol = size(val,2);
            if ncol<3 || 5<ncol, error('List must be an n-by-3 or n-by-4 or n-by-5 matrix'); end
            obj.List = cell(size(val,1),5);
            obj.List(:,1:size(val,2)) = val;
            create_graphic(obj);
        end
        function val = get.ImageList(obj), val = obj.List; end
        function set.ImageList(obj,val), obj.List = val; end %#ok<MCSUP>
        function val = get.OnsetTime(obj), val = obj.Time; end
        
        function init(obj,p)
            init@mladapter(obj,p);
            obj.Time = NaN(size(obj.List,1),1);
            if strcmpi(obj.DurationUnit,'frame')
                obj.ImageSchedule = cumsum([obj.List{:,3}]);
            else
                obj.ImageSchedule = cumsum(round([obj.List{:,3}] / obj.Tracker.Screen.FrameLength));
            end
            obj.ImageIndex = NaN;
            obj.PrevImageIndex = NaN;
            obj.bImageChanged = false;
            obj.PrevFrame = NaN;
        end
        function fini(obj,p)
            fini@mladapter(obj,p);
            activate_all(obj,false);
            p.stimfile(obj.Filepath);
        end
        function continue_ = analyze(obj,p)
            analyze@mladapter(obj,p);
            CurrentFrame = p.scene_frame();
            if obj.PrevFrame==CurrentFrame, continue_ = ~obj.Success; return, else, obj.PrevFrame = CurrentFrame; end  % draw only once in one frame

            if obj.bImageChanged, obj.Time(obj.ImageIndex) = p.LastFlipTime; end
            obj.ImageIndex = find(CurrentFrame < obj.ImageSchedule,1);
            obj.Success = isempty(obj.ImageIndex);
            continue_ = ~obj.Success;
            
            obj.bImageChanged = continue_ && obj.PrevImageIndex ~= obj.ImageIndex;
            if obj.bImageChanged
                if 0<obj.PrevImageIndex, mglactivategraphic(obj.GraphicID{obj.PrevImageIndex},false); end
                obj.PrevImageIndex = obj.ImageIndex;
                id = obj.GraphicID{obj.ImageIndex};
                if ~isempty(id), mglsetproperty(id,'active',true,'origin',obj.ScrPosition{obj.ImageIndex}); end
                p.eventmarker(obj.List{obj.ImageIndex,4});
            end                
        end
    end
    methods (Access = protected)
        function create_graphic(obj)
            destroy_graphic(obj);
            obj.Filepath = [];
            
            nrow = size(obj.List,1);
            obj.GraphicID = cell(nrow,1);
            obj.ScrPosition = cell(nrow,1);
            for m=1:nrow
                if isempty(obj.List{m,1}), continue, end
                switch class(obj.List{m,1})
                    case 'double', obj.GraphicID{m} = obj.List{m,1};  % MGL ID
                    case 'uint8', obj.GraphicID{m} = mgladdbitmap(obj.List{m,1});
                    case 'char'
                        err = []; try imdata = eval(obj.List{m,1}); catch err, end
                        if ~isempty(err), obj.Filepath{end+1} = obj.Tracker.validate_path(obj.List{m,1}); imdata = mglimread(obj.Filepath{end}); end
                        if ~isempty(obj.List{m,5}), imdata = mglimresize(imdata,obj.List{m,5}([2 1])); end
                        obj.GraphicID{m} = mgladdbitmap(imdata);
                    case 'cell'
                        nid = numel(obj.List{m,1});
                        obj.GraphicID{m} = NaN(1,nid);
                        nresize = size(obj.List{m,5},1);
                        for n=1:nid
                            err = []; try imdata = eval(obj.List{m,1}{n}); catch err, end
                            if ~isempty(err), obj.Filepath{end+1} = obj.Tracker.validate_path(obj.List{m,1}{n}); imdata = mglimread(obj.Filepath{end}); end
                            if 0<nresize
                                if nresize<n, row = nresize; else, row = n; end
                                imdata = mglimresize(imdata,obj.List{m,5}(row,[2 1]));
                            end
                            obj.GraphicID{m}(n) = mgladdbitmap(imdata);
                        end
                end
                obj.ScrPosition{m} = obj.Tracker.CalFun.deg2pix(obj.List{m,2});
            end
            activate_all(obj,false);
        end
        function destroy_graphic(obj)
            if isempty(obj.GraphicID), return, end
            for m=1:size(obj.List,1)
                if isa(obj.List{m,1},'double') && isscalar(obj.List{m,1}), continue, end
                mgldestroygraphic(obj.GraphicID{m});
            end
            obj.GraphicID = [];
        end
        function activate_all(obj,active)
            for m=1:size(obj.List,1), mglactivategraphic(obj.GraphicID{m},active); end
        end
    end
end
