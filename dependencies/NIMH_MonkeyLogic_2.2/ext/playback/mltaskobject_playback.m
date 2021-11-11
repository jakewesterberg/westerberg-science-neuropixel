classdef mltaskobject_playback < matlab.mixin.Copyable
    properties (SetAccess = protected)
        ID
        Modality
    end
    properties
        Status
        Position
        Scale
        Angle
        Zorder
    end
    properties (SetAccess = protected)
        Info
        MoreInfo
        Size
        Label
    end
    properties (Hidden)
        PixelsPerDegree
        SubjectScreenHalfSize
        DestroyObject
    end
    methods
        function obj = mltaskobject_playback(taskobj,MLConfig)
            clear(obj);
            if ~exist('taskobj','var'), return; end
            if isa(taskobj,'mltaskobject_playback')
                obj = copy(taskobj);
            else
                obj.PixelsPerDegree = MLConfig.PixelsPerDegree;
                obj.SubjectScreenHalfSize = MLConfig.Screen.SubjectScreenHalfSize;
                obj.DestroyObject = true;
            end
        end
        function delete(obj), clear(obj); end
        function clear(obj)
            try
                if obj.DestroyObject, mgldestroygraphic(obj.ID); end
            catch
                % for suppressing unnecessary error messages
            end
            obj.ID = [];
            obj.Modality = [];
            obj.Status = false;
            obj.Position = [];
            obj.Info = struct;
            obj.MoreInfo = {};
            obj.Label = [];
            obj.Size = [];
            obj.DestroyObject = false;
        end
        function val = end(obj,~,~), val = length(obj.ID); end
        function val = length(obj), val = length(obj.ID); end
        function val = size(obj), val = size(obj.ID); end
        function val = horzcat(obj,varargin)
            val = copy(obj);
            for m=1:length(varargin)
                val.ID = [val.ID varargin{m}.ID];
                val.Modality = [val.Modality varargin{m}.Modality];
                val.Status = [val.Status varargin{m}.Status];
                val.Position = [val.Position; varargin{m}.Position];
                val.Scale = [val.Scale varargin{m}.Scale];
                val.Angle = [val.Angle varargin{m}.Angle];
                val.Zorder = [val.Zorder varargin{m}.Zorder];
                val.Info = [val.Info varargin{m}.Info];
                val.MoreInfo = [val.MoreInfo varargin{m}.MoreInfo];
                val.Size = [val.Size; varargin{m}.Size];
            end
        end
        function val = vertcat(obj,varargin), val = horzcat(obj,varargin{:}); end
        
        function obj = subsasgn(obj,s,b)
