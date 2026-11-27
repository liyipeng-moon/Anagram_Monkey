close all; clear; clc;
parpool(20)
%% Analysis settings
response_window_ms = [60, 400];
unit_dprime_threshold = 0.5;
tuning_fit_r_threshold = 0.3;
neural_rotation_p_threshold = 0.001;
decoder_lambda = 1e-3;
%% Paths and model groups
load root_dir.mat
cd(root_dir)
feature_dir = fullfile(root_dir,'Data/extracted_responses');
anagram_feature_directory = fullfile(feature_dir, 'AnagramPP');
shape_texture_feature_directory = fullfile(feature_dir, 'ShapeTexture1230');
stimulus_root = fullfile(root_dir, 'Data', 'stim');
output_directory = fullfile(root_dir,'Data', 'output');
mkdir(output_directory)
%% Neural single-unit matching-angle reference
[neural_matching_distance_degree, neural_alternative_distance_degree, neural_distance_advantage_degree, neural_matching_angle_advantage, neural_tuning_p, neural_condition_matching_angle_advantage] = calculate_neural_matching_angle_advantage(stimulus_root, root_dir, response_window_ms, unit_dprime_threshold, tuning_fit_r_threshold, neural_rotation_p_threshold);
%% Neural pseudo-population decoding reference
neural_pseudopopulation_result = load(fullfile(output_directory, 'Neural_Pseudopopulation_Decoding.mat'));
neural_decoding_condition_table = neural_pseudopopulation_result.neural_decoding_condition_table;
neural_decoding_summary_table = neural_pseudopopulation_result.neural_decoding_summary_table;
neural_decoding_condition_table = sortrows(neural_decoding_condition_table, {'Family', 'Canonical'});
neural_condition_decoding_bias = neural_decoding_condition_table.Bias.';
assert(isequal(neural_decoding_condition_table.Family, repelem((1:10).', 2)) && isequal(neural_decoding_condition_table.Canonical, repmat((1:2).', 10, 1)), 'Neural decoding must contain the 20 family/canonical conditions.');
assert(all(isfinite(neural_condition_decoding_bias)) && ismember('ConditionCount', neural_decoding_summary_table.Properties.VariableNames), 'Rerun Figure6_Neural_Pooled_Decoding for 20-condition statistics.');
assert(neural_decoding_summary_table.ConditionCount == 20, 'Neural decoding statistics must use 20 conditions.');
%% Define model pools
architecture_names = ["ViT family"; "ResNet family"];
architecture_models = cell(2, 1);
architecture_models{1} = [
    "siglip"; "clip"; "clip_vit_b16"; "eva02_clip_b16";
    "dino_vit_b16"; "dinov2_vitb14"; "dinov3_vitb16";
    "mocov3_vit_b16"; "mae"; "imagenet_vit_b16"; "deit_b16_in1k"];
architecture_models{2} = [
    "clip_rn50"; "openclip_rn50_cc12m"; "openclip_rn50_yfcc15m";
    "simclr"; "dino_resnet50"; "moco_v2"; "mocov3_resnet50";
    "swav"; "imagenet_resnet50"; "resnet18"; "resnet34";
    "resnet101"; "robust_resnet50"];
all_models = [
    "alexnet"; "clip"; "clip_rn50"; "clip_vit_b16"; "convnext_tiny";
    "cornet_s"; "deit_b16_in1k"; "densenet121"; "dino_resnet50";
    "dino_v1"; "dino_vit_b16"; "dinov2"; "dinov2_vitb14";
    "dinov3_vitb16"; "dinov3_vitl16"; "efficientnet_b0";
    "eva02_clip_b16"; "imagenet_resnet50"; "imagenet_vit";
    "imagenet_vit_b16"; "mae"; "mobilenet_v3_large"; "moco_v2";
    "mocov3_resnet50"; "mocov3_vit_b16"; "openclip_rn50_cc12m";
    "openclip_rn50_yfcc15m"; "regnet_y_400mf"; "resnet101";
    "resnet18"; "resnet34"; "robust_resnet50"; "siglip"; "simclr";
    "swav"; "swin_tiny"; "vgg16"];
