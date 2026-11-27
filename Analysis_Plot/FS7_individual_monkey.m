clear;clc;close all
load root_dir.mat
output_directory = fullfile(root_dir, 'Data', 'FS7');
result_path = fullfile(output_directory, 'MonkeyExactPanelReplication.mat');
load(result_path, 'summary_table', 'monkey_names', 'f2_matching_distance', 'f2_nonmatching_distance', 'f2_tvd', 'f3_raw', 'f4_bias')

monkey_labels = {'J', 'Z', 'C'};
first_color = [0.82, 0.25, 0.20];
second_color = [0.20, 0.40, 0.82];
single_color = [0.35, 0.55, 0.75];
paired_positions = [0.8, 1.2, 1.8, 2.2, 2.8, 3.2];
paired_colors = [first_color; second_color; first_color; second_color; first_color; second_color];
empty_pair_labels = {'', '', '', '', '', ''};
empty_single_labels = {'', '', ''};

figure('Position', [20, 110, 2000, 380]);
subplot(1, 4, 1)
subplot(1, 4, 2)
subplot(1, 4, 3)
subplot(1, 4, 4)
%% Figure 2G
subplot(1, 4, 1); hold on
plot_values = [];
plot_groups = [];
monkey_maximum = zeros(3, 1);
for monkey_idx = 1:3
    matching_values = reshape(f2_matching_distance(monkey_idx, :, :), [], 1);
    nonmatching_values = reshape(f2_nonmatching_distance(monkey_idx, :, :), [], 1);
    valid_values = isfinite(matching_values) & isfinite(nonmatching_values);
    matching_values = matching_values(valid_values);
    nonmatching_values = nonmatching_values(valid_values);
    plot_values = [plot_values; matching_values; nonmatching_values];
    plot_groups = [plot_groups; repmat(paired_positions(2 * monkey_idx - 1), length(matching_values), 1); repmat(paired_positions(2 * monkey_idx), length(nonmatching_values), 1)];
    monkey_maximum(monkey_idx) = max([matching_values; nonmatching_values]);
end
boxplot(plot_values, plot_groups, 'Positions', paired_positions, 'Colors', paired_colors, 'Labels', empty_pair_labels, 'Symbol', '', 'Widths', 0.27, 'Whisker', 1.5)
bracket_y = max(monkey_maximum) + 9;
for monkey_idx = 1:3
    result_row = find(summary_table.Monkey == monkey_names(monkey_idx) & summary_table.Panel == "Figure 2G");
    x_1 = paired_positions(2 * monkey_idx - 1);
    x_2 = paired_positions(2 * monkey_idx);
    plot([x_1, x_1, x_2, x_2], [bracket_y - 2, bracket_y, bracket_y, bracket_y - 2], 'k-', 'LineWidth', 1)
    text(mean([x_1, x_2]), bracket_y + 3, sprintf('p = %.3g', summary_table.POneSided(result_row)), 'HorizontalAlignment', 'center', 'FontSize', 10)
