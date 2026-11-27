close all; clear; clc

% Params
dp_pool = cell(10, 1);
mu_pair_pool = cell(10, 3);
mu_fit_r_pair_pool = cell(10, 3);
mu_p_pair_pool = cell(10, 3);
response_pair_pool = cell(10, 3);

dp_threshold = 0.5;
p_threshold = 0.001;
fit_r_threshold = 0.3;
kde_kappa = 8;
kde_angle_grid = deg2rad(0:1:359);
%% Loading Data
root_dir = load('root_dir.mat').root_dir;
all_prep = dir(fullfile('Data', 's0', '*AnagramP*.mat'));
session_count = length(all_prep);
output_directory = fullfile(root_dir,'Fig','newF2');
for session_idx = 1:session_count
    file_name = all_prep(session_idx).name;
    session_path = fullfile(all_prep(session_idx).folder, file_name);
    session_data = load(session_path, 'raster_mtx', 'rsp_mtx', 'trial_idx', 'glb');
    metric_name = sprintf('%s_metric.mat', file_name(1:end-4));
    metric_path = fullfile('Data', 'single', metric_name);
    metric_data = load(metric_path, 'vm_param', 'p48');
    set_name = identify_set_name(file_name);
    [family_stimuli_session, ~, global_family_indices] = gen_famuli_compare(set_name);
    response_window = session_data.glb.pre_onset + (60:400);
    trial_response = squeeze(sum(single(session_data.raster_mtx(:, :, response_window)), 3)) / 0.34;

    for local_family_idx = 1:length(family_stimuli_session)
        global_family_idx = global_family_indices(local_family_idx);
        family_stimuli = family_stimuli_session{local_family_idx};
        exemplar_a_stimuli = family_stimuli(49:96);
        exemplar_b_stimuli = family_stimuli(97:144);
        exemplar_a_trials = find(session_data.trial_idx >= min(exemplar_a_stimuli) & session_data.trial_idx <= max(exemplar_a_stimuli));
        exemplar_b_trials = find(session_data.trial_idx >= min(exemplar_b_stimuli) & session_data.trial_idx <= max(exemplar_b_stimuli));
        exemplar_dp = calc_dp(trial_response, exemplar_a_trials, exemplar_b_trials);
        exemplar_dp = exemplar_dp(:);
        dp_pool{global_family_idx} = [dp_pool{global_family_idx}; exemplar_dp];
        metric_columns = map_family_metric_columns(family_stimuli);
        for condition_idx = 1:3
            metric_columns_here = metric_columns(2 * condition_idx - 1:2 * condition_idx);
            mu_values = metric_data.vm_param(:, metric_columns_here, 1);
            fit_r_values = metric_data.vm_param(:, metric_columns_here, 5);
            p_values = metric_data.p48(:, metric_columns_here);
            condition_stimuli = family_stimuli((condition_idx - 1) * 48 + (1:48));
            condition_response = squeeze(sum(session_data.rsp_mtx(:, condition_stimuli, response_window), 3)) / 0.36;
            mu_pair_pool{global_family_idx, condition_idx} = [mu_pair_pool{global_family_idx, condition_idx}; mu_values];
            mu_fit_r_pair_pool{global_family_idx, condition_idx} = [mu_fit_r_pair_pool{global_family_idx, condition_idx}; fit_r_values];
            mu_p_pair_pool{global_family_idx, condition_idx} = [mu_p_pair_pool{global_family_idx, condition_idx}; p_values];
            response_pair_pool{global_family_idx, condition_idx} = [response_pair_pool{global_family_idx, condition_idx}; condition_response];
        end
    end
end

[family_stimuli_all, critical_angles, ~] = gen_famuli_compare('AnagramPP');
angle_edges = 0:15:360;
critical_angles = deg2rad((critical_angles(:, :, 2) - 1) * 15);
interpretation_matching_distance = nan(20, 1);
interpretation_nonmatching_distance = nan(20, 1);
interpretation_distance_p = nan(20, 1);

[img_pool, ~, ~, ~, angle_colors] = load_stimPP;

