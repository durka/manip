function params = guess_prismatic(t1, r1, ~, ~, t3, ~)

    params = [t1 r1, (t3 - t1)/norm(t3 - t1)];

end