%% Model results
[all_model_table, all_condition_matching_angle_advantage] = calculate_model_matching_angle_advantage(stimulus_root, anagram_feature_directory, all_models, unit_dprime_threshold, tuning_fit_r_threshold);
[model_decoding_bias, all_condition_decoding_bias, decoding_layers] = calculate_model_decoding_bias(stimulus_root, anagram_feature_directory, all_models, decoder_lambda);
[partial_shape_r, partial_texture_r, shape_minus_texture_r] = calculate_shape_texture_preference(shape_texture_feature_directory, all_models);

training_group_names = ["Language-supervised"; "Self-supervised"; "Image classification"];
training_colors = [0.84, 0.37, 0.00; 0.00, 0.45, 0.70; 0.00, 0.62, 0.45];
neuron_color = [0.20, 0.20, 0.20];
all_model_table.PartialShapeR = partial_shape_r;
all_model_table.PartialTextureR = partial_texture_r;
all_model_table.ShapeMinusTextureR = shape_minus_texture_r;
all_model_table.DecodingBias = model_decoding_bias;
all_model_table.DecodingLayer = decoding_layers;
all_model_table.DisplayName = get_model_display_names(all_models);
all_model_table.TrainingGroup = training_group_names(get_training_groups(all_models));
%% Statistical comparisons
% Cross-model tests use one 20-condition mean per model.
scatter_table = all_model_table;
correlation_metric_names = ["Normalized matching-angle advantage"; "Decoding bias"];
correlation_values = {scatter_table.NormalizedMatchingAngleAdvantage, scatter_table.DecodingBias};
scope_names = ["All models"; architecture_names];
shape_correlation_table = table;
for metric_index = 1:2
    for scope_index = 1:3
        if scope_index == 1
            model_rows = true(height(scatter_table), 1);
        else
            model_rows = ismember(scatter_table.Model, architecture_models{scope_index - 1});
        end
        metric_values = correlation_values{metric_index};
        [rho_value, p_value] = corr(scatter_table.ShapeMinusTextureR(model_rows), metric_values(model_rows), 'Type', 'Spearman');
        new_row = table(scope_names(scope_index), correlation_metric_names(metric_index), sum(model_rows), rho_value, p_value, 'VariableNames', {'Scope', 'Metric', 'ModelCount', 'SpearmanRho', 'TwoSidedP'});
        shape_correlation_table = [shape_correlation_table; new_row]; %#ok<AGROW>
    end
end

comparison_metric = correlation_metric_names;
comparison_values = correlation_values;
architecture_comparison_table = table;
for metric_index = 1:2
    vit_values = comparison_values{metric_index}(ismember(all_models, architecture_models{1}));
    resnet_values = comparison_values{metric_index}(ismember(all_models, architecture_models{2}));
    new_row = table(comparison_metric(metric_index), mean(vit_values), mean(resnet_values), ranksum(vit_values, resnet_values), 'VariableNames', {'Metric', 'ViTMean', 'ResNetMean', 'TwoSidedRankSumP'});
    architecture_comparison_table = [architecture_comparison_table; new_row];
