function [params, t, r] = unpack_rigid(p)
    dims = ceil(length(p)/2);

    t = p(1:dims);
    r = p(dims+1:end);
    params{1} = Tmex(t)*Rmex(r);
    
end
