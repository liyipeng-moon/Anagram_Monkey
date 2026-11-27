%% Exp2 population response analysis for Figure 3
close all; clear; cd('G:\Anagram'); addpath(genpath(pwd))
all_prep = dir('Data\s0\*AnagramP*.mat');
ses_num = length(all_prep);
rsp_pool = cell(ses_num, 10, 3);
tic
for d_idx = 1:ses_num
    file_name = all_prep(d_idx).name;
    load(file_name);
    set_name = identify_set_name(file_name);
    [f_compare, ~, anagramIdx] = gen_famuli_compare(set_name);
    TimaA = glb.pre_onset + (-50:400);
    PSTHR = glb.PsthRange(TimaA);
    family_num = length(f_compare);
    for family_idx = 1:family_num
        AnagramStim_Idx = f_compare{family_idx}(1:48);
        Set1 = f_compare{family_idx}(49:96);
        Set2 = f_compare{family_idx}(97:144);
        stims_set = {AnagramStim_Idx, Set1, Set2};
        for set_idx = 1:3
            tmp = squeeze(mean(rsp_mtx(:, stims_set{set_idx}, find(glb.PsthRange == 60):find(glb.PsthRange == 400)), 3));
            tmp = [tmp(:, 1:24); tmp(:, 25:48)];
            rsp_pool{d_idx, anagramIdx(family_idx), set_idx} = tmp;
        end
    end
end

[f_compare, critical_point, anagramIdx] = gen_famuli_compare('AnagramPP');
[img_pool, combined_pool24, combined_pool12, combined_pool8, cm] = load_stimPP;
fprintf('FINISHED! %.01f seconds. \n', toc)
%% Hard-coded Figure 3D exemplar angles
critical_points_exemplar(1, 1) = 7;
critical_points_exemplar(1, 2) = 19;
critical_points_exemplar(2, 1) = 13;
critical_points_exemplar(2, 2) = 13;
critical_points_exemplar(3, 1) = 13;
critical_points_exemplar(3, 2) = 13;
critical_points_exemplar(4, 1) = 13;
critical_points_exemplar(4, 2) = 13;
critical_points_exemplar(5, 1) = 13;
critical_points_exemplar(5, 2) = 13;
critical_points_exemplar(6, 1) = 13;
critical_points_exemplar(6, 2) = 13;
critical_points_exemplar(7, 1) = 7;
critical_points_exemplar(7, 2) = 19;
critical_points_exemplar(8, 1) = 7;
critical_points_exemplar(8, 2) = 19;
critical_points_exemplar(9, 1) = 13;
critical_points_exemplar(9, 2) = 13;
critical_points_exemplar(10, 1) = 19;
critical_points_exemplar(10, 2) = 7;

for f = 1:10
    figure(99 + f);
    set(gcf, 'Position', [1200, 150, 500, 700]);

    subplot(2, 4, 2);
    imshow(squeeze(img_pool(f_compare{f}(critical_point(f, 1, 2)), :, :, :)))
    subplot(2, 4, 3);
    imshow(squeeze(img_pool(f_compare{f}(critical_point(f, 2, 2)), :, :, :)))

    subplot(2, 4, 5);
    Array = 49:72;
    img_IDX = f_compare{f}(Array(1));
    imshow(squeeze(img_pool(img_IDX, :, :, :)))

    subplot(2, 4, 7);
    Array = 97:120;
    img_IDX = f_compare{f}(Array(1));
    imshow(squeeze(img_pool(img_IDX, :, :, :)))

    subplot(2, 4, 6);
    Array = 49:72;
    img_IDX = f_compare{f}(Array(critical_points_exemplar(f, 1)));
    imshow(squeeze(img_pool(img_IDX, :, :, :)))

    subplot(2, 4, 8);
    Array = 97:120;
    img_IDX = f_compare{f}(Array(critical_points_exemplar(f, 2)));
    imshow(squeeze(img_pool(img_IDX, :, :, :)))
end
%% Population RDM, MDS, and Figure 3C/3D correlations
correlation_limit = 1 - 1e-12;
Distance_Save = nan(10, 2, 2);
Distance_Save_Z = nan(10, 2, 2);
Distance_Save_Metric2 = nan(10, 2, 2);
Distance_Save_Metric2_Z = nan(10, 2, 2);

