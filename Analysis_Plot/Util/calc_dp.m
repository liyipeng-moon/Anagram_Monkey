function selectivity_family = calc_dp(avg_rsp, Trial1_idx,Trial2_idx)

mean_a = mean(avg_rsp(:,Trial1_idx),2);
mean_b = mean(avg_rsp(:,Trial2_idx),2);
std_a = std(avg_rsp(:,Trial1_idx),0,2);
std_b = std(avg_rsp(:,Trial2_idx),0,2);
selectivity_family = (mean_a - mean_b) ./ sqrt(0.5 * (std_a.^2 + std_b.^2));