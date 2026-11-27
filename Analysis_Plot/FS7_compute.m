%% Exact per-monkey replication of Figure 2G/H, Figure 3C, and Figure 4F
close all; clear; clc
load root_dir.mat
output_directory = fullfile(root_dir, 'Data','FS7');
addpath(genpath(root_dir))
all_sessions = dir(fullfile(root_dir, 'Data', 's0', '*AnagramP*.mat'));
monkey_names = ["J", "Z", "C"];
session_monkey = strings(length(all_sessions), 1);
for session_idx = 1:length(all_sessions)
    lower_name = lower(all_sessions(session_idx).name);
    if contains(lower_name, 'jianjian')
        session_monkey(session_idx) = "J";
    elseif contains(lower_name, 'zhuangzhuang')
        session_monkey(session_idx) = "Z";
    elseif contains(lower_name, 'facai')
        session_monkey(session_idx) = "C";
    end
end
session_count = zeros(3, 1);
for monkey_idx = 1:3
    session_count(monkey_idx) = sum(session_monkey == monkey_names(monkey_idx));
end
%% Figure 2G and Figure 2H
dp_threshold = 0.5;
p_threshold = 0.001;
fit_r_threshold = 0.3;
kde_kappa = 8;
kde_angle_grid = deg2rad(0:1:359);
kde_grid_step = kde_angle_grid(2) - kde_angle_grid(1);

f2_dp_pool = cell(3, 10);
f2_mu_pool = cell(3, 10, 3);
f2_fit_r_pool = cell(3, 10, 3);
f2_p_pool = cell(3, 10, 3);

for session_idx = 1:length(all_sessions)
    file_name = all_sessions(session_idx).name;
    session_path = fullfile(all_sessions(session_idx).folder, file_name);
    monkey_idx = find(monkey_names == session_monkey(session_idx));
    session_info = load(session_path, 'trial_idx', 'glb');
    session_raster = load(session_path, 'raster_mtx');

    metric_name = sprintf('%s_metric.mat', file_name(1:end-4));
    metric_path = fullfile(root_dir, 'Data', 'single', metric_name);
    metric_data = load(metric_path, 'vm_param', 'p48');

    set_name = identify_set_name(file_name);
    [family_stimuli_session, ~, global_family_indices] = gen_famuli_compare(set_name);
    response_window = session_info.glb.pre_onset + (60:400);

    for local_family_idx = 1:length(family_stimuli_session)
        global_family_idx = global_family_indices(local_family_idx);
        family_stimuli = family_stimuli_session{local_family_idx};
        exemplar_a_stimuli = family_stimuli(49:96);
        exemplar_b_stimuli = family_stimuli(97:144);
        exemplar_a_trials = find(session_info.trial_idx >= min(exemplar_a_stimuli) & session_info.trial_idx <= max(exemplar_a_stimuli));
        exemplar_b_trials = find(session_info.trial_idx >= min(exemplar_b_stimuli) & session_info.trial_idx <= max(exemplar_b_stimuli));

        raster_a = session_raster.raster_mtx(:, exemplar_a_trials, response_window);
        raster_b = session_raster.raster_mtx(:, exemplar_b_trials, response_window);
        response_a = squeeze(sum(single(raster_a), 3)) / 0.34;
        response_b = squeeze(sum(single(raster_b), 3)) / 0.34;
        clear raster_a raster_b

        mean_a = mean(response_a, 2);
        mean_b = mean(response_b, 2);
        std_a = std(response_a, 0, 2);
        std_b = std(response_b, 0, 2);
        exemplar_dp = (mean_a - mean_b) ./ sqrt(0.5 * (std_a.^2 + std_b.^2));
        f2_dp_pool{monkey_idx, global_family_idx} = [f2_dp_pool{monkey_idx, global_family_idx}; exemplar_dp(:)];
        clear response_a response_b

        metric_columns = map_family_metric_columns(family_stimuli);
        for condition_idx = 1:3
            metric_columns_here = metric_columns(2 * condition_idx - 1:2 * condition_idx);
            mu_values = metric_data.vm_param(:, metric_columns_here, 1);
            fit_r_values = metric_data.vm_param(:, metric_columns_here, 5);
            p_values = metric_data.p48(:, metric_columns_here);
            f2_mu_pool{monkey_idx, global_family_idx, condition_idx} = [f2_mu_pool{monkey_idx, global_family_idx, condition_idx}; mu_values];
            f2_fit_r_pool{monkey_idx, global_family_idx, condition_idx} = [f2_fit_r_pool{monkey_idx, global_family_idx, condition_idx}; fit_r_values];
            f2_p_pool{monkey_idx, global_family_idx, condition_idx} = [f2_p_pool{monkey_idx, global_family_idx, condition_idx}; p_values];
        end
    end
    clear session_raster
