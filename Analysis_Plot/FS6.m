clear
clc
family_indices = [1, 2, 3, 4, 5, 7, 9, 10];
time_ms = -50:1:400;
bin_ms = 20;
smoothing_kernel = ones(1, 10);
decoder_lambda = 1e-3;
neuron_batch_size = 32;
latency_window_ms = [0, 400];
latency_hold_ms = 20;
load root_dir.mat
stimulus_root = fullfile(root_dir, 'data', 'stim');
%%
window_left_ms = floor(bin_ms / 2);
window_right_ms = bin_ms - window_left_ms - 1;
critical_angle_index = [1, 7; 1, 13; 1, 13; 1, 13; 13, 1; 13, 1; 19, 1; 19, 1; 13, 1; 1, 19];
critical_angle_offsets = -1:1;
critical_rows_by_family = zeros(numel(family_indices), 12);
for family_position = 1:numel(family_indices)
    centers = critical_angle_index(family_indices(family_position), :);
    first_angles = mod(centers(1) + critical_angle_offsets - 1, 24) + 1;
    second_angles = mod(centers(2) + critical_angle_offsets - 1, 24) + 1;
    critical_rows_by_family(family_position, :) = [first_angles, first_angles + 24, second_angles, second_angles + 24];
end
exemplar_rows = 49:144;
training_labels = [ones(48, 1); 2 * ones(48, 1)];
family_count = numel(family_indices);
time_count = numel(time_ms);
%% Match session stimulus indices and count ALL available neurons
session_files = dir(fullfile(root_dir, 'Data', 's0', '*AnagramP*.mat'));
session_count = numel(session_files);
session_family_rows = cell(session_count, family_count);
session_neuron_count = zeros(session_count, 1);
family_neuron_count = zeros(family_count, 1);
for session_index = 1:session_count
    session_path = fullfile(session_files(session_index).folder, session_files(session_index).name);
    raster_information = whos('-file', session_path, 'raster_mtx');
    session_neuron_count(session_index) = raster_information.size(1);
    if endsWith(session_files(session_index).name, '-AnagramPlus2.mat')
        set_name = 'AnagramPlus2';
        available_families = 6:10;
    elseif endsWith(session_files(session_index).name, '-AnagramPlus.mat')
        set_name = 'AnagramPlus';
        available_families = 1:5;
    elseif endsWith(session_files(session_index).name, '-AnagramPP.mat')
        set_name = 'AnagramPP';
        available_families = 1:10;
    end
    session_table = readtable(fullfile(stimulus_root, set_name, [set_name, '.tsv']), 'FileType', 'text', 'Delimiter', '\t');
    session_names = string(session_table.FileName);
    for family_position = 1:family_count
        family_index = family_indices(family_position);
        if ~ismember(family_index, available_families)
            continue
        end
        image_rows = zeros(1, 144);
        for condition_index = 1:3
            local_family_index = family_index - available_families(1) + 1;
            stimulus_number = (local_family_index - 1) * 3 + condition_index;
            start_row = find(session_names == sprintf('Stim%d_01_ang_000.jpg', stimulus_number) | session_names == sprintf('Stim%d_1_ang_000.jpg', stimulus_number));
            image_rows((condition_index - 1) * 48 + (1:48)) = start_row + (0:47);
        end
        session_family_rows{session_index, family_position} = image_rows;
        family_neuron_count(family_position) = family_neuron_count(family_position) + session_neuron_count(session_index);
    end
end
%% pseudo-populations
pseudo_rate_hz = cell(family_count, 1);
family_write_position = zeros(family_count, 1);
for family_position = 1:family_count
    pseudo_rate_hz{family_position} = zeros(family_neuron_count(family_position), 144, time_count, 'single');
