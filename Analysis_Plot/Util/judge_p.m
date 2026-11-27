function stars = judge_p(p)
if(p>0.05)
    stars = 'n.s.';
elseif(p<0.05 && p>0.01)
    stars = '*';
elseif(p<0.01 && p>0.001)
    stars = '**';
elseif(p<0.001)
    stars = '***';
end