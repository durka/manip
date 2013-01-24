function params = unpack_rigid(p, dims)
	
    t = p(1:dims);
    r = p(dims+1:end);
    params{1} = Tmex(t)*Rmex(r);
    
end