%             if isempty(b), error('Cannot assign an empty matrix'); end
            l = length(s);
            switch s(1).type
                case '.'  % no modification
                case {'()','{}'}
                    if 1==l
                        error('Not a valid indexing expression');
                    elseif 1<l
                        a = s(2); s(2) = s(1); s(1) = a;
                    end
                otherwise
                    error('Not a valid indexing expression');
            end
            switch s(1).subs
                case {'ID','Modality'}, error('Attempt to modify read-only property: ''%s''.',s(1).subs);
                case {'Position','Size'}, if 2<l, s(2).subs{2} = s(3).subs{1}; s(3) = []; end
            end
            obj = builtin('subsasgn',obj,s,b);
            
            if l==1, idx = 1:length(obj.ID); else, idx = s(2).subs{1}; end
            switch s(1).subs
                case 'Position', mglsetorigin(obj.ID(idx),getScreenPosition(obj,obj.Position(idx,:)));
                case 'Scale', mglsetproperty(obj.ID(idx),'scale',b);
                case 'Angle', mglsetproperty(obj.ID(idx),'angle',b);
                case 'Zorder', mglsetproperty(obj.ID(idx),'zorder',b);
            end
        end
        function varargout = subsref(obj,s)
            l = length(s);
            switch s(1).type
                case '.'
                    if 2==l && strcmp(s(2).type,'.')
                        nid = length(obj.(s(1).subs));
                        switch s(1).subs
                            case 'Info', varargout{1} = cell(1,nid); for m=1:nid, varargout{1}{m} = obj.(s(1).subs)(m).(s(2).subs); end
                            case 'MoreInfo', varargout{1} = cell(1,nid); for m=1:nid, varargout{1}{m} = obj.(s(1).subs){m}.(s(2).subs); end
                        end
                    elseif 2<l && strcmp(s(3).type,'.')
                        idx = s(2).subs{1};
                        nid = length(idx);
                        switch s(1).subs
                            case 'Info', varargout{1} = cell(1,nid); for m=1:nid, varargout{1}{m} = obj.(s(1).subs)(idx(m)).(s(3).subs); end
                            case 'MoreInfo', varargout{1} = cell(1,nid); for m=1:nid, varargout{1}{m} = obj.(s(1).subs){idx(m)}.(s(3).subs); end
                        end
                    else
                        [varargout{1:nargout}] = builtin('subsref',obj,s);
                    end
                case {'()','{}'}
                    if 1<length(s(1).subs), error('Not a valid indexing expression'); end
                    if 1==l
                        idx = s(1).subs{1};
                        if isempty(idx), varargout{1} = []; return, end
                        if ischar(idx), idx = 1:length(obj.ID); end
                        b = mltaskobject_playback;
                        b.ID = obj.ID(idx);
                        b.Modality = obj.Modality(idx);
                        b.Status = obj.Status(idx);
                        b.Position = obj.Position(idx,:);
                        b.Scale = obj.Scale(idx);
                        b.Angle = obj.Angle(idx);
                        b.Zorder = obj.Zorder(idx);
                        b.Info = obj.Info(idx);
                        b.MoreInfo = obj.MoreInfo(idx);
                        b.Size = obj.Size(idx,:);
                        b.PixelsPerDegree = obj.PixelsPerDegree;
                        b.SubjectScreenHalfSize = obj.SubjectScreenHalfSize;
                        varargout{1} = b;
                        return
                    elseif 1<l
                        a = s(2); s(2) = s(1); s(1) = a; idx = s(2).subs{1};
                        if isempty(idx), varargout{1} = []; return, end
                        switch s(1).subs
                            case {'Position','Size'}
                                if 2<l, s(2).subs{1,2} = s(3).subs{1}; s(3) = []; else, s(2).subs{1,2} = ':'; end
                                varargout{1} = builtin('subsref',obj,s);
                                if 1<nargout, varargout = mat2cell(varargout{1},ones(1,size(varargout{1},1))); end
                            case {'Info','MoreInfo'}
                                if iscell(obj.(s(1).subs)), s(2).type = '{}'; else, s(2).type = '()'; end
                                varargout{1} = builtin('subsref',obj,s);
                                if 1<nargout, varargout = varargout{1}'; end
                            otherwise
                                varargout{1} = builtin('subsref',obj,s);
                                if 1<nargout, varargout = mat2cell(varargout{1}',ones(1,length(varargout{1}))); end
                        end
                    end
                otherwise
                    error('Not a valid indexing expression');
            end
        end
        
        function createobj(obj,taskobj,MLConfig,TrialRecord,validate_path)
            nobj = length(taskobj);
            obj.ID = NaN(1,nobj);
            obj.Modality = zeros(1,nobj);
            obj.Status = false(1,nobj);
            obj.Position = NaN(nobj,2);
            obj.Scale = ones(1,nobj);
            obj.Angle = zeros(1,nobj);
            obj.Zorder = zeros(1,nobj);
            obj.Info = taskobj;
            obj.MoreInfo = cell(1,nobj);
%             obj.Size = zeros(nobj,2);  % Size is commented out intentionally
            obj.Label = cell(1,nobj);

            switch class(taskobj)
                case 'struct'
                    for m=1:nobj
                        o = taskobj(m);
                        switch lower(o.Type)
                            case 'gen'
                                o.Name = validate_path(o.Name);
                                if ~isempty(o.Name)
                                    func = get_function_handle(o.Name);
                                    info = [];
                                    if 1==nargin(func)
                                        switch nargout(func)
                                            case 2, [imdata,info] = func(TrialRecord);
                                            case 3, imdata = func(TrialRecord);
                                            case 4, [imdata,~,~,info] = func(TrialRecord);
                                            otherwise, imdata = func(TrialRecord);
                                        end
                                    else
                                        switch nargout(func)
                                            case 2, [imdata,info] = func(TrialRecord,MLConfig);
                                            case 3, imdata = func(TrialRecord,MLConfig);
                                            case 4, [imdata,~,~,info] = func(TrialRecord,MLConfig);
                                            otherwise, imdata = func(TrialRecord,MLConfig);
                                        end
                                    end
                                    if ischar(imdata)
                                        imdata = validate_path(imdata);
                                        if ~isempty(imdata)
                                            [~,~,e] = fileparts(imdata);
                                            if strcmpi(e,'.gif'), if 1==length(imfinfo(imdata)), e = 'static_gif'; else, e = 'animated_gif'; end, end
                                            switch lower(e)
                                                case {'.bmp','.jpg','.jpeg','.tif','.tiff','.png','static_gif'}
                                                    bits = mglimread(imdata);
                                                    if 3==size(bits,3) && isfield(info,'Colorkey'), obj.ID(m) = mgladdbitmap(bits,info.Colorkey); else, obj.ID(m) = mgladdbitmap(bits); end
                                                    obj.Modality(m) = 1;
                                                case {'.avi','.mpg','.mpeg','animated_gif'}
                                                    obj.ID(m) = mgladdmovie(imdata,0);
                                                    if isfield(info,'Looping'), mglsetproperty(obj.ID(m),'looping',info.Looping); end
                                                    obj.Modality(m) = 2;
%                                                 case {'.m',''}
%                                                     obj.ID(m) = NaN;
%                                                     obj.Modality(m) = 3;
                                            end
                                        end
                                    else
                                        switch ndims(imdata)
                                            case 2
                                                if isfield(info,'Colorkey'), obj.ID(m) = mgladdbitmap(repmat(imdata,[1 1 3]),info.Colorkey); else, obj.ID(m) = mgladdbitmap(repmat(imdata,[1 1 3])); end
                                                obj.Modality(m) = 1;
                                            case 3
                                                if 3==size(imdata,3) && isfield(info,'Colorkey'), obj.ID(m) = mgladdbitmap(imdata,info.Colorkey); else, obj.ID(m) = mgladdbitmap(imdata); end
                                                obj.Modality(m) = 1;
                                            case 4
                                                if isfield(info,'TimePerFrame'), obj.ID(m) = mgladdmovie(imdata,info.TimePerFrame); else, obj.ID(m) = mgladdmovie(imdata,MLConfig.Screen.FrameLength); end
                                                if isfield(info,'Looping'), mglsetproperty(obj.ID(m),'looping',info.Looping); end
                                                obj.Modality(m) = 2;
                                        end
                                    end
                                end
                                if isnan(obj.ID(m)), obj.ID(m) = mdqmex(2,6,[0 255 0]',obj.Size(m,:),2); obj.Modality(m) = 1; end
                            case {'fix','dot'}
                                obj.ID(m) = load_cursor(MLConfig.FixationPointImage,MLConfig.FixationPointShape,MLConfig.FixationPointColor,MLConfig.PixelsPerDegree(1)*MLConfig.FixationPointDeg,3);
                                obj.Modality(m) = 1;
                            case 'pic'
                                o.Name = validate_path(o.Name);
                                if ~isempty(o.Name)
                                    if isfield(o,'Xsize') && isfield(o,'Ysize'), imdata = mglimresize(mglimread(o.Name),[o.Ysize o.Xsize]); else, imdata = mglimread(o.Name); end
                                    if 3==size(imdata,3) && isfield(o,'Colorkey'), obj.ID(m) = mgladdbitmap(imdata,o.Colorkey); else, obj.ID(m) = mgladdbitmap(imdata); end
                                    obj.Modality(m) = 1;
                                else
                                    obj.ID(m) = mdqmex(2,6,[0 255 0]',obj.Size(m,:),2);
                                    obj.Modality(m) = 1;
                                end
                            case 'crc'
                                obj.ID(m) = mgladdbitmap(make_circle(MLConfig.PixelsPerDegree(1)*o.Radius,o.Color,o.FillFlag));
                                obj.Modality(m) = 1;
                            case 'sqr'
                                obj.ID(m) = mgladdbitmap(make_rectangle([o.Xsize o.Ysize]*MLConfig.PixelsPerDegree(1),o.Color,o.FillFlag));
                                obj.Modality(m) = 1;
                            case 'mov'
                                o.Name = validate_path(o.Name);
                                if isempty(o.Name)
                                    obj.ID(m) = mdqmex(2,6,[0 255 0]',obj.Size(m,:),2);
                                    obj.Modality(m) = 1;
                                else
                                    obj.ID(m) = mgladdmovie(o.Name,0);
                                    if isfield(o,'Looping') && o.Looping, mglsetproperty(obj.ID(m),'looping',true); end
                                    obj.Modality(m) = 2;
                                end
                            case 'snd'
                                if isfield(o,'Name') && ~isempty(o.Name)
                                    if strcmpi(o.Name,'sin'), obj.Label{m} = sprintf('Sine %g kHz',o.Freq/1000); else, [~,n,e] = fileparts(o.Name); obj.Label{m} = [n e]; end
                                else
                                    obj.Label{m} = 'Wave sound';
                                end
                                obj.Modality(m) = 3;
                            case 'stm', obj.Label{m} = sprintf('Stimulation %d',o.OutputPort); obj.Modality(m) = 4;
                            case 'ttl', obj.Label{m} = sprintf('TTL %d',o.OutputPort); obj.Modality(m) = 5;
                        end
                    end
                case 'cell'
                    for m=1:nobj
                        a = taskobj{m};
                        switch lower(a{1})
                            case 'gen'
                                a{2} = validate_path(a{2});
                                if ~isempty(a{2})
                                    func = get_function_handle(a{2});
                                    info = [];
                                    if 1==nargin(func)
                                        switch nargout(func)
                                            case 2, [imdata,info] = func(TrialRecord);
                                            case 3, imdata = func(TrialRecord);
                                            case 4, [imdata,~,~,info] = func(TrialRecord);
                                            otherwise, imdata = func(TrialRecord);
                                        end
                                    else
                                        switch nargout(func)
                                            case 2, [imdata,info] = func(TrialRecord,MLConfig);
                                            case 3, imdata = func(TrialRecord,MLConfig);
                                            case 4, [imdata,~,~,info] = func(TrialRecord,MLConfig);
                                            otherwise, imdata = func(TrialRecord,MLConfig);
                                        end
                                    end
                                    if ischar(imdata)
                                        imdata = validate_path(imdata);
                                        if ~isempty(imdata)
                                            [~,~,e] = fileparts(imdata);
                                            if strcmpi(e,'.gif'), if 1==length(imfinfo(imdata)), e = 'static_gif'; else, e = 'animated_gif'; end, end
                                            switch lower(e)
                                                case {'.bmp','.jpg','.jpeg','.tif','.tiff','.png','static_gif'}
                                                    bits = mglimread(imdata);
                                                    if 3==size(bits,3) && isfield(info,'Colorkey'), obj.ID(m) = mgladdbitmap(bits,info.Colorkey); else, obj.ID(m) = mgladdbitmap(bits); end
                                                    obj.Modality(m) = 1;
                                                case {'.avi','.mpg','.mpeg','animated_gif'}
                                                    obj.ID(m) = mgladdmovie(imdata,0);
                                                    if isfield(info,'Looping'), mglsetproperty(obj.ID(m),'looping',info.Looping); end
                                                    obj.Modality(m) = 2;
%                                                 case {'.m',''}
%                                                     obj.ID(m) = NaN;
%                                                     obj.Modality(m) = 3;
                                            end
                                        end
                                    else
                                        switch ndims(imdata)
                                            case 2
                                                if isfield(info,'Colorkey'), obj.ID(m) = mgladdbitmap(repmat(imdata,[1 1 3]),info.Colorkey); else, obj.ID(m) = mgladdbitmap(repmat(imdata,[1 1 3])); end
                                                obj.Modality(m) = 1;
                                            case 3
                                                if 3==size(imdata,3) && isfield(info,'Colorkey'), obj.ID(m) = mgladdbitmap(imdata,info.Colorkey); else, obj.ID(m) = mgladdbitmap(imdata); end
                                                obj.Modality(m) = 1;
                                            case 4
                                                if isfield(info,'TimePerFrame'), obj.ID(m) = mgladdmovie(imdata,info.TimePerFrame); else, obj.ID(m) = mgladdmovie(imdata,MLConfig.Screen.FrameLength); end
                                                if isfield(info,'Looping'), mglsetproperty(obj.ID(m),'looping',info.Looping); end
                                                obj.Modality(m) = 2;
                                        end
                                    end
                                end
                                if isnan(obj.ID(m)), obj.ID(m) = mdqmex(2,6,[0 255 0]',obj.Size(m,:),2); obj.Modality(m) = 1; end
                            case {'fix','dot'}
                                obj.ID(m) = load_cursor(MLConfig.FixationPointImage,MLConfig.FixationPointShape,MLConfig.FixationPointColor,MLConfig.PixelsPerDegree(1)*MLConfig.FixationPointDeg,3);
                                obj.Modality(m) = 1;
                            case 'pic'
                                a{2} = validate_path(a{2});
                                if ~isempty(a{2})
                                    if 5<length(a), imdata = mglimresize(mglimread(a{2}),[a{6} a{5}]); else, imdata = mglimread(a{2}); end
                                    if 3==size(imdata,3) && 3==length(a{end}), obj.ID(m) = mgladdbitmap(imdata,a{end}); else, obj.ID(m) = mgladdbitmap(imdata); end
                                    obj.Modality(m) = 1;
                                else
                                    obj.ID(m) = mdqmex(2,6,[0 255 0]',obj.Size(m,:),2);
                                    obj.Modality(m) = 1;
                                end
                            case 'crc'
                                obj.ID(m) = mgladdbitmap(make_circle(MLConfig.PixelsPerDegree(1)*a{2},a{3},a{4}));
                                obj.Modality(m) = 1;
                            case 'sqr'
                                obj.ID(m) = mgladdbitmap(make_rectangle(MLConfig.PixelsPerDegree(1)*a{2},a{3},a{4}));
                                obj.Modality(m) = 1;
                            case 'mov'
                                a{2} = validate_path(a{2});
                                if isempty(a{2})
                                    obj.ID(m) = mdqmex(2,6,[0 255 0]',obj.Size(m,:),2);
                                    obj.Modality(m) = 1;
                                else
                                    obj.ID(m) = mgladdmovie(a{2},0);
                                    if 4<length(a) && a{5}, mglsetproperty(obj.ID(m),'looping',true); end
                                    obj.Modality(m) = 2;
                                end
                            case 'snd'
                                if 2==length(a), [~,n,e] = fileparts(a{2}); obj.Label{m} = [n e]; else, obj.Label{m} = sprintf('Sine %g kHz',a{3}/1000); end
                                obj.Modality(m) = 3;
                            case 'stm', obj.Label{m} = sprintf('Stimulation %d',a{2}); obj.Modality(m) = 4;
                            case 'ttl', obj.Label{m} = sprintf('TTL %d',a{2}); obj.Modality(m) = 5;
                        end
                    end
            end
            mglactivategraphic(obj.ID,false);
        end
    end
    
    methods (Access = protected)
        function cp = copyElement(obj)
            cp = copyElement@matlab.mixin.Copyable(obj);
            cp.DestroyObject = false;
        end
        function dest = copyfield(~,dest,src,field)
            if isempty(src), src = struct; end
            if isempty(dest), dest = struct; end
            if ~exist('field','var'), field = fieldnames(src); end
            for m=1:length(field), dest.(field{m}) = src.(field{m}); end
        end
        function val = getScreenPosition(obj,Position)
            n = size(Position,1);
            val = round(Position .* repmat(obj.PixelsPerDegree,n,1)) + repmat(obj.SubjectScreenHalfSize,n,1);
        end
    end
end
