% https://github.com/liyipeng-moon/Anagram_Monkey
% will reorganize this into manuscript index later...
clear;clc;close all
root_dir = 'G:\Anagram'; % this is where you save the entire workflow
GoodUnit_dir = 'G:\Anagram_Preprocess\AnagramGU'; % this is where you download the goodunit file
cd(root_dir); addpath(genpath(pwd));
save('root_dir.mat','root_dir','GoodUnit_dir')
parpool(12) % Do this to speed up decoding analysis
%% Preprocess 
S0_preprocess % reliability and dp
T1_NumberSummary % Table S1, also include preliminary experiment data
FS1; % Figure S1, also include preliminary experiment data
FS2; % preliminary experiment, comparing MIT and AIT
%% Single unit property, related to Figure 1, 2
S1_SingleUnit % Fit VM model
F1_ExampleNeuron % Figure 1
F2_DistributionFinal % Figure 2
%% Populational Analysis, related to Figure 3,4
F3_Population % plot RDM and MDS, and compute neural distance
F4_show_example_raster % just an example
S4_decode_cv_L2 % Perform decoding analysis, this should take < 2 hours for Intel 265K with parpool(8)
F4_Decode % Show Decoding Analysis
FS6
%% Compare to models, related to Figure 5
Figure6_Neural_Pooled_Decoding
Figure6_Calculate
Figure6_Plot
%% Individual Monkey
FS7_compute
FS7_individual_monkey