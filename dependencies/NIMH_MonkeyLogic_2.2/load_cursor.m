function [imdata,imagefile,modality] = load_cursor(imagefile, shape, color, sz, device, fill)

modality = 0;
if ~isempty(imagefile) && 2~=exist(imagefile,'file'), imagefile = ''; end
if ~exist('fill','var'), fill = 1; end

[~,~,e] = fileparts(imagefile);
switch lower(e)
    case ''
        modality = 1;
        switch lower(shape)
            case {1,'circle'}, imdata = make_circle(sz,color,fill);
            otherwise, imdata = make_rectangle(sz,color,fill);
        end
    case {'.bmp','.gif','.jpg','.jpeg','.tif','.tiff','.png'}
        modality = 1;
        imdata = mglimread(imagefile);
    case {'.avi','.mpg','.mpeg'}
        modality = 2;
        imdata = mglimread(imagefile);
end

if exist('device','var')
   switch modality
       case 1
           imdata = mgladdbitmap(imdata,device);
       case 2
           imdata = mgladdmovie(imagefile,[],device);
           mglsetproperty(imdata,'looping',true);
   end
end