end
matching_legend = plot(nan, nan, 's', 'MarkerSize', 10, 'MarkerFaceColor', first_color, 'MarkerEdgeColor', first_color);
nonmatching_legend = plot(nan, nan, 's', 'MarkerSize', 10, 'MarkerFaceColor', second_color, 'MarkerEdgeColor', second_color);
legend([matching_legend, nonmatching_legend], {'Matching', 'Nonmatching'}, 'Location', 'southwest', 'Box', 'off')
xticks(1:3); xticklabels(monkey_labels); xlim([0.5, 3.5]); ylim([0, max(monkey_maximum) + 30])
ylabel('Mean neuron distance (degree)'); title('A')
xlabel('Monkey')
%% Figure 2H
subplot(1, 4, 2); hold on
plot_values = [];
plot_groups = [];
monkey_maximum = zeros(3, 1);
for monkey_idx = 1:3
    anagram_values = repelem(squeeze(f2_tvd(monkey_idx, :, 1)), 2);
    anagram_values = anagram_values(:);
    exemplar_values = reshape(squeeze(f2_tvd(monkey_idx, :, 2:3))', [], 1);
    valid_values = isfinite(anagram_values) & isfinite(exemplar_values);
    anagram_values = anagram_values(valid_values);
    exemplar_values = exemplar_values(valid_values);
    plot_values = [plot_values; exemplar_values; anagram_values];
    plot_groups = [plot_groups; repmat(paired_positions(2 * monkey_idx - 1), length(exemplar_values), 1); repmat(paired_positions(2 * monkey_idx), length(anagram_values), 1)];
    monkey_maximum(monkey_idx) = max([exemplar_values; anagram_values]);
end
f2h_colors = [second_color; first_color; second_color; first_color; second_color; first_color];
boxplot(plot_values, plot_groups, 'Positions', paired_positions, 'Colors', f2h_colors, 'Labels', empty_pair_labels, 'Symbol', '', 'Widths', 0.27, 'Whisker', 1.5)
bracket_y = max(monkey_maximum) + 0.045;
for monkey_idx = 1:3
    result_row = find(summary_table.Monkey == monkey_names(monkey_idx) & summary_table.Panel == "Figure 2H");
    x_1 = paired_positions(2 * monkey_idx - 1);
    x_2 = paired_positions(2 * monkey_idx);
    plot([x_1, x_1, x_2, x_2], [bracket_y - 0.012, bracket_y, bracket_y, bracket_y - 0.012], 'k-', 'LineWidth', 1)
    text(mean([x_1, x_2]), bracket_y + 0.018, sprintf('p = %.3g', summary_table.POneSided(result_row)), 'HorizontalAlignment', 'center', 'FontSize', 10)
end
exemplar_legend = plot(nan, nan, 's', 'MarkerSize', 10, 'MarkerFaceColor', second_color, 'MarkerEdgeColor', second_color);
anagram_legend = plot(nan, nan, 's', 'MarkerSize', 10, 'MarkerFaceColor', first_color, 'MarkerEdgeColor', first_color);
legend([exemplar_legend, anagram_legend], {'Exemplar', 'Anagram'}, 'Location', 'southwest', 'Box', 'off')
xticks(1:3); xticklabels(monkey_labels); xlim([0.5, 3.5]); ylim([0, max(monkey_maximum) + 0.17])
ylabel('TVD'); title('B')
xlabel('Monkey')
%% Figure 3C
subplot(1, 4, 3); hold on
plot_values = [];
plot_groups = [];
monkey_maximum = zeros(3, 1);
for monkey_idx = 1:3
    matching_values = [squeeze(f3_raw(monkey_idx, :, 1, 1))'; squeeze(f3_raw(monkey_idx, :, 2, 2))'];
    nonmatching_values = [squeeze(f3_raw(monkey_idx, :, 2, 1))'; squeeze(f3_raw(monkey_idx, :, 1, 2))'];
    plot_values = [plot_values; matching_values; nonmatching_values];
    plot_groups = [plot_groups; repmat(paired_positions(2 * monkey_idx - 1), length(matching_values), 1); repmat(paired_positions(2 * monkey_idx), length(nonmatching_values), 1)];
    monkey_maximum(monkey_idx) = max([matching_values; nonmatching_values]);
end
boxplot(plot_values, plot_groups, 'Positions', paired_positions, 'Colors', paired_colors, 'Labels', empty_pair_labels, 'Symbol', '', 'Widths', 0.27, 'Whisker', 1.5)
bracket_y = max(monkey_maximum) + 0.025;
for monkey_idx = 1:3
    result_row = find(summary_table.Monkey == monkey_names(monkey_idx) & summary_table.Panel == "Figure 3C");
    x_1 = paired_positions(2 * monkey_idx - 1);
    x_2 = paired_positions(2 * monkey_idx);
    plot([x_1, x_1, x_2, x_2], [bracket_y - 0.007, bracket_y, bracket_y, bracket_y - 0.007], 'k-', 'LineWidth', 1)
    text(mean([x_1, x_2]), bracket_y + 0.009, sprintf('p = %.3g', summary_table.POneSided(result_row)), 'HorizontalAlignment', 'center', 'FontSize', 10)
end
matching_legend = plot(nan, nan, 's', 'MarkerSize', 10, 'MarkerFaceColor', first_color, 'MarkerEdgeColor', first_color);
nonmatching_legend = plot(nan, nan, 's', 'MarkerSize', 10, 'MarkerFaceColor', second_color, 'MarkerEdgeColor', second_color);
legend([matching_legend, nonmatching_legend], {'Matching', 'Nonmatching'}, 'Location', 'southwest', 'Box', 'off')
xticks(1:3); xticklabels(monkey_labels); xlim([0.5, 3.5]); ylim([0, max(monkey_maximum) + 0.09])
ylabel('Population correlation'); title('C')
xlabel('Monkey')
%% Figure 4F
subplot(1, 4, 4); hold on
plot_values = [];
plot_groups = [];
monkey_maximum = zeros(3, 1);
monkey_minimum = zeros(3, 1);
for monkey_idx = 1:3
    bias_values = reshape(f4_bias(monkey_idx, :, :), [], 1);
    bias_values = bias_values(isfinite(bias_values));
    plot_values = [plot_values; bias_values];
    plot_groups = [plot_groups; repmat(monkey_idx, length(bias_values), 1)];
    monkey_maximum(monkey_idx) = max(bias_values);
    monkey_minimum(monkey_idx) = min(bias_values);
end
single_colors = repmat(single_color, 3, 1);
boxplot(plot_values, plot_groups, 'Positions', 1:3, 'Colors', single_colors, 'Labels', empty_single_labels, 'Symbol', '', 'Widths', 0.38, 'Whisker', 1.5)
yline(0, '--k', 'LineWidth', 1)
p_text_y = max(monkey_maximum) + 0.045;
for monkey_idx = 1:3
    result_row = find(summary_table.Monkey == monkey_names(monkey_idx) & summary_table.Panel == "Figure 4F");
    text(monkey_idx, p_text_y, sprintf('p = %.3g', summary_table.POneSided(result_row)), 'HorizontalAlignment', 'center', 'FontSize', 10)
end
xticks(1:3); xticklabels(monkey_labels); xlim([0.5, 3.5])
ylim([min(-0.05, min(monkey_minimum) - 0.04), max(monkey_maximum) + 0.12])
ylabel('Bias toward expected exemplar'); title('D')
xlabel('Monkey')

figsave(fullfile(root_dir,'Fig'),'FS7')
