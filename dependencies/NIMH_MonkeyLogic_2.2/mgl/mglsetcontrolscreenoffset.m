function mglsetcontrolscreenoffset(offset)

if ~exist('offset','var'), offset = [0 0]; end
if 2~=numel(offset), error('offset must be [x y].'); end

mdqmex(1,108,int32(offset));
