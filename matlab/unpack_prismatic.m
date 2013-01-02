function params = unpack_prismatic(p, dims)
	i = 1;
    
    t = p(i:i+dims-1); i = i+dims;
    r = p(i:end-dims);
    params{1} = Tmex(t)*Rmex(r);
    
    params{2} = p(end-dims+1:end);
end
