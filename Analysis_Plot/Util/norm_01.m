function rsp = norm_01(rsp)
for u = 1:size(rsp,1)
    tmp = rsp(u,:);
    tmp = tmp-min(tmp);
    if(max(tmp)==0)
        rsp(u,:) = tmp;
        continue
    end
    tmp = tmp./max(tmp);
    rsp(u,:) = tmp;
end