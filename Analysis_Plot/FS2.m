close all; clear; clc
load('root_dir.mat')
addpath(genpath(root_dir))
output_dir = fullfile(root_dir, 'Fig', 'FS2');

family_count = 12;
mirror_p_threshold = 0.001;
angle_p_threshold = 0.001;
fit_r_threshold = 0.30;
category_dp_threshold = 0.5;
angle_edges = 0:15:360;
angle_centers = 7.5:15:352.5;
area_codes = ['M', 'A'];
group_names = ["Face", "Body"];
line_colors = [0.10, 0.28, 0.70; 0.70, 0.16, 0.18; 0.30, 0.68, 0.90; 0.94, 0.50, 0.42];

critical_a = [0, 0, 0, 0, 180, 0, 0, 0, 0, 0, 180, 0];
critical_b = [90, 90, 180, 180, 0, 180, 90, 180, 180, 180, 0, 270];
stimulus_dir = fullfile(root_dir, 'Data', 'stim', 'Anagram');
stimulus_table = readtable(fullfile(stimulus_dir, 'Anagram.tsv'), 'FileType', 'text', 'Delimiter', 'tab');
family_names = strings(family_count, 1);
for family_idx = 1:family_count
    first_file = string(stimulus_table.FileName{37 + 48 * (family_idx - 1)});
    family_names(family_idx) = extractBefore(first_file, '_');
end

metric_files = dir(fullfile(root_dir, 'Data', 'single', '*-Anagram_metric.mat'));
session_table = readtable(fullfile(root_dir, 'Fig', 'SessionSummary.xlsx'), 'VariableNamingRule', 'preserve');
experiment_rows = find(strcmp(session_table.experiment, 'Exp.1'));
vm_param = [];
p48_data = [];
face_dp = [];
body_dp = [];
area_array = [];
session_array = [];

for session_idx = 1:numel(metric_files)
    session_name = erase(metric_files(session_idx).name, '_metric.mat');
    metric_file = fullfile(metric_files(session_idx).folder, metric_files(session_idx).name);
    neural_file = fullfile(root_dir, 'Data', 's0', session_name + ".mat");
    metric_data = load(metric_file, 'vm_param', 'p48');
    neural_data = load(neural_file, 'fdp', 'bdp');
    unit_count = numel(neural_data.fdp);

    vm_param = [vm_param; metric_data.vm_param];
    p48_data = [p48_data; metric_data.p48];
    face_dp = [face_dp; neural_data.fdp(:)];
    body_dp = [body_dp; neural_data.bdp(:)];
    target = session_table.target{experiment_rows(session_idx)};
    area_array = [area_array; repmat(target(1), unit_count, 1)];
    session_array = [session_array; repmat(session_idx, unit_count, 1)];
end

face_units = face_dp > category_dp_threshold & body_dp < 0;
body_units = body_dp > category_dp_threshold & face_dp < 0;
mirror_r = nan(family_count, 2);
mirror_n = zeros(family_count, 2);
mu_original_pool = cell(family_count, 2);
mu_mirrored_pool = cell(family_count, 2);
polar_fraction = zeros(family_count, 2, 2, 24);
matched_sessions = zeros(family_count, 2);
mirror_fits = zeros(family_count, 2, 2);
group_metrics = nan(family_count, 2, 2, 4);

