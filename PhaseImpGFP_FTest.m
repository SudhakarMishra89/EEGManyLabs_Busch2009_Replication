function [] = PhaseImpGFP_FTest(var, hit_r, gfp)

    
    % Fit a multiple linear regression model
    mdl = fitlm(hit_r, gfp);
    
    % Perform F-test for overall significance
    anovaResults = anova(mdl, 'summary');
    
    % Extract F-statistic and p-value
    f_statistic = anovaResults.F(2);
    p_value = anovaResults.pValue(2);
    
    % Display F-test results
    disp(['F-Statistic: ' num2str(f_statistic)]);
    disp(['P-Value: ' num2str(p_value)]);
end