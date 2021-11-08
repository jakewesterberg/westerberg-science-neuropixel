function [I, Istr, Tab]=getI2(IDX,goodBi,goodDi, goodAll)

alpha = 0.05; 

kls = find([IDX.kls]);

M = zeros(length(IDX),1);
I = false(length(IDX),3);
K = false(length(IDX),1);

for u = 1:length(kls); 
    clear occ eye
    
    if ~any(isnan(IDX(kls(u)).dianov))
        % can use dianov to determin selectivity
       eye =  IDX(kls(u)).dianov(1) < alpha; 
       ori = IDX(kls(u)).dianov(2) < alpha;
       M(kls(u)) = 1; 
       K(kls(u)) = true;
       
    elseif ~isnan(IDX(kls(u)).prefeye)
        % have to use tuning test
        eye = IDX(kls(u)).occ(1) < alpha;        
        ori = IDX(kls(u)).ori(2) < alpha;
        M(kls(u)) = 2;
         K(kls(u)) = true;
    else
        continue
    end
    
     both = eye & ori; 
     if both 
         eye = false; 
         ori = false;
     end
     
    I(kls(u),1) = both; % selective to ori and eye
    I(kls(u),2) = ori; % selective to ori but not eye
    I(kls(u),3) = eye; % selective to eye but not ori
    
    
end

Istr = {...
    'effect of ori and eye';...
    'effect of ori but not eye';...
    'effect of eye but not ori';...
    };


clear T
%cellfun(@(x) x(8), {IDX.penetration})';
good = [goodBi;goodDi;goodDi | goodBi; goodAll];
coln = {'Pen','Units','Sig Resp to Eye or Ori','Both','Ori Only','Eye Only','Method2'};        
for r = 1:4
    for c = 1:length(coln)
        clear II n
        switch coln{c}
            case 'Pen'
                II = K & good(r,:)';
                n = length(unique({IDX(II).penetration}));
            case 'Units'
                II = K & good(r,:)';
                n = sum(II);
            case 'Sig Resp to Eye or Ori'
                II = any(I,2) & good(r,:)';
                n = sum(II);
            case 'Both'
                II = I(:,1) & good(r,:)';
                n = sum(II);
            case 'Ori Only'
                II = I(:,2) & good(r,:)';
                n = sum(II);
            case 'Eye Only'
                II = I(:,3) & good(r,:)';
                n = sum(II);
            case 'Method2'
                II = good(r,:);
                n = sum(M(II) == 2) ; 
        end
        T(r,c) = n;
    end
end

Tab.rows = {'Congruent','Incongruent','OR','AND'};
Tab.col = coln; 
Tab.n = T; 