for family_idx = 1:family_count
    columns = 2 * family_idx - 1 + (0:1);
    mu = vm_param(:, columns, 1);
    fit_r = vm_param(:, columns, 5);
    amplitude = vm_param(:, columns, 3);

    mirror_good = p48_data(:, columns(1)) < mirror_p_threshold;
    mirror_good = mirror_good & all(fit_r >= fit_r_threshold, 2) & all(isfinite(mu), 2);
    for area_idx = 1:2
        selected = mirror_good & area_array == area_codes(area_idx);
        mirror_n(family_idx, area_idx) = sum(selected);
        mirror_r(family_idx, area_idx) = circ_corrcc(mu(selected, 1), mu(selected, 2));
        mu_original_pool{family_idx, area_idx} = mu(selected, 1);
        mu_mirrored_pool{family_idx, area_idx} = mu(selected, 2);
    end

    valid_fit = p48_data(:, columns) < angle_p_threshold & fit_r >= fit_r_threshold & amplitude > 0 & isfinite(mu);
    mu_degrees = mod(rad2deg(mu), 360);
    distance_a = abs(mod(mu_degrees - critical_a(family_idx) + 180, 360) - 180);
    distance_b = abs(mod(mu_degrees - critical_b(family_idx) + 180, 360) - 180);
    nearest_distance = min(distance_a, distance_b);
    critical_hit = double(nearest_distance <= 15);
    b_choice = double(distance_b < distance_a);
    nearest_distance(~valid_fit) = NaN;
    critical_hit(~valid_fit) = NaN;
    b_choice(~valid_fit) = NaN;
    b_critical = b_choice;
    b_critical(nearest_distance > 15) = NaN;

    unit_metrics = [mean(nearest_distance, 2, 'omitnan'), mean(critical_hit, 2, 'omitnan'),mean(b_critical, 2, 'omitnan'), mean(b_choice, 2, 'omitnan')];

    for area_idx = 1:2
        session_metrics = nan(numel(metric_files), 2, 4);
        for session_idx = 1:numel(metric_files)
            area_session = area_array == area_codes(area_idx) & session_array == session_idx;
            face_here = area_session & face_units;
            body_here = area_session & body_units;
            face_fits = repmat(face_here, 1, 2) & valid_fit;
            body_fits = repmat(body_here, 1, 2) & valid_fit;
            face_angles = mu_degrees(face_fits);
            body_angles = mu_degrees(body_fits);
            fit_weights = repmat(1 ./ max(sum(valid_fit, 2), 1), 1, 2);
            face_counts = accumarray(discretize(face_angles, angle_edges), fit_weights(face_fits), [24, 1]);
            body_counts = accumarray(discretize(body_angles, angle_edges), fit_weights(body_fits), [24, 1]);
            polar_fraction(family_idx, area_idx, 1, :) = polar_fraction(family_idx, area_idx, 1, :) + reshape(face_counts, 1, 1, 1, 24);
            polar_fraction(family_idx, area_idx, 2, :) = polar_fraction(family_idx, area_idx, 2, :) + reshape(body_counts, 1, 1, 1, 24);

            if ~isempty(face_angles) && ~isempty(body_angles)
                matched_sessions(family_idx, area_idx) = matched_sessions(family_idx, area_idx) + 1;
                mirror_fits(family_idx, area_idx, 1) = mirror_fits(family_idx, area_idx, 1) + numel(face_angles);
                mirror_fits(family_idx, area_idx, 2) = mirror_fits(family_idx, area_idx, 2) + numel(body_angles);
            end

            for metric_idx = 1:4
                session_metrics(session_idx, 1, metric_idx) = mean(unit_metrics(face_here, metric_idx), 'omitnan');
                session_metrics(session_idx, 2, metric_idx) = mean(unit_metrics(body_here, metric_idx), 'omitnan');
            end
        end

        for group_idx = 1:2
            polar_fraction(family_idx, area_idx, group_idx, :) = polar_fraction(family_idx, area_idx, group_idx, :) / sum(polar_fraction(family_idx, area_idx, group_idx, :), 'all');
        end
        for metric_idx = 1:4
            face_values = session_metrics(:, 1, metric_idx);
            body_values = session_metrics(:, 2, metric_idx);
            matched = isfinite(face_values) & isfinite(body_values);
            group_metrics(family_idx, area_idx, 1, metric_idx) = mean(face_values(matched));
            group_metrics(family_idx, area_idx, 2, metric_idx) = mean(body_values(matched));
        end
    end
end
mirror_p = signrank(mirror_r(:, 2), mirror_r(:, 1), 'tail', 'right');

figure('Color', 'w', 'Position', [10, 80, 3200, 900])
tiledlayout(4, 12, 'TileSpacing', 'compact', 'Padding', 'compact')
for family_idx = 1:family_count
    nexttile(family_idx)
    stimulus_idx = 37 + 48 * (family_idx - 1);
    imshow(imread(fullfile(stimulus_dir, stimulus_table.FileName{stimulus_idx})))
end

for area_idx = 1:2
    for family_idx = 1:family_count
        nexttile(12 * area_idx + family_idx)
        plot_mu_density(mu_original_pool{family_idx, area_idx}, mu_mirrored_pool{family_idx, area_idx}, angle_edges)
        if(area_idx==1)
            area_name_now = 'MIT';
        else
            area_name_now = 'AIT';
        end
        title(sprintf('%s\n circ. r=%.2f, n=%d', area_name_now, mirror_r(family_idx, area_idx), mirror_n(family_idx, area_idx)))
        ylabel('Mirror preferred angle')
    end
end

