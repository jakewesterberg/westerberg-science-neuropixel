function data_out = computecsd(data_in, varargin)

cndt            = 0.0004;
spc             = .02; % in mm

varStrInd = find(cellfun(@ischar,varargin));
for iv = 1:length(varStrInd)
    switch varargin{varStrInd(iv)}
        case {'cndt'}
            cndt = varargin{varStrInd(iv)+1};
        case {'spc'}
            spc = varargin{varStrInd(iv)+1};
    end
end

data_out = nan(size(data_in));

for i_trial = 1 : size(data_in,3)
    
    t_csd_1     = data_in(:,:,i_trial);
    t_csd_2     = data_in(:,:,i_trial);
    nChan       = size( t_csd_2, 1 ) * spc;
    dChan       = spc : spc : nChan;
    nE = length( dChan );
    d = mean( diff( dChan ) );
    
    t_csd_2 = [];
    for i = 1 : nE - 2
        for j = 1 : nE
            if i == (j - 1)
                t_csd_2( i, j ) = -2 / d^2;
            elseif abs( i - j + 1) == 1
                t_csd_2( i, j ) = 1 / d^2;
            else
                t_csd_2( i, j ) = 0; 
            end
        end
    end

    data_out(2:end-1,:,i_trial) = -cndt * t_csd_2 * t_csd_1;
    data_out(2:end-1,:,i_trial) = data_out(2:end-1,:,i_trial) .* 1000; % uA/mm3 to nA/mm3

end
end