for f = 1:10
    pop_rsp = [];
    for ses = 1:ses_num
        avg_rsp = [];
        for set_idx = 1:3
            avg_rsp = [avg_rsp, rsp_pool{ses, f, set_idx}];
        end
        pop_rsp = [pop_rsp; avg_rsp];
    end

    pop_rsp = norm_01(pop_rsp)';
    RDM = squareform(pdist(pop_rsp, 'spearman'));
    MDS = 2000 * mdscale(RDM, 2);

    tmpRDM = RDM(1:24, 1:24);
    tmpRDM(eye(24) == 1) = nan;
    minVal = min(tmpRDM(:));
    CleanRDM = RDM(1:24, 1:24);
    CleanRDM(eye(24) == 1) = minVal;

    figure(f);
    set(gcf, 'Position', [300, 40, 750, 950])
    subplot(3, 2, 1);
    imshow(combined_pool8{f, 1})

    subplot(3, 2, 2);
    imagesc(CleanRDM);
    axis square;
    colorbar;
    xticklabels([]);
    yticklabels([]);

    subplot(3, 2, 3:6);
    hold on; axis equal;
    xticks([]); yticks([]);
    ARY = f_compare{f}([1:24, 49:72, 97:120]);

    for interested_case = [2, 3]
        lag = 24 * (interested_case - 1);
        for t0 = 1:6:13
            LOC1 = lag + t0;
            imagesc(MDS(LOC1, 1) - 150, MDS(LOC1, 2) - 150, flipud(squeeze(img_pool(ARY(LOC1), :, :, :))))
        end
    end

    plot_mds(MDS(1:24, :), cm, 'o', 50)
    plot_mds(MDS(25:48, :), 0.5 * ones(size(cm)), 'o', 20)
    plot_mds(MDS(49:72, :), 0.5 * ones(size(cm)), 'o', 20)
    figsave(fullfile('Fig', 'newF3'), sprintf('PopF3_%02d', f))

    D1 = 1 - RDM(critical_point(f, 1, 2), 25:72);
    D2 = 1 - RDM(critical_point(f, 2, 2), 25:72);
    D1_For_Z = max(min(D1, correlation_limit), -correlation_limit);
    D2_For_Z = max(min(D2, correlation_limit), -correlation_limit);

    figure(99 + f);

    % Raw correlations are retained for plotting.
    Distance_Save(f, 1, 1) = mean(D1(1:24));
    Distance_Save(f, 1, 2) = mean(D2(1:24));
    Distance_Save(f, 2, 1) = mean(D1(25:48));
    Distance_Save(f, 2, 2) = mean(D2(25:48));

    % Fisher transformation is performed before averaging for statistics.
    Distance_Save_Z(f, 1, 1) = mean(atanh(D1_For_Z(1:24)));
    Distance_Save_Z(f, 1, 2) = mean(atanh(D2_For_Z(1:24)));
    Distance_Save_Z(f, 2, 1) = mean(atanh(D1_For_Z(25:48)));
    Distance_Save_Z(f, 2, 2) = mean(atanh(D2_For_Z(25:48)));

    subplot(2, 4, 5)
    title(sprintf('C1 %.02f \n C2 %.02f \n', D1(1), D2(1)))
    subplot(2, 4, 6)
    title(sprintf('C1 %.02f \n C2 %.02f \n', D1(critical_points_exemplar(f, 1)), D2(critical_points_exemplar(f, 1))))
    subplot(2, 4, 7)
    title(sprintf('C1 %.02f \n C2 %.02f \n', D1(25), D2(25)))
    subplot(2, 4, 8)
    title(sprintf('C1 %.02f \n C2 %.02f \n', D1(critical_points_exemplar(f, 2) + 24), D2(critical_points_exemplar(f, 2) + 24)))

    Distance_Save_Metric2(f, 1, 1) = D1(critical_points_exemplar(f, 1));
    Distance_Save_Metric2(f, 2, 1) = D2(critical_points_exemplar(f, 2) + 24);
    Distance_Save_Metric2(f, 1, 2) = D1(25);
    Distance_Save_Metric2(f, 2, 2) = D2(1);

    Distance_Save_Metric2_Z(f, 1, 1) = atanh(D1_For_Z(critical_points_exemplar(f, 1)));
    Distance_Save_Metric2_Z(f, 2, 1) = atanh(D2_For_Z(critical_points_exemplar(f, 2) + 24));
    Distance_Save_Metric2_Z(f, 1, 2) = atanh(D1_For_Z(25));
    Distance_Save_Metric2_Z(f, 2, 2) = atanh(D2_For_Z(1));

    figsave(fullfile('Fig', 'newF3'), sprintf('Dist_PopF3_%02d', f))
