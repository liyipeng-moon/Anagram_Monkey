function d = dprime_xy(a,b)
d = (mean(a)-mean(b)) ./ sqrt(0.5*(var(a)+var(b)));