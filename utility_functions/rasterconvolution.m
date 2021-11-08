function data_out = rasterconvolution( data_in, krnl, fs )

if ndims( data_in ) == 2

    tmp = size( data_in );
    data_out = nan(size(data_in));
    for i = 1 : tmp( 1 )
        data_out( i, : ) = convList( data_in( i, : ), krnl );
    end

else
    data_out = convList(l,k);
end
end

data_out = data_out .* fs;

%--------------------------------------------------

function cl = convList(l,k)
    
  hlen    = floor(length(k)/2);
  llen    = length(l);	
  begmean = mean(l(1:hlen))*ones(1,hlen);
  endmean = mean(l(llen-hlen:llen))*ones(1,hlen);
  ltmp    = [begmean l endmean]; 	
  tmp     = conv(ltmp,k);
  start   = round(length(k)-1);
  finish  = start+length(l)-1;
  cl      = tmp([start:finish]); 

end