end

[~, critical_angles, ~] = gen_famuli_compare('AnagramPP');
critical_angles = deg2rad((critical_angles(:, :, 2) - 1) * 15);
f2_matching_distance = nan(3, 10, 2);
f2_nonmatching_distance = nan(3, 10, 2);
f2_fit_count = zeros(3, 10, 3, 2);
f2_tvd = nan(3, 10, 3);

for monkey_idx = 1:3
    for family_idx = 1:10
        family_dp = f2_dp_pool{monkey_idx, family_idx};
        selected_neurons = find(family_dp > dp_threshold | family_dp < -dp_threshold);
        selected_dp = family_dp(selected_neurons);
        population_rows = cell(1, 2);
        population_rows{1} = find(selected_dp > dp_threshold);
        population_rows{2} = find(selected_dp < -dp_threshold);

        for condition_idx = 1:3
            selected_mu = f2_mu_pool{monkey_idx, family_idx, condition_idx}(selected_neurons, :);
            selected_fit_r = f2_fit_r_pool{monkey_idx, family_idx, condition_idx}(selected_neurons, :);
            selected_p = f2_p_pool{monkey_idx, family_idx, condition_idx}(selected_neurons, :);
            good_mu = isfinite(selected_mu) & selected_fit_r >= fit_r_threshold & selected_p < p_threshold;
            population_density = cell(1, 2);
            population_mu = cell(1, 2);

            for population_idx = 1:2
                rows = population_rows{population_idx};
                mu_values = [selected_mu(rows, 1); selected_mu(rows, 2)];
                good_values = [good_mu(rows, 1); good_mu(rows, 2)];
                mu_values = mu_values(good_values);
                population_mu{population_idx} = mu_values;
                f2_fit_count(monkey_idx, family_idx, condition_idx, population_idx) = length(mu_values);

                if length(mu_values) >= 2
                    density = mean(exp(kde_kappa * cos(kde_angle_grid - mod(mu_values, 2*pi))), 1);
                    population_density{population_idx} = density / (sum(density) * kde_grid_step);
                end
            end

            if f2_fit_count(monkey_idx, family_idx, condition_idx, 1) >= 2 && f2_fit_count(monkey_idx, family_idx, condition_idx, 2) >= 2
                density_a = population_density{1};
                density_b = population_density{2};
                f2_tvd(monkey_idx, family_idx, condition_idx) = 0.5 * sum(abs(density_a - density_b)) * kde_grid_step;
            end

            if condition_idx == 1
                for population_idx = 1:2
                    mu_values = population_mu{population_idx};
                    matching_distance = abs(rad2deg(angle(exp(1i * (mu_values - critical_angles(family_idx, population_idx))))));
                    nonmatching_distance = abs(rad2deg(angle(exp(1i * (mu_values - critical_angles(family_idx, 3 - population_idx))))));
                    f2_matching_distance(monkey_idx, family_idx, population_idx) = mean(matching_distance);
                    f2_nonmatching_distance(monkey_idx, family_idx, population_idx) = mean(nonmatching_distance);
                end
            end
        end
    end
