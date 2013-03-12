function [params, t, r, u] = unpack_prismatic(p)
    dims = ceil(length(p)/3);
	i = 1;
    
    t = p(i:i+dims-1); i = i+dims;
    r = p(i:end-dims);
    params{1} = Tmex(t)*Rmex(r);
    
    u = p(end-dims+1:end);
    params{2} = u;
end
