%% Neural pseudo-population decoding for Figure 6
close all;clear;clc
% Analysis settings
smoothing_window_ms = 50;
sampled_time_ms = -50:5:400;
decoder_window_ms = [60, 400];
images_per_stimulus = 48;
angles_per_mirror = 24;
decoder_lambda = 1e-3;
% Paths
load root_dir.mat
output_directory = fullfile(root_dir,'Data', 'output');
mkdir(output_directory)
tensor_directory = fullfile(root_dir,'Data', 'neural_pseudopopulation');
mkdir(tensor_directory)
stimulus_root = fullfile(root_dir, 'Data', 'stim');

session_files = dir(fullfile(root_dir, 'Data', 's0', '*AnagramP*.mat'));
session_file_names = string({session_files.name}).';
session_family_indices = cell(length(session_files), 1);
session_neuron_counts = zeros(length(session_files), 1);
family_total_neurons = zeros(10, 1);

for session_index = 1:length(session_files)
    session_path = fullfile(session_files(session_index).folder, session_files(session_index).name);
    raster_information = whos('-file', session_path, 'raster_mtx');
    session_neuron_counts(session_index) = raster_information.size(1);
    set_name = identify_set_name(session_files(session_index).name);
    [~, ~, global_family_indices] = gen_famuli_compare(set_name);
    session_family_indices{session_index} = global_family_indices(:).';
    family_total_neurons(global_family_indices) = family_total_neurons(global_family_indices) + session_neuron_counts(session_index);
end
cd(root_dir)
%% Use the same temporal settings as S4
first_session_path = fullfile(session_files(1).folder, session_files(1).name);
first_session = load(first_session_path, 'glb');
time_ms = sampled_time_ms;
time_positions = first_session.glb.pre_onset + time_ms;
mean_time_rows = find(time_ms >= decoder_window_ms(1) & time_ms <= decoder_window_ms(2));
time_count = length(time_ms);
image_count = images_per_stimulus * 3;
smoothing_kernel = reshape(ones(smoothing_window_ms, 1, 'single'), 1, 1, smoothing_window_ms);

% Compute the exact time weights for the S4 mean of 50 ms binned responses.
raw_time_count = length(first_session.glb.PsthRange);
mean_response_weights = zeros(1, raw_time_count, 'single');
mean_time_positions = time_positions(mean_time_rows);
for raw_time_index = 1:raw_time_count
    impulse = zeros(1, raw_time_count, 'single');
    impulse(raw_time_index) = 1;
    binned_impulse = conv(impulse, ones(1, smoothing_window_ms, 'single'), 'same');
    mean_response_weights(raw_time_index) = mean(binned_impulse(mean_time_positions));
end
weighted_time_rows = find(mean_response_weights > 0);
%% Preallocate one on-disk neuron x image x time tensor per family
family_tensor_files = strings(10, 1);
family_write_positions = zeros(10, 1);
for family_index = 1:10
    family_tensor_files(family_index) = fullfile(tensor_directory, sprintf('Neural_Pseudopopulation_Family%02d.mat', family_index));
    if isfile(family_tensor_files(family_index))
        delete(family_tensor_files(family_index))
    end
    response_description = sprintf('Trial-averaged %d-ms binned response; dimensions are neuron x image x time.', smoothing_window_ms);
    mean_response_description = sprintf('The %d-%d ms response was z-scored per neuron across all trials within its session, then averaged for each image.', decoder_window_ms(1), decoder_window_ms(2));
    save(family_tensor_files(family_index), 'time_ms', 'session_file_names', 'response_description', 'mean_response_description', '-v7.3')
    family_store = matfile(family_tensor_files(family_index), 'Writable', true);
    family_store.response(family_total_neurons(family_index), image_count, time_count) = single(0);
    family_store.mean_response(family_total_neurons(family_index), image_count) = single(0);
    family_store.neuron_session_index(family_total_neurons(family_index), 1) = uint16(0);
    family_store.neuron_within_session(family_total_neurons(family_index), 1) = uint16(0);
