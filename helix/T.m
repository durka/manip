function t = T(params)
    d = length(params);
    t = eye(d+1);
    if isa(params, 'sym')
        t = sym(t);
    end
    t(1:d,d+1) = params;
end