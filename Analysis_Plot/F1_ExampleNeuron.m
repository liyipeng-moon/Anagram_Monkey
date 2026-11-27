close all; clear; clc
root_dir = load('root_dir.mat').root_dir;
cd(root_dir);
stimulus_root = fullfile(root_dir, 'Data', 'stim');

% Selection settings.
dp_threshold = 1;
p_threshold = 0.001;
fit_r_threshold = 0.5;
maximum_matching_distance = 45;
minimum_distance_advantage = 30;
unit_chunk_size = 25;
examples_per_preference = 3;

canonical_window = 60:400;
anagram_window = 60:400;
plot_start = -50;
plot_end = 450;
smooth_bin = 50;
plot_step = 10;
lag_time = 500;

starting_directory = pwd;
cd(fullfile(stimulus_root, 'AnagramPP'))
[f_compare_all, critical_point_all, ~] = gen_famuli_compare('AnagramPP');
stimulus_table = readtable('AnagramPP.tsv', 'FileType', 'text', 'Delimiter', 'tab');

all_sessions = dir(fullfile(root_dir, 'Data', 's0', '*AnagramP*.mat'));
output_directory = fullfile(root_dir,'Fig','ExampleUnit');
candidate_session = [];
candidate_unit = [];
candidate_family = [];
candidate_preference = [];
candidate_dp = [];
candidate_mu = [];
candidate_fit_r = [];
candidate_p = [];
candidate_matching_distance = [];
candidate_nonmatching_distance = [];
candidate_score = [];

for session_idx = 1:length(all_sessions)
    file_name = all_sessions(session_idx).name;
    session_path = fullfile(all_sessions(session_idx).folder, file_name);
    session_file = matfile(session_path);
    trial_idx = session_file.trial_idx;
    glb = session_file.glb;

    raster_size = size(session_file, 'raster_mtx');
    unit_count = raster_size(1);
    canonical_time_idx = glb.pre_onset + canonical_window;
    trial_response = zeros(unit_count, length(trial_idx), 'single');

    for first_unit = 1:unit_chunk_size:unit_count
        last_unit = min(first_unit + unit_chunk_size - 1, unit_count);
        raster_chunk = session_file.raster_mtx(first_unit:last_unit, :, canonical_time_idx);
        response_chunk = squeeze(sum(single(raster_chunk), 3)) / 0.34;
        response_chunk = reshape(response_chunk, last_unit - first_unit + 1, length(trial_idx));
        trial_response(first_unit:last_unit, :) = response_chunk;
    end

    metric_name = sprintf('%s_metric.mat', file_name(1:end-4));
    metric_path = fullfile(root_dir, 'Data', 'single', metric_name);
    metric_data = load(metric_path, 'vm_param', 'p48');

    set_name = identify_set_name(file_name);
    cd(fullfile(stimulus_root, set_name))
    [f_compare_session, ~, anagram_indices] = gen_famuli_compare(set_name);

    for session_family_idx = 1:length(f_compare_session)
        global_family_idx = anagram_indices(session_family_idx);
        family_stimuli = f_compare_session{session_family_idx};
        canonical_1_stimuli = family_stimuli(49:96);
        canonical_2_stimuli = family_stimuli(97:144);
        canonical_1_trials = find(trial_idx >= min(canonical_1_stimuli) & trial_idx <= max(canonical_1_stimuli));
        canonical_2_trials = find(trial_idx >= min(canonical_2_stimuli) & trial_idx <= max(canonical_2_stimuli));
        exemplar_dp = calc_dp(trial_response, canonical_1_trials, canonical_2_trials);
        exemplar_dp = exemplar_dp(:);

        % Map the family stimulus indices to the stored metric columns.
        metric_columns = map_family_metric_columns(family_stimuli);
        original_anagram_column = metric_columns(1);

        fitted_mu = metric_data.vm_param(:, original_anagram_column, 1);
        fit_r = metric_data.vm_param(:, original_anagram_column, 5);
        tuning_p = metric_data.p48(:, original_anagram_column);
        fitted_mu = fitted_mu(:);
        fit_r = fit_r(:);
        tuning_p = tuning_p(:);

        critical_angle_1 = deg2rad((critical_point_all(global_family_idx, 1, 2) - 1) * 15);
        critical_angle_2 = deg2rad((critical_point_all(global_family_idx, 2, 2) - 1) * 15);
        distance_to_1 = abs(rad2deg(angle(exp(1i * (fitted_mu - critical_angle_1)))));
        distance_to_2 = abs(rad2deg(angle(exp(1i * (fitted_mu - critical_angle_2)))));

        for preference_idx = 1:2
            if preference_idx == 1
                matching_distance = distance_to_1;
                nonmatching_distance = distance_to_2;
                preference_mask = exemplar_dp > dp_threshold;
            else
                matching_distance = distance_to_2;
                nonmatching_distance = distance_to_1;
                preference_mask = exemplar_dp < -dp_threshold;
            end

            distance_advantage = nonmatching_distance - matching_distance;
            good_units = preference_mask;
            good_units = good_units & tuning_p < p_threshold;
            good_units = good_units & fit_r >= fit_r_threshold;
            good_units = good_units & matching_distance <= maximum_matching_distance;
            good_units = good_units & distance_advantage >= minimum_distance_advantage;
            good_units = good_units & ~isnan(fitted_mu);
            good_units = good_units & ~isnan(exemplar_dp);
            selected_units = find(good_units);

            for selected_idx = 1:length(selected_units)
                unit_idx = selected_units(selected_idx);
                score = abs(exemplar_dp(unit_idx)) + fit_r(unit_idx) + distance_advantage(unit_idx) / 90;
                candidate_session(end + 1, 1) = session_idx;
                candidate_unit(end + 1, 1) = unit_idx;
                candidate_family(end + 1, 1) = global_family_idx;
                candidate_preference(end + 1, 1) = preference_idx;
                candidate_dp(end + 1, 1) = exemplar_dp(unit_idx);
                candidate_mu(end + 1, 1) = fitted_mu(unit_idx);
                candidate_fit_r(end + 1, 1) = fit_r(unit_idx);
                candidate_p(end + 1, 1) = tuning_p(unit_idx);
                candidate_matching_distance(end + 1, 1) = matching_distance(unit_idx);
                candidate_nonmatching_distance(end + 1, 1) = nonmatching_distance(unit_idx);
                candidate_score(end + 1, 1) = score;
            end
        end
    end
