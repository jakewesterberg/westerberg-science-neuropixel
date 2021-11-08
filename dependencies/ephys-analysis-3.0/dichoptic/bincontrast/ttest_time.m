function [h, p, stats] = ttest_time(A, B)

%A = ALL.MON.DE_PS.supra.SDF; % contrast x time x units
%B = ALL.BIN.PS.supra.SDF; % contrast x time x units

if any((size(A) == size(B)) == 0)
    error('Matrix dim not the same size')
end

h = nan(size(A, 1), size(A, 2));
p = nan(size(A, 1), size(A, 2));
stats = nan(size(A, 1), size(A, 2));

for i = 1 : size(A,1)
    
    temp_a = squeeze(A(i,:,:));
    temp_b = squeeze(B(i,:,:));
    
    for k = 1 : size(temp_a, 1)
        
        [h(i,k), p(i,k)] = ttest(temp_a(k,:), temp_b(k,:),'alpha',0.01);
        
    end
end

end