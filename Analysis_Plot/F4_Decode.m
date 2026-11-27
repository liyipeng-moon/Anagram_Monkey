%% Plus
root_dir = load('root_dir.mat').root_dir; cd(root_dir); addpath(genpath(root_dir));
close all; clear; clc
all_prep = dir('Data\s0\*AnagramP*.mat');
cc_bin = 1;
%% Load session wise data
for d_idx =  1:length(all_prep)
    file_name = all_prep(d_idx).name;
    set_name = identify_set_name(file_name);
    load(fullfile("Data/decode_l2/",sprintf('PlusDecode_%s_metric.mat',file_name(1:end-4))))
    [img_pool,stimuli_idx,combined_pool,c12,c38, cm] = load_stim(set_name);
    [f_compare, critical_point, anagramIdx] = gen_famuli_compare(set_name);
    %
    for family_idx = 1:length(f_compare)
        figure; set(gcf,'Position',[500 150 1250 750])
        real_family_idx = (f_compare{family_idx}(24)-36)/ (24);
        img1 = combined_pool{real_family_idx}; subplot(3,3,[7,8,9]);imshow(img1)
        SS_1 = f_compare{family_idx}(49); SS_2 = f_compare{family_idx}(97);

        subplot(3,3,1);
        img2 = squeeze(img_pool(SS_1,:,:,:)); img3 = squeeze(img_pool(SS_2,:,:,:));
        imshow([img2;img3])

        SS = f_compare{family_idx}(1:24);
        Score_mean_24 = []; Score_std = [];
        
        for case_idx = 1:24
            trial_now = find(trial_idx==SS(case_idx) | trial_idx==SS(case_idx)+24);
            Score_now = smooth_score(squeeze(score(family_idx,:, trial_now,1)),cc_bin);
            MeanScore = mean(Score_now,2);
            score_over24{d_idx, anagramIdx(family_idx), case_idx} = squeeze(score_mean(family_idx, trial_now, 1));
            Avg_Score =  squeeze(score_mean(family_idx,trial_now,1));
            Score_std(case_idx) = std(Avg_Score)./sqrt(length(Avg_Score));
            Score_mean_24(case_idx) = mean(Avg_Score);
            subplot(3,3,2); hold on
            plot(PSTHR, MeanScore, Color=cm(case_idx,:)); xlim([-25,350]); ylim([-0.1,1.1])
            subplot(3,3,3); hold on
            errorbar(15*case_idx, Score_mean_24(case_idx), Score_std(case_idx),'Color',cm(case_idx,:),'LineWidth',2,CapSize=0);
            scatter(15*case_idx, Score_mean_24(case_idx), 10,'MarkerFaceColor',cm(case_idx,:),MarkerEdgeAlpha=0)
        end
        h = plot(15:15:360,Score_mean_24,'Color',[0.5,0.5,0.5],'LineWidth',1); uistack(h, 'bottom');
        xlim([7.5,367.5]); ylim([-0.1,1.1]); 
        yline(0.5,LineWidth=1,LineStyle="--");
        

        imgbig=[];
        score_save{d_idx,anagramIdx(family_idx),1}=[]; 
        score_save{d_idx,anagramIdx(family_idx),2}=[];
        score_avg_save{d_idx,anagramIdx(family_idx),1}=[];
        score_avg_save{d_idx,anagramIdx(family_idx),2}=[];

        for examplar_case = 1:2
            imgrow = []; Score_vec = []; trial_loc = [];
            central = squeeze(critical_point(family_idx,examplar_case,2));
            for examplar_idx = 1:3
                image_index_all = SS(critical_point(family_idx,examplar_case,examplar_idx));
                img = squeeze(img_pool(image_index_all,:,:,:));
                imgrow = [img, imgrow];
                trial_loc = [trial_loc, find(trial_idx==image_index_all | trial_idx==image_index_all+24)];
            end
            Score_now = smooth_score(squeeze(score(family_idx,:, trial_loc ,1)),cc_bin);
            Score_vec = [Score_vec, Score_now];
            score_save{d_idx,anagramIdx(family_idx),examplar_case} = Score_now;
            score_avg_save{d_idx,anagramIdx(family_idx),examplar_case} = score_mean(family_idx,trial_loc,1);

            imgbig = [imgbig; add_edge(imgrow,uint8(255*cm(central,:)),20)];
            subplot(3,3,5); hold on
            m=mean(Score_vec'); e=std(Score_vec')./sqrt(size(Score_vec,2));
            shadedErrorBar(PSTHR,m,e,'patchSaturation',0.5,'lineProps',{'Color', cm(central(1),:)})
        end

        p_obs = ttest_groups(squeeze(score_save(d_idx,anagramIdx(family_idx),:)),'groups',PSTHR);
        [b] = find(p_obs<0.001);

        range_data = [mean(score_save{d_idx,anagramIdx(family_idx),1}'),mean(score_save{d_idx,anagramIdx(family_idx),2}')];
        yl = 1.1*max(abs(range_data-0.5));
        yd = min([1.1*max(range_data),1,yl+0.5]);

        for t = 1:size(b)
            scatter(PSTHR(b),yd,10,"filled",MarkerFaceColor=[0,0,0],MarkerEdgeAlpha=0);
        end
        xlim([-25,350]);ylim([-yl,yl]+0.5);xlabel('Time (ms)');ylabel('Decoding confidence');yticks([0:0.25:1]);
        yline(0.5,LineWidth=1,LineStyle="--");
        subplot(3,3,6); imshow(imgbig);