red_color = [0.85, 0.20, 0.15];
blue_color = [0.15, 0.35, 0.85];
example_angle_indices = [1, 4, 7, 10, 13, 16, 19, 22];
condition_names = {'Anagram', 'Exemplar A', 'Exemplar B'};
mu_distribution_distance = nan(10, 3);
mu_observation_count = zeros(10, 3, 2);
tuning_mu_density = cell(10, 3, 2);
tuning_mu = cell(10, 3, 2);
tuning_response = cell(10, 3, 2);
kde_grid_step = kde_angle_grid(2) - kde_angle_grid(1);

for family_idx = 1:10
    family_dp = dp_pool{family_idx};
    selected_neurons = find(family_dp > dp_threshold | family_dp < -dp_threshold);
    population_rows = {find(family_dp(selected_neurons) > dp_threshold), find(family_dp(selected_neurons) < -dp_threshold)};

    for condition_idx = 1:3
        selected_mu = mu_pair_pool{family_idx, condition_idx}(selected_neurons, :);
        selected_fit_r = mu_fit_r_pair_pool{family_idx, condition_idx}(selected_neurons, :);
        selected_p = mu_p_pair_pool{family_idx, condition_idx}(selected_neurons, :);
        selected_response = response_pair_pool{family_idx, condition_idx}(selected_neurons, :);
        good_mu = isfinite(selected_mu) & selected_fit_r >= fit_r_threshold & selected_p < p_threshold;
        population_mu = cell(1, 2);

        for population_idx = 1:2
            rows = population_rows{population_idx};
            mu_values = [selected_mu(rows, 1); selected_mu(rows, 2)];
            response_values = [selected_response(rows, 1:24); selected_response(rows, 25:48)];
            good_values = [good_mu(rows, 1); good_mu(rows, 2)];
            mu_values = mu_values(good_values);
            response_values = response_values(good_values, :);
            population_mu{population_idx} = mu_values;
            mu_observation_count(family_idx, condition_idx, population_idx) = length(mu_values);

            if length(mu_values) >= 2
                density = mean(exp(kde_kappa * cos(kde_angle_grid - mod(mu_values, 2*pi))), 1);
                tuning_mu_density{family_idx, condition_idx, population_idx} = density / (sum(density) * kde_grid_step);
            end

            minimum_response = min(response_values, [], 2);
            response_range = max(response_values, [], 2) - minimum_response;
            varying_response = response_range > 0;
            response_values(varying_response, :) = (response_values(varying_response, :) - minimum_response(varying_response)) ./ response_range(varying_response);
            [mu_plot, sort_order] = sort(rad2deg(mu_values));
            response_values = response_values(sort_order, :);
            mu_plot(mu_plot > 352.5) = mu_plot(mu_plot > 352.5) - 360;
            tuning_mu{family_idx, condition_idx, population_idx} = mu_plot;
            tuning_response{family_idx, condition_idx, population_idx} = response_values;
        end

        if all(mu_observation_count(family_idx, condition_idx, :) >= 2)
            density_a = tuning_mu_density{family_idx, condition_idx, 1};
            density_b = tuning_mu_density{family_idx, condition_idx, 2};
            mu_distribution_distance(family_idx, condition_idx) = 0.5 * sum(abs(density_a - density_b)) * kde_grid_step;
        end

        if condition_idx == 1
            for population_idx = 1:2
                interpretation_idx = 2 * family_idx - 2 + population_idx;
                matching_distance = abs(rad2deg(angle(exp(1i * (population_mu{population_idx} - critical_angles(family_idx, population_idx))))));
                nonmatching_distance = abs(rad2deg(angle(exp(1i * (population_mu{population_idx} - critical_angles(family_idx, 3 - population_idx))))));
                interpretation_matching_distance(interpretation_idx) = mean(matching_distance);
                interpretation_nonmatching_distance(interpretation_idx) = mean(nonmatching_distance);
                interpretation_distance_p(interpretation_idx) = signrank(matching_distance, nonmatching_distance, 'tail', 'left');
            end
        end
    end
end

valid_interpretations = isfinite(interpretation_matching_distance) & isfinite(interpretation_nonmatching_distance);
matching_summary_p = signrank(interpretation_matching_distance(valid_interpretations),interpretation_nonmatching_distance(valid_interpretations), 'tail', 'left');
%% Generate figures

