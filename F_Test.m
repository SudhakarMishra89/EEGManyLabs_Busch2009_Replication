% Assuming you have a response variable 'data' and a grouping variable 'group'
% 'group' should be a categorical variable indicating the conditions and levels

% Example data:
data = [rand(10,1);rand(10,1);rand(10,1);rand(10,1)];
group = [repmat({'Condition 1 - Group 1'}, 10, 1);
         repmat({'Condition 1 - Group 2'}, 10, 1);
         repmat({'Condition 2 - Group 1'}, 10, 1);
         repmat({'Condition 2 - Group 2'}, 10, 1)];

% Perform one-way ANOVA
p_value = anova1(data, group, 'off');  % 'off' suppresses the table output

% Display p-value
disp('One-way ANOVA p-value:');
disp(p_value);
