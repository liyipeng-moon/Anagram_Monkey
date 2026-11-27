clear;clc;close all;
root_dir = load('root_dir.mat').root_dir; cd(root_dir); addpath(genpath(root_dir));
GU_dir = load('root_dir.mat').GoodUnit_dir;
all_good_unit = dir(fullfile(GU_dir,"*mat"));
%%
tic
mkdir(fullfile(root_dir,"Data",'s0'))
for i = 1:length(all_good_unit)
    PreprocessGoodUnit(fullfile(GU_dir,all_good_unit(i).name));
    fprintf('S0 preprocess: finished %d out of %d, take %.01f seconds \n',i,length(all_good_unit), toc)
end