end
%% Save numerical results
[~, result_critical_points] = get_anagrampp_model_definition(stimulus_root, anagram_feature_directory, all_models(1));
canonical_angle_a_degree = (result_critical_points(:, 1, 2) - 1) * 15;
canonical_angle_b_degree = (result_critical_points(:, 2, 2) - 1) * 15;
canonical_separation_degree = abs(rad2deg(angle(exp(1i * deg2rad(canonical_angle_a_degree - canonical_angle_b_degree)))));
canonical_angle_normalization_table = table((1:10).', canonical_angle_a_degree, canonical_angle_b_degree, canonical_separation_degree, 'VariableNames', {'Family', 'CanonicalAngleADegree', 'CanonicalAngleBDegree', 'NormalizationDegree'});
neural_metric = ["SingleUnitMatchingDistanceDegree"; "SingleUnitAlternativeDistanceDegree"; "SingleUnitDistanceAdvantageDegree"; "SingleUnitNormalizedMatchingAngleAdvantage"; "DecodingBias"; "DecodingBiasSEM"];
neural_value = [neural_matching_distance_degree; neural_alternative_distance_degree; neural_distance_advantage_degree; neural_matching_angle_advantage; neural_decoding_summary_table.MeanBias; neural_decoding_summary_table.SEMAcross20Conditions];
neural_reference_table = table(neural_metric, neural_value, 'VariableNames', {'Metric', 'NeuronValue'});
decoding_summary_table = table(mean(model_decoding_bias), median(model_decoding_bias), neural_decoding_summary_table.MeanBias, neural_decoding_summary_table.SEMAcross20Conditions, 'VariableNames', {'ModelMeanBias', 'ModelMedianBias', 'NeuronMeanBias', 'NeuronSEMAcross20Conditions'});
save(fullfile(output_directory, 'Figure6_Results.mat'), 'all_model_table', 'shape_correlation_table', 'architecture_comparison_table', 'decoding_summary_table', 'neural_reference_table', 'neural_decoding_condition_table', 'canonical_angle_normalization_table', 'all_condition_matching_angle_advantage', 'all_condition_decoding_bias', 'neural_condition_matching_angle_advantage', 'neural_condition_decoding_bias', 'neural_decoding_summary_table', 'neural_tuning_p')

function [matching_mean, alternative_mean, distance_advantage, normalized_advantage, summary_p, condition_advantage] = calculate_neural_matching_angle_advantage(stimulus_root, root_dir, response_window_ms, dp_threshold, fit_r_threshold, p_threshold)
dp_pool = cell(10, 1);
mu_pool = cell(10, 1);
fit_r_pool = cell(10, 1);
p_pool = cell(10, 1);
cd(root_dir)
session_files = dir(fullfile(root_dir, 'Data', 's0', '*AnagramP*.mat'));
for session_index = 1:length(session_files)
    session_path = fullfile(session_files(session_index).folder, session_files(session_index).name);
    session_data = load(session_path, 'raster_mtx', 'trial_idx', 'glb');
    metric_name = sprintf('%s_metric.mat', session_files(session_index).name(1:end - 4));
    metric_path = fullfile(root_dir, 'Data', 'single', metric_name);
    metric_data = load(metric_path, 'vm_param', 'p48');
    set_name = identify_set_name(session_files(session_index).name);
    [family_stimuli_session, ~, global_family_indices] = gen_famuli_compare(set_name);
    response_time_points = response_window_ms(1):response_window_ms(2);
    response_window = session_data.glb.pre_onset + response_time_points;
    response_window_seconds = diff(response_window_ms) / 1000;
    trial_response = squeeze(sum(single(session_data.raster_mtx(:, :, response_window)), 3)) / response_window_seconds;
    for local_family_index = 1:length(family_stimuli_session)
        global_family_index = global_family_indices(local_family_index);
        family_stimuli = family_stimuli_session{local_family_index};
        exemplar_a_stimuli = family_stimuli(49:96);
        exemplar_b_stimuli = family_stimuli(97:144);
        exemplar_a_trials = find(session_data.trial_idx >= min(exemplar_a_stimuli) & session_data.trial_idx <= max(exemplar_a_stimuli));
        exemplar_b_trials = find(session_data.trial_idx >= min(exemplar_b_stimuli) & session_data.trial_idx <= max(exemplar_b_stimuli));
        exemplar_dp = calc_dp(trial_response, exemplar_a_trials, exemplar_b_trials);
        metric_columns = map_family_metric_columns(family_stimuli);
        anagram_columns = metric_columns(1:2);
        dp_pool{global_family_index} = [dp_pool{global_family_index}; exemplar_dp(:)];
        mu_pool{global_family_index} = [mu_pool{global_family_index}; metric_data.vm_param(:, anagram_columns, 1)];
        fit_r_pool{global_family_index} = [fit_r_pool{global_family_index}; metric_data.vm_param(:, anagram_columns, 5)];
        p_pool{global_family_index} = [p_pool{global_family_index}; metric_data.p48(:, anagram_columns)];
    end
    fprintf('Figure 6 neuronal data %d/%d\n', session_index, length(session_files))
end
[~, critical_points, ~] = gen_famuli_compare('AnagramPP');
critical_angles = deg2rad((critical_points(:, :, 2) - 1) * 15);
canonical_separation_degrees = abs(rad2deg(angle(exp(1i * (critical_angles(:, 1) - critical_angles(:, 2))))));
interpretation_matching_distance = nan(20, 1);
interpretation_alternative_distance = nan(20, 1);
for family_index = 1:10
    family_dp = dp_pool{family_index};
    family_mu = mu_pool{family_index};
    family_fit_r = fit_r_pool{family_index};
    family_p = p_pool{family_index};
    selected_neurons = find(abs(family_dp) > dp_threshold);
    for population_index = 1:2
        if population_index == 1
            population_rows = selected_neurons(family_dp(selected_neurons) > dp_threshold);
        else
            population_rows = selected_neurons(family_dp(selected_neurons) < -dp_threshold);
        end
        mu_values = [family_mu(population_rows, 1); family_mu(population_rows, 2)];
        fit_r_values = [family_fit_r(population_rows, 1); family_fit_r(population_rows, 2)];
        p_values = [family_p(population_rows, 1); family_p(population_rows, 2)];
        good_values = isfinite(mu_values) & fit_r_values >= fit_r_threshold & p_values < p_threshold;
        mu_values = mu_values(good_values);
        matching_angle = critical_angles(family_index, population_index);
        alternative_angle = critical_angles(family_index, 3 - population_index);
        matching_distance = abs(rad2deg(angle(exp(1i * (mu_values - matching_angle)))));
        alternative_distance = abs(rad2deg(angle(exp(1i * (mu_values - alternative_angle)))));
        interpretation_index = 2 * family_index - 2 + population_index;
        interpretation_matching_distance(interpretation_index) = mean(matching_distance);
        interpretation_alternative_distance(interpretation_index) = mean(alternative_distance);
    end
end
valid_rows = isfinite(interpretation_matching_distance) & isfinite(interpretation_alternative_distance);
matching_mean = mean(interpretation_matching_distance(valid_rows));
alternative_mean = mean(interpretation_alternative_distance(valid_rows));
distance_advantage = alternative_mean - matching_mean;
condition_normalization_degrees = repelem(canonical_separation_degrees, 2);
normalized_advantage = mean((interpretation_alternative_distance(valid_rows) - interpretation_matching_distance(valid_rows)) ./ condition_normalization_degrees(valid_rows));
summary_p = signrank(interpretation_matching_distance(valid_rows), interpretation_alternative_distance(valid_rows), 'Tail', 'left');
condition_advantage = (interpretation_alternative_distance - interpretation_matching_distance) ./ condition_normalization_degrees;
end

function [partial_shape_r, partial_texture_r, shape_minus_texture_r] = calculate_shape_texture_preference(feature_directory, model_names)
% Compare each model RDM with independent shape and texture hypothesis RDMs.
shape_id = repelem((1:30)', 41);
texture_id = repmat((1:41)', 30, 1);
upper_triangle = triu(true(1230), 1);
shape_distance = squareform(pdist(shape_id, 'hamming'));
texture_distance = squareform(pdist(texture_id, 'hamming'));
shape_values = shape_distance(upper_triangle);
texture_values = texture_distance(upper_triangle);
shape_texture_r = corr(shape_values, texture_values, 'Type', 'Spearman');
partial_shape_r = nan(length(model_names), 1);
partial_texture_r = nan(length(model_names), 1);
for model_index = 1:length(model_names)
    [features, layer_name] = load_final_model_response(feature_directory, model_names(model_index));
    feature_norm = sqrt(sum(features .^ 2, 2));
    feature_norm(feature_norm == 0) = 1;
    normalized_features = features ./ feature_norm;
    model_distance = 1 - normalized_features * normalized_features';
    model_distance = max(0, min(2, model_distance));
    model_values = model_distance(upper_triangle);
    model_shape_r = corr(model_values, shape_values, 'Type', 'Spearman');
    model_texture_r = corr(model_values, texture_values, 'Type', 'Spearman');
    partial_shape_r(model_index) = (model_shape_r - model_texture_r * shape_texture_r) / sqrt((1 - model_texture_r ^ 2) * (1 - shape_texture_r ^ 2));
    partial_texture_r(model_index) = (model_texture_r - model_shape_r * shape_texture_r) / sqrt((1 - model_shape_r ^ 2) * (1 - shape_texture_r ^ 2));
    fprintf('Shape-texture RSA %d/%d: %s / %s\n', model_index, length(model_names), model_names(model_index), layer_name)
end
shape_minus_texture_r = partial_shape_r - partial_texture_r;
end

function [model_bias, condition_bias, final_layers] = calculate_model_decoding_bias(stimulus_root, feature_directory, model_names, lambda)
% Train one canonical-exemplar decoder per model and Anagram family.
images_per_stimulus = 48;
angles_per_mirror = 24;
rng(1009)
[family_model_rows, critical_points] = get_anagrampp_model_definition(stimulus_root, feature_directory, model_names(1));

model_bias = nan(length(model_names), 1);
condition_bias = nan(length(model_names), 20);
final_layers = strings(length(model_names), 1);
for model_index = 1:length(model_names)
    [layer_response, final_layers(model_index)] = load_final_model_response(feature_directory, model_names(model_index));
    feature_standard_deviation = std(layer_response, 0, 1);
    valid_features = feature_standard_deviation > 0 & isfinite(feature_standard_deviation) & all(isfinite(layer_response), 1);
    layer_response = zscore(layer_response(:, valid_features), 0, 1);

    for family_index = 1:10
        rows_here = family_model_rows{family_index};
        anagram_rows = rows_here(1:images_per_stimulus);
        exemplar_a_rows = rows_here((images_per_stimulus + 1):(2 * images_per_stimulus));
        exemplar_b_rows = rows_here((2 * images_per_stimulus + 1):(3 * images_per_stimulus));
        training_features = [layer_response(exemplar_a_rows, :); layer_response(exemplar_b_rows, :)];
        training_labels = [ones(images_per_stimulus, 1); 2 * ones(images_per_stimulus, 1)];
        decoder = fitclinear(training_features, training_labels, 'Learner', 'logistic', 'Regularization', 'ridge', 'Lambda', 1e-3);
        exemplar_a_column = find(decoder.ClassNames == 1, 1);

        for canonical_index = 1:2
            center_index = critical_points(family_index, canonical_index, 2);
            test_rows = anagram_rows([center_index, center_index + angles_per_mirror]);
            test_features = layer_response(test_rows, :);
            [~, class_scores] = predict(decoder, test_features);
            exemplar_a_probability = class_scores(:, exemplar_a_column);
            if canonical_index == 1
                bias_here = mean(exemplar_a_probability - 0.5);
            else
                bias_here = mean(0.5 - exemplar_a_probability);
            end
            condition_column = 2 * family_index - 2 + canonical_index;
            condition_bias(model_index, condition_column) = bias_here;
        end
    end
    assert(all(isfinite(condition_bias(model_index, :))), 'Model decoding requires 20 finite condition biases.');
    model_bias(model_index) = mean(condition_bias(model_index, :));
    fprintf('Figure 6 decoding %d/%d: %s / %s, mean bias = %.3f\n', model_index, length(model_names), model_names(model_index), final_layers(model_index), model_bias(model_index))
    clear layer_response
end
end

function [model_table, condition_matching_angle_advantage] = calculate_model_matching_angle_advantage(stimulus_root, feature_directory, model_names, dp_threshold, fit_r_threshold)
% Fit model-unit tuning and measure proximity to the matching critical angle.
images_per_stimulus = 48;
angles_per_mirror = 24;
[family_model_rows, critical_points] = get_anagrampp_model_definition(stimulus_root, feature_directory, model_names(1));
critical_angles_degrees = (critical_points(:, :, 2) - 1) * 15;
canonical_separation_degrees = abs(rad2deg(angle(exp(1i * deg2rad(critical_angles_degrees(:, 1) - critical_angles_degrees(:, 2))))));
final_layers = strings(length(model_names), 1);
model_matching_angle_advantage = nan(length(model_names), 1);
distance_advantage_degree = nan(length(model_names), 1);
condition_matching_angle_advantage = nan(length(model_names), 20);
for model_index = 1:length(model_names)
    [layer_response, final_layers(model_index)] = load_final_model_response(feature_directory, model_names(model_index));
    layer_response = layer_response - min(layer_response, [], 1);
    family_population_advantage = nan(10, 2);
    for family_index = 1:10
        rows_here = family_model_rows{family_index};
        anagram_rows = rows_here(1:images_per_stimulus);
        exemplar_a_rows = rows_here((images_per_stimulus + 1):(2 * images_per_stimulus));
        exemplar_b_rows = rows_here((2 * images_per_stimulus + 1):(3 * images_per_stimulus));
        exemplar_a_response = layer_response(exemplar_a_rows, :);
        exemplar_b_response = layer_response(exemplar_b_rows, :);
        pooled_variance = 0.5 * (var(exemplar_a_response, 0, 1) + var(exemplar_b_response, 0, 1));
        canonical_dp = (mean(exemplar_a_response, 1) - mean(exemplar_b_response, 1)) ./ sqrt(pooled_variance);
        canonical_dp(pooled_variance <= eps) = nan;
        selective_units = find(abs(canonical_dp) > dp_threshold & isfinite(canonical_dp));
        selective_response = layer_response(anagram_rows, selective_units).';
        unit_count = size(selective_response, 1);
        mirror_mu = nan(unit_count, 2);
        mirror_fit_r = nan(unit_count, 2);
        trial_indices = 1:images_per_stimulus;
        stimulus_groups = {1:angles_per_mirror, (angles_per_mirror + 1):images_per_stimulus};
        parfor unit_index = 1:unit_count
            unit_response = selective_response(unit_index, :);
            if any(~isfinite(unit_response))
                continue
            end
            try
                [vm_parameters, ~, ~] = fit_distribution(unit_response, trial_indices, stimulus_groups);
                mirror_mu(unit_index, :) = mod(vm_parameters(:, 1), 2 * pi).';
                mirror_fit_r(unit_index, :) = vm_parameters(:, 5).';
            catch
                mirror_mu(unit_index, :) = nan;
                mirror_fit_r(unit_index, :) = nan;
            end
        end
        for population_index = 1:2
            if population_index == 1
                population_positions = find(canonical_dp(selective_units) > dp_threshold);
            else
                population_positions = find(canonical_dp(selective_units) < -dp_threshold);
            end
            qualified_mu = [];
            for mirror_number = 1:2
                good_fit = isfinite(mirror_mu(:, mirror_number)) & mirror_fit_r(:, mirror_number) >= fit_r_threshold;
                selected_positions = population_positions(good_fit(population_positions));
                qualified_mu = [qualified_mu; mirror_mu(selected_positions, mirror_number)]; %#ok<AGROW>
            end
            if isempty(qualified_mu)
                continue
            end
            matching_angle = deg2rad(critical_angles_degrees(family_index, population_index));
            alternative_angle = deg2rad(critical_angles_degrees(family_index, 3 - population_index));
            matching_distance = abs(rad2deg(angle(exp(1i * (qualified_mu - matching_angle)))));
            alternative_distance = abs(rad2deg(angle(exp(1i * (qualified_mu - alternative_angle)))));
            family_population_advantage(family_index, population_index) = mean(alternative_distance) - mean(matching_distance);
        end
    end
    valid_model_values = family_population_advantage(isfinite(family_population_advantage));
    normalization_matrix = repmat(canonical_separation_degrees, 1, 2);
    normalized_condition_advantage = family_population_advantage ./ normalization_matrix;
    condition_matching_angle_advantage(model_index, :) = reshape(normalized_condition_advantage.', 1, []);
    valid_normalization_values = normalization_matrix(isfinite(family_population_advantage));
    model_matching_angle_advantage(model_index) = mean(valid_model_values ./ valid_normalization_values);
    distance_advantage_degree(model_index) = mean(valid_model_values);
    fprintf('Single-unit tuning %d/%d: %s\n', model_index, length(model_names), model_names(model_index))
end
model_table = table(model_names, final_layers, model_matching_angle_advantage, distance_advantage_degree, 'VariableNames', {'Model', 'FinalLayer', 'NormalizedMatchingAngleAdvantage', 'DistanceAdvantageDegree'});
end