%         sgtitle(file_name)
%         figsave(fullfile("FIG/newF4"),sprintf('F4z_PlusDecode%02d_%s',anagramIdx(family_idx),file_name(1:end-4)))
    end
end
%% Test combined data
[img_pool,combined_pool24,combined_pool12,combined_pool8,cm] = load_stimPP; 
[f_compare, critical_point, anagramIdx] = gen_famuli_compare('AnagramPP');
for family_idx = 1:length(f_compare)
    SS_1 = f_compare{family_idx}(49); SS_2 = f_compare{family_idx}(97);
    img2 = squeeze(img_pool(SS_1,:,:,:)); img3 = squeeze(img_pool(SS_2,:,:,:));
    stim{family_idx} = [img2;255*ones([200,300,3]);img3];
    A_1 = f_compare{family_idx}(critical_point(family_idx,1,2));
    A_2 = f_compare{family_idx}(critical_point(family_idx,2,2));
    img2 = squeeze(img_pool(A_1,:,:,:)); img3 = squeeze(img_pool(A_2,:,:,:));
    img2 = add_edge(img2, [255,0,0],20);img3 = add_edge(img3, [0,0,255],20);
    stim_a{family_idx} = [img2;255*ones([100,340,3]);img3];
end
%% Show Data
close all
figure;set(gcf,'Position', [1,1,1920,1080]);c = {'r','b'};
tiledlayout(5,10,'TileSpacing','compact','Padding','compact');
for anagram_idx = 1:10
    nexttile; imshow(stim{anagram_idx});
    % Plot time course
    nexttile; hold on;
    trace_here{1} = [];  trace_here{2} = [];
    for case_now = 1:2
        for ses = 1:size(score_save,1)
            trace_here{case_now} = [trace_here{case_now}, score_save{ses,anagram_idx,case_now}];
        end
        trace_here{case_now} = trace_here{case_now}';
        data = trace_here{case_now};
        m = mean(data); e = std(data)./sqrt(size(data,1));
        shadedErrorBar(PSTHR, m,e,'patchSaturation',0.5,'lineProps',{'Color',c{case_now}})
    end
    D1 = trace_here{1}'; D2 = trace_here{2}';
    p_sig_t = ttest_groups({D1,D2},'groups',PSTHR);
    scatter(PSTHR(p_sig_t),0.95,10,"filled",MarkerFaceColor=[0,0,0],MarkerEdgeAlpha=0);

    p_sig_t = ttest_groups(D1,'L0',PSTHR);
    scatter(PSTHR(p_sig_t),0.9, 10,"filled",MarkerFaceColor=c{1},MarkerEdgeAlpha=0);

    p_sig_t = ttest_groups(D2,'S0',PSTHR);
    scatter(PSTHR(p_sig_t),0.85, 10,"filled",MarkerFaceColor=c{2},MarkerEdgeAlpha=0);

    xlim([-25,350]); ylim([0,1]); xlabel('Time (ms)'); ylabel('Score')
    yline(0.5,LineWidth=1,LineStyle="--");

    set_font(10)
    % Plot Averaged Result
    nexttile; hold on;yline(0.5,Color=[0.5,0.5,0.5],LineStyle="--")
    for case_now = 1:2
        data_now{case_now} = [];
        for ses = 1:size(score_save,1)
            data_now{case_now} = [data_now{case_now}, squeeze(score_avg_save{ses,anagram_idx,case_now})];
        end
        d = data_now{case_now}; mean_val(anagram_idx,case_now) = mean(d,'omitnan'); e = std(d,'omitnan')./sqrt(length(d));
        bar(case_now,mean_val(anagram_idx,case_now),FaceColor=c{case_now},FaceAlpha=0.5,EdgeAlpha=0)
        errorbar(case_now, mean_val(anagram_idx,case_now), e,'Color',c{case_now})
    end
    [~,p,~,stats] = ttest2(data_now{1}, data_now{2});
    [~,p1,~,stats1] = ttest(data_now{1},0.5,'Tail','right');
    [~,p2,~,stats2] = ttest(data_now{2},0.5,'Tail','left');
    title(sprintf('t(%d)=%.02f, pval:%.04f',stats.df,stats.tstat,p))
    
    val = 0.8;
    text(1,val,judge_p(p1),'FontSize',12,'HorizontalAlignment','center','VerticalAlignment','middle')
    text(2,val,judge_p(p2),'FontSize',12,'HorizontalAlignment','center','VerticalAlignment','middle')
    text(1.5, 0.96,judge_p(p),'FontSize',12,'HorizontalAlignment','center','VerticalAlignment','middle')

    plot([1,2],[0.9,0.9],Color='k',LineWidth=0.5);ylim([0,1]); xticks([1,2])
    yline(0.5,LineWidth=1,LineStyle="--");

    set_font(10)

    nexttile; imshow(stim_a{anagram_idx});
    nexttile; hold on;
    for case_now = 1:24
        data_here = [];
        for ses = 1:size(score_save,1)
            data_here = [data_here, score_over24{ses,anagram_idx,case_now}];
        end
        m_save(case_now) = mean(data_here); e(case_now) = std(data_here)./sqrt(length(data_here));
        errorbar(15*case_now, m_save(case_now), e(case_now), 'Color',cm(case_now,:),'LineWidth',2,'CapSize',0)
    end
    H=plot(15:15:360,m_save,'LineWidth',1,Color=[0.5,0.5,0.5]);uistack(H, 'bottom');
    xticks([90,180,270]);
    xlim([7.5,367.5])
    xlabel('Angles')
    xlim([7.5,367.5]); ylim([0,1])
    yline(0.5,LineWidth=1,LineStyle="--");
    set_font(10)
