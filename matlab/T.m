function t = T(params)
    d = length(params);
    t = eye(d+1);
    t(1:d,d+1) = params';
end