end
save(fullfile(output_directory, 'Figure2_by_monkey.mat'), 'f2_matching_distance', 'f2_nonmatching_distance', 'f2_fit_count', 'f2_tvd', 'monkey_names', 'session_count')
%% Figure 3C
f3_rsp_pool = cell(3, 10, 3);
for session_idx = 1:length(all_sessions)
    file_name = all_sessions(session_idx).name;
    session_path = fullfile(all_sessions(session_idx).folder, file_name);
    monkey_idx = find(monkey_names == session_monkey(session_idx));
    session_info = load(session_path, 'glb');
    session_response = load(session_path, 'rsp_mtx');
    set_name = identify_set_name(file_name);
    [family_stimuli_session, ~, global_family_indices] = gen_famuli_compare(set_name);
    time_indices = find(session_info.glb.PsthRange == 60):find(session_info.glb.PsthRange == 400);

    for local_family_idx = 1:length(family_stimuli_session)
        global_family_idx = global_family_indices(local_family_idx);
        family_stimuli = family_stimuli_session{local_family_idx};
        for condition_idx = 1:3
            condition_stimuli = family_stimuli((condition_idx - 1) * 48 + (1:48));
            response_values = session_response.rsp_mtx(:, condition_stimuli, time_indices);
            mean_response = squeeze(mean(response_values, 3));
            mean_response = [mean_response(:, 1:24); mean_response(:, 25:48)];
            f3_rsp_pool{monkey_idx, global_family_idx, condition_idx} = [f3_rsp_pool{monkey_idx, global_family_idx, condition_idx}; mean_response];
            clear response_values mean_response
        end
    end
    clear session_response
end

[~, critical_points, ~] = gen_famuli_compare('AnagramPP');
correlation_limit = 1 - 1e-12;
f3_raw = nan(3, 10, 2, 2);
f3_z = nan(3, 10, 2, 2);
f3_unit_count = zeros(3, 10);

for monkey_idx = 1:3
    for family_idx = 1:10
        population_response = [];
        for condition_idx = 1:3
            population_response = [population_response, f3_rsp_pool{monkey_idx, family_idx, condition_idx}];
        end
        f3_unit_count(monkey_idx, family_idx) = size(population_response, 1);
        population_response = norm_01(population_response)';
        rdm = squareform(pdist(population_response, 'spearman'));
        correlation_1 = 1 - rdm(critical_points(family_idx, 1, 2), 25:72);
        correlation_2 = 1 - rdm(critical_points(family_idx, 2, 2), 25:72);
        correlation_1_z = atanh(max(min(correlation_1, correlation_limit), -correlation_limit));
        correlation_2_z = atanh(max(min(correlation_2, correlation_limit), -correlation_limit));

        f3_raw(monkey_idx, family_idx, 1, 1) = mean(correlation_1(1:24));
        f3_raw(monkey_idx, family_idx, 1, 2) = mean(correlation_2(1:24));
        f3_raw(monkey_idx, family_idx, 2, 1) = mean(correlation_1(25:48));
        f3_raw(monkey_idx, family_idx, 2, 2) = mean(correlation_2(25:48));
        f3_z(monkey_idx, family_idx, 1, 1) = mean(correlation_1_z(1:24));
        f3_z(monkey_idx, family_idx, 1, 2) = mean(correlation_2_z(1:24));
        f3_z(monkey_idx, family_idx, 2, 1) = mean(correlation_1_z(25:48));
        f3_z(monkey_idx, family_idx, 2, 2) = mean(correlation_2_z(25:48));
    end