end
analysis_timer = tic;
for session_index = 1:session_count
    if all(cellfun(@isempty, session_family_rows(session_index, :)))
        continue
    end
    session_path = fullfile(session_files(session_index).folder, session_files(session_index).name);
    session_data = load(session_path, 'trial_idx', 'glb');
    raw_time_ms = double(session_data.glb.PsthRange(:).');
    raw_start = find(raw_time_ms == time_ms(1) - window_left_ms, 1);
    raw_end = find(raw_time_ms == time_ms(end) + window_right_ms, 1);
    bin_start = time_ms - window_left_ms - raw_time_ms(raw_start) + 1;
    bin_end = bin_start + bin_ms - 1;
    trial_count = numel(session_data.trial_idx);
    raster_store = matfile(session_path);
    raster_size = size(raster_store, 'raster_mtx');
    image_trial_rows = cell(family_count, 144);
    for family_position = 1:family_count
        if isempty(session_family_rows{session_index, family_position})
            continue
        end
        image_rows = session_family_rows{session_index, family_position};
        for image_index = 1:144
            image_trial_rows{family_position, image_index} = find(session_data.trial_idx == image_rows(image_index));
        end
    end
    for first_neuron = 1:neuron_batch_size:session_neuron_count(session_index)
        neuron_rows = first_neuron:min(first_neuron + neuron_batch_size - 1, session_neuron_count(session_index));
        raster_batch = raster_store.raster_mtx(neuron_rows, 1:trial_count, raw_start:raw_end);
        for family_position = 1:family_count
            if isempty(session_family_rows{session_index, family_position})
                continue
            end
            image_mean = zeros(numel(neuron_rows), 144, raw_end - raw_start + 1, 'single');
            for image_index = 1:144
                image_mean(:, image_index, :) = mean(single(raster_batch(:, image_trial_rows{family_position, image_index}, :)), 2);
            end
            cumulative_spikes = cat(3, zeros(numel(neuron_rows), 144, 1, 'single'), cumsum(image_mean, 3));
            binned_rate = (cumulative_spikes(:, :, bin_end + 1) - cumulative_spikes(:, :, bin_start)) * (1000 / bin_ms);
            destination_rows = family_write_position(family_position) + neuron_rows;
            pseudo_rate_hz{family_position}(destination_rows, :, :) = binned_rate;
        end
    end
    for family_position = 1:family_count
        if ~isempty(session_family_rows{session_index, family_position})
            family_write_position(family_position) = family_write_position(family_position) + session_neuron_count(session_index);
        end
    end
    clear raster_batch image_mean cumulative_spikes binned_rate
    fprintf('Pseudo-population: session %d/%d; elapsed %.1f min.\n', session_index, session_count, toc(analysis_timer) / 60)
end
try
    parpool(18)
end
%% Fit one decoder per time bin; evaluate the two critical angles    
exemplar_probability_a = nan(family_count, 96, time_count);
anagram_probability_a = nan(family_count, 12, time_count);
for family_position = 1:family_count
    family_index = family_indices(family_position);
    family_response = pseudo_rate_hz{family_position};
    critical_rows = critical_rows_by_family(family_position, :);
    family_exemplar_probability = nan(96, time_count);
    family_anagram_probability = nan(12, time_count);
    family_timer = tic;
    parfor time_index = 1:time_count
        image_features = double(family_response(:, :, time_index)).';
        training_features = image_features(exemplar_rows, :);
        training_mean = mean(training_features, 1);
        training_std = std(training_features, 0, 1);
        training_std(training_std == 0) = 1;
        normalized_features = (image_features - training_mean) ./ training_std;
        decoder = fitclinear(normalized_features(exemplar_rows, :), training_labels, 'Learner', 'logistic', 'Regularization', 'ridge', 'Lambda', decoder_lambda, 'Solver', 'lbfgs', 'ScoreTransform', 'logit');
        [~, probabilities] = predict(decoder, normalized_features(critical_rows, :));
        family_anagram_probability(:, time_index) = probabilities(:, decoder.ClassNames == 1);
        cv_scores = nan(96, 1);
        for angle_index = 1:24
            test_rows = angle_index + [0, 24, 48, 72];
            train_rows = setdiff(1:96, test_rows);
            fold_mean = mean(training_features(train_rows, :), 1);
            fold_std = std(training_features(train_rows, :), 0, 1);
            fold_std(fold_std == 0) = 1;
            fold_train = (training_features(train_rows, :) - fold_mean) ./ fold_std;
            fold_test = (training_features(test_rows, :) - fold_mean) ./ fold_std;
            decoder = fitclinear(fold_train, training_labels(train_rows), 'Learner', 'logistic', 'Regularization', 'ridge', 'Lambda', decoder_lambda, 'Solver', 'lbfgs', 'ScoreTransform', 'logit');
            [~, probabilities] = predict(decoder, fold_test);
            cv_scores(test_rows) = probabilities(:, decoder.ClassNames == 1);
        end
        family_exemplar_probability(:, time_index) = cv_scores;
    end
    exemplar_probability_a(family_position, :, :) = reshape(family_exemplar_probability, 1, 96, time_count);
    anagram_probability_a(family_position, :, :) = reshape(family_anagram_probability, 1, 12, time_count);
    pseudo_rate_hz{family_position} = [];
    fprintf('Finished family %d: %.1f seconds.\n', family_index, toc(family_timer))
end
clear pseudo_rate_hz family_response
%% Balance the interpretations and smooth decoding Bias
exemplar_bias = reshape((mean(exemplar_probability_a(:, 1:48, :), 2) - mean(exemplar_probability_a(:, 49:96, :), 2)) / 2, family_count, time_count);
anagram_bias = reshape((mean(anagram_probability_a(:, 1:6, :), 2) - mean(anagram_probability_a(:, 7:12, :), 2)) / 2, family_count, time_count);
smoothing_weights = conv(ones(1, time_count), smoothing_kernel, 'same');
for family_position = 1:family_count
    exemplar_bias(family_position, :) = conv(exemplar_bias(family_position, :), smoothing_kernel, 'same') ./ smoothing_weights;
    anagram_bias(family_position, :) = conv(anagram_bias(family_position, :), smoothing_kernel, 'same') ./ smoothing_weights;
end
mean_exemplar_bias = mean(exemplar_bias, 1);
mean_anagram_bias = mean(anagram_bias, 1);
%% Family t50: first sustained half-response crossing
response_rows = find(time_ms >= latency_window_ms(1) & time_ms <= latency_window_ms(2));
baseline_rows = find(time_ms + window_right_ms + ceil(numel(smoothing_kernel) / 2) < 0);
hold_samples = ceil(latency_hold_ms / (time_ms(2) - time_ms(1)));
t50_ms = nan(family_count, 2);
for family_position = 1:family_count
    for stimulus_type = 1:2
        if stimulus_type == 1
            trace = exemplar_bias(family_position, :);
        else
            trace = anagram_bias(family_position, :);
        end
        baseline = mean(trace(baseline_rows));
        increase = max(trace(response_rows)) - baseline;
        if increase <= 0
            continue
        end
        above_threshold = trace(response_rows) >= baseline + 0.5 * increase;
        for first_row = 1:numel(response_rows) - hold_samples + 1
            if all(above_threshold(first_row:first_row + hold_samples - 1))
                t50_ms(family_position, stimulus_type) = time_ms(response_rows(first_row));
                break
            end
        end
    end
end
%% Paired-family latency and Bias strength
bias_strength_window_ms = [60, 300];
strength_rows = time_ms >= 60 & time_ms <= 300;
bias_strength = [mean(exemplar_bias(:, strength_rows), 2), mean(anagram_bias(:, strength_rows), 2)];
bias_strength_difference = bias_strength(:, 1) - bias_strength(:, 2);
%% Exact paired Wilcoxon tests
paired_t50 = t50_ms(all(isfinite(t50_ms), 2), :);
t50_lag_ms = paired_t50(:, 2) - paired_t50(:, 1);
paired_bias = bias_strength(all(isfinite(bias_strength), 2), :);
t50_p = signrank(paired_t50(:, 2), paired_t50(:, 1), 'tail', 'both', 'method', 'exact');
bias_strength_p = signrank(paired_bias(:, 1), paired_bias(:, 2), 'tail', 'both', 'method', 'exact');
%% Plot
colors = [0.1, 0.4, 0.8; 0.8, 0.2, 0.1];
bias_curves = {exemplar_bias, anagram_bias};
bias_means = {mean_exemplar_bias, mean_anagram_bias};

figure('Position', [100, 100, 350, 500]);
subplot(3,1,[1,2]); hold on
for condition_index = 1:2
    traces = bias_curves{condition_index};
    average = bias_means{condition_index};
    standard_error = std(traces, 0, 1) / sqrt(family_count);
    fill([time_ms, fliplr(time_ms)], [average - standard_error, fliplr(average + standard_error)], colors(condition_index, :), 'FaceAlpha', .13, 'EdgeColor', 'none')
    pale_color = .65 + .35 * colors(condition_index, :);
    for family_position = 1:family_count
        plot(time_ms, traces(family_position, :), 'Color', pale_color, 'LineWidth', .55)
        row = find(time_ms == t50_ms(family_position, condition_index), 1);
        plot(time_ms(row), traces(family_position, row), 'o', 'Color', pale_color, 'MarkerFaceColor', pale_color, 'MarkerSize', 3)
    end
end
mean_lines = gobjects(1, 2);
for condition_index = 1:2
    mean_lines(condition_index) = plot(time_ms, bias_means{condition_index}, 'Color', colors(condition_index, :), 'LineWidth', 2);
end
yline(0, ':', 'Color', [.5,.5,.5]); ylim([-.15,.55])
ylabel('Decoding bias'); xlabel('Time (ms)');xlim([0,300]);
legend(mean_lines, {'Exemplar','Anagram'}, 'Location', 'best', 'Box', 'off')
title(sprintf('Mean Bias: E %.2f | A %.2f |p = %.1e', mean(paired_bias(:, 1)), mean(paired_bias(:, 2)),bias_strength_p))

subplot(3,1,3); hold on
for family_position = 1:family_count
    if all(isfinite(t50_ms(family_position, :)))
        plot(t50_ms(family_position, :), [2,1], '-', 'Color', [.8,.8,.8], 'LineWidth', .6)
    end
end
for condition_index = 1:2
    position = (3 - condition_index) * ones(family_count, 1);
    boxchart(position, t50_ms(:, condition_index), 'Orientation', 'horizontal', 'BoxFaceColor', colors(condition_index, :), 'BoxFaceAlpha', .12, 'MarkerStyle', 'none', 'BoxWidth', .4)
    scatter(t50_ms(:, condition_index), position, 12, colors(condition_index, :), 'filled')
end
yticks([1,2]); yticklabels({'Anagram','Exemplar'}); ylim([.4,2.6]);xlabel('t50 (ms)'); xlim([0,300]);
title(sprintf('Mean t50: E %.0f ms | A %.0f ms | P = %.1e', round(mean(paired_t50(:, 1))), round(mean(paired_t50(:, 2))),t50_p))
figsave(fullfile(root_dir,'Fig'),'FS6')