nexttile(37); hold on
plot([-1, 1], [-1, 1], '--', 'Color', [0.65, 0.65, 0.65], 'LineWidth', 1)
scatter(mirror_r(:, 1), mirror_r(:, 2), 25, [0.35, 0.35, 0.35], 'filled')
axis square;xlim([-1, 1]); ylim([-1, 1])
xticks([-1, 0, 1]); yticks([-1, 0, 1])
xlabel('Middle IT consistency'); ylabel('Anterior IT consistency')
title(sprintf('p=%.3g', mirror_p), 'FontWeight', 'normal')
figsave(fullfile(root_dir, 'Fig'), 'FS2_Integrated')


image_angles = 0:45:315;
image_positions = [0.42, 0.78, 0.16, 0.16; 0.74, 0.72, 0.16, 0.16; ...
    0.78, 0.42, 0.16, 0.16; 0.74, 0.12, 0.16, 0.16; ...
    0.42, 0.04, 0.16, 0.16; 0.10, 0.12, 0.16, 0.16; ...
    0.06, 0.42, 0.16, 0.16; 0.10, 0.72, 0.16, 0.16];

for family_idx = 1:family_count
    radial_max = max(polar_fraction(family_idx, :, :, :), [], 'all') * 1.18;
    figure('Color', 'w', 'Position', [50, 50, 550, 550]);
    polar_axis = polaraxes('Parent', gcf, 'Position', [0.265, 0.265, 0.47, 0.47]);
    hold(polar_axis, 'on')
    polar_axis.ThetaZeroLocation = 'top';
    polar_axis.ThetaDir = 'clockwise';
    polar_axis.ThetaTick = 0:45:315;
    polar_axis.RLim = [0, radial_max];
    polar_axis.RTick = [0, radial_max / 2, radial_max];
    polar_axis.RTickLabel = {"0", sprintf('%.1f%%', 50 * radial_max), sprintf('%.1f%%', 100 * radial_max)};
    curve_handles = gobjects(4, 1);
    curve_labels = strings(4, 1);
    for area_idx = 1:2
        for group_idx = 1:2
            curve_idx = 2 * (area_idx - 1) + group_idx;
            fractions = squeeze(polar_fraction(family_idx, area_idx, group_idx, :));
            curve_handles(curve_idx) = polarplot(polar_axis, deg2rad([angle_centers, angle_centers(1) + 360]), ...
                [fractions; fractions(1)], 'Color', line_colors(curve_idx, :), 'LineWidth', 2.8);
            curve_labels(curve_idx) = string(area_codes(area_idx)) + "IT " + group_names(group_idx);
        end
    end

    for image_idx = 1:8
        angle = image_angles(image_idx);
        image_name = sprintf('%s_1_ang_%03d.jpg', family_names(family_idx), angle);
        image_data = imread(fullfile(stimulus_dir, image_name));
        image_axis = axes('Parent', gcf, 'Position', image_positions(image_idx, :));
        imshow(image_data, 'Parent', image_axis)
    end
    
    legend_handle = legend(polar_axis, curve_handles, curve_labels, 'Orientation', 'horizontal', 'Box', 'off');
    legend_handle.Units = 'normalized';
    legend_handle.Position = [0.26, 0.22, 0.48, 0.035];
    figsave(output_dir, sprintf('%02d_%s_wheel.png', family_idx, family_names(family_idx)))
end

function plot_mu_density(mu_original, mu_mirrored, angle_edges)
    original_degrees = mod(rad2deg(mu_original), 360);
    mirrored_degrees = mod(rad2deg(mu_mirrored), 360);
    bin_counts = histcounts2(original_degrees, mirrored_degrees, angle_edges, angle_edges);
    density_percent = 100 * bin_counts / length(mu_original);
    bin_centers = angle_edges(1:end-1) + diff(angle_edges) / 2;
    imagesc(bin_centers, bin_centers, density_percent')
    set(gca, 'YDir', 'normal'); axis square
    xlim([0, 360]); ylim([0, 360]); xticks([0, 180, 360]); yticks([0, 180, 360])
    xlabel('Original preferred angle', 'FontSize', 7)
    colormap(gca, flipud(gray(256)))
    ll = [0, floor(max(density_percent(:)))];
    clim(ll); color_bar = colorbar; color_bar.Ticks = ll; color_bar.FontSize = 6;
    box on; set(gca, 'FontName', 'Arial', 'FontSize', 6, 'LineWidth', 0.6)
end
