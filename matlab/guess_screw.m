function params = guess_screw(deltas, t1, r1, t2, r2, t3, r3)

    params = [guess_revolute(deltas, t1, r1, t2, r2, t3, r3) 1];
    
end
