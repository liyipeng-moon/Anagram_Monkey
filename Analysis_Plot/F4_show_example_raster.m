close all; clear; clc; 
root_dir = load('root_dir.mat').root_dir; cd(root_dir); addpath(genpath(root_dir));
all_prep = dir('Data\s0\*AnagramP*.mat');
all_prep = all_prep(2);

file_name = all_prep.name; load(file_name);
set_name = identify_set_name(file_name);
[f_compare, critical_point, anagramIdx] = gen_famuli_compare(set_name);
[img_pool,ss,combined_pool24,combined_pool12,combined_pool38,cm] = load_stim('AnagramPlus');
s1_data = load(sprintf('%s_metric.mat',file_name(1:end-4)));
TimaA = glb.pre_onset+(-50:400); PSTHR = glb.PsthRange(TimaA);
raster_mtx = raster_mtx(:,:,TimaA);
%%
figure;set(gcf,'Position',[300,50,900,240])

stim_array=f_compare{4}(1:12:end);
stim_array = stim_array([5,6,9,10,1,2]);

cms = {'r','r','b','b','k','k'};
for i = 1:6
    im=stim_array(i);
    loc = find(trial_idx==im); loc = loc(4);
    ras = squeeze(raster_mtx(s1_data.p48(:,5,1)<0.01,loc,:));
    [a,b] = find(ras);
    nexttile
    scatter(PSTHR(b),a,4,'filled',Marker='square',MarkerEdgeAlpha=0,MarkerFaceColor=cms{i});
    xlim([-50,350]); ylim([0,size(ras,1)]);xticks([0,300])
    yticks([]);
    xlabel('Time (ms)'); 
    if(i==1)
        ylabel('# units')
    end
end
for i = 1:6
    nexttile
    im=stim_array(i);
    imshow(squeeze(img_pool(im,:,:,:)))
end
figsave('Fig','F4_Example')