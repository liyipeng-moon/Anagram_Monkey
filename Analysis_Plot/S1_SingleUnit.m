close all; clear;
root_dir = load('root_dir.mat').root_dir; addpath(genpath(root_dir)); cd(root_dir)
all_prep = dir('Data\s0\*Anagram.mat');
[~,stimuli_idx,~,~,~] = load_stim('Anagram');
tic
for d_idx = 1:length(all_prep)
    file_name = all_prep(d_idx).name; 
    load(file_name)
    T_avg_rsp = squeeze(sum(raster_mtx(:,:,glb.pre_onset+[60:550]),3)) ./ (0.49);
    u_num = length(fdp);
    tmp0=zeros([u_num, length(stimuli_idx)]); 
    tmp4=zeros([u_num, length(stimuli_idx),5]);
    vm_param=tmp4; 
    wg_param=tmp4; 
    self_rho=tmp0; 
    parfor unit = 1:u_num
        [vm_param(unit,:,:),wg_param(unit,:,:),self_rho(unit,:)] = fit_distribution(T_avg_rsp(unit,:), trial_idx, stimuli_idx);
    end
    p48 = perform_anova_tuning(T_avg_rsp, trial_idx);
    save(fullfile("Data/single/",sprintf('%s_metric.mat',file_name(1:end-4))), "p48","vm_param","wg_param","self_rho");
    fprintf('S1 Original preprocess: finished %d out of %d, take %.01f seconds \n',d_idx,length(all_prep), toc)
end
%%
close all; clear;
root_dir = load('root_dir.mat').root_dir; addpath(genpath(root_dir)); cd(root_dir)
all_prep = dir('Data\s0\*AnagramP*.mat');
tic
for d_idx = 1:length(all_prep)
    file_name = all_prep(d_idx).name; 
    load(file_name)
    T_avg_rsp = squeeze(sum(raster_mtx(:,:,glb.pre_onset+[60:400]),3)) ./ (0.34);
    u_num = length(fdp);
    [img_pool,stimuli_idx,combined_pool,c12,c38] = load_stim(identify_set_name(file_name));
    tmp0=zeros([u_num, length(stimuli_idx)]); 
    tmp4=zeros([u_num, length(stimuli_idx),5]);
    vm_param=tmp4; 
    wg_param=tmp4; 
    self_rho=tmp0; 
    parfor unit = 1:u_num
        [vm_param(unit,:,:),wg_param(unit,:,:),self_rho(unit,:)] = fit_distribution(T_avg_rsp(unit,:), trial_idx, stimuli_idx);
    end
    p48 = perform_anova_tuning(T_avg_rsp, trial_idx);
    save(fullfile("Data/single/",sprintf('%s_metric.mat',file_name(1:end-4))), "p48","vm_param","wg_param","self_rho");
    fprintf('S1 Original preprocess: finished %d out of %d, take %.01f seconds \n',d_idx,length(all_prep), toc)
end