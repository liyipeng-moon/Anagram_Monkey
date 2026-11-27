%% Plot Figure 6
clear;clc;close all
%% Paths and visual settings
load('root_dir.mat')
output_directory = fullfile(root_dir,'Data', 'output');
result_path = fullfile(output_directory, 'Figure6_Results.mat');

training_group_names = ["Language-supervised"; "Self-supervised"; "Image classification"];
training_colors = [0.84, 0.37, 0.00; 0.00, 0.45, 0.70; 0.00, 0.62, 0.45];
neuron_color = [0.20, 0.20, 0.20];

vit_models = ["siglip"; "clip"; "clip_vit_b16"; "eva02_clip_b16";
    "dino_vit_b16"; "dinov2_vitb14"; "dinov3_vitb16";
    "mocov3_vit_b16"; "mae"; "imagenet_vit_b16"; "deit_b16_in1k"];
resnet_models = ["clip_rn50"; "openclip_rn50_cc12m"; "openclip_rn50_yfcc15m";
    "simclr"; "dino_resnet50"; "moco_v2"; "mocov3_resnet50";
    "swav"; "imagenet_resnet50"; "resnet18"; "resnet34";
    "resnet101"; "robust_resnet50"];
%% Load the values needed for plotting
results = load(result_path, ...
    'all_model_table', ...
    'all_condition_matching_angle_advantage', ...
    'all_condition_decoding_bias', ...
    'neural_condition_matching_angle_advantage', ...
    'neural_condition_decoding_bias', ...
    'neural_reference_table');

all_model_table = results.all_model_table;
neural_matching_angle_advantage = results.neural_reference_table.NeuronValue( ...
    results.neural_reference_table.Metric == "SingleUnitNormalizedMatchingAngleAdvantage");
neural_decoding_bias = results.neural_reference_table.NeuronValue( ...
    results.neural_reference_table.Metric == "DecodingBias");

vit_rows = ismember(all_model_table.Model, vit_models);
resnet_rows = ismember(all_model_table.Model, resnet_models);
[~, vit_order] = ismember(vit_models, all_model_table.Model);
[~, resnet_order] = ismember(resnet_models, all_model_table.Model);

ordered_rows = [vit_order; resnet_order];
ordered_table = all_model_table(ordered_rows, :);
ordered_training_groups = get_training_groups(ordered_table.Model);
ordered_colors = training_colors(ordered_training_groups, :);
ordered_labels = [ordered_table.DisplayName; "IT Neuron"];
ordered_colors = [ordered_colors; neuron_color];
vit_model_count = length(vit_models);
resnet_model_count = length(resnet_models);
%% Main Figure 6: decoding bias
decoding_figure = figure;
tiledlayout(decoding_figure, 2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
set(gcf, 'Position', [1,41,1000,680]);

nexttile(1, [1, 3]);hold on
combined_decoding_bias = [results.all_condition_decoding_bias(ordered_rows, :); results.neural_condition_decoding_bias];
assert(size(combined_decoding_bias, 2) == 20, 'Decoding plots require 20 conditions per model and neural population.');
plot_family_boxcharts(combined_decoding_bias, ordered_labels, ordered_colors)
ylabel('Decoding bias')
ylim([-0.55,0.6])
xline(11.5,LineStyle="--")
xline(24.5,LineStyle="--")

legend_handles = gobjects(4, 1);
for group_index = 1:3
    legend_handles(group_index) = scatter(nan, nan, 30, training_colors(group_index, :), 's', 'filled');
end
legend_handles(4) = scatter(nan, nan, 30, neuron_color, 's', 'filled');
legend(legend_handles, [cellstr(training_group_names); {'IT Neuron'}], 'Location', 'northeastoutside', 'Box', 'off')

nexttile(4)
plot_labeled_model_scatter(all_model_table.ShapeMinusTextureR, all_model_table.DecodingBias, all_model_table.DisplayName, all_model_table.TrainingGroup, training_group_names, training_colors, false)
yline(neural_decoding_bias,LineStyle="--");
xlabel('Shape preference (all models)')
ylabel('Decoding bias')

nexttile(5)
plot_labeled_model_scatter(all_model_table.ShapeMinusTextureR(vit_rows), all_model_table.DecodingBias(vit_rows), all_model_table.DisplayName(vit_rows), all_model_table.TrainingGroup(vit_rows), training_group_names, training_colors, true)
yline(neural_decoding_bias,LineStyle="--");xlabel('Shape preference (ViT models)')
ylabel('Decoding bias')

nexttile(6)
plot_labeled_model_scatter(all_model_table.ShapeMinusTextureR(resnet_rows), all_model_table.DecodingBias(resnet_rows), all_model_table.DisplayName(resnet_rows), all_model_table.TrainingGroup(resnet_rows), training_group_names, training_colors, true)
yline(neural_decoding_bias,LineStyle="--");
xlabel('Shape preference (ResNet models)')
ylabel('Decoding bias')

figsave(fullfile(root_dir,'Fig'),'F6_Decoding')
%% Supplementary Figure S6: single-unit matching-angle tuning
tuning_figure = figure;
layout = tiledlayout(tuning_figure, 2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
set(gcf, 'Position', [1,41,1000,680]);

nexttile(1, [1, 3]);hold on
combined_matching_angle_advantage = [results.all_condition_matching_angle_advantage(ordered_rows, :); results.neural_condition_matching_angle_advantage(:).'];
assert(size(combined_matching_angle_advantage, 2) == 20, 'Matching-angle plots require 20 condition columns.');
plot_family_boxcharts(combined_matching_angle_advantage, ordered_labels, ordered_colors)
ylabel('Normalized matching-angle advantage')
ylim([-0.25,1.05])
xline(11.5,LineStyle="--")
xline(24.5,LineStyle="--")
for group_index = 1:3
    legend_handles(group_index) = scatter(nan, nan, 30, training_colors(group_index, :), 's', 'filled');
end
legend_handles(4) = scatter(nan, nan, 30, neuron_color, 's', 'filled');
legend(legend_handles, [cellstr(training_group_names); {'IT Neuron'}], 'Location', 'northeastoutside', 'Box', 'off')

nexttile(4)
plot_labeled_model_scatter(all_model_table.ShapeMinusTextureR, all_model_table.NormalizedMatchingAngleAdvantage, all_model_table.DisplayName, all_model_table.TrainingGroup, training_group_names, training_colors, false)
yline(neural_matching_angle_advantage,LineStyle="--");
xlabel('Shape preference (all models)')
ylabel('Matching-angle advantage')

nexttile(5)
plot_labeled_model_scatter(all_model_table.ShapeMinusTextureR(vit_rows), all_model_table.NormalizedMatchingAngleAdvantage(vit_rows), all_model_table.DisplayName(vit_rows), all_model_table.TrainingGroup(vit_rows), training_group_names, training_colors, true)
yline(neural_matching_angle_advantage,LineStyle="--");
xlabel('Shape preference (ViT models)')
ylabel('Matching-angle advantage')

nexttile(6)
plot_labeled_model_scatter(all_model_table.ShapeMinusTextureR(resnet_rows), all_model_table.NormalizedMatchingAngleAdvantage(resnet_rows), all_model_table.DisplayName(resnet_rows), all_model_table.TrainingGroup(resnet_rows), training_group_names, training_colors, true)
yline(neural_matching_angle_advantage,LineStyle="--");
xlabel('Shape preference (ResNet models)')
ylabel('Matching-angle advantage')

figsave(fullfile(root_dir,'Fig'),'F6_Single')