end
save(fullfile(output_directory, 'Figure3C_by_monkey.mat'), 'f3_raw', 'f3_z', 'f3_unit_count', 'monkey_names', 'session_count')
clear f3_rsp_pool
%% Figure 4F
f4_score_pool = cell(3, 10, 2);
for session_idx = 1:length(all_sessions)
    file_name = all_sessions(session_idx).name;
    monkey_idx = find(monkey_names == session_monkey(session_idx));
    decode_name = sprintf('PlusDecode_%s_metric.mat', file_name(1:end-4));
    decode_path = fullfile(root_dir, 'Data', 'decode_l2', decode_name);
    decode_data = load(decode_path, 'score_mean', 'trial_idx');
    set_name = identify_set_name(file_name);
    [family_stimuli_session, critical_points_session, global_family_indices] = gen_famuli_compare(set_name);

    for local_family_idx = 1:length(family_stimuli_session)
        global_family_idx = global_family_indices(local_family_idx);
        anagram_stimuli = family_stimuli_session{local_family_idx}(1:24);
        for interpretation_idx = 1:2
            trial_locations = [];
            for neighbor_idx = 1:3
                image_index = anagram_stimuli(critical_points_session(local_family_idx, interpretation_idx, neighbor_idx));
                trial_locations = [trial_locations, find(decode_data.trial_idx == image_index | decode_data.trial_idx == image_index + 24)];
            end
            score_values = decode_data.score_mean(local_family_idx, trial_locations);
            f4_score_pool{monkey_idx, global_family_idx, interpretation_idx} = [f4_score_pool{monkey_idx, global_family_idx, interpretation_idx}, score_values];
        end
    end
end

f4_mean_score = nan(3, 10, 2);
f4_trial_count = zeros(3, 10, 2);
f4_bias = nan(3, 10, 2);
for monkey_idx = 1:3
    for family_idx = 1:10
        for interpretation_idx = 1:2
            score_values = f4_score_pool{monkey_idx, family_idx, interpretation_idx};
            f4_mean_score(monkey_idx, family_idx, interpretation_idx) = mean(score_values, 'omitnan');
            f4_trial_count(monkey_idx, family_idx, interpretation_idx) = sum(isfinite(score_values));
        end
        f4_bias(monkey_idx, family_idx, 1) = f4_mean_score(monkey_idx, family_idx, 1) - 0.5;
        f4_bias(monkey_idx, family_idx, 2) = 0.5 - f4_mean_score(monkey_idx, family_idx, 2);
    end
end

save(fullfile(output_directory, 'Figure4F_by_monkey.mat'), 'f4_mean_score', 'f4_trial_count', 'f4_bias', 'monkey_names', 'session_count')
%% Exact panel statistics
summary_monkey = strings(12, 1);
summary_panel = strings(12, 1);
summary_sessions = zeros(12, 1);
summary_n = zeros(12, 1);
summary_value_1 = nan(12, 1);
summary_value_2 = nan(12, 1);
summary_effect = nan(12, 1);
summary_statistic = nan(12, 1);
summary_p = nan(12, 1);

