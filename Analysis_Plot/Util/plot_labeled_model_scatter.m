function plot_labeled_model_scatter(x_values, y_values, display_labels, training_groups, training_group_names, training_colors, show_model_names)
% Draw model points, an OLS line, its 95% mean confidence interval, and labels.
valid_rows = isfinite(x_values) & isfinite(y_values);
x_values = x_values(valid_rows);
y_values = y_values(valid_rows);
display_labels = display_labels(valid_rows);
training_groups = training_groups(valid_rows);
x_range = max(x_values) - min(x_values);
y_range = max(y_values) - min(y_values);
if show_model_names
    x_padding = max(0.01, 0.22 * x_range);
    y_padding = max(0.01, 0.23 * y_range);
else
    x_padding = max(0.01, 0.08 * x_range);
    y_padding = max(0.01, 0.10 * y_range);
end
x_limits = [min(x_values) - x_padding, max(x_values) + x_padding];
y_limits = [min(y_values) - y_padding, max(y_values) + y_padding];
hold on
if length(x_values) >= 3 && x_range > 0
    line_coefficients = polyfit(x_values, y_values, 1);
    line_x = linspace(x_limits(1), x_limits(2), 200).';
    line_y = polyval(line_coefficients, line_x);
    fitted_y = polyval(line_coefficients, x_values);
    residual_degrees_of_freedom = length(x_values) - 2;
    residual_standard_error = sqrt(sum((y_values - fitted_y) .^ 2) / residual_degrees_of_freedom);
    centered_x_sum_squares = sum((x_values - mean(x_values)) .^ 2);
    confidence_half_width = tinv(0.975, residual_degrees_of_freedom) * residual_standard_error .* sqrt(1 / length(x_values) + (line_x - mean(x_values)) .^ 2 / centered_x_sum_squares);
    confidence_lower = line_y - confidence_half_width;
    confidence_upper = line_y + confidence_half_width;
    y_limits(1) = min(y_limits(1), min(confidence_lower));
    y_limits(2) = max(y_limits(2), max(confidence_upper));
    confidence_band = patch([line_x; flipud(line_x)], [confidence_lower; flipud(confidence_upper)], [0.30, 0.30, 0.30], 'FaceAlpha', 0.10, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    uistack(confidence_band, 'bottom')
    plot(line_x, line_y, '-', 'Color', [0.5, 0.5, 0.5], 'HandleVisibility', 'off')
end
point_colors = zeros(length(x_values), 3);
for model_index = 1:length(x_values)
    group_index = find(training_group_names == training_groups(model_index), 1);
    point_colors(model_index, :) = training_colors(group_index, :);
    scatter(x_values(model_index), y_values(model_index), 30, point_colors(model_index, :), 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 1.0, 'HandleVisibility', 'off')
end
if show_model_names
    place_model_text_labels(x_values, y_values, display_labels, point_colors, x_limits, y_limits)
end
[rho, p_value] = corr(x_values, y_values, 'Type', 'Spearman');
result_text = sprintf('corr. = %.2f, p = %.2g', rho, p_value);
title(result_text)
xlim(x_limits)
ylim(y_limits)
box off
axis_handle = gca;
axis_handle.TickDir = 'out';
axis_handle.Layer = 'top';
axis_handle.XGrid = 'off';
axis_handle.YGrid = 'off';
axis_handle.GridColor = [0.84, 0.84, 0.84];
axis_handle.GridAlpha = 0.22;
end

function place_model_text_labels(x_values, y_values, display_labels, point_colors, x_limits, y_limits)
% Place labels outside the point cloud and separate them vertically.
x_range = range(x_limits);
y_range = range(y_limits);
x_offset = 0.015 * x_range;
minimum_vertical_gap = 0.060 * y_range;
label_x = x_values;
label_y = y_values;
horizontal_alignment = strings(length(x_values), 1);

% Send points on the left to left-facing labels and vice versa.
for model_index = 1:length(x_values)
    if x_values(model_index) <= median(x_values)
        label_x(model_index) = x_values(model_index) - x_offset;
        horizontal_alignment(model_index) = "right";
    else
        label_x(model_index) = x_values(model_index) + x_offset;
        horizontal_alignment(model_index) = "left";
    end
end

% Resolve collisions separately on the left and right sides.
for side_index = 1:2
    if side_index == 1
        side_rows = find(horizontal_alignment == "right");
    else
        side_rows = find(horizontal_alignment == "left");
    end
    if isempty(side_rows)
        continue
    end
    [~, sort_order] = sort(y_values(side_rows));
    sorted_rows = side_rows(sort_order);
    sorted_y = y_values(sorted_rows);
    for label_index = 2:length(sorted_y)
        sorted_y(label_index) = max(sorted_y(label_index), sorted_y(label_index - 1) + minimum_vertical_gap);
    end
    % Leave the upper band free for the correlation annotation.
    upper_limit = y_limits(2) - 0.13 * y_range;
    lower_limit = y_limits(1) + 0.03 * y_range;
    if sorted_y(end) > upper_limit
        sorted_y = sorted_y - (sorted_y(end) - upper_limit);
    end
    for label_index = (length(sorted_y) - 1):-1:1
        sorted_y(label_index) = min(sorted_y(label_index), sorted_y(label_index + 1) - minimum_vertical_gap);
    end
    if sorted_y(1) < lower_limit
        sorted_y = sorted_y + (lower_limit - sorted_y(1));
    end
    label_y(sorted_rows) = sorted_y;
end

for model_index = 1:length(x_values)
    leader_color = 0.55 * point_colors(model_index, :) + 0.45;
    plot([x_values(model_index), label_x(model_index)], [y_values(model_index), label_y(model_index)], '-', 'Color', leader_color, 'LineWidth', 0.7, 'HandleVisibility', 'off')
    text(label_x(model_index), label_y(model_index), display_labels(model_index), 'Color', point_colors(model_index, :), 'FontSize', 6, 'HorizontalAlignment', horizontal_alignment(model_index), 'VerticalAlignment', 'middle', 'Interpreter', 'none');
end
end