for family_idx = 1:10
    % Figure 2: fitted-mu distributions and canonical-angle matching.
    figure;set(gcf, 'Position', [1,41,950,1000]);colormap('hot')
    tiledlayout(6, 3, 'Padding', 'compact', 'TileSpacing', 'compact')
    % Row 1: repeat the stimulus examples so this figure can stand alone.
    for condition_idx = 1:3
        block_start = (condition_idx - 1) * 48 + 1;
        condition_stimuli = family_stimuli_all{family_idx}(block_start:block_start + 23);
        example_images = make_angle_image_strip(img_pool, condition_stimuli, example_angle_indices, angle_colors, 20);
        nexttile(condition_idx)
        imshow(example_images)
        title(sprintf('%s', condition_names{condition_idx}))
    end

    % Row 2: fitted-mu distributions.
    for condition_idx = 1:3
        nexttile(3 + condition_idx);hold on
        mu_1 = tuning_mu{family_idx, condition_idx, 1};
        mu_2 = tuning_mu{family_idx, condition_idx, 2};
        kde_density_1 = tuning_mu_density{family_idx, condition_idx, 1};
        kde_density_2 = tuning_mu_density{family_idx, condition_idx, 2};
        mode_degree_1 = nan;
        mode_degree_2 = nan;
        histogram(mod(mu_1, 360), angle_edges, 'Normalization', 'probability', 'DisplayStyle', 'stairs', 'EdgeColor', red_color, 'LineWidth', 1)
        histogram(mod(mu_2, 360), angle_edges, 'Normalization', 'probability', 'DisplayStyle', 'stairs', 'EdgeColor', blue_color, 'LineWidth', 1)
        if ~isempty(kde_density_1) && ~isempty(kde_density_2)
            histogram_bin_width = deg2rad(angle_edges(2) - angle_edges(1));
            kde_plot_degrees = [rad2deg(kde_angle_grid), 360];
            kde_plot_density_1 = [kde_density_1, kde_density_1(1)] * histogram_bin_width;
            kde_plot_density_2 = [kde_density_2, kde_density_2(1)] * histogram_bin_width;
            kde_curve_1 = plot(kde_plot_degrees, kde_plot_density_1, 'Color', red_color, 'LineWidth', 2.5);
            kde_curve_2 = plot(kde_plot_degrees, kde_plot_density_2, 'Color', blue_color, 'LineWidth', 2.5);
            histogram_y_limits = ylim;
            mode_marker_y = 1.16 * histogram_y_limits(2);
            ylim([0, 1.30 * histogram_y_limits(2)])
            [~, mode_idx_1] = max(kde_density_1);
            [~, mode_idx_2] = max(kde_density_2);
            mode_degree_1 = rad2deg(kde_angle_grid(mode_idx_1));
            mode_degree_2 = rad2deg(kde_angle_grid(mode_idx_2));
            scatter(mode_degree_1, mode_marker_y, 55, red_color, 'v', 'filled')
            scatter(mode_degree_2, mode_marker_y, 55, blue_color, 'v', 'filled')
        else
            text(180, 0.5, 'Insufficient qualified mu fits', 'HorizontalAlignment', 'center')
            ylim([0, 1])
        end
        xlim([0, 360])
        xticks(0:90:360)
        xlabel('Fitted mu (degree)')
        ylabel('Probability per 15-degree bin')
        if condition_idx == 1 && ~isempty(kde_density_1) && ~isempty(kde_density_2)
            legend([kde_curve_1, kde_curve_2], {'Exemplar A-pref.', 'Exemplar B-pref.'}, 'Location', 'best', 'Box', 'off')
        end
        if condition_idx == 1
            title(sprintf(['Modes = %.1f/%.1f deg\n' ...
                'TV = %.3f; n = %d/%d'], ...
                mode_degree_1, mode_degree_2, ...
                mu_distribution_distance(family_idx, condition_idx), ...
                mu_observation_count(family_idx, condition_idx, 1), mu_observation_count(family_idx, condition_idx, 2)))
        else
            title(sprintf(['%s mu \n' ...
                'TV dist. = %.3f; n = %d/%d'], ...
                condition_names{condition_idx}, mu_distribution_distance(family_idx, condition_idx), ...
                mu_observation_count(family_idx, condition_idx, 1), mu_observation_count(family_idx, condition_idx, 2)))
        end
    end

    % Rows 3-6: Exemplar A- and B-selective populations.
    population_colors = [red_color; blue_color];
    for population_idx = 1:2
        interpretation_idx = 2 * family_idx - 2 + population_idx;
        for condition_idx = 1:3
            nexttile(6 * population_idx + condition_idx, [2, 1])
            normalized_response = tuning_response{family_idx, condition_idx, population_idx};
            mu_plot = tuning_mu{family_idx, condition_idx, population_idx};
            imagesc(0:15:345, 1:size(normalized_response, 1), normalized_response)
            hold on
            % replace the scatter with this, for illustration.
            positive_rows = mu_plot >= 0;
            negative_rows = mu_plot < 0;
            plot(mu_plot(positive_rows), find(positive_rows), 'w-', 'LineWidth', 1)
            plot(mu_plot(negative_rows), find(negative_rows), 'w-', 'LineWidth', 1)

            xline(rad2deg(critical_angles(family_idx, population_idx)), '--', 'Color', population_colors(population_idx, :), 'LineWidth', 1.5)
            set(gca, 'YDir', 'normal')
            xlim([-7.5, 352.5])
            xticks(0:90:270)
            yticks([])
            xlabel(sprintf('%s angle (degree)', condition_names{condition_idx}))
            ylabel(sprintf('n = %d mu observations', length(mu_plot)))
            if condition_idx == 1 && population_idx == 1
                title(sprintf('dist. = %.1f/%.1f deg; p = %.3g', ...
                    interpretation_matching_distance(interpretation_idx), interpretation_nonmatching_distance(interpretation_idx), ...
                    interpretation_distance_p(interpretation_idx)))
            elseif condition_idx == 1
                title(sprintf(' dist. = %.1f/%.1f deg; p = %.3g', ...
                    interpretation_matching_distance(interpretation_idx), interpretation_nonmatching_distance(interpretation_idx), ...
                    interpretation_distance_p(interpretation_idx)))
            end
            colorbar
        end
    end

    figsave(output_directory, sprintf('F2_MuDistribution_Family%02d', family_idx))
