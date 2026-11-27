clear;clc;close all
root_dir = load('root_dir.mat').root_dir;
cd(root_dir);
addpath(genpath(pwd));
[img_pool,stimuli_idx,combined_pool,c12,c38, cm] = load_stim('AnagramPP');
%%
[f_compare, critical_point, anagramIdx] = gen_famuli_compare('AnagramPP');
for f = 1:length(f_compare)
    figure; 
    i1=squeeze(img_pool(f_compare{f}(1),:,:,:));
    i2=squeeze(img_pool(f_compare{f}(49),:,:,:));
    i3=squeeze(img_pool(f_compare{f}(97),:,:,:));
    nexttile;imshow([i1,i2,i3])
end
%%
[img_pool,stimuli_idx,combined_pool,c12,c38, cm] = load_stim('AnagramPP');
[f_compare, critical_point, anagramIdx] = gen_famuli_compare('AnagramPP');
figure; set(gcf,'Position', [100,700,1800,250])
for f = 1:length(f_compare)
    i1=squeeze(img_pool(f_compare{f}(1),:,:,:));
    nexttile;imshow([i1]);title(anagramIdx(f))
end

[img_pool,stimuli_idx,combined_pool,c12,c38, cm] = load_stim('AnagramPlus');
[f_compare, critical_point, anagramIdx] = gen_famuli_compare('AnagramPlus');
figure; set(gcf,'Position', [0,250,900,250])
for f = 1:length(f_compare)
    i1=squeeze(img_pool(f_compare{f}(1),:,:,:));
    nexttile;imshow([i1]);title(anagramIdx(f))
end

[img_pool,stimuli_idx,combined_pool,c12,c38, cm] = load_stim('AnagramPlus2');
[f_compare, critical_point, anagramIdx] = gen_famuli_compare('AnagramPlus2');
figure; set(gcf,'Position', [900,250,960,250])
for f = 1:length(f_compare)
    i1=squeeze(img_pool(f_compare{f}(1),:,:,:));
    nexttile;imshow([i1]);title(anagramIdx(f))
end
%% Generate img for Fig1 illustration
[img_pool,stimuli_idx,combined_pool,c12,c38, cm] = load_stim('Anagram');
[f_compare, critical_point, anagramIdx] = gen_famuli_compare('Anagram');
for example_family = [1:24]
    BigImg = [];k=0;
    for order_idx = [1,7,13,19,1]
        img_idx = stimuli_idx{example_family}(order_idx);
        img = squeeze(img_pool(img_idx,:,:,:));
        BigImg = [BigImg, img];
        k=k+1;
        if(k~=5)
            BigImg = [BigImg, 255*ones([300,75,3])];
        end
    end
    imwrite(BigImg,fullfile('Fig/ShowStim',sprintf('Exp01_%02d.png', example_family)))
end
% Save img for example unit
for example_family = [1:24]
    imwrite(combined_pool{example_family},fullfile('Fig/ShowStim',sprintf('Exp01_ALL_%02d.png', example_family)))
end

for example_family = [1:2:24]
    s=stimuli_idx{example_family};
    i1 = squeeze(img_pool(s(f_compare{example_family,1}(2)),:,:,:));
    i2 = squeeze(img_pool(s(f_compare{example_family,2}(2)),:,:,:));
    imwrite([i1,i2],fullfile('Fig/ShowStim',sprintf('Exp01_critical_%02d.png', example_family)))
    imwrite([i1;i2],fullfile('Fig/ShowStim',sprintf('Exp01_Hcritical_%02d.png', example_family)))
end
%% Generate Img for Fig3 intro
[img_pool,stimuli_idx,combined_pool,c12,c38, cm] = load_stim('AnagramPP');
[f_compare, critical_point, anagramIdx] = gen_famuli_compare('AnagramPP');
for example_family = [1:10]
    i1 = squeeze(img_pool(f_compare{example_family}(critical_point(example_family,1,2)),:,:,:));
    i2 = squeeze(img_pool(f_compare{example_family}(critical_point(example_family,2,2)),:,:,:));
    i3 = squeeze(img_pool(f_compare{example_family}(49),:,:,:));
    i4 = squeeze(img_pool(f_compare{example_family}(97),:,:,:));
    BigImg=[i1,i3;i2,i4];
    imwrite(BigImg,fullfile('Fig/ShowStim',sprintf('Exp02_%02d.png', example_family)))
end
% Save img for Fig 3
for example_family = [1:2:60]
    imwrite(c12{example_family},fullfile('Fig/ShowStim',sprintf('Exp02_ALL_%02d.png', example_family)))
end
% save colormap for convenience