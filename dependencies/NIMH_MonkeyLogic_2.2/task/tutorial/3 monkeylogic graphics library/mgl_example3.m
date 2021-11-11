% This is not a NIMH ML task but a MATLAB script to explain how to use MGL
% functions directly.

base_folder = [fileparts(which('monkeylogic')) filesep];
addpath([base_folder 'daqtoolbox']);
addpath([base_folder 'mgl']);

err = [];
try
    max_adapter_count = mglgetadaptercount;
    mglcreatesubjectscreen(max_adapter_count,[0 0 0],[0 0 1024 768],false);
    rect = mglgetadapterrect(1);
    mglcreatecontrolscreen([rect(3)-512 rect(2) rect(3) rect(2)+384]);
    
    % add a movie
    mov = mgladdmovie([base_folder 'initializing.avi']);
    for m=0:60
        mglrendergraphic(m);  % frame number
        mglpresent;
    end

    % add a circle
    % Static objects are not affected by frame number
    crc = mgladdcircle([0 1 0; 1 0 0],[200 100]);
    mglsetproperty(crc,'origin',[300 300],'angle',45,'scale',2);
%     mglsetproperty(mov,'seek',0);  % streamed movies need rewinding
    for m=0:60
        mglrendergraphic(m);
        mglpresent;
    end
    
catch err
end

mgldestroycontrolscreen;  % mov and crc will be destroyed here
mgldestroysubjectscreen;

if ~isempty(err), rethrow(err); end
