function [b,yCalc,R,p]= myLinearRegression(x,y)

% NOV 7
% DOES NOT WORK WITH DUPLICATE X DATA AT THE MOMENT

if size(x,2) ~= 1 
    x = x';
end
if size(y,2) ~= 1 
    y = y';
end

% remove NaN
exclude = any(isnan([x y]),2);
x = x(~exclude); y = y(~exclude);

% sort 
[x, I]= sort(x);
y = y(I);

% calculat regression
X = [ones(length(x),1) x];
b = X\y;

yCalc = X*b;

R = 1 - sum((y - yCalc).^2)/sum((y - mean(y)).^2);
[~,P] = corrcoef(x,y);
p = P(2);
