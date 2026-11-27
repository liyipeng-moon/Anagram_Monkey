function p_fdr = ttest_groups(PSTHs,type,PSTHR)
t1 = find(PSTHR==-25);
t2 = find(PSTHR==350);
switch type
    case 'groups'
        PSTH1=PSTHs{1};
        PSTH2=PSTHs{2};
        ntime = size(PSTH1,1);
        p_obs = nan(1, ntime);
        for t = 1:ntime
            [~, p_obs(t), ~, ~] = ttest2(PSTH1(t,:), PSTH2(t,:),'Tail','right');
        end
    case 'L0'
        ntime = size(PSTHs,1);
        p_obs = nan(1, ntime);
        for t = 1:ntime
            [~, p_obs(t), ~, ~] = ttest(PSTHs(t,:),0.5,'Tail','right');
        end
    case 'S0'
        ntime = size(PSTHs,1);
        p_obs = nan(1, ntime);
        for t = 1:ntime
            [~, p_obs(t), ~, ~] = ttest(PSTHs(t,:),0.5,'Tail','left');
        end
end
p_obs_valid_time = p_obs(t1:t2);
[p_obs_frd] = mafdr(p_obs_valid_time, 'BHFDR', true);
p_fdr = ones(size(p_obs));
p_fdr(t1:t2) = p_obs_frd;
p_fdr = find(p_fdr<0.01);
end