end
figsave(fullfile('Fig','newF4'), 'F4A_GroupAvg')

[~,p,~,stats] = ttest(mean_val(:,1), mean_val(:,2));
figure; set(gcf,'Position', [1,41,550,175])
subplot(1,3,1); hold on; yline(0.5,LineWidth=1,LineStyle="--");
for s = 1:10
    plot([1,2], mean_val(s,:),Color=[0.5,0.5,0.5],LineWidth=0.5)
end
for ca = 1:2
    data = mean_val(:,ca);
    bar(ca,mean(data),FaceColor=c{ca},FaceAlpha=0.5,EdgeAlpha=0)
    errorbar(ca,mean(data),std(data)./sqrt(10),Color=c{ca},LineWidth=2);
end
ylim([0,1]);xticks([1,2])
ylabel('Score')
title(sprintf('t(%d)=%.02f, pval:%.04f',stats.df,stats.tstat,p))
set_font(8)
% 
% subplot(1,3,2); hold on;
% data_diff=[mean_val(:,1)-mean_val(:,2)];
% [h,p,ci,stats] = ttest(data_diff, 0, Tail="right");
% histogram(data_diff,-0.6:0.1:0.6,'EdgeAlpha',0,FaceColor=[0.5,0.5,0.5])
% add_histogram_mean(data_diff)
% title(sprintf('t(%d)=%.02f, pval:%.07f \n median=%.02f',stats.df,stats.tstat,p,mean(data_diff)))
% xlabel('Difference')
% ylabel('Count')
% set_font(8)

subplot(1,3,2); hold on;
data_from_05=[mean_val(:,1)-0.5; 0.5-mean_val(:,2)];
[h,p,ci,stats] = ttest(data_from_05, 0, Tail="right");
histogram(data_from_05,-0.5:0.1:0.5,'EdgeAlpha',0,FaceColor=[0.5,0.5,0.5])
add_histogram_mean(data_from_05)
title(sprintf('t(%d)=%.02f, pval:%.07f \n median=%.02f',stats.df,stats.tstat,p,mean(data_from_05)))
xlabel('Bias toward exemplar')
ylabel('Count')
set_font(8)
    
figsave(fullfile('Fig','newF4'), 'F4B_CombinedTest')