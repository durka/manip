function [params, ct, cr, rt, rr] = unpack_screw(p)
    dims = ceil((length(p)-1)/4);
    i = 1;
    n = dims*(dims-1)/2;
    
    ct = p(i:i+dims-1); i = i+dims;
    cr = p(i:i+n-1);    i = i+n;
    params{1} = T(ct)*R(cr);
    
    %fprintf('\t\t\tunpacked %s, %s;', mat2str(t), mat2str(r));
    
    rt = p(i:i+dims-1); i = i+dims;
    rr = p(i:i+n-1);    i = i+n;
    params{2} = T(rt)*R(rr);
    
    %fprintf(' %s, %s => %s, %s\n', mat2str(t), mat2str(r), mat2str(params{1}), mat2str(params{2}));
    
    params{3} = p(i);
end
