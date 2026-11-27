function [param_vm,param_wg,self_rho] = fit_distribution(rsp, trial_idx, ss)
param_vm = zeros([length(ss),5]); 
param_wg = zeros([length(ss),5]);
self_rho = zeros([1,length(ss)]); 

for stims_family = 1:length(ss)
    stim_idx = ss{stims_family};
    deg_array = []; rsp_array = []; 
    r1 = []; r2 = []; rsp24 = [];
    for example_idx = 1:length(stim_idx)
        deg_here = (example_idx-1)*15;
        img_loc = find(trial_idx==stim_idx(example_idx));
        deg_array = [deg_array, deg_here*ones([1,length(img_loc)])];
        rsp_here= rsp(img_loc);
        rsp_array = [rsp_array, rsp_here];
        r1(example_idx) = mean(rsp_here(1:2:end));
        r2(example_idx) = mean(rsp_here(2:2:end));
        rsp24(example_idx) = mean(rsp_here);
    end

    self_rho(stims_family) = corr(r1',r2');
    theta_here = deg2rad(deg_array);
    y_here = rsp_array';

    theta24 = deg2rad(15*((1:24)-1));
    %%
    options = optimoptions('lsqcurvefit','MaxFunctionEvaluations',10000, 'MaxIterations',10000,'Display','off', 'TolFun',1e-6,'TolX',1e-6);
    vm_model = @(p,theta) p(4) + p(3) * exp(p(2) * cos(theta - p(1))) / (2*pi*besseli(0,p(2)));
    wg_model = @(p, th) wrapped_gaussian_func(p, th);
    [~,xxx] = max(rsp24);
    peakMu = deg2rad((xxx-1)*15);
    RangeRsp = max(rsp24)-min(rsp24);
    min_rsp = min(rsp24); meanrsp = mean(rsp24); max_rsp=max(rsp24);
    %% Do for vmpar
    p0 = [peakMu, 1, RangeRsp, min_rsp];
    lb = [0, 0, 0, 0];
    ub = [2*pi, 10, 5*RangeRsp, max_rsp];
    p_vm = lsqcurvefit(vm_model, p0, theta_here, y_here', lb, ub,options);
    param_vm(stims_family,1:4) = p_vm;
    r_hat_vm = vm_model(p_vm,theta24);
    param_vm(stims_family,5) = corr(r_hat_vm', rsp24');
    %% Do for WG
    p0 = [peakMu, pi/8, RangeRsp, min_rsp];
    lb = [0, 0.0001, 0, 0];
    ub = [2*pi, 5*pi, 5*RangeRsp, max(rsp_array)*2];
    p_wg = lsqcurvefit(wg_model, p0, theta_here, y_here', lb, ub,options);
    param_wg(stims_family,1:4) = [p_wg(1),p_wg(2),p_wg(3),p_wg(4)];
    r_hat_wg = wrapped_gaussian_func(p_wg, theta24);
    param_wg(stims_family,5) = corr(r_hat_wg', rsp24');
end
    self_rho = (2*self_rho)./(1+self_rho);
end