function str = statstr(type,varargin)

switch type 
    case 'corrcoef' 
        % Correlations are reported with the degrees of freedom (which is N-2) in parentheses and the significance level:
        % The two variables were strongly correlated, r(55) = .49, p < .01.
        str = sprintf('r(%u) = %0.3f, p = %0.3f',varargin{3}-2,varargin{1},varargin{2});
    case 'myLinearRegression'
        str = sprintf('f(x) = %0.3fx + %0.3f',varargin{1}(2),varargin{1}(1));
    case 'K-S'
         str = sprintf('D = %0.3f, p = %0.3f',varargin{1},varargin{2});
    case 'ttest'
        str = sprintf('t(%u) = %0.3f, p = %0.3f',varargin{1}.df,varargin{1}.tstat,varargin{2});
end

% 
% Chi-Square statistics are reported with degrees of freedom and sample size in parentheses, the Pearson chi-square value (rounded to two decimal places), and the significance level:
% 
% The percentage of participants that were married did not differ by gender, c2(1, N = 90) = 0.89, p = .35.
% 
% 
% T Tests are reported like chi-squares, but only the degrees of freedom are in parentheses. Following that, report the t statistic (rounded to two decimal places) and the significance level.
% 
% There was a significant effect for gender, t(54) = 5.43, p < .001, with men receiving higher scores than women.
% 
% 
% ANOVAs (both one-way and two-way) are reported like the t test, but there are two degrees-of-freedom numbers to report. First report the between-groups degrees of freedom, then report the within-groups degrees of freedom (separated by a comma). After that report the F statistic (rounded off to two decimal places) and the significance level.
% 
% There was a significant main effect for treatment, F(1, 145) = 5.43, p = .02, and a significant interaction, F(2, 145) = 3.24, p = .04.
% 
% 
% 
% 
% 
% Regression results are often best presented in a table. APA doesn't say much about how to report regression results in the text, but if you would like to report the regression in the text of your Results section, you should at least present the unstandardized or standardized slope (beta), whichever is more interpretable given the data, along with the t-test and the corresponding significance level. (Degrees of freedom for the t-test is N-k-1 where k equals the number of predictor variables.) It is also customary to report the percentage of variance explained along with the corresponding F test.
% Social support significantly predicted depression scores, b = -.34, t(225) = 6.53, p < .001. Social support also explained a significant proportion of variance in depression scores, R2 = .12, F(1, 225) = 42.64, p < .001.
% 


