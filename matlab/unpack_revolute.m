function params = unpack_revolute(p, dims)
    i = 1;
    n = dims*(dims-1)/2;
    
    t = p(i:i+dims-1); i = i+dims;
    r = p(i:i+n-1);    i = i+n;
    params{1} = T(t)*R(r);
    
    %fprintf('\t\t\tunpacked %s, %s;', mat2str(t), mat2str(r));
    
    t = p(i:i+dims-1); i = i+dims;
    r = p(i:i+n-1);    i = i+n;
    params{2} = T(t)*R(r);
    
    %fprintf(' %s, %s => %s, %s\n', mat2str(t), mat2str(r), mat2str(params{1}), mat2str(params{2}));
end
