%% Plus
close all; clear; clc;
root_dir = load('root_dir.mat').root_dir; cd(root_dir); addpath(genpath(root_dir));
all_prep = dir('Data\s0\*AnagramP*.mat');
%%
tic
for d_idx = 1:length(all_prep)
    file_name = all_prep(d_idx).name; load(file_name);
    set_name = identify_set_name(file_name);
    [f_compare, critical_point] = gen_famuli_compare(set_name);

    raster_binned = bin_raster(raster_mtx, 50);

    TimaA = glb.pre_onset+(-50:5:400); 
    PSTHR = glb.PsthRange(TimaA);
    raster_binned_selected = single(raster_binned(:,:,TimaA)); 
    clear raster_binned raster_mtx
    
    family_num = length(f_compare);
    % prepare space
    score = nan([family_num,length(PSTHR),length(trial_idx)]);
    score_mean = nan([family_num,length(trial_idx)]);
    score_cv = nan([family_num,length(PSTHR),24,length(trial_idx)]);
    % loop for base stimuli
    for family_idx = 1:family_num
        % Prepare
        AnagramIdx = f_compare{family_idx}(1:48);
        Set1 = f_compare{family_idx}(49:96);
        Set2 = f_compare{family_idx}(97:144);
        Trial1_idx = find(trial_idx>=min(Set1) & trial_idx<=max(Set1));
        Trial2_idx = find(trial_idx>=min(Set2) & trial_idx<=max(Set2));
        Vec48 = [ones([1,length(Trial1_idx)]), 2*ones([1,length(Trial2_idx)])]';
        Selected_Population = raster_binned_selected;

        % Do with 48 variants train, averaged response
        avg_rsp = zscore(squeeze(mean(raster_binned_selected(:, :, find(PSTHR==60):find(PSTHR==400)),3)),0,2);
        RSP_train = avg_rsp(:, [Trial1_idx, Trial2_idx])';

        Mdl = fitclinear(RSP_train, Vec48,'Learner','logistic','Regularization','ridge','Lambda',1e-3);
        [~, score_now] = predict(Mdl, avg_rsp');
        score_mean(family_idx,:) = score_now(:,1);
        parfor t = 1:size(Selected_Population,3)
            unit_data = squeeze(Selected_Population(:,:,t));
            RSP_NOW = zscore(unit_data,0,2);

            % Do with 48 variants train and anagram test, time resolved
            RSP_train = RSP_NOW(:, [Trial1_idx, Trial2_idx])';
            Mdl = fitclinear(RSP_train, Vec48,'Learner','logistic','Regularization','ridge','Lambda',1e-3); 
            [~,score_now] = predict(Mdl, RSP_NOW');
            score(family_idx,t,:) = single(score_now(:,1));

            % Do with 46 variants and test on held out 2 variants
            for cv_idx = 1:24
                test1 = Set1(cv_idx+[0,24]);
                test1_trial = find(trial_idx==test1(1) | trial_idx==test1(2));
                test2 = Set2(cv_idx+[0,24]);
                test2_trial = find(trial_idx==test2(1) | trial_idx==test2(2));
                test_trials = [test1_trial, test2_trial];
                train_1 = setdiff(Trial1_idx, test1_trial);
                train_2 = setdiff(Trial2_idx, test2_trial);
                Vec46 = [ones([1,length(train_1)]), 2*ones([1,length(train_2)])]';
                RSP_train = RSP_NOW(:, [train_1, train_2])';
                Mdl = fitclinear(RSP_train, Vec46,'Learner','logistic','Regularization','ridge','Lambda',1e-3); 
                [~,score_now] = predict(Mdl, RSP_NOW');
                score_cv(family_idx,t,cv_idx,:) = single(score_now(:,1));
            end % finish 24 variants
        end % finish time points
        fprintf('Decode: finished %d out of %d family, take %.01f seconds \n',family_idx,family_num, toc)
    end % finish anagram family
    save(fullfile("Data/decode_l2/",sprintf('PlusDecode_%s_metric.mat',file_name(1:end-4))),"score_mean","f_compare","critical_point", "score","trial_idx","PSTHR",'score_cv',"-nocompression","-v7.3")
    fprintf('Decode: finished %d out of %d sessions, take %.01f seconds \n',d_idx,length(all_prep), toc)
end