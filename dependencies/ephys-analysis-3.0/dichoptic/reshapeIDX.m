function [IDX, eyestr,...
    Mo, Bi, Di, dBi, dDi, TM, DEPTH,...
    goodBi, goodDi, goodAll,...
     sBi, sDi, sOi,...
     diwin, dimeasures] = reshapeIDX(deltaC,SDF,alpha,IDXdir,IDXname)

if nargin == 0
    SDF = 'SDF';
    alpha = 0.05;
    deltaC = 1;
    IDXdir = 'G:\LaCie';
    IDXname = 'IDXadaptdcos_191109.mat';
end

load([ IDXdir filesep IDXname]);
diwin        = flipud(IDX(1).statwin);
dimeasures   = {'mc','tstat','sigdir'};

if deltaC == 0
    c = [0 0];
%     mstr = '[full contrast, blank]';
%     dstr = '[full contrast, full contrast]';
    eyestr = 'DE at full contrast, NDE at full';
else
    c = [3 2];
%     mstr = '[1/2 contrast, blank]';
%     dstr = '[1/2 contrast, full contrast]';
    eyestr = 'DE at 1/2 contrast, NDE at full';
end

% setup SDF vars
clear *Mo* *Bi* *Di* *Oi* DEPTH TM R
for i = 1:length(IDX);
    Mo(i,:) = IDX(i).(SDF)(1+c(1), :); % SDF row 4 = half contrast in DE, max contrast in NDE, Monocular
    Bi(i,:) = IDX(i).(SDF)(2+c(1), :); % SDF row 5 = half contrast in DE, max contrast in NDE, Binocular
    Di(i,:) = IDX(i).(SDF)(3+c(1), :);
    
    dBi(i,:) = IDX(i).(SDF)( 9+c(2), :); % SDF row 11 - half contrast DE, max contrast NDE binocular, - half contrast DE monocular
    dDi(i,:) = IDX(i).(SDF)(10+c(2), :); % SDF row 12
    
    DEPTH(i,:) =  IDX(i).depth(2);
    TM(i,:)    =  IDX(i).tm;
    
end

% extract good unints based on condition
clear good
goodBi  = ~all(isnan(dBi)');
goodDi  = ~all(isnan(dDi)');
goodAll = goodDi & goodBi;

% setup MC and TSTAT for windows
for w = 1:size(diwin,1)
    for m = 1:length(dimeasures)
        
        for i = 1:length(IDX);
            
            switch dimeasures{m}
                case 'mc'
                    
                    clear tm tmlim
                    tm = TM(i,:);
                    tmlim = tm >= diwin(w,1) & tm <= diwin(w,2);
                    sBi.(dimeasures{m}).dat(i,:,w) = nanmean(IDX(i).(SDF)( 9+c(2), tmlim)) ./ (nanmean(IDX(i).(SDF)(2+c(1), tmlim)) + nanmean(IDX(i).(SDF)(1+c(1), tmlim))) ;
                    sDi.(dimeasures{m}).dat(i,:,w) = nanmean(IDX(i).(SDF)(10+c(2), tmlim)) ./ (nanmean(IDX(i).(SDF)(3+c(1), tmlim)) + nanmean(IDX(i).(SDF)(1+c(1), tmlim)));
                    sOi.(dimeasures{m}).dat(i,:,w) = ...
                        (nanmean(IDX(i).(SDF)(2+c(1), tmlim)) - nanmean(IDX(i).(SDF)(3+c(1), tmlim)))...
                        ./ (nanmean(IDX(i).(SDF)(2+c(1), tmlim)) + nanmean(IDX(i).(SDF)(3+c(1), tmlim)));
                    
                case 'tstat'
                    
                    window = ismember(IDX(i).statwin,diwin(w,:));
                    [a,~]  = find(window);
                    a = unique(a);
                    sBi.(dimeasures{m}).dat(i,:,w) = IDX(i).distats(1 + c(1)  + (a-1)*12);
                    sDi.(dimeasures{m}).dat(i,:,w) = IDX(i).distats(2 + c(1)  + (a-1)*12);
                    sOi.(dimeasures{m}).dat(i,:,w) = IDX(i).distats(3 + c(1)  + (a-1)*12);
                    
                    sBi.('pvalue').dat(i,:,w) = IDX(i).distats(7 + c(1)  + (a-1)*12);
                    sDi.('pvalue').dat(i,:,w) = IDX(i).distats(8 + c(1)  + (a-1)*12);
                    sOi.('pvalue').dat(i,:,w) = IDX(i).distats(9 + c(1)  + (a-1)*12);
                    
                    
                case 'sigdir'
                    % -2 = negative and sig, -1 = negative and non sig
                    % +2 = positive and sig, +1 = positive and non sig
                    clear bi di
                    bi = [...
                        sign(IDX(i).distats(1 + c(1)  + (a-1)*12)) ...
                        (IDX(i).distats(7 + c(1)  + (a-1)*12) < alpha)+1 ...
                        ];
                    sBi.(dimeasures{m}).dat(i,:,w) = bi(1)*bi(2);
                    clear bi di
                    di = [...
                        sign(IDX(i).distats(2 + c(1)  + (a-1)*12)) ...
                        (IDX(i).distats(8 + c(1)  + (a-1)*12) < alpha)+1 ...
                        ];
                    sDi.(dimeasures{m}).dat(i,:,w) = di(1)*di(2);
            end
        end
    end
end