function params = guess_screw(deltas, t1, r1, t2, r2, t3, r3)

    Y = permute(cat(3, deltas{:}), [3 1 2]);
    Y = squeeze(Y(:,1:3,4));
    [a, r, p, plane] = helfit2(Y);
    
    c = [plane(4:6)' plane(7:9)' a];
    [ct, cr] = extract_SE(R(c));
    
    params = [ct, cr, r 0 0, 0 0 0, p];
    
end