end
%% Average repeated trials within each session and concatenate neurons
for session_index = 1:length(session_files)
    session_path = fullfile(session_files(session_index).folder, session_files(session_index).name);
    session_data = load(session_path, 'raster_mtx', 'trial_idx', 'glb');
    neuron_count = size(session_data.raster_mtx, 1);
    trial_count = size(session_data.raster_mtx, 2);

    % Match the S4 standardization for the 60-400 ms mean response.
    trial_mean_response = zeros(neuron_count, trial_count, 'single');
    for weighted_index = 1:length(weighted_time_rows)
        raw_time_index = weighted_time_rows(weighted_index);
        trial_mean_response = trial_mean_response + single(session_data.raster_mtx(:, :, raw_time_index)) * mean_response_weights(raw_time_index);
    end
    trial_response_mean = mean(trial_mean_response, 2);
    trial_response_std = std(trial_mean_response, 0, 2);
    standardized_trial_response = nan(neuron_count, trial_count, 'single');
    valid_session_neurons = isfinite(trial_response_std) & trial_response_std > 0;
    standardized_trial_response(valid_session_neurons, :) = (trial_mean_response(valid_session_neurons, :) - trial_response_mean(valid_session_neurons)) ./ trial_response_std(valid_session_neurons);

    set_name = identify_set_name(session_files(session_index).name);
    [family_stimuli_session, ~, global_family_indices] = gen_famuli_compare(set_name);
    for local_family_index = 1:length(global_family_indices)
        global_family_index = global_family_indices(local_family_index);
        family_stimuli = family_stimuli_session{local_family_index};
        image_response = zeros(neuron_count, image_count, raw_time_count, 'single');
        mean_image_response = nan(neuron_count, image_count, 'single');
        for image_index = 1:image_count
            image_trial_rows = find(session_data.trial_idx == family_stimuli(image_index));
            if isempty(image_trial_rows)
                error('Stimulus %d has no trials in %s.', family_stimuli(image_index), session_files(session_index).name)
            end
            image_response(:, image_index, :) = mean(single(session_data.raster_mtx(:, image_trial_rows, :)), 2);
            mean_image_response(:, image_index) = mean(standardized_trial_response(:, image_trial_rows), 2, 'omitnan');
        end
        binned_image_response = convn(image_response, smoothing_kernel, 'same');
        selected_image_response = binned_image_response(:, :, time_positions);
        first_neuron_row = family_write_positions(global_family_index) + 1;
        last_neuron_row = family_write_positions(global_family_index) + neuron_count;
        family_store = matfile(family_tensor_files(global_family_index), 'Writable', true);
        family_store.response(first_neuron_row:last_neuron_row, :, :) = selected_image_response;
        family_store.mean_response(first_neuron_row:last_neuron_row, :) = mean_image_response;
        family_store.neuron_session_index(first_neuron_row:last_neuron_row, 1) = uint16(session_index);
        family_store.neuron_within_session(first_neuron_row:last_neuron_row, 1) = uint16((1:neuron_count).');
        family_write_positions(global_family_index) = last_neuron_row;
        clear image_response binned_image_response selected_image_response mean_image_response
    end
    clear session_data trial_mean_response standardized_trial_response
end
%% Train on 48 + 48 canonical images and test the Anagram
[~, critical_points, ~] = gen_famuli_compare('AnagramPP');
rng(1009)
condition_bias = nan(10, 2);
mean_exemplar_a_probability = nan(10, 2);
valid_neuron_count = zeros(10, 1);
for family_index = 1:10
    family_store = matfile(family_tensor_files(family_index));
    family_mean_response = double(family_store.mean_response);
    valid_neurons = all(isfinite(family_mean_response), 2) & std(family_mean_response, 0, 2) > 0;
    family_mean_response = family_mean_response(valid_neurons, :);
    valid_neuron_count(family_index) = sum(valid_neurons);
    exemplar_a_rows = (images_per_stimulus + 1):(2 * images_per_stimulus);
    exemplar_b_rows = (2 * images_per_stimulus + 1):(3 * images_per_stimulus);
    training_features = [family_mean_response(:, exemplar_a_rows), family_mean_response(:, exemplar_b_rows)].';
    training_labels = [ones(images_per_stimulus, 1); 2 * ones(images_per_stimulus, 1)];
    decoder = fitclinear(training_features, training_labels, 'Learner', 'logistic', 'Regularization', 'ridge', 'Lambda', 1e-3);
    exemplar_a_column = find(decoder.ClassNames == 1, 1);
    for canonical_index = 1:2
        center_index = critical_points(family_index, canonical_index, 2);
        test_rows = [center_index, center_index + angles_per_mirror];
        test_features = family_mean_response(:, test_rows).';
        [~, class_scores] = predict(decoder, test_features);
        exemplar_a_probability = mean(class_scores(:, exemplar_a_column));
        mean_exemplar_a_probability(family_index, canonical_index) = exemplar_a_probability;
        if canonical_index == 1
            condition_bias(family_index, canonical_index) = exemplar_a_probability - 0.5;
        else
            condition_bias(family_index, canonical_index) = 0.5 - exemplar_a_probability;
        end
    end
end

% Keep both canonical conditions in each family as separate observations.
family_column = repelem((1:10).', 2);
canonical_column = repmat((1:2).', 10, 1);
probability_column = reshape(mean_exemplar_a_probability.', [], 1);
bias_column = reshape(condition_bias.', [], 1);
condition_count = numel(bias_column);
assert(condition_count == 20 && all(isfinite(bias_column)), 'Decoding requires 20 finite condition biases.');
[~, one_sided_p, ~, test_statistics] = ttest(bias_column, 0, 'Tail', 'right');
signrank_p = signrank(bias_column, 0, 'Tail', 'right');
neural_decoding_condition_table = table(family_column, canonical_column, probability_column, bias_column, repelem(valid_neuron_count, 2), 'VariableNames', {'Family', 'Canonical', 'MeanPExemplarA', 'Bias', 'NeuronCount'});
neural_decoding_summary_table = table(mean(bias_column), std(bias_column) / sqrt(condition_count), condition_count, test_statistics.tstat, test_statistics.df, one_sided_p, signrank_p, length(session_files), 'VariableNames', {'MeanBias', 'SEMAcross20Conditions', 'ConditionCount', 'ConditionBiasT', 'ConditionBiasDF', 'ConditionBiasOneSidedP', 'ConditionBiasSignrankP', 'SessionFileCount'});
preprocessing_description = sprintf('Within each session, repeated trials were averaged by image after per-neuron trial-wise z-scoring. Neurons were then concatenated across sessions. The decoder used %d-%d ms mean responses, %d images per exemplar, L2 logistic regression with Lambda %.4g, and two Anagram mirror images per canonical angle. Summary statistics and tests used 20 separate canonical-angle conditions, ordered by family then canonical angle.', decoder_window_ms(1), decoder_window_ms(2), images_per_stimulus, decoder_lambda);
save(fullfile(output_directory, 'Neural_Pseudopopulation_Decoding.mat'), 'neural_decoding_condition_table', 'neural_decoding_summary_table', 'condition_bias', 'family_total_neurons', 'valid_neuron_count', 'family_tensor_files', 'time_ms', 'session_file_names', 'preprocessing_description')
