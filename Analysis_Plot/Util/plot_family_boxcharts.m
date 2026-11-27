function plot_family_boxcharts(family_values, labels, model_plot_colors)
family_count = size(family_values, 2);
jitter_positions = linspace(-0.16, 0.16, family_count);
for model_index = 1:size(family_values, 1)
    valid_values = family_values(model_index, isfinite(family_values(model_index, :)));
    group_positions = repmat(model_index, length(valid_values), 1);
    boxchart(group_positions, valid_values(:), 'BoxFaceColor', model_plot_colors(model_index, :), 'BoxEdgeColor', model_plot_colors(model_index, :), 'BoxFaceAlpha', 0.24, 'BoxWidth', 0.52, 'MarkerStyle', 'none', 'HandleVisibility', 'off')
    x_positions = model_index + jitter_positions(1:length(valid_values));
    scatter(x_positions, valid_values, 25, model_plot_colors(model_index, :), 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 0.45, 'MarkerFaceAlpha', 0.78, 'HandleVisibility', 'off')
end
xticks(1:length(labels)); xticklabels(labels)
xtickangle(90); xlim([0.5, length(labels) + 0.5]); set(gca, 'TickLabelInterpreter', 'none')
end