end
%%
pair_exemplar = repmat([1; 2], 10, 1);
pair_exemplar_mu_distance = reshape(mu_distribution_distance(:, 2:3).', [], 1);
pair_anagram_mu_distance = repelem(mu_distribution_distance(:, 1), 2);
valid_mu_pairs = isfinite(pair_exemplar_mu_distance) & isfinite(pair_anagram_mu_distance);
anagram_vs_exemplar_mu_p = signrank(pair_anagram_mu_distance(valid_mu_pairs),pair_exemplar_mu_distance(valid_mu_pairs), 'tail', 'right');
%%
figure;set(gcf,'Position',[1,41,450,350]);tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact')

nexttile;hold on
for interpretation_idx = 1:20
    plot([1, 2], [interpretation_matching_distance(interpretation_idx),interpretation_nonmatching_distance(interpretation_idx)], '-', 'Color','k')
end
scatter(ones(sum(valid_interpretations), 1), interpretation_matching_distance(valid_interpretations), 25, 'k', 'filled')
scatter(2 * ones(sum(valid_interpretations), 1), interpretation_nonmatching_distance(valid_interpretations), 25,'k', 'filled')
xlim([0.5, 2.5]); ylim([0, 180]); xticks([1, 2]); xticklabels({'Matching', 'Nonmatching'}); ylabel('Mean neuron distance (degree)')
title(sprintf('Mean = %.1f/%.1f deg \n paired Wilcoxon, n = %d, p = %.3g', ...
    mean(interpretation_matching_distance(valid_interpretations)), ...
    mean(interpretation_nonmatching_distance(valid_interpretations)), ...
    sum(valid_interpretations), matching_summary_p))

nexttile
plot_exemplar_anagram_pairs(pair_exemplar_mu_distance, pair_anagram_mu_distance, valid_mu_pairs, pair_exemplar);
ylim([0, 0.7]); ylabel('Circular KDE TV distance')
title(sprintf('Median TV = %.3f/%.3f \n paired Wilcoxon, n = %d, p = %.3g', ...
    median(pair_exemplar_mu_distance(valid_mu_pairs)), median(pair_anagram_mu_distance(valid_mu_pairs)), ...
    sum(valid_mu_pairs), anagram_vs_exemplar_mu_p))

set_font(9); figsave(output_directory, 'F2_Combined_Summary')