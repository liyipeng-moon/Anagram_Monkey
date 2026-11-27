function [GoodUnitStrc,fdp,bdp,odp,trial_idx, raster_mtx, rsp_mtx, glb] = PreprocessGoodUnit(filename)
load(filename)
threshold = 0.4;
trial_idx = meta_data.trial_valid_idx(meta_data.trial_valid_idx~=0);
for i = 1:max(trial_idx)
    trial_here = find(trial_idx==i);
    set1{i} = trial_here(1:2:length(trial_here));
    set2{i} = trial_here(2:2:length(trial_here));
end
face_idx = find(trial_idx>12 & trial_idx<25);
body_idx = find(trial_idx<13);
object_idx =  find(trial_idx>24 & trial_idx<37);
rsp_mean = [];
for u = 1:length(GoodUnitStrc)
    rsp = sum(GoodUnitStrc(u).Raster(:, global_params.pre_onset+[60:300]),2);
    rsp_mean(u,:)=sum(GoodUnitStrc(u).response_matrix_img(1:36, global_params.pre_onset+[60:300]),2);
    r1=[];r2=[];
    for i = 1:max(trial_idx)
        r1(i) = mean(rsp(set1{i}));
        r2(i) = mean(rsp(set2{i}));
    end
    nc(u) = corr(r1',r2');
    fdp(u) = dprime_xy(rsp(face_idx), rsp([body_idx,object_idx]));
    bdp(u) = dprime_xy(rsp(body_idx), rsp([face_idx,object_idx]));
    odp(u) = dprime_xy(rsp(object_idx), rsp([face_idx,body_idx]));
    fb(u) = dprime_xy(rsp(face_idx), rsp(body_idx));
    pos(u,:) = GoodUnitStrc(u).spikepos(2);
end
nc = 2*nc./(1+nc);
GoodUnitStrc = GoodUnitStrc(nc>threshold);
fdp = fdp(nc>threshold);
bdp = bdp(nc>threshold);
odp = odp(nc>threshold);
pos = pos(nc>threshold);
fb = fb(nc>threshold);
rsp_mean = zscore(rsp_mean(nc>threshold,:),0,2);
raster_mtx = zeros([length(GoodUnitStrc),size(GoodUnitStrc(1).Raster)]);
rsp_mtx = zeros([length(GoodUnitStrc),size(GoodUnitStrc(1).response_matrix_img)]);
parfor u = 1:length(GoodUnitStrc)
    data_here = GoodUnitStrc(u).response_matrix_img;
    rsp_mtx(u,:,:) = data_here;
    RR = GoodUnitStrc(u).Raster;
    raster_mtx(u,:,:) = RR;
end
glb = global_params;
figure; set(gcf,'Position',[900 100 230 480])
subplot(2,1,1);
[~,dp_order]=sort(fb);
imagesc(rsp_mean(dp_order,:))
clim([-2,2]); xline([12.5,24.5],LineWidth=1); xlim([0.5,36.5]);ylim([0,length(fdp)]); xticks([6,18,30])
xticklabels({'Body','Face','Object'}); ylabel('Unit');xlabel('Stimuli'); axis square
subplot(2,1,2); hold on
scatter(fdp, bdp, 5, 'filled');
xlabel('face d-prime'); ylabel('body d-prime');
xlim([-2,2]);ylim([-2,2]);
xline(0);yline(0); axis square

[tmp] = find(filename=='\');
nm=filename(tmp(end)+10:end-7);nm(nm=='_')='-';
sgtitle(nm)
figsave(fullfile('Fig','F1B_Localizer'),sprintf('LOC%s.svg',nm))
raster_mtx = uint8(raster_mtx); rsp_mtx = single(rsp_mtx);
save(fullfile("Data/s0",sprintf('%s.mat',nm)),"pos","fb","fdp","bdp","odp","trial_idx","raster_mtx","rsp_mtx","glb","-nocompression","-v7.3")
end