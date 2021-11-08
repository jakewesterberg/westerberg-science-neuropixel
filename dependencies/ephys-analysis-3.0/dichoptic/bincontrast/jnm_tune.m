function [ fit_out, best_mod ] = jnm_tune( n_dat, o_dat, params )

params.o_bin = 10;
params.t_min = 3;
params.ctm = 'mean';

fo = fitoptions( 'gauss1');
lim = 1000000000000000000000000000000000000000;
fo.lower = [-lim -lim -lim];
fo.upper = [lim lim lim];

tilts = unique( o_dat );
%t_sep = abs( tilts(1) - tilts(2) );
%t_vec = 0 : t_sep : numel(tilts) * t_sep - t_sep;
t_vec = unique(tilts);

if any(tilts > 179)
    for i = 1 : length( o_dat)
        if o_dat(i) == 360
            o_dat(i) = 0;
        elseif o_dat(i) > 179
            o_dat(i) = o_dat(i) - 180;
            
        end
    end
end

[u2, bad1, bad2] = grpstats(n_dat, o_dat, {'mean','sem','gname'});
S2 = anovan(n_dat,{o_dat},'display','off') < 0.05; % logical for signficance
[~,mi2]= max(u2);
TH2 = tilts(mi2);

if S2 == 0
    disp('NO TUNING');
    fit_out = NaN;
end

for i = 1 : numel(tilts) 
    if strcmp( params.ctm, 'med' )
        t_m(i) = nanmedian( n_dat( :, o_dat == tilts(i) ) );
    else
        t_m(i) = nanmean( n_dat( :, o_dat == tilts(i) ) );
    end
    t_num(i) = sum( o_dat == tilts(i) );
    t_ident(i) = tilts(i);
end

for i = 1 : numel( tilts )
   
    fit_m{i}.dat = t_m;
    
    fit_m{i}.num = t_num;
    
    fit_m{i}.ident = t_ident;
    
    fit_m{i}.vec = t_vec;
    
    fo.exclude = find(t_num < params.t_min);
    
    [ fit_m{i}.f, fit_m{i}.gof ] = fit( t_vec.', t_m.', ...
        'gauss1', fo );
    
%    plot( fit_m{i}.f, t_vec, t_m, fo.exclude )
    
    fit_m{i}.feval = feval( fit_m{i}.f, t_vec );
    pe = findpeaks( fit_m{i}.feval );
    
    if ~isempty(pe)
        fit_m{i}.n_peaks = numel( pe );
    else
        fit_m{i}.n_peaks = 0;
    end
    
    t_m = [ t_m(end) t_m(1:end-1) ];
    t_num = [ t_num(end) t_num(1:end-1) ];
    t_ident = [ t_ident(end) t_ident(1:end-1) ];
    
end

for i = 1 : numel( tilts )
    
    rs(i) = fit_m{i}.gof.adjrsquare;
    ps(i) = fit_m{i}.n_peaks;
    
end

best_mod = find( max( rs( ps == 1 ) ) == rs, 1 );

peak_ind = find( max( fit_m{best_mod}.feval ) == fit_m{best_mod}.feval );

pref = fit_m{best_mod}.ident(peak_ind);

test = o_dat;

tryin = abs(pref-test);
tryin2=tryin>90;
tryin3=tryin(tryin2)-90;
tryin4=tryin(tryin2)-(2.*tryin3);
tryin(tryin2)=tryin4;

upd = tryin;

tilts = unique( upd );
%t_sep = abs( tilts(1) - tilts(2) );
%t_vec = -(max(tilts)) : t_sep : numel(tilts) * t_sep - t_sep;
t_vec = unique(tilts);

clear t_m

for i = 1 : numel(tilts) 
    if strcmp( params.ctm, 'med' );
        t_m(i) = nanmedian( n_dat( :, upd == tilts(i) ) );
    else
        t_m(i) = nanmean( n_dat( :, upd == tilts(i) ) );
    end 
end

t_m = cat(2, fliplr(t_m(2:end)), t_m);
t_vec = cat(2, -(fliplr(t_vec(2:end))), t_vec);

fit_o.alldat = n_dat;
fit_o.occdat = upd;
fit_o.tilts = tilts;

fit_o.dat = t_m;
fit_o.num = t_num;
fit_o.ident = t_ident;
fit_o.vec = t_vec;
fo.exclude = find(t_num < params.t_min);


[ fit_o.f, fit_o.gof ] = fit( t_vec.', t_m.', ...
    'gauss1', fo );

%plot( fit_o{i}.f, t_vec, t_m, fo.exclude )

fit_o.feval = feval( fit_o.f, t_vec );
pe = findpeaks( fit_o.feval );
fit_o.n_peaks = numel( pe );
fit_o.fo = fo;

%{
make_vec = 1;
make_change = 0;
i = 0;
while make_vec == 1
   
    i = i + 1;
    vec_r(i) = pref + (i-1) * t_sep;
    
    if vec_r(i) >= 180
        if make_change == 0
            make_change = i;
        end
        vec_r(i) = 0 ;
    end
end

make_vec = 1;
i = 0;
while make_vec == 1
   
    i = i + 1;
    vec_l(i) = pref - (i-1) * t_sep;
    
    if vec_r(i) < 0
        
    end
    
    if vec
end

lr = peak_ind > numel( t_vec ) / 2;

l = length( t_vec( 1 : peak_ind - 1 ) );
r = length( t_vec( peak_ind + 1 : end ) );

if lr
   
    for i = peak_ind - 1 : -1 : 1
    end
    
else
    
    for i = peak_ind : 1 : numel( t_vec )
    end
    
end
%}

fit_o.sig = S2;
fit_o.pref = mi2;
fit_out = fit_o;

end