row_idx = 0;
for monkey_idx = 1:3
    matching_values = reshape(f2_matching_distance(monkey_idx, :, :), [], 1);
    nonmatching_values = reshape(f2_nonmatching_distance(monkey_idx, :, :), [], 1);
    valid_values = isfinite(matching_values) & isfinite(nonmatching_values);
    [p_value, ~, test_stats] = signrank(matching_values(valid_values), nonmatching_values(valid_values), 'tail', 'left');
    row_idx = row_idx + 1;
    summary_monkey(row_idx) = monkey_names(monkey_idx);
    summary_panel(row_idx) = "Figure 2G";
    summary_sessions(row_idx) = session_count(monkey_idx);
    summary_n(row_idx) = sum(valid_values);
    summary_value_1(row_idx) = mean(matching_values(valid_values));
    summary_value_2(row_idx) = mean(nonmatching_values(valid_values));
    summary_effect(row_idx) = mean(nonmatching_values(valid_values) - matching_values(valid_values));
    summary_statistic(row_idx) = test_stats.signedrank;
    summary_p(row_idx) = p_value;

    anagram_tvd = repelem(squeeze(f2_tvd(monkey_idx, :, 1)), 2);
    anagram_tvd = anagram_tvd(:);
    exemplar_tvd = reshape(squeeze(f2_tvd(monkey_idx, :, 2:3))', [], 1);
    valid_values = isfinite(anagram_tvd) & isfinite(exemplar_tvd);
    [p_value, ~, test_stats] = signrank(anagram_tvd(valid_values), exemplar_tvd(valid_values), 'tail', 'right');
    row_idx = row_idx + 1;
    summary_monkey(row_idx) = monkey_names(monkey_idx);
    summary_panel(row_idx) = "Figure 2H";
    summary_sessions(row_idx) = session_count(monkey_idx);
    summary_n(row_idx) = sum(valid_values);
    summary_value_1(row_idx) = median(anagram_tvd(valid_values));
    summary_value_2(row_idx) = median(exemplar_tvd(valid_values));
    summary_effect(row_idx) = median(anagram_tvd(valid_values) - exemplar_tvd(valid_values));
    summary_statistic(row_idx) = test_stats.signedrank;
    summary_p(row_idx) = p_value;

    match_raw = [squeeze(f3_raw(monkey_idx, :, 1, 1))'; squeeze(f3_raw(monkey_idx, :, 2, 2))'];
    nonmatch_raw = [squeeze(f3_raw(monkey_idx, :, 2, 1))'; squeeze(f3_raw(monkey_idx, :, 1, 2))'];
    match_z = [squeeze(f3_z(monkey_idx, :, 1, 1))'; squeeze(f3_z(monkey_idx, :, 2, 2))'];
    nonmatch_z = [squeeze(f3_z(monkey_idx, :, 2, 1))'; squeeze(f3_z(monkey_idx, :, 1, 2))'];
    [~, p_value, ~, test_stats] = ttest(match_z, nonmatch_z, 'Tail', 'right');
    row_idx = row_idx + 1;
    summary_monkey(row_idx) = monkey_names(monkey_idx);
    summary_panel(row_idx) = "Figure 3C";
    summary_sessions(row_idx) = session_count(monkey_idx);
    summary_n(row_idx) = length(match_z);
    summary_value_1(row_idx) = mean(match_raw);
    summary_value_2(row_idx) = mean(nonmatch_raw);
    summary_effect(row_idx) = mean(match_z - nonmatch_z);
    summary_statistic(row_idx) = test_stats.tstat;
    summary_p(row_idx) = p_value;

    bias_values = reshape(f4_bias(monkey_idx, :, :), [], 1);
    valid_values = isfinite(bias_values);
    [~, p_value, ~, test_stats] = ttest(bias_values(valid_values), 0, 'Tail', 'right');
    row_idx = row_idx + 1;
    summary_monkey(row_idx) = monkey_names(monkey_idx);
    summary_panel(row_idx) = "Figure 4F";
    summary_sessions(row_idx) = session_count(monkey_idx);
    summary_n(row_idx) = sum(valid_values);
    summary_value_1(row_idx) = mean(bias_values(valid_values));
    summary_value_2(row_idx) = 0;
    summary_effect(row_idx) = mean(bias_values(valid_values));
    summary_statistic(row_idx) = test_stats.tstat;
    summary_p(row_idx) = p_value;
end
summary_table = table(summary_monkey, summary_sessions, summary_panel, summary_n, summary_value_1, summary_value_2, summary_effect, summary_statistic, summary_p);
summary_table.Properties.VariableNames = {'Monkey', 'Sessions', 'Panel', 'N', 'Value1', 'Value2', 'Effect', 'Statistic', 'POneSided'};
save(fullfile(output_directory, 'MonkeyExactPanelReplication.mat'), 'summary_table', 'session_monkey', 'all_sessions', 'monkey_names', 'session_count', 'f2_matching_distance', 'f2_nonmatching_distance', 'f2_fit_count', 'f2_tvd', 'f3_raw', 'f3_z', 'f3_unit_count', 'f4_mean_score', 'f4_trial_count', 'f4_bias')