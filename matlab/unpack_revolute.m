function [params, ct, cr, rt, rr] = unpack_revolute(p)
    dims = ceil(length(p)/4);
    i = 1;
    n = dims*(dims-1)/2;
    
    ct = p(i:i+dims-1); i = i+dims;
    cr = p(i:i+n-1);    i = i+n;
    params{1} = SEmex(ct,cr);
    
    %fprintf('\t\t\tunpacked %s, %s;', mat2str(t), mat2str(r));
    
    rt = p(i:i+dims-1); i = i+dims;
    rr = p(i:i+n-1);
    params{2} = SEmex(rt,rr);
    
    %fprintf(' %s, %s => %s, %s\n', mat2str(t), mat2str(r), mat2str(params{1}), mat2str(params{2}));
end