end
%% Figure 3C and Figure 3D summary
figure; set(gcf, 'Position', [1, 500, 600, 500]);
BoxColor = [0, 0, 0];

% Figure 3C: 20 paired interpretation-level samples.
Val1 = [squeeze(Distance_Save(:, 1, 1)); squeeze(Distance_Save(:, 2, 2))];
Val2 = [squeeze(Distance_Save(:, 2, 1)); squeeze(Distance_Save(:, 1, 2))];
Val1_Z = [squeeze(Distance_Save_Z(:, 1, 1)); squeeze(Distance_Save_Z(:, 2, 2))];
Val2_Z = [squeeze(Distance_Save_Z(:, 2, 1)); squeeze(Distance_Save_Z(:, 1, 2))];

subplot(1, 2, 1);hold on;axis square;box off
scatter(0.08 + ones(size(Val1)), Val1, 20, "filled", MarkerEdgeAlpha=0, MarkerFaceColor=[0.5, 0.5, 0.5]);
scatter(0.08 + 2 * ones(size(Val1)), Val2, 20, "filled", MarkerEdgeAlpha=0, MarkerFaceColor=[0.5, 0.5, 0.5]);
boxplot([Val1, Val2], 'BoxStyle', 'outline', 'Symbol', '', 'MedianStyle', 'target', 'Colors', BoxColor)
ylim([0, 0.4]);
yticks(0:0.1:0.4)
[~, p, ~, stats] = ttest(Val1_Z, Val2_Z, 'Tail', 'right');
xticklabels({'Match', 'Non-Match'})
ylabel('Corr.')
title(sprintf('t (%d) = %.02f,p = %.09f', stats.df, stats.tstat, p))

% Figure 3D: 20 paired interpretation-level samples.
Distance_Save_Metric_Same = Distance_Save_Metric2(:, :, 1);
Distance_Save_Metric_Diff = Distance_Save_Metric2(:, :, 2);
Distance_Save_Metric_Same_Z = Distance_Save_Metric2_Z(:, :, 1);
Distance_Save_Metric_Diff_Z = Distance_Save_Metric2_Z(:, :, 2);
Val1 = Distance_Save_Metric_Same(:);
Val2 = Distance_Save_Metric_Diff(:);
Val1_Z = Distance_Save_Metric_Same_Z(:);
Val2_Z = Distance_Save_Metric_Diff_Z(:);

subplot(1, 2, 2);hold on;axis square;box off
scatter(0.08 + ones(size(Val1)), Val1, 20, "filled", MarkerEdgeAlpha=0, MarkerFaceColor=[0.5, 0.5, 0.5]);
scatter(0.08 + 2 * ones(size(Val1)), Val2, 20, "filled", MarkerEdgeAlpha=0, MarkerFaceColor=[0.5, 0.5, 0.5]);
boxplot([Val1, Val2], 'BoxStyle', 'outline', 'Symbol', '', 'MedianStyle', 'target', 'Colors', BoxColor)
ylim([0, 0.4]);
yticks(0:0.1:0.4)
[~, p, ~, stats] = ttest(Val1_Z, Val2_Z, 'Tail', 'right');
xticklabels({'Match', 'Non-Match'})
ylabel('Corr.')
title(sprintf('t (%d) = %.02f,p = %.09f', stats.df, stats.tstat, p))
figsave(fullfile('Fig', 'newF3'), sprintf('F3_summary'))