end
%%
close all
angle_colors = colorcet('C6');
angle_colors = angle_colors(1:11:256, :);
canonical_colors = [0.85, 0.20, 0.15; 0.15, 0.35, 0.85];
neutral_color = [0.35, 0.35, 0.35];
theta_fit = linspace(0, 2*pi, 361);
angle_fit = rad2deg(theta_fit);
vm_model = @(p, theta) p(4) + p(3) * exp(p(2) * cos(theta - p(1))) / (2*pi*besseli(0, p(2)));

for selected_family = [1,7]
    selected_candidates = cell(1, 2);
    for preference_idx = 1:2
        candidates_here = find(candidate_family == selected_family & candidate_preference == preference_idx);
        [~, score_order] = sort(candidate_score(candidates_here), 'descend');
        candidates_here = candidates_here(score_order);
        example_count = min(examples_per_preference, length(candidates_here));
        selected_candidates{preference_idx} = candidates_here(1:example_count);
    end

    row_count = max(length(selected_candidates{1}), length(selected_candidates{2}));
    anagram_stimuli_all = f_compare_all{selected_family}(1:24);
    stimulus_strip = [];

    for angle_idx = 1:24
        stimulus_idx = anagram_stimuli_all(angle_idx);
        image_path = fullfile(stimulus_root, 'AnagramPP', stimulus_table.FileName{stimulus_idx});
        image_here = imresize(imread(image_path), [300, 300]);
        image_here = add_edge(image_here, floor(255 * angle_colors(angle_idx, :)), 20);
        stimulus_strip = [stimulus_strip, image_here];
    end

    canonical_1_idx = f_compare_all{selected_family}(49);
    canonical_2_idx = f_compare_all{selected_family}(97);
    canonical_1_image = imresize(imread(fullfile(stimulus_root, 'AnagramPP', stimulus_table.FileName{canonical_1_idx})), [300, 300]);
    canonical_2_image = imresize(imread(fullfile(stimulus_root, 'AnagramPP', stimulus_table.FileName{canonical_2_idx})), [300, 300]);
    canonical_images = [canonical_1_image, uint8(255 * ones(300, 40, 3)), canonical_2_image];

    figure;
    set(gcf, 'Position', [10, 20, 2400, 300 + 280 * row_count])
    tiledlayout(row_count + 1, 12, 'Padding', 'compact', 'TileSpacing', 'compact')
    nexttile(1, [1, 10]);imshow(stimulus_strip)
    nexttile(11, [1, 2]);imshow(canonical_images)
    
    for example_row = 1:row_count
        for preference_idx = 1:2
            if example_row > length(selected_candidates{preference_idx})
                continue
            end

            candidate_idx = selected_candidates{preference_idx}(example_row);
            session_idx = candidate_session(candidate_idx);
            unit_idx = candidate_unit(candidate_idx);
            session_file_name = all_sessions(session_idx).name;
            session_path = fullfile(all_sessions(session_idx).folder, session_file_name);
            session_file = matfile(session_path);
            trial_idx = session_file.trial_idx;
            glb = session_file.glb;
            unit_raster = squeeze(session_file.raster_mtx(unit_idx, :, :));

            set_name = identify_set_name(session_file_name);
            cd(fullfile(stimulus_root, set_name))
            [f_compare_session, ~, anagram_indices] = gen_famuli_compare(set_name);
            session_family_idx = find(anagram_indices == selected_family);
            family_stimuli = f_compare_session{session_family_idx};
            anagram_stimuli = family_stimuli(1:24);
            canonical_1_stimuli = family_stimuli(49:96);
            canonical_2_stimuli = family_stimuli(97:144);

            anagram_time_idx = glb.pre_onset + anagram_window;
            response_data = zeros(1, 24);
            for angle_idx = 1:24
                angle_trials = trial_idx == anagram_stimuli(angle_idx);
                angle_response = sum(single(unit_raster(angle_trials, anagram_time_idx)), 2) / 0.34;
                response_data(angle_idx) = mean(angle_response);
            end

            canonical_time_idx = glb.pre_onset + canonical_window;
            trial_response = sum(single(unit_raster(:, canonical_time_idx)), 2) / 0.34;
            canonical_response = cell(1, 2);
            canonical_stimulus_sets = {canonical_1_stimuli, canonical_2_stimuli};
            for canonical_idx = 1:2
                variant_response = zeros(48, 1);
                for variant_idx = 1:48
                    variant_trials = trial_idx == canonical_stimulus_sets{canonical_idx}(variant_idx);
                    variant_response(variant_idx) = mean(trial_response(variant_trials));
                end
                canonical_response{canonical_idx} = variant_response;
            end

            metric_name = sprintf('%s_metric.mat', session_file_name(1:end-4));
            metric_path = fullfile(root_dir, 'Data', 'single', metric_name);
            metric_data = load(metric_path, 'vm_param');
            metric_columns = map_family_metric_columns(family_stimuli);
            original_anagram_column = metric_columns(1);
            fitted_params = squeeze(metric_data.vm_param(unit_idx, original_anagram_column, 1:4))';
            fitted_response = vm_model(fitted_params, theta_fit);
            fitted_response_at_angles = vm_model(fitted_params, deg2rad(0:15:345));
            response_variance = var(response_data);
            if response_variance > 0
                explained_variance = 1 - var(response_data - fitted_response_at_angles) / response_variance;
            else
                explained_variance = nan;
            end
            fitted_mu_degree = mod(rad2deg(candidate_mu(candidate_idx)), 360);

            if preference_idx == 1
                matching_critical_angle = (critical_point_all(selected_family, 1, 2) - 1) * 15;
                nonmatching_critical_angle = (critical_point_all(selected_family, 2, 2) - 1) * 15;
            else
                matching_critical_angle = (critical_point_all(selected_family, 2, 2) - 1) * 15;
                nonmatching_critical_angle = (critical_point_all(selected_family, 1, 2) - 1) * 15;
            end

            [~, plot_start_idx] = min(abs(glb.PsthRange - plot_start));
            [~, plot_end_idx] = min(abs(glb.PsthRange - plot_end));
            plot_time_idx = plot_start_idx:plot_step:plot_end_idx;
            tick_positions = zeros(1, 24);
            psth = zeros(24, length(glb.PsthRange));
            first_tile = 12 + (example_row - 1) * 12 + 1 + (preference_idx - 1) * 6;

            nexttile(first_tile);hold on
            boxchart(ones(48, 1), canonical_response{1}, 'BoxFaceColor', canonical_colors(1, :),'MarkerStyle','.','MarkerColor', [0 0 0]);
            boxchart(2 * ones(48, 1), canonical_response{2}, 'BoxFaceColor', canonical_colors(2, :),'MarkerStyle','.','MarkerColor', [0 0 0]);
            xlim([0.4, 2.6]);xticks([1, 2]);xticklabels({'Canonical 1', 'Canonical 2'});ylabel('Response (Hz)')
            title(sprintf('d'' = %.2f', candidate_dp(candidate_idx)))
            set_font(7)

            nexttile(first_tile+1, [1, 4]);hold on
            for angle_idx = 1:24
                angle_trials = unit_raster(trial_idx == anagram_stimuli(angle_idx), :);
                average_raster = mean(angle_trials, 1);
                psth(angle_idx, :) = 1000 * conv(average_raster, ones(1, smooth_bin), 'same') / smooth_bin;
                plot_x = (angle_idx - 1) * lag_time + glb.PsthRange(plot_time_idx);
                plot(plot_x, psth(angle_idx, plot_time_idx), 'LineWidth', 1.1, 'Color', angle_colors(angle_idx, :))
                tick_positions(angle_idx) = mean([plot_x(1), plot_x(end)]);
            end
            maximum_psth = max(psth(:, plot_time_idx), [], 'all');
            if maximum_psth <= 0
                maximum_psth = 1;
            end
            xlim([glb.PsthRange(plot_start_idx), 23 * lag_time + glb.PsthRange(plot_end_idx)])
            ylim([0, maximum_psth * 1.08])
            xticks(tick_positions); xticklabels(string(0:15:345))
            xlabel('Anagram angle (degree)'); ylabel('Response (Hz)')
            set_font(7)


            nexttile(first_tile+5);hold on
            data_handle = scatter(0:15:345, response_data, 25, angle_colors, 'filled');
            fit_handle = plot(angle_fit, fitted_response, '-', 'Color', neutral_color, 'LineWidth', 1.6);
            response_minimum = min([response_data, fitted_response]);
            response_maximum = max([response_data, fitted_response]);
            response_range = response_maximum - response_minimum;
            if response_range <= 0
                response_range = 1;
            end
            ylim([response_minimum - 0.05 * response_range, response_maximum + 0.20 * response_range])
            current_y_limits = ylim;
            mu_marker_y = current_y_limits(2) - 0.04 * diff(current_y_limits);
            mu_handle = plot(fitted_mu_degree, mu_marker_y, 'v', 'MarkerSize', 7, ...
                'MarkerEdgeColor', canonical_colors(preference_idx, :), ...
                'MarkerFaceColor', canonical_colors(preference_idx, :));
            xlim([0, 360]);xticks(0:90:360)
            xlabel('Angle (degree)');ylabel('Response (Hz)');title(sprintf('pref = %.1f deg',fitted_mu_degree));
            explained_variance_text = text(0.03, 0.96, sprintf('EV = %.2f', explained_variance),'Units', 'normalized', 'VerticalAlignment', 'top', 'FontWeight', 'bold');
            set_font(7)

        end
    end
    figsave(output_directory, sprintf('CanonicalPreference_Album_Family%02d', selected_family))
end
