function [] = PhaseImpInteract(att_phase, Uatt_phase, att_DV, Uatt_DV)
    tableA = table(att_phase, att_DV, repmat(1, length(att_phase), 1));    
    tableU = table(Uatt_phase, Uatt_DV, repmat(0, length(Uatt_phase),1));
    combTable = [tableA.Variables;tableU.Variables];
    Table_ = table(combTable(:,1), combTable(:,2), combTable(:,3), 'VariableNames', {'Phase', 'DV', 'Cond'});

    mdl = fitlm(Table_, 'DV ~ Phase * Cond');
    
    % Perform F-test for overall significance
    anovaResults = anova(mdl, 'summary');
    
    % Extract F-statistic and p-value
    f_statistic = anovaResults.F(2);
    p_value = anovaResults.pValue(2);
    
    % Display F-test results
    disp(['F-Statistic: ' num2str(f_statistic)]);
    disp(['P-Value: ' num2str(p_value)]);
end