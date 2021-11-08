function krnl = defkernel(kType, kWidth, fs)


if exist( 'kType', 'var' ) == false || isempty( kType ) == true
    kType = 'psp';
end

if exist( 'kWidth', 'var' ) == false || isempty( kWidth ) == true
    kWidth = 0.02;
end

kWidth = kWidth * fs;

switch lower( kType )

    case 'gauss'
        
        Half_BW = round( 4 * kWidth );
        x = -Half_BW : Half_BW;
        krnl = ( 1 / ( sqrt( 2 * pi ) * kWidth ) ) * ...
            exp( -1 * ( ( x.^2 ) / ( 2 * kWidth^2 ) ) );
        
    case 'psp'
        
        if length( kWidth ) == 2
            tg = kWidth( 2 );
            kWidth( 2 ) = []; 
        else
            tg = 1;
        end 
      
        Half_BW = ceil( kWidth * 8 );
        x = 0 : Half_BW;
        krnl = [ zeros( 1, Half_BW ), ...
            ( 1 - ( exp( -( x ./ tg ) ) ) ) .* ( exp( -( x ./ kWidth) ) ) ];
      
end

krnl = krnl - krnl( end );
krnl( krnl < 0 ) = 0;
krnl = krnl / sum( krnl );

end 
