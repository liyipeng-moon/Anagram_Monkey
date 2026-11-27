close all; clear; clc
load('root_dir.mat')
cd(root_dir); addpath(genpath(root_dir));
all_metric = dir('Data\s0\*.mat');
tb = readtable("SessionSummary.xlsx");
dp_thres = 0.5;
%%
tic
fdp=[]; bdp=[]; odp=[]; MA_array = [];ses_array = [];rsp_t = []; SetArray=[];
for idx = 1:length(all_metric)
    file_name = all_metric(idx).name;
    S0Data{idx} = load(file_name);
    rsp_t = [rsp_t; S0Data{idx}.rsp_mtx(:,1:36,:)];
    fdp = [fdp, S0Data{idx}.fdp]; bdp = [bdp, S0Data{idx}.bdp]; odp = [odp, S0Data{idx}.odp];
    ses_array = [ses_array, idx*ones([1, length(S0Data{idx}.fdp)])];
    MA_array = [MA_array, repmat(tb.target{idx}(1),[1,length(S0Data{idx}.fdp)])];
    idx
end

for idx = 1:length(all_metric)
    SetArray = [SetArray, repmat(tb.experiment{idx}(5),[1,length(S0Data{idx}.fdp)])];
end

for unit = 1:size(rsp_t,1)
    tmp = rsp_t(unit,:,:);
    rsp_t(unit,:,:) = (tmp-mean(tmp(:))) ./ std(tmp(:));
    unit
end
toc
%%

close all
cc = colormap_matplotlib('tab10',10);

img_idx = {1:12,13:24,25:36}; psthr = S0Data{1}.glb.PsthRange;
figure; set(gcf,'Position',[500 200 1250 800])
set_order = [1,23,2,3];
for s = 1:length(set_order)
    S0 = S0Data{set_order(s)};
    subplot(3,4,s); hold on
    [~,dp_order]=sort(S0.fb,'descend');
    AvgRsp = mean(S0.rsp_mtx(dp_order,1:36,find(psthr==60):find(psthr==300)),3);
    AvgRsp = zscore(AvgRsp,0,2);
    imagesc(AvgRsp)
    clim([-2,2]); xline([12.5,24.5],LineWidth=1); xlim([0.5,36.5]);ylim([0,length(dp_order)]); xticks([6,18,30])
    xticklabels({'Body','Face','Object'}); ylabel('Unit');xlabel('Stimuli'); axis square
    title(all_metric(set_order(s)).name(1:end-12)) 
    set_font(8)
end

for MA_case = ['M','A']
    switch MA_case
        case 'M'
            AP = 'middle ';row = 1;
        case 'A'
            AP = 'anterior ';row = 2;
    end
    unit_here = find(MA_array==MA_case);
    fdp_here = fdp(unit_here); bdp_here = bdp(unit_here);

    for dp_case = 1:2
        switch dp_case
            case 1
                unit_here = find(MA_array==MA_case & fdp>dp_thres & SetArray=='1');
                nm='face unit';
                col=1;
            case 2
                unit_here = find(MA_array==MA_case & bdp>dp_thres & SetArray=='1');
                nm='body unit';
                col=2;
        end
        subplot(3,4,2+row*2+col); hold on
        for c = 1:3
            data = squeeze(mean(rsp_t(unit_here,img_idx{c},:),2));
            m(c,:) = mean(data); ci = tinv(0.975, size(data,1)-1) .* std(data,[],1) ./ sqrt(size(data,1));
            shadedErrorBar(psthr,m(c,:),ci,'lineprops',{'Color', cc(c,:),'LineWidth',1},'patchSaturation',0.5)
            title(sprintf('%s%s (%d)',AP,nm,length(unit_here)))
        end
        ylim([min(m(:))*1.5, max(m(:))*1.2]);xlim([-50,600]);xline(0,'LineStyle',':','Color',[0.5,0.5,0.5,0.5]);xline(500,'LineStyle',':','Color',[0.5,0.5,0.5,0.5]);ylabel('Norm. rsp. '); xlabel('Time (ms)'); axis square;set_font(8)
    end
end

MA_case = 'A'; AP = 'anterior '; row = 3;
unit_here = find(MA_array==MA_case);
fdp_here = fdp(unit_here); bdp_here = bdp(unit_here);
for dp_case = 1:2
    switch dp_case
        case 1
            unit_here = find(MA_array==MA_case & fdp>dp_thres & SetArray=='2');
            nm='face unit';
            col=1;
        case 2
            unit_here = find(MA_array==MA_case & bdp>dp_thres & SetArray=='2');
            nm='body unit';
            col=2;
    end
    subplot(3,4,2+row*2+col); hold on
    for c = 1:3
        data = squeeze(mean(rsp_t(unit_here,img_idx{c},:),2));
        m(c,:) = mean(data); ci = tinv(0.975, size(data,1)-1) .* std(data,[],1) ./ sqrt(size(data,1));
        shadedErrorBar(psthr,m(c,:),ci,'lineprops',{'Color', cc(c,:),'LineWidth',1},'patchSaturation',0.5)
        title(sprintf('%s (%d)',nm,length(unit_here)))
    end
    ylim([min(m(:))*1.5, max(m(:))*1.2]);xlim([-50,600]);xline(0,'LineStyle',':','Color',[0.5,0.5,0.5,0.5]);xline(300,'LineStyle',':','Color',[0.5,0.5,0.5,0.5]);ylabel('Norm. rsp. '); xlabel('Time (ms)'); axis square;set_font(8)
end

i1=imread("Data\stim\Anagram\003.png"); i1=add_edge(i1, 255*cc(1,:),45);
i2=imread("Data\stim\Anagram\025.png"); i2=add_edge(i2, 255*cc(2,:),45);
i3=imread("Data\stim\Anagram\071.png"); i3=add_edge(i3, 255*cc(3,:),45);
subplot(3,4,[11,12]); imshow([i1,i2,i3]); title('Body   Face   Object')

figsave('Fig/FS1','FS1');