function [fdrp48] = perform_anova_tuning(Trsp, trial_idx)
trial_idx = trial_idx - 36;
trial_idx(trial_idx < 0) = 0; % so that we ignore localizer images
family_num = max(trial_idx)/24; % should be 12 for exp 1
p48 = ones([size(Trsp,1),family_num]);

for u = 1:size(Trsp,1)
    for f = 1:2:family_num
        rsp_array=[]; array48=[];
        family_idx = 24*(f-1)+[1:48]; % don't add 36 since it's substracted in the beginning!!!
        for s = 1:48
            loc = find(trial_idx==family_idx(s));
            array48 = [array48, s*ones([1,length(loc)])];
            rsp_array = [rsp_array, Trsp(u,loc)];
        end
        p48(u,f) = anovan(rsp_array, {array48}, 'model', 'linear', 'display', 'off');
    end
end

fdrp48=ones(size(p48));
for f = 1:2:family_num
    fdrp48(:,f) = mafdr(squeeze(p48(:,f)),'BHFDR', true);
    fdrp48(:,f+1) = fdrp48(:,f);
end