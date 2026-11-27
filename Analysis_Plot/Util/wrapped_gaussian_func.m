function y = wrapped_gaussian_func(params, theta)
    mu = params(1);
    sigma = params(2);
    A = params(3);
    b = params(4);
    y = zeros(size(theta));
    K = 3;
    for k = -K:K
        y = y + A * exp(-(theta - mu + 2*pi*k).^2 ./ (2*sigma^2));
    end
    y = y + b;
end